{Robot, Adapter, TextMessage} = require 'hubot'
https = require 'https'

class Sqwiggle extends Adapter

  ###################################################################
  # Override the necesary methods
  ###################################################################

  send: (envelope, strings...) ->
    logger = @robot.logger
    logger.debug envelope 
    envelope.room = @room unless envelope.room
    messages = []
    strings.forEach (str) =>
      if str.length < 1024
        args = JSON.stringify
          stream_id  : envelope.room
          text       : str.replace(/[<>]/g, "'")
        messages.push args
      else
        strs = str.match(/(.*?[\n$])/g)
        strCount = strs.length
        i = 1
        s = ""
        while i < strCount
          s += strs[i]
          i++
          if i < strCount
            if s.length + strs[i].length < 1024
              continue
          args = JSON.stringify
            stream_id  : envelope.room
            text       : s.replace(/[<>]/g, "'")
          if s isnt ""
            messages.push args
          s = ""
    @sendMessages messages
    
  sendMessages: (messages) ->
    message = messages.shift()
    @post "/messages", message, () =>
      if messages.length
        @sendMessages messages

  reply: (envelope, strings...) ->
    #TODO

  run: ->
    # Tell Hubot we're connected so it can load scripts
    @emit "connected"
    logger = @robot.logger

    @lastId = 0
    @locked = false
    @token = process.env.HUBOT_SQWIGGLE_TOKEN
    @name  = process.env.HUBOT_SQWIGGLE_BOTNAME or 'sqwigglebot'
    @room  = process.env.HUBOT_SQWIGGLE_ROOM

    return logger.error "No token provided to bot" unless @token
    return logger.error "No team provided to bot" unless @name
    return logger.error "No dedault room to bot" unless @room

    logger.info "-------- Successfully 'connected' as #{@name} --------"

    @startPolling()

  ###################################################################
  # Retrieve messages from sqwiggle
  ###################################################################

  poll: ->
    return if @locked
#    @robot.logger.debug "Polling"
    @locked = true
    path = '/messages'

    if @lastId > 0
      path += "?after_id=#{@lastId}" 
    else
      path += "?limit=1"

    @get path, (foo, body) =>
      try
        responseJson = JSON.parse(body)
      catch e
        @robot.logger.error e
        @locked = false
        return
      if responseJson.length
        @lastId = responseJson[0].id
        @handleMessage msg for msg in responseJson
      @locked = false

  startPolling:  ->
    callback = @poll.bind @
    setInterval callback, 1000
    
  handleMessage: (msg) ->
    return if msg.author.name is @name
      
    author = 
      id: msg.author.id 
      name: msg.author.name

    message = new TextMessage(author, msg.text) 
    message.id = msg.id
    message.room = msg.stream_id
    @receive(message)


  ###################################################################
  # Convenience HTTP Methods for sending data back to Sqwiggle.
  ###################################################################
  get: (path, callback) ->
    @request "GET", path, null, callback

  post: (path, body, callback) ->
    @request "POST", path, body, callback

  request: (method, path, body, callback) ->
    logger = @robot.logger

    host = "api.Sqwiggle.com"

    headers =
      Host: host

    reqOptions =
      agent    : false
      hostname : host
      port     : 443
      auth     : "#{@token}:X"
      path     : path
      method   : method
      headers  : headers

    if method is "POST"
      body = new Buffer body
      reqOptions.headers["Content-Type"] = "application/json"
      reqOptions.headers["Content-Length"] = body.length

    request = https.request reqOptions, (response) ->
      data = ""
      response.on "data", (chunk) ->
        data += chunk

      response.on "end", ->
#        logger.debug response.statusCode
        if response.statusCode >= 400
          logger.error "Sqwiggle services error: #{response.statusCode}"
          logger.error data

        if callback
          try
            callback null, data
          catch err
            callback err, null

        response.on "error", (err) ->
          logger.error "HTTPS response error: #{err}"
          callback? err, null

    if method is "POST"
      request.end body, "binary"
    else
      request.end()

    request.on "error", (err) ->
      logger.error "HTTPS request error: #{err}"
      logger.error err.stack
      callback? err


###################################################################
# Exports to handle actual usage and unit testing.
###################################################################
exports.use = (robot) ->
  new Sqwiggle robot

