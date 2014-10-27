fs = require 'fs'
path = require 'path'
coffeeScript = require 'coffee-script'
browserify = require('browserify')({debug: true})
mkdirp = require('mkdirp');
yamlParser = require 'js-yaml'
coffeelint = require 'coffeelint'
winston = require 'winston'
logger = new winston.Logger()

lowfab = require './src/server/main'


coffeeScript.register()

tasks = {}
options = {}
switches = []
oparse = null

buildDir = '/build/'
sourceDir = '/src/'


logger.add winston.transports.Console, {colorize: true}


compileFile = (inputfile, compilerOptions, outputfile) ->
	console.log inputfile
	fcontent = fs.readFileSync inputfile, 'utf8'
	compileObject = coffeeScript.compile fcontent, compilerOptions
	fs.writeFile outputfile, compileObject.js, (error) ->
		throw error if error
	fs.writeFile outputfile + '.map', compileObject.v3SourceMap, (error) ->
		throw error if error

# Compiles all .coffee files in sourcePath to .js files in buildPath
# and calls the callback with the build-filename
compileAndExecuteOnJs = (sourcePath, buildPath, callback) ->
	fs
	.readdirSync sourcePath
	.filter((element)->
		element.search(/.*\.coffee/g) >= 0)
	.forEach (file) ->
		outfilename = buildPath + path.basename(file, '.coffee') + '.js'
		compileFile path.normalize(sourcePath + file), {sourceMap: true, filename: 'test.map'}, outfilename
		callback outfilename if callback?

yamlToJson = () ->
	globalConfig = yamlParser.safeLoad fs.readFileSync(path.normalize('src/client/globals.yaml'), 'utf8')
	fs.writeFileSync(path.normalize('build/client/globals.json'), JSON.stringify(globalConfig))


buildClient = () ->
	sourcePath = path.normalize __dirname + sourceDir + 'client/'
	buildPath = path.normalize __dirname + buildDir + 'client/'

	mkdirp.sync buildPath

	yamlToJson()

	compileAndExecuteOnJs sourcePath, buildPath, (outfilename) ->
		browserify.add outfilename

	browserify.bundle().pipe fs.createWriteStream(__dirname + '/public/index.js')


buildServer = () ->
	sourcePath = path.normalize __dirname + sourceDir + 'server/'
	buildPath = path.normalize __dirname + buildDir + 'server/'

	mkdirp.sync buildPath

	compileAndExecuteOnJs sourcePath, buildPath, null


linkHooks = () ->
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
		hookPath = path.join(__dirname, 'hooks', hook)
		gitHookPath = path.join(".git/hooks", hook)

		fs.unlink gitHookPath, (error) ->
			if error then return

		fs.exists hookPath, (exists) ->
			if exists
				fs.link hookPath, gitHookPath, (error) ->
					if error
						throw new Error error


getFilesSync = (nodePath, options) ->
	returnFiles = []

	walkTree = (nodePath) ->
		stats = fs.statSync(nodePath)

		if stats.isFile()
			if options.regex.test(nodePath)
				returnFiles.push(nodePath)

		else if stats.isDirectory()

			files = fs.readdirSync nodePath

			for file in files
				if file and options.ignore.indexOf file
					walkTree path.join(nodePath, file)

	walkTree(nodePath)

	return returnFiles


checkStyle = () ->
	getFilesSync('.',
		ignore: ['node_modules', '.git']
		regex: /.*\.coffee/g
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
			logger.warn file,
				(error.lineNumber + '\n'),
				(error.rule + ':'),
				(error.message + '\n')


task 'linkHooks', 'Links git hooks into .git/hooks', ->
	linkHooks()


task 'checkStyle', 'Symlinks git hooks into .git/hooks', ->
	checkStyle()


task 'buildClient', 'Builds the client js files', ->
	buildClient()


task 'buildServer', 'Builds the server js files', ->
	buildServer()


task 'build', 'Builds client and server js files', ->
	buildClient()
	buildServer()


task 'start', 'Builds files and starts server', ->
	buildClient()
	buildServer()

	linkHooks()

	lowfab.startServer()
