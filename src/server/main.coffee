http = require 'http'
path = require 'path'
url = require 'url'
fs = require 'fs'

# Makes it possible to directly require coffee modules
#require 'coffee-script/register'

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
pluginLoader = require './pluginLoader'
index = require '../../routes/index'
statesync = require '../../routes/statesync'
logger = require 'winston'
exec = require 'exec'
modelStorage = require './modelStorage'
modelStorageApi = require '../../routes/modelStorageApi'

app = express()
server = ''
port = process.env.NODEJS_PORT or process.env.PORT or 3000
ip = process.env.NODEJS_IP or '127.0.0.1'
developmentMode = true if app.get('env') is 'development'

app.set 'hostname', 'localhost:' + port

logger.remove logger.transports.Console

if not developmentMode
	app.set('hostname', process.env.HOSTNAME or 'lowfab.net')
	logger.add logger.transports.Console, {colorize: true, level: 'warn'}
else
	logger.add logger.transports.Console, {colorize: true, level: 'debug'}

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
then app.use morgan 'dev',
	stream:
		write: (str) ->
			logger.info str.substring(0, str.length - 1)
else app.use morgan 'combined',
	stream:
		write: (str) ->
			logger.info str.substring(0, str.length - 1)

app.use session {secret: 'lowfabCookieSecret!'}

modelStorage.init()

jsonParser = bodyParser.json {limit: '100mb'}
urlParser = bodyParser.urlencoded {extended: true, limit: '100mb'}
rawParser = bodyParser.raw({limit: '100mb'})

app.get '/', index
app.get '/statesync/get', jsonParser, statesync.getState
app.post '/statesync/set', jsonParser, statesync.setState
app.get '/statesync/reset', jsonParser, statesync.resetState
app.get '/model/exists/:md5/:extension', urlParser, modelStorageApi.modelExists
app.get '/model/get/:md5/:extension', urlParser, modelStorageApi.getModel
app.post '/model/submit/:md5/:extension', rawParser, modelStorageApi.saveModel

app.post '/updateGitAndRestart', (request, response) ->
	response.send ""
	exec '../updateAndRestart.sh', (err, out, code) ->
		logger.warn "Error while updating server: " + err if err?

pluginLoader.loadPlugins statesync,
	path.normalize __dirname + '../../../src/server/plugins/'

if app.get 'env' is 'development'
	app.use errorHandler()

app.use ((req, res) ->
	res.render '404'
)

module.exports.startServer = () ->
	app.listen(port, ip)
	logger.info 'Server is listening on ' + ip + ':' + port
