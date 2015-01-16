require('es6-promise').polyfill()

http = require 'http'
path = require 'path'
url = require 'url'
fs = require 'fs'

bootstrap = require 'bootstrap-styl'
winston = require 'winston'
express = require 'express'
bodyParser = require 'body-parser'
compress = require 'compression'
morgan = require 'morgan'
errorHandler = require 'errorhandler'
session = require 'express-session'
favicon = require 'serve-favicon'
compression = require 'compression'
stylus = require 'stylus'
nib = require 'nib'
exec = require 'exec'
http = require 'http'
# Support mixing .coffee and .js files in lowfab-project
coffeeify = require 'coffeeify'
# Load yaml configuration into javascript file
browserifyData = require 'browserify-data'
envify = require 'envify'
browserify = require 'browserify-middleware'
urlSessions = require './urlSessions'
cookieParser = require 'cookie-parser'

# Make logger available to other modules.
# Must be instantiated before requiring bundled modules
winston.loggers.add 'log',
	console:
		level: loggingLevel
		colorize: true
log = winston.loggers.get('log')

pluginLoader = require './pluginLoader'
app = require '../../routes/app'
landingPage = require '../../routes/landingpage'
statesync = require '../../routes/statesync'
modelStorage = require './modelStorage'
modelStorageApi = require '../../routes/modelStorageApi'
dataPackets = require '../../routes/dataPackets'
sharelinkGen = require '../../routes/share'

webapp = express()

# Express assumes that no env means develop.
# Therefore override it to make it clear for all
developmentMode = webapp.get('env') is 'development'
if developmentMode
	process.env.NODE_ENV = 'development'
	log.info 'development mode activated'
else
	log.info 'production mode activated'

testMode = webapp.get('env') is 'test'

loggingLevel = if developmentMode then 'debug' else 'warn'
loggingLevel = 'error' if testMode

browserify.settings({
	transform: [coffeeify, browserifyData, envify]
})

server = http.createServer(webapp)
port = process.env.NODEJS_PORT or process.env.PORT or 3000
ip = process.env.NODEJS_IP or '127.0.0.1'
sessionSecret = process.env.LOWFAB_SESSION_SECRET or 'lowfabSessionSecret!'

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
			.set 'include css', true
			.use nib()
			.use bootstrap()
	)

	webapp.use (req, res, next) ->
		res.locals.app = webapp
		next()

	if developmentMode
		shared = [
			'blueimp-md5'
			'bootstrap'
			'clone'
			'jquery'
			'jsondiffpatch'
			'path'
			'react'
			'stats-js'
			'three'
			'three-orbit-controls'
			'zeroclipboard'
		]
		webapp.get '/shared.js', browserify(shared, {
			cache: true
			precompile: true
			noParse: shared
		})

	webapp.get '/app.js', browserify('src/client/main.coffee', {
		extensions: ['.coffee']
		external: shared
		insertGlobals: developmentMode
	})
	webapp.get '/landingpage.js', browserify('src/landingpage/main.coffee', {
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

	modelStorage.init()

	webapp.use cookieParser()
	webapp.use urlSessions.middleware

	jsonParser = bodyParser.json {limit: '100mb'}
	urlParser = bodyParser.urlencoded {extended: true, limit: '100mb'}
	rawParser = bodyParser.raw({limit: '100mb'})

	webapp.get '/', landingPage.getLandingpage
	webapp.get '/contribute', landingPage.getContribute
	webapp.get '/team', landingPage.getTeam
	webapp.get '/app', app
	webapp.get '/share', sharelinkGen
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

	pluginLoader.loadPlugins statesync, path.resolve(__dirname, '../plugins')

	if developmentMode
		webapp.use errorHandler()
		require('express-debug')(webapp, {extra_panels: ['nav']})

	webapp.use (req, res) ->
		res
		.status(404)
		.render '404'
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
