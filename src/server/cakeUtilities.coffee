fs = require 'fs'
path = require 'path'
coffeeScript = require 'coffee-script'
mkdirp = require 'mkdirp'
browserify = require('browserify')
winston = require 'winston'
coffeeify = require 'coffeeify'
browserifyData = require('browserify-data')

logger = new winston.Logger()
logger.add winston.transports.Console, {colorize: true}


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
	logger.info inputfile + ' -> ' + outputfile
	fcontent = fs.readFileSync inputfile, 'utf8'
	compileObject = coffeeScript.compile fcontent, compilerOptions
	fs.writeFile outputfile, compileObject.js, (error) ->
		throw error if error
	fs.writeFile outputfile + '.map', compileObject.v3SourceMap, (error) ->
		throw error if error

	return module.exports


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


module.exports.buildServer = (buildDir, sourceDir) ->
	sourcePath = path.join sourceDir, '/server'
	buildPath = path.join buildDir, '/server'
	sourcePathPlugins = path.join sourceDir, '/server/plugins'
	buildPathPlugins = path.join buildDir, '/server/plugins'

	mkdirp.sync buildPath
	mkdirp.sync buildPathPlugins

	compileAndExecuteOnJs sourcePath, buildPath, null
	compileAndExecuteOnJs sourcePathPlugins, buildPathPlugins, null

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

		console.log hookPath, gitHookPath

		fs.unlink gitHookPath, (error) ->
			if error then return

		fs.exists hookPath, (exists) ->
			if exists
				fs.link hookPath, gitHookPath, (error) ->
					if error
						throw new Error error

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

		console.log file

		coffeelint
		.lint(fs.readFileSync(file, 'utf8'),
			no_tabs:
				level: 'ignore'
			indentation:
				level: 'ignore'
		)
		.forEach (error) ->
			logger.warn file,
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
