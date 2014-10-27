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

index = require '../../routes/index.coffee'
statesync = require '../../routes/statesync.coffee'

#test for state sync
statesync.addDiffCallback (delta, state) ->
	state.iHazModified = true

app = express()
server = ''
port = process.env.NODEJS_PORT or process.env.PORT or 3000
ip = process.env.NODEJS_IP or '127.0.0.1'
developmentMode = true if app.get('env') is 'development'


app.set 'hostname', 'localhost:' + port

if not developmentMode
	app.set('hostname', process.env.HOSTNAME or 'lowfab.net')


app.set 'views', path.normalize 'views'
app.set 'view engine', 'jade'

app.use favicon(path.normalize 'public/img/favicon.png')

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
then app.use morgan 'dev'
else app.use morgan()

app.use bodyParser.json()
app.use bodyParser.urlencoded()

app.use session {secret: 'lowfabCookieSecret!'}

app.get  '/', index
app.get  '/statesync/get', statesync.getState
app.post '/statesync/set', statesync.setState
app.get  '/statesync/reset', statesync.resetState


if app.get 'env' is 'development'
	app.use errorHandler()

app.use ((req, res) ->
	res.render '404'
)

module.exports.startServer = () ->
	app.listen(port, ip)
	console.log('Server is listening on ' + ip + ':' + port)


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
						response.writeHeader(500, {'Content-Type': 'text/plain'})
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
