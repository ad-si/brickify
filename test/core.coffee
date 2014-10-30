expect = require('chai').expect
lowfab = require('../src/server/main')
http = require('http')

describe 'Lowfab', () ->
	server = {}

	before (done) ->
		lowfab.loadFrontendDependencies () ->
			server = lowfab
				.setupRouting()
				.startServer(3001)

			done()

	describe 'Server', () ->
		it 'should host the lowfab website', (done) ->
			request = http.request(
				{method: 'HEAD', host: 'localhost', port: 3001},
				(response) ->
					expect(response.statusCode).to.equal(200)
					done()
			)

			request.end()

	after () ->
		server.close()
