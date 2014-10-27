fs = require 'fs'
path = require 'path'
coffeeScript = require 'coffee-script'
browserify = require('browserify')({debug: true})
mkdirp = require('mkdirp');
yamlParser = require 'js-yaml'

lowfab = require './src/server/main'


coffeeScript.register()

tasks = {}
options = {}
switches = []
oparse = null

buildDir = '/build/'
sourceDir = '/src/'


compileFile = (inputfile, compilerOptions, outputfile) ->
	console.log inputfile + ' -> ' + outputfile
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
	sourcePathPlugins = path.normalize __dirname + sourceDir + 'client/plugins/'
	buildPathPlugins = path.normalize __dirname + buildDir + 'client/plugins/'

	mkdirp.sync buildPath
	mkdirp.sync buildPathPlugins

	yamlToJson()

	compileAndExecuteOnJs sourcePath, buildPath, (outfilename) ->
		browserify.add outfilename

	compileAndExecuteOnJs sourcePathPlugins, buildPathPlugins, (outfilename) ->
		browserify.add outfilename

	browserify.bundle().pipe fs.createWriteStream(__dirname + '/public/index.js')


buildServer = () ->
	sourcePath = path.normalize __dirname + sourceDir + 'server/'
	buildPath = path.normalize __dirname + buildDir + 'server/'
	sourcePathPlugins = path.normalize __dirname + sourceDir + 'server/plugins/'
	buildPathPlugins = path.normalize __dirname + buildDir + 'server/plugins/'

	mkdirp.sync buildPath
	mkdirp.sync buildPathPlugins

	compileAndExecuteOnJs sourcePath, buildPath, null
	compileAndExecuteOnJs sourcePathPlugins, buildPathPlugins, null


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

	lowfab.startServer()


