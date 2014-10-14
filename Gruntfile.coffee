path      = require 'path'
{ spawn } = require 'child_process'

module.exports = (grunt) ->

  ###
  # Took this from grunt-brunch, since the package doesn't work
  ###
  grunt.registerMultiTask "brunch", "Brunch asset pipeline", ->
    # Get the options
    options = grunt.config('brunch')[@target]
    grunt.verbose.writeflags options, "Options"
    { action, port, async, production } = options
    action ?= 'serve'
    port ?= 8888
    async ?= false
    production ?= false

    # Always run asynchronously unless otherwise specified
    done = @async() unless async

    # Available command list
    brunchPath = path.resolve "#{__dirname}/node_modules/.bin/brunch"
    if (process.platform == "win32")
      brunchPath = brunchPath + ".cmd"
    command = switch action
      when 'serve'
        "#{brunchPath} watch --server --port #{port}"
      when 'watch'
        "#{brunchPath} watch --port #{port}"
      when 'compile'
        "#{brunchPath} build"
      when 'build'
        "#{brunchPath} build -P"

    process.env.BRUNCH_ENV = 'production' if production

    # Run it
    [ cmd, args... ] = command.split ' '
    brunch = spawn cmd, args

    # Capture all output
    brunch.stdout.pipe process.stdout
    brunch.stderr.pipe process.stdout

    # Finish on close
    brunch.on 'close', done unless async

    # Quit child process on exit
    process.on 'exit', ->
      brunch.kill 'SIGHUP'



  ###
  # Grunt config
  ###
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"

    brunch:
      serve:
        action: 'serve'
        port: 8888
        async: false


      watch:
        action: 'watch'

      build:
        action: 'build'
        production: true

    rsync:
      options:
        exclude: [ "*.map" ]
        args: [ "--verbose" ]
        recursive: true

      overlord:
        options:
          src: "public/*"
          dest: "/var/www/smartomato-partner"
          host: "deployer@overlord.whymy.ru"

      production:
        options:
          src: "public/*"
          dest: "/var/www/smartomato-partner"
          host: "deployer@smartomato-web.whymy.ru"

  grunt.loadNpmTasks 'grunt-rsync'

  grunt.registerTask "serve", [ "brunch:serve" ]
  grunt.registerTask "build", [ "brunch:build" ]
  grunt.registerTask "w", [ "brunch:watch" ]

  grunt.registerTask "deploy:overlord",   [ "build", "rsync:overlord"]
  grunt.registerTask "deploy:production", [ "build", "rsync:production"]

  grunt.registerTask "default", [ "serve"]
  grunt.registerTask "deploy",  ["deploy:overlord"]
