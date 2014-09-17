{Robot, Adapter, TextMessage} = require 'hubot'
http = require 'http'

class Sqwiggle extends Adapter

  ###################################################################
  # Override the necesary methods
  ###################################################################
  send: (envelope, strings...) ->
    console.log(envelope)

  reply: (envelope, strings...) ->
    console.log(envelope)
    # for str in strings
    #   @send envelope.user, "@#{envelope.user.name}: #{str}"

  run: ->
    self = @
    @lastId = 0
    @locked = false
    @parseOptions()

    console.log "Sqwiggle adapter options:", @options

    return console.log "No services token provided to Hubot" unless @options.token
    return console.log "No team provided to Hubot" unless @options.name

    # Provide our name to Hubot
    self.robot.name = @options.name

    # Tell Hubot we're connected so it can load scripts
    console.log "Successfully 'connected' as", self.robot.name
    self.emit "connected"

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
    
  ###################################################################
  # Filter messages
  ###################################################################

  handleMessage: (msg) ->
    if msg.text.substring(0, @robot.name.length) == "#{@robot.name}"
      console.log("message #{msg.id} is for this bot")
      author =
        id: msg.author.id 
        name: msg.author.name 
      message = new TextMessage(author, msg.text) 
      message.room = msg.stream_id
      console.log('receiving')
      @receive message
      console.log('message received')


  ###################################################################
  # Convenience HTTP Methods for sending data back to Sqwiggle.
  ###################################################################
  get: (path, callback) ->
    @request "GET", path, null, callback

  post: (path, body, callback) ->
    @request "POST", path, body, callback

  request: (method, path, body, callback) ->
    console.log('request made', path)
    self = @

    #host = "api.Sqwiggle.com"
    host = "localhost"
    headers =
      Host: host

    reqOptions =
      agent    : false
      hostname : host
      # port     : 443
      auth     : "#{@options.token}:X"
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
          self.logError "HTTPS response error:", err
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
  # Parse out config 
  ###################################################################
  
  parseOptions: ->
    @options =
      token         : process.env.HUBOT_SQWIGGLE_TOKEN or "cli_8765fe17fdccc685e753ccea8e6c3bf9"
      name          : process.env.HUBOT_SQWIGGLE_BOTNAME or 'sqwigglebot'


  
###################################################################
# Exports to handle actual usage and unit testing.
###################################################################
exports.use = (robot) ->
  new Sqwiggle robot

