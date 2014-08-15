define([module], function(module){
  return {
    /**
     * Replace i18n strings in templates. The keys should be wrapped in
     * double curly-braces:
     *
     *     {{i18nKey}}
     *
     * @param strings
     * @param template
     * @return String
     */
    processStrings: function(strings, template) {
      var output;

      // Allow an array of string objects to be passed in
      if( Object.prototype.toString.call(strings) === '[object Array]' ) {
        output = template;
        for (var offset = 0; offset < strings.length; offset++) {
          output = this.processStrings(strings[offset], output);
        }
      } else {
        var key,
            keys = template.match(/\{\{([\w\-,\s]+)\}\}/g),
            parsed,
            value;
        output = template;
        if (keys !== null) {
          for (var offset = 0; offset < keys.length; offset++ )
          {
            parsed = keys[offset].match(/[\w\-,\s]+/i)[0].split(',');
            key = parsed.shift().trim();
            value = parsed.length ? parsed.shift() : null;
            if (strings[key] !== undefined) {
              if (value !== null)
              {
                output = output.replace(keys[offset], strings[key]({VALUE: !isNaN(value.trim()) ? parseInt(value.trim()) : value}));
              } else {
                output = output.replace(keys[offset], strings[key]());
              }
            }
          }
        }
      }
      return output;
    }
  };
});
