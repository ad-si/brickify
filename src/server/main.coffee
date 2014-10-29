http = require 'http'
path = require 'path'
url = require 'url'
fs = require 'fs'

# Makes it possible to directly require coffee modules
require 'coffee-script/register'

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
logger = require 'winston'
exec = require 'exec'

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
		logger.warn "Error while updating server: " + err if err?

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
	server = false

	try
		server = app.listen(port, ip)
		logger.info 'Server is listening on ' + ip + ':' + port

	catch error
		winston.error 'Server could not be started!'

	return server

###
module.exports.createServer = () ->
	server = http.createServer (request, response) ->
		my_path = url.parse(request.url).pathname
		full_path = path.join(process.cwd(), my_path)

		fs.exists full_path, (exists) ->
			if not exists
				response.writeHeader(404, {'Content-Type': 'text/plain'})
				response.write('404 Not Found\n')
				response.end()
			else
				fs.readFile full_path, 'binary', (err, file) ->
					if err
						response.writeHeader(500,
                            'Content-Type': 'text/plain'
                        )
						response.write(err + '\n')
						response.end()
					else
						response.writeHeader(200)
						response.write(file, 'binary')
						response.end()

	return @


module.exports.startServer = () ->
	server.listen(8080)
	console.log 'Started server. Access website on http://localhost:8080'

	return @
###
