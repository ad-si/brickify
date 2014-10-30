coffeelint = require 'coffeelint'
coffeeScript = require 'coffee-script'
winston = require 'winston'
winston.loggers.add 'buildLog',
	console:
		level: 'debug'
		colorize: true

cakeUtilities = require './src/server/cakeUtilities'
lowfab = require './src/server/main'



coffeeScript.register()

buildDir = 'build'
sourceDir = 'src'


task 'linkHooks', 'Links git hooks into .git/hooks', ->
	cakeUtilities.linkHooks()


task 'buildClient', 'Builds the client js files', ->
	cakeUtilities.buildClient()


task 'buildServer', 'Builds the server js files', ->
	cakeUtilities.buildServer(buildDir, sourceDir)


task 'build', 'Builds client and server js files', ->
	cakeUtilities
	.buildClient()
	.buildServer(buildDir, sourceDir)


task 'start', 'Builds files and starts server', ->
	cakeUtilities
	.linkHooks()
	.buildClient()
	.buildServer(buildDir, sourceDir)

	lowfab.startServer()
