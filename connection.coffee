request = require 'request'
colors  = require 'colors'

helpers = require './helpers'

class Connection

  token: null

  server: null

  topics: []

  partnerId: null

  mirror: null

  constructor: (topics, mirror) ->
    mirror.add(@)
    @topics = topics
    @mirror = mirror
    @token = @generateToken()
    # Initial request to get servers available
    @log 'Getting available servers'
    url = 'http://front' + helpers.random(1, 8) + '.omegle.com/status'
    request helpers.getRequestObject(url), (err, response, body) =>
      return err if err
      obj = JSON.parse body
      @server = 'http://' + obj.servers[helpers.random(0, obj.servers.length-1)] + '/'
      @log 'Server found, working with ' + @server
      setTimeout(@lookForPartner.bind @, helpers.random(1000, 3000))

  generateToken: ->
    # Taken from Omegle's main lib
    token = ''
    for i in [0..8]
      c = Math.floor 32 * Math.random()
      token = token + "23456789ABCDEFGHJKLMNPQRSTUVWXYZ".charAt c
    token

  lookForPartner: ->
    @log 'Looking for a partner'
    params = [
      ['rcs', '1'],
      ['firstevents', '1'],
      ['spid', ''],
      ['randid', @token],
      ['topics', @topics],
      ['lang', 'en']
    ]
    url = @server + 'start' + helpers.fromArrayToQuery params
    request helpers.getRequestObject(url), (err, response, body) =>
      return err if err
      obj = JSON.parse body
      if !obj.clientID or obj.clientID.length < 1
        @log 'Something went wrong, retrying'
        return setTimeout @lookForPartner.bind(@), 1000
      @partnerId = obj.clientID
      @checkOmegleEvents()

  checkOmegleEvents: =>
    url = @server + 'events'
    request.post helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      return setTimeout(@checkOmegleEvents.bind(@), 2000) if body is 'null'
      events = (JSON.parse '{ "pew" : ' + body + '}').pew
      events.map (cur) =>
        @handleOmegleEvent.call @, cur
      setTimeout(@checkOmegleEvents.bind(@), 2000)

  handleOmegleEvent: (event) =>
    events =
      gotMessage: @messageReceived.bind @
      typing: @partnerTyped.bind @
      strangerDisconnected: @partnerDisconnected.bind @
    if events[event[0]]
      events[event[0]](event)
    else
      #@log "I don't yet know the event " + event[0]

  messageReceived: (event) =>
    @mirror.gotMessage(@, event[1])

  partnerTyped: (event) =>
    @mirror.typing(@)

  partnerDisconnected: (event) =>
    @mirror.strangerDisconnected(@)

  sendMessage: (msg) =>
    url = @server + 'send'
    params =
      id: @partnerId,
      msg: msg
    request helpers.getRequestObject(url, params), (err, response, body) =>
      if body is 'win'
        # @log 'Message sent to ' + @partnerId
      else
        @log 'Message send failed to ' + @partnerId

  sendTyping: =>
    url = @server + 'typing'
    request helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      if body is 'win'
        #@log 'Typing flag sent to ' + @partnerId
      else
        @log 'Typing sent failed to ' + @partnerId

  sendStopTyping: =>
    url = @server + 'stoppedtyping'
    request helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      if body is 'win'
        #@log 'Typing flag sent to ' + @partnerId
      else
        @log 'Typing sent failed to ' + @partnerId

  sendDisconnect: =>
    url = @server + 'disconnect'
    request helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      if body is 'win'
        @log 'Disconnected from ' + @partnerId
      else
        @log 'Not disconnected from ' + @partnerId + ' (error)'

  log: (msg) ->
    console.log (@token + ': ').green.bold + msg.white

module.exports = Connection
