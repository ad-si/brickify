clone = require 'clone'
chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
chai.use chaiAsPromised
expect = chai.expect

DataPacketsMock = require './dataPacketsMock'
SyncObject = require '../../src/common/sync/syncObject'
Dummy = require './dummySyncObject'

dataPackets = null

describe 'SyncObject tests', ->
	beforeEach ->
		dataPackets = new DataPacketsMock()
		SyncObject.dataPacketProvider = dataPackets

	describe 'SyncObject creation', ->
		it 'should resolve after creation', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dummy = new Dummy()
			expect(dummy.done()).to.resolve

		it 'should get an id by dataPacketProvider', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dummy = new Dummy()
			dummy.done ->
				expect(dummy).to.have.property('id', nextId)
				expect(dataPackets.calls).to.equal(1)
				expect(dataPackets.createCalls).to.deep.equal([nextId])

		it 'should support creation from a packet', ->
			pojso = {a: 'b', c: {d: 'e'}}
			packet = {id: 'abcdefgh', data: pojso}
			dummy = Dummy.newFrom packet
			dummy.done ->
				expect(dataPackets.calls).to.equal(0)
				expect(dummy).to.be.an.instanceof(Dummy)
				expect(dummy).to.be.an.instanceof(SyncObject)
				expect(dummy).to.have.property('id', packet.id)

		it 'should have the same properties as the source packet', ->
			dataPackets.nextId = wrongid = 'shouldnotbeid'
			pojso = {a: 'b', c: {d: 'e'}}
			packet = {id: 'abcdefgh', data: pojso}
			dummy = Dummy.newFrom packet
			dummy.done ->
				expect(dummy).to.have.property('a', 'b')
				expect(dummy).to.have.property('c').deep.equal({d: 'e'})

	describe 'SyncObject synchronization', ->
		it 'should save a correct dataPacket', ->
			dataPackets.nextPut = true
			pojso = {a: 'b', c: {d: 'e'}}
			packet = {id: 'abcdefgh', data: pojso}
			expected = clone packet
			expected.data.dummyProperty = 'a'
			dummy = Dummy.newFrom packet
			dummy.save().then ->
				expect(dataPackets.calls).to.equal(1)
				expect(dataPackets.putCalls).
					to.deep.have.property('[0].packet').deep.equal(expected)
				expect(dataPackets.putCalls).to.deep.have.property('[0].put', true)

		it 'should delete the right datapacket', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dataPackets.nextDelete = true
			dummy = new Dummy()
			dummy.delete().then ->
				expect(dataPackets.calls).to.equal(2)
				expect(dataPackets.createCalls).to.deep.equal([nextId])
				expect(dataPackets.deleteCalls)
					.to.deep.equal([{delete: true, id: nextId}])

		it 'should reject after deletion', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dataPackets.nextDelete = true
			dummy = new Dummy()
			dummy.delete().then ->
				expect(dummy.done()).to.be.rejectedWith("Dummy \##{nextId} was deleted")

	describe 'task chaining', ->
		it 'should return itself when calling next', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dummy = new Dummy()
			expect(dummy.next()).to.equal(dummy)

		it 'should return a promise when calling done', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dummy = new Dummy()
			expect(dummy.done()).to.be.an.instanceof(Promise)

		it 'should resolve the done promise to the result of the callback', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dummy = new Dummy()
			result = {a: 'b'}
			expect(dummy.done( -> return result)).to.eventually.equal(result)

		it 'should reject the done promise to thrown errors of the callback', ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dummy = new Dummy()
			error = 'Something bad happened'
			expect(dummy.done( -> throw new Error error)).to.be.rejectedWith(error)

		it 'should catch previous errors',  ->
			dataPackets.nextId = nextId = 'abcdefgh'
			dummy = new Dummy()
			error = 'Something bad happened'
			result = {a: 'b'}
			expect(dummy.done( -> throw new Error error).catch( -> return result)).
			to.eventually.equal(result)
