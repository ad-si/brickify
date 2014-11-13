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
# Resolve javascript dependencies and build the js file for client side
browserify = require('browserify')
# Support mixing .coffee and .js files in lowfab-project
coffeeify = require 'coffeeify'
# Load yaml configuration into javascript file
browserifyData = require('browserify-data')
# Colorful logger for console
winston = require 'winston'
buildLog = winston.loggers.get('buildLog')

compileAllCoffeeFiles = (directory, afterCompileCallback,
												 createSourceMap = true) ->
	buildLog.info "Compiling files from #{directory}"
	readdirp root: directory, fileFilter: '*.coffee'
	.on 'data', (entry) -> compileFile entry, createSourceMap
	.on 'error', (error) -> buildLog.error error
	.on 'warn', (warning) -> buildLog.warn warning
	.on 'end', () -> afterCompileCallback(directory) if afterCompileCallback?

compileFile = (inputfileEntry, createSourceMap = true) ->
	inputfile = inputfileEntry.fullPath
	buildLog.info " compile #{inputfile}"
	compileObject = coffeeScript._compileFile inputfile, sourceMap = yes
	outputfile = path.join inputfileEntry.fullParentDir,
			path.basename(inputfile, '.coffee') + '.js'
	fs.writeFile outputfile, compileObject.js, (error) ->
		throw error if error
	if createSourceMap
		fs.writeFile outputfile + '.map', compileObject.v3SourceMap, (error) ->
			throw error if error

deleteAllJsFiles = (directory, afterDeleteCallback) ->
	buildLog.info "Clearing directory #{directory}..."
	readdirp root: directory, fileFilter: ['*.js','*.js.map']
	.on 'data', (entry) -> fs.unlinkSync entry.fullPath
	.on 'error', (error) -> buildLog.error error
	.on 'warn', (warning) -> buildLog.warn warning
	.on 'end', () -> afterDeleteCallback(directory) if afterDeleteCallback?

module.exports.buildClient = () ->
	browserify = browserify
		debug: process.env.NODE_ENV is not 'production'
		extensions: ['.coffee']

	browserify
	.add path.join __dirname, '..', 'client', 'main'
	.transform coffeeify
	.transform browserifyData
	.bundle()
	.pipe fs.createWriteStream 'public/index.js'

	return module.exports

module.exports.buildServer = (onlyDelete = false) ->
	directories = [
		__dirname
		path.join __dirname, '../../routes'
		path.join __dirname, '../common'
	]

	for dir in directories
		#build js in same directory as coffeescript to enable server debugging
		deleteAllJsFiles dir, (directory) ->
			compileAllCoffeeFiles(directory, null) if not onlyDelete

	return module.exports
	
module.exports.linkHooks = () ->
	# gist.github.com/domenic/2238951
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
	]
	.forEach (hook) ->
		hookPath = path.join('hooks', hook)
		gitHookPath = path.join(".git/hooks", hook)

		fs.unlink gitHookPath, (error) ->
			if error and error.code is not 'ENOENT'
				buildLog.error error

		fs.exists hookPath, (exists) ->
			if exists
				fs.link hookPath, gitHookPath, (error) ->
					if error
						buildLog.error error
					else
						buildLog.info hookPath, '->', gitHookPath

	return module.exports


# No used at the moment
# Please keep for future usage
###
module.exports.checkStyle = () ->
	getFilesSync('.',
		ignore: ['node_modules', '.git']
		regex: /.*\.coffee/gi
	)
	.forEach (file) ->

		coffeelint
		.lint(fs.readFileSync(file, 'utf8'),
			no_tabs:
				level: 'ignore'
			indentation:
				level: 'ignore'
		)
		.forEach (error) ->
			buildLog.warn file,
				(error.lineNumber + '\n'),
				(error.rule + ':'),
				(error.message + '\n')


module.exports.getFilesSync = (nodePath, options) ->
	returnFiles = []

	walkTree = (localNodePath) ->
		stats = fs.statSync(localNodePath)

		if stats.isFile()

			if (localNodePath.search(options.regex) >= 0)
				returnFiles.push localNodePath

		else if stats.isDirectory()

			files = fs.readdirSync localNodePath

			for file in files
				if file and options.ignore.indexOf(file) is -1
					walkTree path.join(localNodePath, file)

	walkTree(nodePath)

	return returnFiles
###
