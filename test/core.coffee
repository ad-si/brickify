process.env.NODE_ENV = 'test'

expect = require('chai').expect
http = require('http')

lowfab = require('../src/server/main')


describe 'Lowfab', () ->
	server = {}

	before (done) ->
		this.timeout(5000)

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
