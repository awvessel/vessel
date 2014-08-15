nodeRequire = require;

// Hack to fix something wonky with setInterval and setTimeout
var atom = {
  setInterval: window.setInterval,
  setTimeout: window.setTimeout
};

try {
  atom.setTimeout(function(){console.log("hack");}, 1000);
} catch(err) {
  //console.log("Caught expected error from setTimeout");
}
// End hack

requirejs.config({

  baseUrl: '.',
  locale: 'en',
  msg: {
    icuLocation: 'translations',
    localeLocation: 'lib/messageformat/locale'
  },
  paths: {
    backbone: 'lib/backbone',
    base64: 'lib/base64',
    bootstrap: 'lib/bootstrap',
    'bootstrap-select': 'lib/bootstrap-select',
    'coffee-script': 'lib/coffee-script',
    jquery: 'lib/jquery',
    listener: 'lib/listener',
    model: 'lib/model',
    underscore: 'lib/underscore',
    topsort: 'lib/topsort',
    transparency: 'lib/transparency',

    // CodeMirror
    codemirror: 'lib/codemirror',

    // i18n/l10n/date/number formatting
    i18n: 'lib/i18n',
    messageformat: 'lib/messageformat/messageformat',
    moment: 'lib/moment',
    numeral: 'lib/numeral/numeral',

    // RequireJS plugins
    cs:   'lib/require/cs',
    html: 'lib/require/html',
    strings: 'lib/require/strings'
  },

  shim: {
    backbone: {
      deps: ['jquery', 'underscore'],
      exports: 'Backbone'
    },
    bootstrap: {
      deps: ['jquery'],
      exports: 'Bootstrap'
    },
    'bootstrap-select': {
      deps: ['bootstrap'],
      exports: 'BootstrapSelect'
    },
    'coffee-script': {
      exports: 'CoffeeScript'
    },
    cs: {
      deps: ['coffee-script'],
      exports: 'cs'
    },
    listener: {
      deps: ['backbone', 'underscore'],
      exports: 'Listener'
    },
    model: {
      deps: ['backbone', 'underscore'],
      exports: 'Model'
    },
    transparency: {
      deps: ['jquery'],
      exports: 'Transparency'
    },
    underscore: {
      exports: '_'
    }
  }
});

requirejs(['jquery', 'cs!app'], function($, App){
  app = new App();
});
