L.Map.include((window.chrome === undefined ) ? {} : {  // this bug only affects Chrome/chromium
  fire: function (type, data) { // (String[, Object])
    if (!this.hasEventListeners(type)) {
      return this;
    }

    var event = L.Util.extend({}, data, { type: type, target: this });

    var events = this._leaflet_events,  // MONKEY-PATCH CHANGE: hard-code to scoped value
        listeners, i, len, typeIndex, contextId;

    if (events[type]) {
      // make sure adding/removing listeners inside other listeners won't cause infinite loop
      listeners = events[type].slice();

      for (i = 0, len = listeners.length; i < len; i++) {
        listeners[i].action.call(listeners[i].context, event);
      }
    }

    // fire event for the context-indexed listeners as well
    typeIndex = events[type + '_idx'];

    for (contextId in typeIndex) {
      (function() {  // MONKEY-PATCH CHANGE: wrapping this loop body in an
                     // anonymous function prevents the bug
                     // Uncaught TypeError: Cannot read property 'slice' of undefined
                     // that comes from the following line:
        listeners = typeIndex[contextId].slice();
      })(); // END MONKEY-PATCH CHANGE

      if (listeners) {
        for (i = 0, len = listeners.length; i < len; i++) {
          listeners[i].action.call(listeners[i].context, event);
        }
      }
    }

    return this;
  }
});
