expect = require('chai').expect
dataPackets = require '../../routes/dataPackets'

Request = require '../mocks/express-request'
Response = require '../mocks/express-response'

describe 'server-side dataPacket-storage tests', ->
	afterEach ->
		dataPackets.clear()

	describe 'dataPacket creation', ->
		it 'should create empty packets', ->
			response = new Response()
			dataPackets.create new Request(), response
			response.whenSent.then(->
				expect(response).to.have.deep.property('type', 'json')
				expect(response).to.have.deep.property('code', 201)
				expect(response).to.have.deep.property('content.id')
				expect(response).to.have.deep.property('content.data').to.be.empty
			)

	describe 'dataPacket existence checks', ->
		it 'should reject invalid id exists checks', ->
			response = new Response()
			dataPackets.exists(
				new Request({id: 'äöü'})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 400)
			)

		it 'should not find non existing packet', ->
			response = new Response()
			id = 'abcdefgh'
			dataPackets.exists(
				new Request({id: id})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 404)
				expect(response).to.have.property('content', id)
			)

		it 'should find existing packet', ->
			createResponse = new Response()
			dataPackets.create new Request(), createResponse
			createResponse.whenSent.then(->
				id = createResponse.content.id
				existsResponse = new Response()
				dataPackets.exists(
					new Request({id: id})
					existsResponse
				)
				existsResponse.whenSent.then(->
					expect(existsResponse).to.have.property('type', 'text')
					expect(existsResponse).to.have.property('code', 200)
					expect(existsResponse).to.have.property('content', id)
				)
			)

	describe 'dataPacket get requests', ->
		it 'should reject invalid id gets', ->
			response = new Response()
			dataPackets.get(
				new Request({id: 'äöü'})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 400)
			)

		it 'should not get non existing packet', ->
			response = new Response()
			dataPackets.get(
				new Request({id: 'abcdefgh'})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 404)
				expect(response).to.have.property('content', 'abcdefgh')
			)

		it 'should return existing packet', ->
			createResponse = new Response()
			dataPackets.create new Request(), createResponse
			createResponse.whenSent.then(->
				id = createResponse.content.id
				content = {a: 0, b: 'c'}
				putResponse = new Response()
				dataPackets.put(
					new Request({id: id}, content)
					putResponse
				)
				putResponse.whenSent.then(->
					getResponse = new Response()
					dataPackets.get(
						new Request({id: id})
						getResponse
					)
					getResponse.whenSent.then(->
						expect(getResponse).to.have.property('type', 'json')
						expect(getResponse).to.have.property('code', 200)
						expect(getResponse).to.have.deep.property('content.id', id)
						expect(getResponse).to.have.deep.property('content.data', content)
					)
				)
			)

	describe 'dataPacket put requests', ->
		it 'should reject invalid id puts', ->
			response = new Response()
			dataPackets.put(
				new Request({id: 'äöü'}, {a: 0, b: 'c'})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 400)
			)

		it 'should not put non existing packet', ->
			response = new Response()
			dataPackets.put(
				new Request({id: 'abcdefgh'}, {a: 0, b: 'c'})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 404)
				expect(response).to.have.property('content', 'abcdefgh')
			)

		it 'should put existing packet', ->
			createResponse = new Response()
			dataPackets.create new Request(), createResponse
			createResponse.whenSent.then(->
				id = createResponse.content.id
				content = {a: 0, b: 'c'}
				putResponse = new Response()
				dataPackets.put(
					new Request({id: id}, content)
					putResponse
				)
				putResponse.whenSent.then(->
					expect(putResponse).to.have.property('type', 'text')
					expect(putResponse).to.have.property('code', 200)
					expect(putResponse).to.have.property('content', id)
				)
			)

	describe 'dataPacket deletion', ->
		it 'should reject invalid id puts', ->
			response = new Response()
			dataPackets.delete(
				new Request({id: 'äöü'}, {a: 0, b: 'c'})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 400)
			)

		it 'should not delete non existing packet', ->
			response = new Response()
			dataPackets.delete(
				new Request({id: 'abcdefgh'}, {a: 0, b: 'c'})
				response
			)
			response.whenSent.then(->
				expect(response).to.have.property('type', 'text')
				expect(response).to.have.property('code', 404)
				expect(response).to.have.property('content', 'abcdefgh')
			)

		it 'should delete specified packets', ->
			createResponse = new Response()
			dataPackets.create new Request(), createResponse
			createResponse.whenSent.then(->
				deleteResponse = new Response()
				dataPackets.delete(
					new Request({id: createResponse.content.id})
					deleteResponse
				)
				deleteResponse.whenSent.then(->
					expect(deleteResponse).to.have.property('type', 'text')
					expect(deleteResponse).to.have.property('code', 204)
					expect(deleteResponse).not.to.have.property('content')
				)
			)

		it 'should not find deleted packets', ->
			createResponse = new Response()
			dataPackets.create new Request(), createResponse
			createResponse.whenSent.then(->
				id = createResponse.content.id
				deleteResponse = new Response()
				dataPackets.delete(
					new Request({id: id})
					deleteResponse
				)
				deleteResponse.whenSent.then(->
					existsResponse = new Response()
					dataPackets.exists(
						new Request({id: id})
						existsResponse
					)
					existsResponse.whenSent.then(->
						expect(existsResponse).to.have.property('type', 'text')
						expect(existsResponse).to.have.property('code', 404)
						expect(existsResponse).to.have.property('content', id)
					)
				)
			)
