http = require 'http'
path = require 'path'
url = require 'url'
fs = require 'fs'

winston = require 'winston'
express = require 'express'

app = express()
developmentMode = if app.get('env') is 'development' then true else false
testMode = if app.get('env') is 'test' then true else false

loggingLevel = if developmentMode then 'debug' else 'warn'
loggingLevel = 'error' if testMode

# Make logger available to other modules
winston.loggers.add 'log',
	console:
		level: loggingLevel
		colorize: true

log = winston.loggers.get('log')

# Support mixing .coffee and .js files in lowfab-project
coffeeify = require 'coffeeify'
# Load yaml configuration into javascript file
browserifyData = require('browserify-data')
browserify = require 'browserify-middleware'
browserify.settings({
	transform: [coffeeify, browserifyData]
})
bodyParser = require 'body-parser'
compress = require 'compression'
morgan = require 'morgan'
errorHandler = require 'errorhandler'
session = require 'express-session'
favicon = require 'serve-favicon'
compression = require 'compression'
stylus = require 'stylus'
nib = require 'nib'
bower = require 'bower'
pluginLoader = require './pluginLoader'
index = require '../../routes/index'
statesync = require '../../routes/statesync'
exec = require 'exec'
http = require 'http'

pluginLoader = require './pluginLoader'
index = require '../../routes/index'
statesync = require '../../routes/statesync'
modelStorage = require './modelStorage'
modelStorageApi = require '../../routes/modelStorageApi'


server = http.createServer(app)
port = process.env.NODEJS_PORT or process.env.PORT or 3000
ip = process.env.NODEJS_IP or '127.0.0.1'
sessionSecret = process.env.LOWFAB_SESSION_SECRET or 'lowfabSessionSecret!'

links = {}
sortedDependencies = [
	'jquery',
	'bootstrap',
	'threejs',
	'JavaScript-MD5',
	'STLLoader',
	'TrackballControls',
	'OrbitControls',
	'FileSaver',
	'Blob'
]


module.exports.loadFrontendDependencies = (callback) ->
	allDependencies = []

	getDependencyPath = (depPath) ->
		path.join.apply null, depPath.split('/').slice(1)

	bower
	.commands
	.list {paths: true}
	.on 'end', (dependencies) ->
		for name, depPath of dependencies
			if Array.isArray depPath
				for subPath in depPath
					allDependencies.push getDependencyPath subPath
			else
				allDependencies.push getDependencyPath depPath

		isCss = (element) ->
			path.extname(element) is '.css'
		isJs = (element) ->
			path.extname(element) is '.js'

		links.styles = allDependencies.filter(isCss)
		links.styles.push('styles/screen.css')

		links.scripts = sortedDependencies.map (element, index) ->
			if Array.isArray dependencies[element]
				getDependencyPath dependencies[element].filter(isJs)[0]
			else
				getDependencyPath dependencies[element]
		links.scripts.push('index.js')

		callback()


module.exports.setupRouting = () ->
	app.set 'hostname', if developmentMode then "localhost:#{port}" else
		process.env.HOSTNAME or 'lowfab.net'


	app.set 'views', path.normalize 'views'
	app.set 'view engine', 'jade'

	app.use favicon(path.normalize 'public/img/favicon.png', {maxAge: 1000})

	app.use compress()

	app.use stylus.middleware(
		src: 'public',
		compile: (string, path) ->
			stylus string
			.set 'filename', path
			.set 'compress', !developmentMode
			.use nib()
			.import 'nib'
	)

	app.get '/index.js', browserify('src/client/main.coffee', {
		extensions: ['.coffee']
	})
	app.use express.static('public')
	app.use('/node_modules', express.static('node_modules'))

	if developmentMode
		app.use morgan 'dev',
			stream:
				write: (str) ->
					log.info str.substring(0, str.length - 1)
	else
		app.use morgan 'combined',
			stream:
				write: (str) ->
					log.info str.substring(0, str.length - 1)


	app.use session {
		secret: sessionSecret
		resave: true
		saveUninitialized: true
	}

	modelStorage.init()

	jsonParser = bodyParser.json {limit: '100mb'}
	urlParser = bodyParser.urlencoded {extended: true, limit: '100mb'}
	rawParser = bodyParser.raw({limit: '100mb'})


	app.get '/', index(links)
	app.get '/statesync/get', jsonParser, statesync.getState
	app.post '/statesync/set', jsonParser, statesync.setState
	app.get '/statesync/reset', jsonParser, statesync.resetState
	app.get '/model/exists/:md5/:extension', urlParser, modelStorageApi.modelExists
	app.get '/model/get/:md5/:extension', urlParser, modelStorageApi.getModel
	app.post '/model/submit/:md5/:extension', rawParser, modelStorageApi.saveModel

	app.post '/updateGitAndRestart', jsonParser, (request, response) ->
		if request.body.ref?
			if not (request.body.ref.indexOf("develop") >= 0 or request.body.ref.indexOf("master") >= 0)
				log.debug 'Got a server restart command, but "ref" did not contain develop or master'
				response.send ''
				return
		else
			log.warn 'Got a server restart command without a "ref" json member from ' + request.connection.remoteAddress
			response.send ''
			return

		response.send ''
		exec '../updateAndRestart.sh', (error, out, code) ->
			if error
				log.warn "Error while updating server: #{error}"

	pluginLoader.loadPlugins statesync,
		path.join __dirname, 'plugins/'

	if developmentMode
		app.use errorHandler()

	app.use (req, res) ->
		res.render '404', links

	return module.exports


module.exports.startServer = (_port, _ip) ->
	port = _port || port
	ip = _ip || ip


	server.on 'error', (error) ->
		if error.code is 'EADDRINUSE'
			log.error "Another Server is already listening on #{ip}:#{port}"
		else
			log.error 'Server could not be started:', error

	server.listen port, ip, () ->
		log.info "Server is listening on #{ip}:#{port}"

	return server
