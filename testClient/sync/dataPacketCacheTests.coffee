require('es6-promise').polyfill()
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
chai.use chaiAsPromised
expect = chai.expect
window.jQuery = window.$ = require 'jquery'
mockjax = require 'jquery-mockjax'

dataPackets = require '../../src/client/sync/dataPackets'

describe 'dataPacket client cache', ->
	beforeEach ->
		$.mockjaxSettings.logging = false

	afterEach ->
		dataPackets.clear()
		$.mockjax.clear()
		$.mockjaxSettings.logging = true

	describe 'dataPacket creation', ->
		it 'should call the server to create a dataPacket', ->
			newPacket = {id: 'abcdefgh', data: {}}
			$.mockjax(
				type: 'GET'
				url: '/datapacket/create'
				status: 200
				contentType: 'application/json'
				responseText: newPacket
			)
			dataPackets.create().then((packet) ->
				expect(packet).to.deep.equal(newPacket)
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should cache a newly created dataPacket', ->
			newPacket = {id: 'abcdefgh', data: {}}
			$.mockjax(
				type: 'GET'
				url: '/datapacket/create'
				status: 200
				contentType: 'application/json'
				responseText: newPacket
			)
			dataPackets.create().then(->
				dataPackets.get(newPacket.id).then((packet) ->
					expect(packet).to.deep.equal(newPacket)
					expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
					expect($.mockjax.unmockedAjaxCalls()).to.be.empty
				)
			)

		it 'should fail if the server cannot create a dataPacket', ->
			$.mockjax(
				type: 'GET'
				url: '/datapacket/create'
				status: 500
				responseText: 'Packet could not be created'
			)
			creation = dataPackets.create()
			# Rejected returns the reason which is a thenable ajax response that
			# rejects as well -> we have to use not fulfilled and cannot directly
			# use eventually
			Promise.all([
				expect(creation).not.to.be.fulfilled
				creation.catch (error) -> expect(error).to.have.property('status', 500)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

	describe 'dataPacket existence checks', ->
		it 'should fail with a malformed id', ->
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/exists\/(.*)$/
				urlParams: ['id']
				status: 400
				responseText: 'Invalid data packet id provided'
			)
			id = 'äöü'
			existence = dataPackets.exists(id)
			Promise.all([
				expect(existence).not.to.be.fulfilled
				existence.catch (error) -> expect(error).to.have.property('status', 400)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should check with the server about unknown dataPackets', ->
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/exists\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 200
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			id = 'abcdefgh'
			existence = dataPackets.exists(id)
			Promise.all([
				expect(existence).to.be.fulfilled
				expect(existence).to.eventually.equal(id)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should answer from cache if dataPacket is known', ->
			newPacket = {id: 'abcdefgh', data: {}}
			$.mockjax(
				type: 'GET'
				url: '/datapacket/create'
				status: 200
				contentType: 'application/json'
				responseText: newPacket
			)
			dataPackets.create().then((packet) ->
				existence = dataPackets.exists(newPacket.id)
				Promise.all([
					expect(existence).to.be.fulfilled
					expect(existence).to.eventually.equal(newPacket.id)
				]).then(->
					expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
					expect($.mockjax.unmockedAjaxCalls()).to.be.empty
				)
			)

		it 'should fail if dataPacket does not exist', ->
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/exists\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 404
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			id = 'abcdefgh'
			existence = dataPackets.exists(id)
			Promise.all([
				expect(existence).not.to.be.fulfilled
				existence.catch (error) ->
					expect(error).to.have.property('status', 404)
					expect(error).to.have.property('responseText', id)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

	describe 'dataPacket get requests', ->
		it 'should fail with a malformed id', ->
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/get\/(.*)$/
				urlParams: ['id']
				status: 400
				responseText: 'Invalid data packet id provided'
			)
			id = 'äöü'
			get = dataPackets.get(id)
			Promise.all([
				expect(get).not.to.be.fulfilled
				get.catch (error) -> expect(error).to.have.property('status', 400)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should get unknown dataPackets from the server', ->
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/get\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 200
				contentType: 'application/json'
				responseText: packet
			)
			get = dataPackets.get(packet.id)
			Promise.all([
				expect(get).to.be.fulfilled
				expect(get).to.become(packet)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should cache requested dataPackets', ->
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/get\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 200
				contentType: 'application/json'
				responseText: packet
			)
			dataPackets.get(packet.id).then(->
				get = dataPackets.get(packet.id)
				Promise.all([
					expect(get).to.be.fulfilled
					expect(get).to.become(packet)
				]).then(->
					expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
					expect($.mockjax.unmockedAjaxCalls()).to.be.empty
				)
			)

		it 'should fail if dataPacket does not exist', ->
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/get\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 404
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			get = dataPackets.get(packet.id)
			Promise.all([
				expect(get).not.to.be.fulfilled
				get.catch (error) ->
					expect(error).to.have.property('status', 404)
					expect(error).to.have.property('responseText', packet.id)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

	describe 'dataPacket put requests', ->
		it 'should fail with a malformed id', ->
			$.mockjax(
				type: 'PUT'
				url: /^\/datapacket\/put\/(.*)$/
				urlParams: ['id']
				status: 400
				responseText: 'Invalid data packet id provided'
			)
			packet = {id: 'äöü', data: {a: 0, b: 'c'}}
			put = dataPackets.put(packet)
			Promise.all([
				expect(put).not.to.be.fulfilled
				put.catch (error) -> expect(error).to.have.property('status', 400)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should fail if dataPacket does not exist', ->
			$.mockjax(
				type: 'PUT'
				url: /^\/datapacket\/put\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 404
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			put = dataPackets.put(packet)
			Promise.all([
				expect(put).not.to.be.fulfilled
				put.catch (error) ->
					expect(error).to.have.property('status', 404)
					expect(error).to.have.property('responseText', packet.id)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should put to server', ->
			$.mockjax(
				type: 'PUT'
				url: /^\/datapacket\/put\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 200
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			put = dataPackets.put(packet)
			Promise.all([
				expect(put).to.be.fulfilled
				expect(put).to.become(packet.id)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should cache changes', ->
			$.mockjax(
				type: 'PUT'
				url: /^\/datapacket\/put\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 200
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			dataPackets.put(packet).then(->
				get = dataPackets.get(packet.id)
				Promise.all([
					expect(get).to.be.fulfilled
					expect(get).to.become(packet)
				]).then(->
					expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
					expect($.mockjax.unmockedAjaxCalls()).to.be.empty
				)
			)

	describe 'dataPacket deletion', ->
		it 'should fail with a malformed id', ->
			$.mockjax(
				type: 'DELETE'
				url: /^\/datapacket\/delete\/(.*)$/
				urlParams: ['id']
				status: 400
				responseText: 'Invalid data packet id provided'
			)
			packet = {id: 'äöü', data: {a: 0, b: 'c'}}
			del = dataPackets.delete(packet.id)
			Promise.all([
				expect(del).not.to.be.fulfilled
				del.catch (error) -> expect(error).to.have.property('status', 400)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should fail if dataPacket does not exist', ->
			$.mockjax(
				type: 'DELETE'
				url: /^\/datapacket\/delete\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 404
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			del = dataPackets.delete(packet.id)
			Promise.all([
				expect(del).not.to.be.fulfilled
				del.catch (error) ->
					expect(error).to.have.property('status', 404)
					expect(error).to.have.property('responseText', packet.id)
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should delete dataPackets from server', ->
			$.mockjax(
				type: 'DELETE'
				url: /^\/datapacket\/delete\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 204
				responseText: ''
			)
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			del = dataPackets.delete(packet.id)
			Promise.all([
				expect(del).to.be.fulfilled
				expect(del).to.eventually.be.empty
			]).then(->
				expect($.mockjax.mockedAjaxCalls()).to.have.length(1)
				expect($.mockjax.unmockedAjaxCalls()).to.be.empty
			)

		it 'should not find deleted dataPackets', ->
			@timeout(4000)
			$.mockjax(
				type: 'DELETE'
				url: /^\/datapacket\/delete\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 204
				responseText: ''
			)
			$.mockjax(
				type: 'GET'
				url: /^\/datapacket\/exists\/([a-zA-Z0-9]+)$/
				urlParams: ['id']
				status: 404
				response: (settings) ->
					@responseText = settings.urlParams.id
			)
			packet = {id: 'abcdefgh', data: {a: 0, b: 'c'}}
			dataPackets.delete(packet.id).then(->
				existence = dataPackets.exists(packet.id)
				Promise.all([
					expect(existence).not.to.be.fulfilled
					existence.catch (error) ->
						expect(error).to.have.property('status', 404)
						expect(error).to.have.property('responseText', packet.id)
				]).then(->
					expect($.mockjax.mockedAjaxCalls()).to.have.length(2)
					expect($.mockjax.unmockedAjaxCalls()).to.be.empty
				)
			)
