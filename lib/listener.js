define(['backbone', 'underscore'], function (Backbone, _) {

  var Listener = function(attributes, options) {
    var attrs = attributes || {};
    options || (options = {});
    this.cid = _.uniqueId('c');
    _.extend(this, _.pick(options, listenerOptions));
    this._bindEvents();
    this.initialize.apply(this, arguments);
  };

  _.extend(Listener.prototype, Backbone.Events, {

    // Initialize is an empty function by default. Override it with your own
    // initialization logic.
    initialize: function(){},

    // Set callbacks, where `this.events` is a hash of
    //
    // *{"event": "callback"}*
    //
    //     {
    //       'eventString'        'callbackMethod',
    //       'other-event':       function(e) { ... }
    //     }
    //
    // pairs. Callbacks will be bound to the view, with `this` set properly.
    _bindEvents: function(events) {
      if (!(events || (events = _.result(this, 'events')))) return this;
      for (var key in events) {
        var method = events[key];
        if (!_.isFunction(method)) method = this[events[key]];
        if (!method) continue;
        Backbone.on(key, method);
      }
      return this;
    }
  });

  var listenerOptions = ['model', 'collection', 'id', 'attributes', 'events'];
  return Listener;
});
