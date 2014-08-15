/*jslint indent: 2 */
/*global define,require */
define(['module'], function (module) {
    'use strict';

  var fs = require('fs');

  return {
    version: '0.1.0',
    load: function (name, req, onload, config) {
      var path = __dirname + '/' + config.baseUrl + 'html/' + name + '.html';
      onload(fs.readFileSync(path, 'utf8'));
    }
  };
});
