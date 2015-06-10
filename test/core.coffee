process.env.NODE_ENV = 'test'

expect = require('chai').expect
http = require('http')

brickify = require('../src/server/main')


describe 'Brickify', ->
	server = {}

	before (done) ->
		@timeout(5000)

		server = brickify
			.setupRouting()
			.startServer(3001)

		done()

	describe 'Server', ->
		it 'should host the brickify website', (done) ->
			@timeout(5000)
			request = http.request(
				{method: 'HEAD', host: 'localhost', port: 3001},
				(response) ->
					expect(response.statusCode).to.equal(200)
					done()
			)

			request.end()

	after ->
		server.close()
