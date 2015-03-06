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

		it 'should set the model\'s hash in constructor', ->
			dataPackets.nextIds.push 'abcdefgh'
			hash = 'randomModelHash'
			node = new Node modelHash: hash
			expect(node.getModelHash()).to.eventually.equal(hash)

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
				to.have.deep.property('[0].packet.data.name', name)

		it 'should set the node\'s name in constructor', ->
			dataPackets.nextIds.push 'abcdefgh'
			name = 'Beautiful Model'
			node = new Node name: name
			expect(node.getName()).to.eventually.equal(name)

	describe 'plugin data in nodes', ->
		it 'should store plugin data chainable', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			data = {random: ['plugin', 'data']}
			result = node.storePluginData 'pluginName', data
			expect(result).to.equal(node)
			result.done ->
				expect(node).to.have.property('pluginName').that.deep.equals(data)

		it 'should get plugin data', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			data = {random: ['plugin', 'data']}
			result = node.storePluginData 'pluginName', data
			expect(node.getPluginData('pluginName')).to.eventually.deep.equal(data)

		it 'should return undefined if plugin data is not available', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			expect(node.getPluginData('pluginName')).to.eventually.be.undefined

		it 'should not store plugin data by default', ->
			dataPackets.nextIds.push 'abcdefgh'
			dataPackets.nextPuts.push true
			node = new Node()
			data = {random: ['plugin', 'data']}
			node.storePluginData 'pluginName', data
			node.save().then ->
				expect(dataPackets.calls).to.equal(2)
				expect(dataPackets.createCalls).to.have.length(1)
				expect(dataPackets.putCalls).
				to.not.deep.have.property('[0].packet.data.pluginName')

		it 'should store plugin data if transient set to false', ->
			dataPackets.nextIds.push 'abcdefgh'
			dataPackets.nextPuts.push true
			node = new Node()
			data = {random: ['plugin', 'data']}
			node.storePluginData 'pluginName', data, false
			node.save().then ->
				expect(dataPackets.calls).to.equal(2)
				expect(dataPackets.createCalls).to.have.length(1)
				expect(dataPackets.putCalls).
				to.deep.have.property('[0].packet.data.pluginName').
				that.deep.equals(data)

	describe 'node transform', ->
		it 'should provide reasonable default transforms', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			position = x: 0, y: 0, z: 0
			rotation = x: 0, y: 0, z: 0
			scale = x: 1, y: 1, z: 1
			Promise.all([
				expect(node.getPosition()).to.eventually.deep.equal(position)
				expect(node.getRotation()).to.eventually.deep.equal(rotation)
				expect(node.getScale()).to.eventually.deep.equal(scale)
			])

		it 'should set the position chainable', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			position = x: 10, y: 20, z: 30
			result = node.setPosition(position)
			expect(result).to.equal(node)
			result.done ->
				expect(node).to.have.deep.property('transform.position', position)

		it 'should get the position', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			position = x: 10, y: 20, z: 30
			node.setPosition(position)
			expect(node.getPosition()).to.eventually.deep.equal(position)

		it 'should set the rotation chainable', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			rotation = x: 1, y: 2, z: 3
			result = node.setRotation(rotation)
			expect(result).to.equal(node)
			result.done ->
				expect(node).to.have.deep.property('transform.rotation', rotation)

		it 'should get the rotation', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			rotation = x: 1, y: 2, z: 3
			node.setRotation(rotation)
			expect(node.getRotation()).to.eventually.deep.equal(rotation)

		it 'should set the scale chainable', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			scale = x: 2, y: 2, z: 2
			result = node.setScale(scale)
			expect(result).to.equal(node)
			result.done ->
				expect(node).to.have.deep.property('transform.scale', scale)

		it 'should get the scale', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			scale = x: 2, y: 2, z: 2
			node.setScale(scale)
			expect(node.getScale()).to.eventually.deep.equal(scale)

		it 'should set the transform chainable', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			position = x: 0, y: 10, z: 20
			rotation = x: 30, y: 40, z: 50
			scale = x: 1, y: 2, z: 3
			transform = position: position, rotation: rotation, scale: scale
			result = node.setTransform(transform)
			expect(result).to.equal(node)
			result.done ->
				expect(node).to.have.deep.property('transform.position', position)
				expect(node).to.have.deep.property('transform.rotation', rotation)
				expect(node).to.have.deep.property('transform.scale', scale)

		it 'should set the transform in constructor', ->
			dataPackets.nextIds.push 'abcdefgh'
			position = x: 0, y: 10, z: 20
			rotation = x: 30, y: 40, z: 50
			scale = x: 1, y: 2, z: 3
			transform = position: position, rotation: rotation, scale: scale
			node = new Node transform: transform
			Promise.all([
				expect(node.getPosition()).to.eventually.deep.equal(position)
				expect(node.getRotation()).to.eventually.deep.equal(rotation)
				expect(node.getScale()).to.eventually.deep.equal(scale)
			])

		it 'should get the transform', ->
			dataPackets.nextIds.push 'abcdefgh'
			node = new Node()
			position = x: 0, y: 10, z: 20
			rotation = x: 30, y: 40, z: 50
			scale = x: 1, y: 2, z: 3
			transform = position: position, rotation: rotation, scale: scale
			node.setTransform(transform)
			expect(node.getTransform()).to.eventually.deep.equal(transform)

		it 'should store the transform', ->
			dataPackets.nextIds.push 'abcdefgh'
			dataPackets.nextPuts.push true
			node = new Node()
			position = x: 0, y: 10, z: 20
			rotation = x: 30, y: 40, z: 50
			scale = x: 1, y: 2, z: 3
			transform = position: position, rotation: rotation, scale: scale
			node.setTransform(transform)
			node.save().then ->
				expect(dataPackets.calls).to.equal(2)
				expect(dataPackets.createCalls).to.have.length(1)
				expect(dataPackets.putCalls).
				to.deep.have.deep.property('[0].packet.data.transform').
				that.deep.equals(transform)
