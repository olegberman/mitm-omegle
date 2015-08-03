colors = require 'colors'

Connection = require './connection'

class Mirror

  connections: []

  add: (connection) =>
    @connections.push connection

  getOther: (connection) =>
    for item in @connections
      if item.token isnt connection.token
        return item
      else

  typing: (connection) =>
    console.log (connection.token.green.bold + ' is typing').bold
    against = @getOther.call @, connection
    against.sendTyping.call against

  stoppedtyping: (connection) =>
    against = @getOther.call @, connection
    against.sendStopTyping.call against

  gotMessage: (connection, message) =>
    console.log connection.token.green.bold + ': ' + message.yellow.bold
    against = @getOther.call @, connection
    against.sendMessage.call against, message

  strangerDisconnected: (connection) =>
    console.log connection.token.green.bold + ' disconnected'.red
    against = @getOther.call @, connection
    connection.sendDisconnect.call connection
    connection.lookForPartner.call connection
    against.lookForPartner.call against

module.exports = Mirror;
