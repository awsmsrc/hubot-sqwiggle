{Robot, Adapter, TextMessage} = require 'hubot'
http = require 'http'

class Sqwiggle extends Adapter

  ###################################################################
  # Override the necesary methods
  ###################################################################

  send: (envelope, strings...) ->
    console.log("send called")
    console.log(envelope)

  reply: (envelope, strings...) ->
    console.log("reply called")
    console.log(envelope)
    # for str in strings
    #   @send envelope.user, "@#{envelope.user.name}: #{str}"

  run: ->
    # Tell Hubot we're connected so it can load scripts
    @emit "connected"

    @lastId = 0
    @locked = false
    @token = process.env.HUBOT_SQWIGGLE_TOKEN or "cli_8765fe17fdccc685e753ccea8e6c3bf9"
    @name  = process.env.HUBOT_SQWIGGLE_BOTNAME or 'sqwigglebot'

    return console.log "No token provided to bot" unless @token
    return console.log "No team provided to bot" unless @name

    console.log "Successfully 'connected' as", @name

    @startPolling()

  ###################################################################
  # Retrieve messages from sqwiggle
  ###################################################################

  poll: ->
    return if @locked
    console.log "Polling"
    @locked = true
    path = '/messages'

    if @lastId > 0
      path += "?after_id=#{@lastId}" 

    @get path, (foo, body) =>
      responseJson = JSON.parse(body)
      if responseJson.length
        @lastId = responseJson[0].id
        @handleMessage msg for msg in responseJson
      @locked = false

  startPolling:  ->
    callback = @poll.bind @
    setInterval callback, 1000
    
  handleMessage: (msg) ->
    author = 
      id: msg.author.id 
      name: msg.author.name

    message = new TextMessage(author, msg.text) 
    message.id = msg.id
    message.room = msg.stream_id
    console.log('message received')
    console.log(message)
    @receive(message)


  ###################################################################
  # Convenience HTTP Methods for sending data back to Sqwiggle.
  ###################################################################
  get: (path, callback) ->
    @request "GET", path, null, callback

  post: (path, body, callback) ->
    @request "POST", path, body, callback

  request: (method, path, body, callback) ->
    console.log('request made', path)

    #host = "api.Sqwiggle.com"
    host = "localhost"
    headers =
      Host: host

    reqOptions =
      agent    : false
      hostname : host
      # port     : 443
      auth     : "#{@token}:X"
      port     : 3001
      path     : path
      method   : method
      headers  : headers

    if method is "POST"
      body = new Buffer body
      reqOptions.headers["Content-Type"] = "application/json"
      reqOptions.headers["Content-Length"] = body.length

    request = http.request reqOptions, (response) ->
      data = ""
      response.on "data", (chunk) ->
        data += chunk

      response.on "end", ->
        console.log(response.statusCode)
        if response.statusCode >= 400
          console.log "Sqwiggle services error: #{response.statusCode}"
          console.log data

        #console.log "HTTPS response:", data
        callback? null, data

        response.on "error", (err) ->
          console.log "HTTPS response error:", err
          callback? err, null

    if method is "POST"
      request.end body, "binary"
    else
      request.end()

    request.on "error", (err) ->
      console.log "HTTPS request error:", err
      console.log err.stack
      callback? err

  
###################################################################
# Exports to handle actual usage and unit testing.
###################################################################
exports.use = (robot) ->
  new Sqwiggle robot

