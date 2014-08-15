define (require, exports, module) ->

  p = /(git\@|\w{3,5}:\/\/)([\w\-_\.]+)[:\/]([\w\-\_\.]+)\/([\w\-\_\.]+)\.git/

  parse = (uri) ->
    parts = p.exec uri
    parts.shift()
    parts

  {
    parse: parse
  }
