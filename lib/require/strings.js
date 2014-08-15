/*jslint indent: 2 */
/*global define,require */
define(['module', 'messageformat'], function (module, MessageFormat) {
  'use strict';

  var fs = require('fs'), cached = {};

  return {
    version: '0.1.0',

    load: function (name, req, onLoad, config) {
      var file, key, mf, path, pluralFunction, strings;

      if (cached[config.locale + ":" + name] !== undefined)
        onload(cached[config.locale + ":" + name]);
      else {
        // Load in the locale specific formatter
        if(!MessageFormat.locale[config.locale]) {
          path = __dirname + '/' + config.msg.localeLocation + '/' + config.locale + '.js';
          console.log("Loading plural functions at " + path);
          MessageFormat.locale[config.locale] = require(path);
        }

        // Load in the requested string file
        path = __dirname + '/' + config.msg.icuLocation + '/' + config.locale + '/' + name + '.json';
        file = fs.readFileSync(path, 'utf8');
        if (file.indexOf('\uFEFF') === 0) file = file.substring(1);
        strings = JSON.parse(file);

        // Convert the payload to compiled messageformat values
        mf = new MessageFormat(config.locale);
        for (key in strings) {
          strings[key] = mf.compile(strings[key]);
        }

        // Cache the strings to not have to re-read them from disk
        cached[config.locale + ":" + name] = strings;
        onLoad(strings);
      }
    }
  };
});
