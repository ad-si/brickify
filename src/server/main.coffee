http = require('http')
path = require('path')
url = require('url')
fs = require('fs')
server = ''


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
