'use strict'

###*
 # @ngdoc service
 # @name edudashApp.announcements
 # @description
 # # Announcements Service
 # Fetches and updates listeners when new announcments are available
###

angular.module('edudashApp').factory 'announcements', ['$http', ($http) ->
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
