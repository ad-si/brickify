clone = require 'clone'
chai = require 'chai'
chai.use require 'chai-as-promised'
chai.use require 'chai-shallow-deep-equal'
expect = chai.expect

DataPacketsMock = require '../mocks/dataPacketsMock'
SyncObject = require '../../src/common/sync/syncObject'
Dummy = require './dummySyncObject'

dataPackets = null

describe 'SyncObject tests', ->
	beforeEach ->
		dataPackets = new DataPacketsMock()
		SyncObject.dataPacketProvider = dataPackets

	describe 'SyncObject creation', ->
		it 'should resolve after creation', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			expect(dummy.done()).to.resolve

		it 'should be a Dummy and a SyncObject', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			dummy.done ->
				expect(dummy).to.be.an.instanceof(Dummy)
				expect(dummy).to.be.an.instanceof(SyncObject)

		it 'should get an id by dataPacketProvider', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			dummy.done ->
				expect(dummy).to.have.property('id', nextId)
				expect(dataPackets.calls).to.equal(1)
				expect(dataPackets.createCalls).to.deep.equal([nextId])

		it 'should support creation from a packet', ->
			pojso = {a: 'b', c: {d: 'e'}}
			packet = {id: 'abcdefgh', data: pojso}
			request = Dummy.from packet
			expect(request).to.resolve
			request.then (dummy) ->
				expect(dataPackets.calls).to.equal(0)
				dummy.done ->
					expect(dummy).to.be.an.instanceof(Dummy)
					expect(dummy).to.be.an.instanceof(SyncObject)
					expect(dummy).to.shallowDeepEqual(pojso)

		it 'should support loading from many packets', ->
			pojsos = []
			packets = []

			for i in [0..2]
				pojsos[i] = {a: 'b' + i, c: {d: 'e' + i}}
				packets[i] = {id: 'abcdefgh' + i, data: pojsos[i]}

			requests = Promise.all Dummy.from packets
			expect(requests).to.resolve
			requests.then (dummies) ->
				expect(dummies).to.have.length(packets.length)
				promises = dummies.map (dummy) -> dummy.done()
				Promise.all(promises).then ->
					expect(dataPackets.calls).to.equal(0)
					for i in [0...dummies.length] by 1
						dummy = dummies[i]
						expect(dummy).to.be.an.instanceof(Dummy)
						expect(dummy).to.be.an.instanceof(SyncObject)
						expect(dummy).to.shallowDeepEqual(pojsos[i])

		it 'should support loading from an id', ->
			pojso = {a: 'b', c: {d: 'e'}}
			id = 'abcdefgh'
			packet = {id: id, data: pojso}
			dataPackets.nextGets.push packet
			request = Dummy.from id
			expect(request).to.resolve
			request.then (dummy) -> dummy.done ->
				expect(dataPackets.calls).to.equal(1)
				expect(dataPackets.getCalls).to.have.length(1)
				expect(dummy).to.be.an.instanceof(Dummy)
				expect(dummy).to.be.an.instanceof(SyncObject)
				expect(dummy).to.shallowDeepEqual(pojso)

		it 'should support loading from many ids', ->
			pojsos = []
			ids = []
			packets = []

			for i in [0..2]
				pojsos[i] = {a: 'b' + i, c: {d: 'e' + i}}
				ids[i] = 'abcdefgh' + i
				packets[i] = {id: ids[i], data: pojsos[i]}
				dataPackets.nextGets.push packets[i]

			requests = Promise.all Dummy.from ids
			expect(requests).to.resolve
			requests.then (dummies) ->
				expect(dummies).to.have.length(ids.length)
				expect(dataPackets.calls).to.equal(ids.length)
				expect(dataPackets.getCalls).to.have.length(ids.length)
				promises = dummies.map (dummy) -> dummy.done()
				Promise.all(promises).then ->
					for i in [0...dummies.length] by 1
						dummy = dummies[i]
						expect(dummy).to.be.an.instanceof(Dummy)
						expect(dummy).to.be.an.instanceof(SyncObject)
						expect(dummy).to.shallowDeepEqual(pojsos[i])

		it 'should support loading from a reference', ->
			pojso = {a: 'b', c: {d: 'e'}}
			id = 'abcdefgh'
			packet = {id: id, data: pojso}
			dataPackets.nextGets.push packet
			request = Dummy.from {dataPacketRef: id}
			expect(request).to.resolve
			request.then (dummy) -> dummy.done ->
				expect(dataPackets.calls).to.equal(1)
				expect(dataPackets.getCalls).to.have.length(1)
				expect(dummy).to.be.an.instanceof(Dummy)
				expect(dummy).to.be.an.instanceof(SyncObject)
				expect(dummy).to.shallowDeepEqual(pojso)

		it 'should support loading from many references', ->
			pojsos = []
			ids = []
			references = []
			packets = []

			for i in [0..2]
				pojsos[i] = {a: 'b' + i, c: {d: 'e' + i}}
				ids[i] = 'abcdefgh' + i
				references[i] = {dataPacketRef: ids[i]}
				packets[i] = {id: ids[i], data: pojsos[i]}
				dataPackets.nextGets.push packets[i]

			requests = Promise.all Dummy.from references
			expect(requests).to.resolve
			requests.then (dummies) ->
				expect(dummies).to.have.length(references.length)
				expect(dataPackets.calls).to.equal(references.length)
				expect(dataPackets.getCalls).to.have.length(references.length)
				promises = dummies.map (dummy) -> dummy.done()
				Promise.all(promises).then ->
					for i in [0...dummies.length] by 1
						dummy = dummies[i]
						expect(dummy).to.be.an.instanceof(Dummy)
						expect(dummy).to.be.an.instanceof(SyncObject)
						expect(dummy).to.shallowDeepEqual(pojsos[i])

	describe 'SyncObject synchronization', ->
		it 'should be stringified to a reference', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			dummy.done ->
				string = JSON.stringify(dummy)
				expect(string).to.equal("{\"dataPacketRef\":\"#{nextId}\"}")

		it 'should save a correct dataPacket', ->
			dataPackets.nextPuts.push true
			pojso = {a: 'b', c: {d: 'e'}}
			packet = {id: 'abcdefgh', data: pojso}
			expected = clone packet
			expected.data.dummyProperty = 'a'
			request = Dummy.from packet
			request.then (dummy) -> dummy.save().then ->
				expect(dataPackets.calls).to.equal(1)
				expect(dataPackets.putCalls).
					to.deep.have.property('[0].packet').deep.equal(expected)
				expect(dataPackets.putCalls).to.deep.have.property('[0].put', true)

		it 'should delete the right datapacket', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dataPackets.nextDeletes.push true
			dummy = new Dummy()
			dummy.delete().then ->
				expect(dataPackets.calls).to.equal(2)
				expect(dataPackets.createCalls).to.deep.equal([nextId])
				expect(dataPackets.deleteCalls)
					.to.deep.equal([{delete: true, id: nextId}])

		it 'should reject after deletion', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dataPackets.nextDeletes.push true
			dummy = new Dummy()
			dummy.delete().then ->
				expect(dummy.done()).to.be.rejectedWith("Dummy \##{nextId} was deleted")

	describe 'Task chaining', ->
		it 'should return itself when calling next', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			expect(dummy.next()).to.equal(dummy)

		it 'should return a promise when calling done', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			expect(dummy.done()).to.be.an.instanceof(Promise)

		it 'should resolve the done promise to the result of the callback', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			result = {a: 'b'}
			expect(dummy.done( -> return result)).to.eventually.equal(result)

		it 'should reject the done promise to thrown errors of the callback', ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			error = 'Something bad happened'
			expect(dummy.done( -> throw new Error error)).to.be.rejectedWith(error)

		it 'should catch previous errors',  ->
			dataPackets.nextIds.push nextId = 'abcdefgh'
			dummy = new Dummy()
			error = 'Something bad happened'
			result = {a: 'b'}
			expect(dummy.done( -> throw new Error error).catch( -> return result)).
			to.eventually.equal(result)
