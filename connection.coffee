request = require 'request'
colors  = require 'colors'

helpers = require './helpers'

#request = request.defaults({ proxy: '' });

class Connection

  token: null
  server: null
  topics: []
  partnerId: null
  mirror: null

  checkEventsDelay: 2000

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
      setTimeout(@lookForPartner.bind @, helpers.random(@checkEventsDelay, @checkEventsDelay * 2))

  generateToken: ->
    # Ripped from Omegle's main lib
    token = ''
    for i in [0..8]
      c = Math.floor 32 * Math.random()
      token = token + "23456789ABCDEFGHJKLMNPQRSTUVWXYZ".charAt c
    token

  lookForPartner: =>
    @partnerId = null
    @log 'Looking for a partner'
    params = [
      ['rcs', '1'],
      ['firstevents', '1'],
      ['spid', ''],
      ['randid', @token],
      ['topics', JSON.stringify(@topics)],
      ['lang', 'en']
    ]
    url = @server + 'start' + helpers.fromArrayToQuery params
    request helpers.getRequestObject(url), (err, response, body) =>
      if err
        @log 'Error with request (looking for partner), retrying...'.red
        return setTimeout @lookForPartner.bind(@), 1000
      @handleOmegleEvents.call @, body

  checkOmegleEvents: =>
    url = @server + 'events'
    request.post helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      @log 'Error with request (getting events)'.red if err
      if body is 'null'
        return setTimeout @checkOmegleEvents.bind(@), @checkEventsDelay
      @handleOmegleEvents.call @, body
      setTimeout @checkOmegleEvents.bind(@), @checkEventsDelay

  handleOmegleEvents: (body) =>
    body = '[]' if !body
    body = (JSON.parse '{ "pew" : ' + body + '}').pew
    if !@partnerId
      if body.clientID
        return @partnerFound(body.clientID)
      else
        return setTimeout @lookForPartner.bind(@), @checkEventsDelay
    else
      body = [] if !body or !body.map
      body.map (cur) =>
        @handleOmegleEvent.call @, cur

  handleOmegleEvent: (event) =>
    events =
      gotMessage: @messageReceived.bind @
      typing: @partnerTyped.bind @
      stoppedtyping: @partnerStoppedTyping.bind @
      strangerDisconnected: @partnerDisconnected.bind @
      recaptchaRequired: @recaptchaRequired.bind @
    if events[event[0]]
      events[event[0]](event)

  partnerFound: (partnerId) =>
    @log 'Partner found for ' + @token
    @partnerId = partnerId
    @checkOmegleEvents.call @

  messageReceived: (event) =>
    @mirror.gotMessage(@, event[1])

  partnerTyped: (event) =>
    @mirror.typing(@)

  partnerDisconnected: (event) =>
    @mirror.strangerDisconnected(@)

  partnerStoppedTyping: (event) =>
    @mirror.stoppedTyping(@)

  sendMessage: (msg) =>
    url = @server + 'send'
    params =
      id: @partnerId,
      msg: msg
    request helpers.getRequestObject(url, params), (err, response, body) =>
      if body is 'win'
        # @log 'Message sent to ' + @partnerId
      else
        @log 'Message send failed'

  sendTyping: =>
    url = @server + 'typing'
    request helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      if body is 'win'
        @log 'Typing flag sent'
      else
        @log 'Typing sent failed'

  sendStopTyping: =>
    url = @server + 'stoppedtyping'
    request helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      if body is 'win'
        @log 'Not typing flag sent'
      else
        @log 'Not typing flag is not sent'

  sendDisconnect: =>
    url = @server + 'disconnect'
    request helpers.getRequestObject(url, {id: @partnerId}), (err, response, body) =>
      if body is 'win'
        @log 'Disconnected successfully'
      else
        @log 'Not disconnected'

  recaptchaRequired: ->
    @log 'Recaptcha required, try changing proxy settings...'
    return process.exit()

  flushPatnerId: =>
    @partnerId = null

  log: (msg) ->
    console.log (@token + ': ').green.bold + msg.white

module.exports = Connection
