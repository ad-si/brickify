http = require 'http'
path = require 'path'
url = require 'url'
fs = require 'fs'

winston = require 'winston'
express = require 'express'

webapp = express()
developmentMode = if webapp.get('env') is 'development' then true else false
testMode = if webapp.get('env') is 'test' then true else false

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
browserifyData = require 'browserify-data'
envify = require 'envify'
browserify = require 'browserify-middleware'
browserify.settings({
	transform: [coffeeify, browserifyData, envify]
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
app = require '../../routes/app'
landingPage = require '../../routes/landingpage'
statesync = require '../../routes/statesync'
modelStorage = require './modelStorage'
modelStorageApi = require '../../routes/modelStorageApi'
dataPackets = require '../../routes/dataPackets'
exec = require 'exec'
http = require 'http'

server = http.createServer(webapp)
port = process.env.NODEJS_PORT or process.env.PORT or 3000
ip = process.env.NODEJS_IP or '127.0.0.1'
sessionSecret = process.env.LOWFAB_SESSION_SECRET or 'lowfabSessionSecret!'

links = {}
sortedDependencies = [
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
		callback()


module.exports.setupRouting = () ->
	webapp.set 'hostname', if developmentMode then "localhost:#{port}" else
		process.env.HOSTNAME or 'lowfab.net'


	webapp.set 'views', path.normalize 'views'
	webapp.locals.pretty = true
	webapp.set 'view engine', 'jade'

	webapp.use favicon(path.normalize 'public/img/favicon.png', {maxAge: 1000})

	webapp.use compress()

	webapp.use stylus.middleware(
		src: 'public',
		compile: (string, path) ->
			stylus string
			.set 'filename', path
			.set 'compress', !developmentMode
			.use nib()
			.import 'nib'
	)

	webapp.get '/app.js', browserify('src/client/main.coffee', {
		extensions: ['.coffee']
	})
	webapp.get '/landingpage.js', browserify('src/landingpage/main.coffee', {
		extensions: ['.coffee']
	})
	webapp.get '/quickconvert.js', browserify('src/quickconvert/main.coffee', {
		extensions: ['.coffee']
	})
	webapp.use express.static('public')
	webapp.use('/node_modules', express.static('node_modules'))

	if developmentMode
		webapp.use morgan 'dev',
			stream:
				write: (str) ->
					log.info str.substring(0, str.length - 1)
	else
		webapp.use morgan 'combined',
			stream:
				write: (str) ->
					log.info str.substring(0, str.length - 1)


	webapp.use session {
		secret: sessionSecret
		resave: true
		saveUninitialized: true
	}

	modelStorage.init()

	jsonParser = bodyParser.json {limit: '100mb'}
	urlParser = bodyParser.urlencoded {extended: true, limit: '100mb'}
	rawParser = bodyParser.raw({limit: '100mb'})

	landingPage.setLinks links

	webapp.get '/', landingPage.getLandingpage
	webapp.get '/contribute', landingPage.getContribute
	webapp.get '/team', landingPage.getTeam
	webapp.get '/quickconvert', urlParser, landingPage.getQuickConvertPage
	webapp.get '/app', app(links)
	webapp.get '/statesync/get', jsonParser, statesync.getState
	webapp.post '/statesync/set', jsonParser, statesync.setState
	webapp.get '/statesync/reset', jsonParser, statesync.resetState
	webapp.get '/model/exists/:hash', urlParser, modelStorageApi.modelExists
	webapp.get '/model/get/:hash', urlParser, modelStorageApi.getModel
	webapp.post '/model/submit/:hash', rawParser, modelStorageApi.saveModel

	webapp.post '/datapacket/packet/undefined',
		jsonParser, dataPackets.createPacket
	webapp.post '/datapacket/packet/:id', jsonParser, dataPackets.updatePacket
	webapp.get  '/datapacket/packet/:id', jsonParser, dataPackets.getPacket

	webapp.post '/updateGitAndRestart', jsonParser, (request, response) ->
		if request.body.ref?
			ref = request.body.ref
			if not (ref.indexOf('develop') >= 0 or ref.indexOf('master') >= 0)
				log.debug 'Got a server restart command, but "ref" ' +
									'did not contain develop or master'
				response.send ''
				return
		else
			log.warn 'Got a server restart command without a "ref" ' +
								'json member from ' + request.connection.remoteAddress
			response.send ''
			return

		response.send ''
		exec '../updateAndRestart.sh', (error, out, code) ->
			if error
				log.warn "Error while updating server: #{error}"

	pluginLoader.loadPlugins statesync,
		path.join __dirname, 'plugins/'

	if developmentMode
		webapp.use errorHandler()

	webapp.use (req, res) ->
		res
		.status(404)
		.render '404', links
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
