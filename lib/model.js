define(['backbone', 'underscore'], function (Backbone, _) {

  var Model = Backbone.Model.extend({

    constructor: function(attributes, options) {
      var attrs = attributes || {};
      options || (options = {});
      options.parse = true;
      for (var key in this.defaults) {
        if (_.isFunction(this.defaults[key]) === true) {
          attrs[key] = new this.defaults[key](attrs[key]);
        }
      }
      Backbone.Model.apply(this, [attrs, options]);
      for (var key in this.attributes) {
        if (this._isModel(this.attributes[key]) === true ||
            this._isCollection(this.attributes[key]) === true) {
          var self = this;
          this.listenTo(this.attributes[key], 'change', function(obj) {
            self.trigger('change', obj);
          });
        }
      }
    },

    parse: function(attributes, options) {
      var key;
      if (_.isObject(attributes) === true) {
        for (key in attributes) {
          if (this.attributes.hasOwnProperty(key) === true) {
            if (this._isModel(this.attributes[key]) === true ||
                this._isCollection(this.attributes[key]) === true) {
              this.attributes[key].set(attributes[key]);
              delete attributes[key];
            }
          }
        }
      }
      return attributes;
    },

    set: function(attributes, options) {
      Backbone.Model.prototype.set.apply(this,
                                         [this.parse(attributes, options),
                                         options]);
    },

    toJSON: function() {
      var key, obj = {};
      for (key in this.attributes)
        if (this._isCollection(this.attributes[key]) === true)
          obj[key] = this.attributes[key].toJSON();
        else if (this._isModel(this.attributes[key]) === true)
          obj[key] = this.attributes[key].toJSON();
        else
          obj[key] = _.clone(this.attributes[key]);
      return obj;
    },

    _isCollection: function(value) {
      return value instanceof Backbone.Collection;
    },

    _isModel: function(value) {
      return value instanceof Backbone.Model;
    }

  });

  Model.extend = Backbone.Model.extend;

  return Model;
});
