angular.module('edudashApp').factory 'announceService', ['$http', ($http) ->
  message = 'Loading...'
  messageListeners = []

  window.setTimeout (() -> messageRecieved 'yo sup???'), 500

  messageRecieved = (newMessage) ->
    message = newMessage
    messageListeners.forEach (listener) -> listener message

  listen = (listener) ->
    listener message
    messageListeners.push listener
    # return a function to call to unsubscribe
    () -> listeners.splice((listeners.indexOf listener), 1)

  listen
]
