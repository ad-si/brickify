chai = require 'chai'
chai.use require 'chai-as-promised'
expect = chai.expect

DataPacketsMock = require '../mocks/dataPacketsMock'
SyncObject = require '../../src/common/sync/syncObject'
Project = require '../../src/common/project/project'
Scene = require '../../src/common/project/scene'

dataPackets = null

describe 'Project tests', ->
	beforeEach ->
		dataPackets = new DataPacketsMock()
		SyncObject.dataPacketProvider = dataPackets

	describe 'Project creation', ->
		it 'should resolve after creation', ->
			dataPackets.nextId = 'abcdefgh'
			project = new Project()
			expect(project.done()).to.resolve

		it 'should be a Project and a SyncObject', ->
			dataPackets.nextId = 'abcdefgh'
			before = Date.now()
			project = new Project()
			project.done ->
				expect(project).to.be.an.instanceof(Project)
				expect(project).to.be.an.instanceof(SyncObject)

		it 'should have one scene that is active', ->
			dataPackets.nextId = 'abcdefgh'
			before = Date.now()
			project = new Project()
			project.done ->
				expect(project).to.have.property('scenes').
					that.is.an('array').with.length(1)
				expect(project).to.have.deep.property('scenes.active').
					that.equals(project.scenes[0])
