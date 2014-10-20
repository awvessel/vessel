gruntFunction = (grunt) ->

  binDir = 'binaries/Vessel.app'
  contentsDir = "#{binDir}/Contents"
  resourcesDir = "#{contentsDir}/Resources"
  appDir = "#{resourcesDir}/app"
  staticDir = "#{appDir}/static"
  cssDir = "#{staticDir}/css"
  infoPlist = "#{contentsDir}/Info.plist"

  grunt.initConfig

    pkg: grunt.file.readJSON 'package.json'

    checkDependencies:
      this: {}

    devUpdate:
      main:
        options:
          updateType: 'prompt'
          reportUpdated: false
          semver: true

    clean:
      app: appDir
      css: "#{resourcesDir}/*.css"
      fonts: "#{appDir}/static/fonts"
      icon: "#{resourcesDir}/*.icns"
      dist: binDir

    coffee:
      app:
        expand: true
        cwd: 'src/app'
        src: ['*.coffee', '*/*.coffee']
        dest: appDir
        ext: '.js'
        flatten: false
        sourceMap: true

    coffeelint:
      options:
        indentation:
          value: 2
          level: 'warn'
      app:
        files:
          src: ['src/**/*.coffee', 'src/**/*/*.coffee']
    copy:
      app:
        files: [
          {expand: true, src: 'resources/Info.plist', dest: contentsDir, flatten: true, filter: 'isFile'}
          {expand: true, src: 'resources/Credits.rtf', dest: resourcesDir, flatten: true, filter: 'isFile'}
          {expand: true, src: 'resources/vessel.icns', dest: resourcesDir, flatten: true, filter: 'isFile'}
          {expand: true, cwd: 'resources', src: 'fonts/**', dest: staticDir}
          {expand: true, cwd: 'resources', src: 'images/**', dest: appDir}
          {expand: true, cwd: 'resources', src: 'scripts/**', dest: appDir}
          {expand: true, cwd: 'resources', src: 'templates/**', dest: appDir}
          {expand: true, src: 'package.json', dest: appDir, filter: 'isFile'}
          {expand: true, cwd: 'src', src: 'startup/**', dest: appDir}
          {expand: true, cwd: 'src', src: 'renderer/**', dest: appDir}
          {expand: true, src: 'lib/**', dest: appDir + '/renderer'}
          {expand: true, src: 'lib/jquery.js', dest: appDir + '/startup', flatten: true, filter: 'isFile'}
          {expand: true, src: 'resources/vessel.css', dest: cssDir, flatten: true, filter: 'isFile'}
        ]

    'download-atom-shell':
      version: '0.18.1'
      outputDir: '.atom-shell'

    less:
      development:
        options:
          cleancss: true
          paths: ['src/less', 'src/less/font-awesome']
        files:
          'resources/vessel.css': 'src/less/bootstrap.less'

    shell:
      prep:
        command: 'scripts/prep.sh'
        options:
          stdout: true
          stderr: true
          failOnError: true
      dist:
        command: "scripts/dist.sh <%= pkg.version %>"
        options:
          stdout: true
          stderr: true
          failOnError: false
      kill:
        command: 'pkill -9 Vessel'
        options:
          stdout: false
          stderr: false
          failOnError: false
      run:
        command: 'binaries/Vessel.app/Contents/MacOS/Vessel'
        options:
          stdout: true
          stderr: true
          failOnError: true

    template:
      info:
        options:
          data:
            productName: "<%= pkg.productName %>"
            version: "<%= pkg.version %>"
        files:
          'resources/Info.plist': 'resources/Info.plist.tmpl'

    watch:
      config:
        files: ['Gruntfile.coffee']
        options:
          reload: true
      coffee:
        files: ['src/app/*.coffee']
        tasks: ['coffeelint', 'coffee', 'restart']
      less:
        files: ['src/less/*.less']
        tasks: ['less']
      package_json:
        files: ['package.json']
        tasks: ['npm-install']
      source:
        files: ['lib/**',
                'resources/**',
                'src/renderer/**']
        tasks: ['coffeelint', 'copy', 'restart']

  grunt.loadNpmTasks 'grunt-check-dependencies'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-dev-update'
  grunt.loadNpmTasks 'grunt-download-atom-shell'
  grunt.loadNpmTasks 'grunt-npm-install'
  grunt.loadNpmTasks 'grunt-shell-spawn'
  grunt.loadNpmTasks 'grunt-template'

  grunt.registerTask 'default', ['compile']
  grunt.registerTask 'setup',   ['checkDependencies', 'devUpdate', 'download-atom-shell','shell:prep']
  grunt.registerTask 'lint',    ['coffeelint:app']
  grunt.registerTask 'compile', ['lint', 'coffee', 'less', 'template', 'copy']
  grunt.registerTask 'build',   ['setup', 'compile', 'shell:dist']
  grunt.registerTask 'run',     ['shell:run']

module.exports = gruntFunction
