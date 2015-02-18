chai = require 'chai'
chaiAsPromised = require 'chai-as-promised'
chai.use chaiAsPromised
expect = chai.expect

DataPacketsMock = require '../mocks/dataPacketsMock'
SyncObject = require '../../src/common/sync/syncObject'
ModelProviderMock = require '../mocks/modelProviderMock.coffee'
Node = require '../../src/common/project/node'

modelProvider = null
dataPackets = null

describe 'Node tests', ->
	beforeEach ->
		modelProvider = new ModelProviderMock()
		Node.modelProvider = modelProvider
		dataPackets = new DataPacketsMock()
		SyncObject.dataPacketProvider = dataPackets

	describe 'Node creation', ->
		it 'should resolve after creation', ->
			dataPackets.nextId = 'abcdefgh'
			node = new Node()
			expect(node.done()).to.resolve

		it 'should be a Node and a SyncObject', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			node.done ->
				expect(node).to.be.an.instanceof(Node)
				expect(node).to.be.an.instanceof(SyncObject)

	describe 'Node manipulation', ->
		it 'should set the model\'s hash chainable', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			hash = 'randomModelHash'
			result = node.setModelHash(hash)
			expect(result).to.equal(node)
			result.done ->
				expect(node).to.have.property('modelHash', hash)

		it 'should get the model\'s hash', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			hash = 'randomModelHash'
			node.setModelHash(hash)
			expect(node.getModelHash()).to.eventually.equal(hash)

		it 'should store the model\'s hash', ->
			dataPackets.nextIds.push 'abcdefgh'
			dataPackets.nextPuts.push true
			node = new Node()
			hash = 'randomModelHash'
			node.setModelHash(hash)
			node.save().then ->
				expect(dataPackets.calls).to.equal(2)
				expect(dataPackets.createCalls).to.have.length(1)
				expect(dataPackets.putCalls).
					to.deep.have.deep.property('[0].packet.data.modelHash', hash)

		it 'should request the correct model', ->
			dataPackets.nextIds.push 'abcdefgh'
			dataPackets.nextPuts.push true
			modelProvider.nextRequest = 'dummy'
			node = new Node()
			hash = 'randomModelHash'
			node.setModelHash(hash)
			model = node.getModel()
			expect(model).to.eventually.equal('dummy')
			model.then ->
				expect(modelProvider.calls).to.equal(1)
				expect(modelProvider.requestCalls).
					to.have.deep.property('[0].hash', hash)

		it 'should set the node\'s name chainable', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			name = 'Beautiful Model'
			result = node.setName(name)
			expect(result).to.equal(node)
			result.done ->
				expect(node).to.have.property('name', name)

		it 'should get the node\'s name', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			name = 'Beautiful Model'
			node.setName(name)
			expect(node.getName()).to.eventually.equal(name)

		it 'should store the node\'s name', ->
			dataPackets.nextIds.push 'abcdefgh'
			dataPackets.nextPuts.push true
			node = new Node()
			name = 'Beautiful Model'
			node.setName(name)
			node.save().then ->
				expect(dataPackets.calls).to.equal(2)
				expect(dataPackets.createCalls).to.have.length(1)
				expect(dataPackets.putCalls).
				to.deep.have.deep.property('[0].packet.data.name', name)
