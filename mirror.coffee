colors = require 'colors'

Connection = require './connection'

class Mirror

  connections: []

  add: (connection) =>
    @connections.push connection

  getOther: (connection) =>
    for v in @connections
      if v.token isnt connection.token
        return v
      else

  typing: (connection) =>
    console.log (connection.token + ' is typing').bold
    against = @getOther.call @, connection
    against.sendTyping.call against

  stoppedtyping: (connection) =>
    against = @getOther.call @, connection
    against.sendStopTyping.call against

  gotMessage: (connection, message) =>
    console.log connection.token.white + ':' + message.blue.bold
    against = @getOther.call @, connection
    against.sendMessage.call against, message

  strangerDisconnected: (connection) =>
    console.log connection.token + ' is disconnected :('
    against = @getOther.call @, connection
    against.sendDisconnect.call against
    connection.lookForPartner.call connection
    against.lookForPartner.call against

module.exports = Mirror;
