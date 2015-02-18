chai = require 'chai'
chai.use require './sceneChaiHelper'
chai.use require 'chai-as-promised'
expect = chai.expect

DataPacketsMock = require '../mocks/dataPacketsMock'
SyncObject = require '../../src/common/sync/syncObject'
Scene = require '../../src/common/project/scene'
Node = require '../../src/common/project/node'

dataPackets = null

describe 'Scene tests', ->
	beforeEach ->
		dataPackets = new DataPacketsMock()
		SyncObject.dataPacketProvider = dataPackets

	describe 'Scene creation', ->
		it 'should resolve after creation', ->
			dataPackets.nextIds.push 'abcdefgh'
			scene = new Scene()
			expect(scene.done()).to.resolve

		it 'should be a Scene and a SyncObject', ->
			dataPackets.nextIds.push 'abcdefgh'
			before = Date.now()
			scene = new Scene()
			scene.done ->
				expect(scene).to.be.an.instanceof(Scene)
				expect(scene).to.be.an.instanceof(SyncObject)
				expect(scene).to.have.property('nodes').
					that.is.an('array').with.length(0)
				expect(scene).to.be.modified(Date.now(), Date.now() - before).with.
					cause('Scene creation')

	describe 'Scene manipulation', ->
		it 'should accept new nodes', ->
			dataPackets.nextIds.push 'abcdefgh'
			scene = new Scene()
			dataPackets.nextIds.push 'ijklmnop'
			node = new Node()
			name = 'Beautiful Model'
			node.setName name
			before = Date.now()
			result = scene.addNode node
			expect(result).to.equal(scene)
			scene.done ->
				expect(scene).to.have.property('nodes').that.deep.equals([node])
				expect(scene).to.be.modified(Date.now(), Date.now() - before).with.
					cause("Node \"#{name}\" added")

		it 'should remove present nodes', ->
			dataPackets.nextIds.push 'abcdefgh'
			scene = new Scene()
			dataPackets.nextIds.push 'ijklmnop'
			node = new Node()
			name = 'Beautiful Model'
			node.setName name
			before = Date.now()
			scene.addNode node
			result = scene.removeNode node
			expect(result).to.equal(scene)
			scene.done ->
				expect(scene).to.have.property('nodes').
					that.is.an('array').with.length(0)
				expect(scene).to.be.modified(Date.now(), Date.now() - before).with.
					cause("Node \"#{name}\" removed")

	describe 'Scene synchronization', ->
		it 'should store nodes as references', ->
			dataPackets.nextIds.push 'abcdefgh'
			scene = new Scene()
			dataPackets.nextIds.push nodeId = 'nodeid'
			node = new Node()
			node.setName 'Beautiful Model'
			scene.addNode node
			dataPackets.nextPuts.push true
			scene.save()
			scene.done ->
				packet = dataPackets.putCalls[0].packet
				expect(packet).to.have.deep.property('data.nodes').that.is.an('array')
				nodes = packet.data.nodes
				expect(nodes).to.have.length(1)
				expect(nodes[0]).to.deep.equal({dataPacketRef: nodeId})
