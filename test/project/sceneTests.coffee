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
			dataPackets.nextId = 'abcdefgh'
			scene = new Scene()
			expect(scene.done()).to.resolve

		it 'should be a Scene and a SyncObject', ->
			dataPackets.nextId = 'abcdefgh'
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
			dataPackets.nextId = 'abcdefgh'
			scene = new Scene()
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
			dataPackets.nextId = 'abcdefgh'
			scene = new Scene()
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
