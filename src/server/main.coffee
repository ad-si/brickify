http = require 'http'
path = require 'path'
url = require 'url'
fs = require 'fs'

# Makes it possible to directly require coffee modules
require 'coffee-script/register'

winston = require 'winston'
# Make logger available to other modules
winston.loggers.add 'log',
	console:
		level: 'debug' #if developmentMode then 'debug' else 'warn'
		colorize: true
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
pluginLoader = require './pluginLoader.coffee'
index = require '../../routes/index.coffee'
statesync = require '../../routes/statesync.coffee'
exec = require 'exec'
http = require 'http'


app = express()
developmentMode = true if app.get('env') is 'development'
log = winston.loggers.get('log')


server = http.createServer(app)
port = process.env.NODEJS_PORT or process.env.PORT or 3000
ip = process.env.NODEJS_IP or '127.0.0.1'

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

app.use express.static(path.normalize 'public')

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

app.use bodyParser.json()
app.use bodyParser.urlencoded extended: true

app.use session {secret: 'lowfabCookieSecret!'}

app.get '/', index
app.get '/statesync/get', statesync.getState
app.post '/statesync/set', statesync.setState
app.get '/statesync/reset', statesync.resetState

app.post '/updateGitAndRestart', (request, response) ->
	response.send ""
	exec '../updateAndRestart.sh', (err, out, code) ->
		log.warn "Error while updating server: " + err if err?

pluginLoader.loadPlugins statesync,
	path.normalize __dirname + '../../../src/server/plugins/'

if app.get 'env' is 'development'
	app.use errorHandler()

app.use ((req, res) ->
	res.render '404'
)

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
