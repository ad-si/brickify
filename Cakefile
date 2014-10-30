###
  #Cakefile
  Building and running of lowfab is specified through this cakefile.

  **Note that you should only need to run `$ npm install` and `$ npm start`,
  all other tasks are being executed automatically.**

  For information on how to *build the documentation* have a look on the
  [readme](index.html) and the [package declaration](package.html).
###

###
  #Modules
###

###
  We use *coffeelint* to enforce code style guidelines.<br>
  See [coffeelint configuration](coffeelint.html)
###
coffeelint = require 'coffeelint'

coffeeScript = require 'coffee-script'
winston = require 'winston'
winston.loggers.add 'buildLog',
	console:
		level: 'debug'
		colorize: true

# *CakeUtilities* provides the build and start functions called below.<br>
# See [cakeUtilities](src/server/cakeUtilities.html)
cakeUtilities = require './src/server/cakeUtilities'

# *Lowfab* is the main server part which is responsible for delivering the
# website and for server-side plugin integration and model processing
lowfab = require './src/server/main'

# Makes it possible to directly require coffee modules
coffeeScript.register()

sourceDir = 'src'

###
  #Tasks
###

# Git hooks are used for automated test running and code style checking
task 'linkHooks', 'Links git hooks into .git/hooks', ->
	cakeUtilities.linkHooks()

# Build the client javascript files from all coffee-script files inside
# `src/client`<br>
# See [cakeUtilities](src/server/cakeUtilities.html)
task 'buildClient', 'Builds the client js files', ->
	cakeUtilities.buildClient()

# Build the server javascript files from all coffee-script files inside
# `src/server`<br>
# See [cakeUtilities](src/server/cakeUtilities.html)
task 'buildServer', 'Builds the server js files', ->
	cakeUtilities.buildServer(sourceDir)

# Delete old javascript files from previous builds
task 'clean', 'Removes js files from src directory', ->
    cakeUtilities.buildServer(sourceDir, true)

# Build the client and the server
task 'build', 'Builds client and server js files', ->
	cakeUtilities
	.buildClient()
	.buildServer(sourceDir)

###
  ##Building and starting

  **This is the only task you should need to invoke directly.**

  This task creates all git-hooks, builds the client and the server and starts
  the server afterwards.
###
task 'start', 'Builds files and starts server', ->
	cakeUtilities
	.linkHooks()
	.buildClient()
	.buildServer(sourceDir)

	lowfab.startServer()
