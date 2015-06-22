# File system support
fs = require 'fs'
# Manipulate platform-independent path strings
path = require 'path'
# Coffeescript-compiler for build chain
coffeeScript = require 'coffee-script'
# Recursively create folders
mkdirp = require 'mkdirp'
# Recursively process folders and files
readdirp = require 'readdirp'
# Support mixing .coffee and .js files in brickify-project
coffeeify = require 'coffeeify'
# Load yaml configuration into javascript file
browserifyData = require('browserify-data')
# Colorful logger for console
winston = require 'winston'
buildLog = winston.loggers.get('buildLog')

compileAllCoffeeFiles = (directory, afterCompileCallback) ->
	buildLog.info "Compiling files from #{directory}"
	readdirp root: directory, fileFilter: '*.coffee'
	.on 'data', (entry) -> compileFile entry
	.on 'error', (error) -> buildLog.error error
	.on 'warn', (warning) -> buildLog.warn warning
	.on 'end', -> afterCompileCallback(directory) if afterCompileCallback?

compileFile = (inputfileEntry) ->
	inputfile = inputfileEntry.fullPath
	buildLog.info " compile #{inputfile}"
	compileObject = coffeeScript._compileFile inputfile, sourceMap = yes
	outputfile = path.join inputfileEntry.fullParentDir,
			path.basename(inputfile, '.coffee') + '.js'
	fs.writeFile outputfile, compileObject.js, (error) ->
		throw error if error
	fs.writeFile outputfile + '.map', compileObject.v3SourceMap, (error) ->
		throw error if error

deleteAllJsFiles = (directory, afterDeleteCallback) ->
	buildLog.info "Clearing directory #{directory}..."
	readdirp root: directory, fileFilter: ['*.js', '*.js.map']
	.on 'data', (entry) -> fs.unlinkSync entry.fullPath
	.on 'error', (error) -> buildLog.error error
	.on 'warn', (warning) -> buildLog.warn warning
	.on 'end', -> afterDeleteCallback(directory) if afterDeleteCallback?

module.exports.buildServer = (onlyDelete = false) ->
	directories = [
		path.join __dirname, '/src/server'
		path.join __dirname, '/routes'
		path.join __dirname, '/src/common'
	]

	for dir in directories
		#build js in same directory as coffeescript to enable server debugging
		deleteAllJsFiles dir, (directory) ->
			compileAllCoffeeFiles(directory, null) if not onlyDelete

	return module.exports

module.exports.linkHooks = ->

	# The first 9 hooks are taken from `git init` which creates .sample files
	# even though some of them are not listed in the
	# [documentation](http://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks).
	# The rest of the hooks are taken from the documentation.
	[
		'applypatch-msg'
		'commit-msg'
		'post-commit'
		'post-receive'
		'post-update'
		'pre-applypatch'
		'pre-commit'
		'prepare-commit-msg'
		'pre-rebase'
		'update'
		'post-rewrite'
		'post-checkout'
		'post-merge'
		'pre-push'
		'pre-auto-gc'
	]
	.forEach (hook) ->
		hookPath = path.join('hooks', hook)
		gitHookPath = path.join('.git/hooks', hook)

		fs.unlink gitHookPath, (error) ->
			if error and error.code is not 'ENOENT'
				buildLog.error error

			fs.link hookPath, gitHookPath, (error) ->
				if error
					if error.code is not 'ENOENT'
						buildLog.error error
				else
					buildLog.info hookPath, '->', gitHookPath

	return module.exports
