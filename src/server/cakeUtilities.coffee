fs = require 'fs'
path = require 'path'
coffeeScript = require 'coffee-script'
mkdirp = require 'mkdirp'
browserify = require('browserify')
coffeeify = require 'coffeeify'
browserifyData = require('browserify-data')
winston = require 'winston'

buildLog = winston.loggers.get('buildLog')

compileAndExecuteOnJs = (sourcePath, buildPath, callback) ->
	# Compiles all .coffee files in sourcePath to .js files in buildPath
	# and calls the callback with the build-filename
	fs
	.readdirSync sourcePath
	.filter((element)->
		element.search(/.*\.coffee/g) >= 0)
	.forEach (file) ->
		outfilename = path.join buildPath, '/',
				path.basename(file, '.coffee') + '.js'
		compileFile(
			path.join(sourcePath, file),
			sourceMap: true
			filename: 'test.map',
			outfilename
		)
		callback outfilename if callback?

compileFile = (inputfile, compilerOptions, outputfile) ->
	buildLog.info inputfile + ' -> ' + outputfile
	fcontent = fs.readFileSync inputfile, 'utf8'
	compileObject = coffeeScript.compile fcontent, compilerOptions
	fs.writeFile outputfile, compileObject.js, (error) ->
		throw error if error
	fs.writeFile outputfile + '.map', compileObject.v3SourceMap, (error) ->
		throw error if error

	return module.exports

String.prototype.endsWith = (suffix) ->
	return this.indexOf(suffix, this.length - suffix.length) != -1

deleteAllJsFiles = (directory) ->
	fs.readdir directory, (err, files) ->
		for file in files
			if (file.endsWith '.js') or (file.endsWith '.js.map')
				fs.unlink path.join(directory, file), (err) ->
					console.log 'Unable to delete file "' +
						path.join(directory, file) +
						'" (' + err + ')' if err

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


module.exports.buildServer = (sourceDir, onlyDelete = false) ->
	directories = [
		path.join sourceDir, '/server'
		path.join sourceDir, '/server/plugins'
		path.join sourceDir, '../routes'
	]

	for dir in directories
		#build js in same directory as coffeescript to enable server debugging
		deleteAllJsFiles dir
		compileAndExecuteOnJs dir, dir, null if not onlyDelete

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
