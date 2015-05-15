angular.module('edudashApp').factory 'announceService', ['$http', ($http) ->
  message = null
  messageListeners = []

  window.setTimeout (() -> messageRecieved 'Some announcement: ...'), 200

  messageRecieved = (newMessage) ->
    message = newMessage
    messageListeners.forEach (listener) -> listener message

  listen = (listener) ->
    if message
      listener message
    messageListeners.push listener
    # return a function to call to unsubscribe
    () -> listeners.splice((listeners.indexOf listener), 1)

  listen
]
