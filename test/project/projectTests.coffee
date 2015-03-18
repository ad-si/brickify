require '../../src/common/polyfills'
chai = require 'chai'
chai.use require 'chai-as-promised'
chai.use require 'chai-shallow-deep-equal'
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
			dataPackets.nextIds.push 'abcdefgh'
			project = new Project()
			expect(project.done()).to.resolve

		it 'should be a Project and a SyncObject', ->
			dataPackets.nextIds.push 'abcdefgh'
			project = new Project()
			project.done ->
				expect(project).to.be.an.instanceof(Project)
				expect(project).to.be.an.instanceof(SyncObject)

		it 'should have one scene that is active', ->
			dataPackets.nextIds.push 'abcdefgh'
			project = new Project()
			project.done ->
				expect(project).to.have.property('scenes').
					that.is.an('array').with.length(1)
				expect(project).to.have.property('activeScene').
					that.equals(project.scenes[0])

	describe 'Project synchronization', ->
		it 'should store scenes as references', ->
			dataPackets.nextIds.push 'projectid'
			dataPackets.nextIds.push sceneId = 'sceneid'
			project = new Project()
			dataPackets.nextPuts.push true
			project.save()
			project.done ->
				packet = dataPackets.putCalls[0].packet
				expect(packet).to.have.deep.property('data.scenes').that.is.an('array')
				scenes = packet.data.scenes
				expect(scenes).to.have.length(1)
				expect(scenes[0]).to.deep.equal({dataPacketRef: sceneId})

		it 'should store the active scene', ->
			dataPackets.nextIds.push 'projectid'
			dataPackets.nextIds.push sceneId = 'sceneid'
			project = new Project()
			dataPackets.nextPuts.push true
			project.save()
			project.done ->
				packet = dataPackets.putCalls[0].packet
				expect(packet).to.have.deep.property('data.activeScene').
				that.deep.equals(packet.data.scenes[0])

		it 'should restore scene objects from references', ->
			project = {
				id: 'projectid'
				data: {
					scenes: [{dataPacketRef: 'sceneid'}]
				}
			}
			dataPackets.nextGets.push project
			scene = {
				id: 'sceneid'
				data: {
					nodes: []
				}
			}
			dataPackets.nextGets.push scene

			request = Project.from('projectid')
			expect(request).to.resolve
			request.then (project) -> project.done ->
				expect(project).to.have.property('scenes').that.is.an('array')
				scenes = project.scenes
				expect(scenes).to.have.length(1)
				expect(scenes[0]).to.shallowDeepEqual(scene.data)

		it 'should set the active scene from references', ->
			sceneRef = {dataPacketRef: 'sceneid'}
			project = {
				id: 'projectid'
				data: {
					activeScene: sceneRef
					scenes: [sceneRef]
				}
			}
			dataPackets.nextGets.push project
			scene = {
				id: 'sceneid'
				data: {
					nodes: []
				}
			}
			dataPackets.nextGets.push scene

			request = Project.from('projectid')
			expect(request).to.resolve
			request.then (project) -> project.done ->
				expect(project).to.have.property('activeScene').equal(project.scenes[0])


		it 'should not create a new scene on loading', ->
			project = {
				id: 'projectid'
				data: {
					scenes: [{dataPacketRef: 'sceneid'}]
				}
			}
			dataPackets.nextGets.push project
			scene = {
				id: 'sceneid'
				data: {
					nodes: []
				}
			}
			dataPackets.nextGets.push scene
			request = Project.from('projectid')
			expect(request).to.resolve
			request.then (project) -> project.done ->
				expect(dataPackets.createCalls).to.have.length(0)

		it 'should create a scene if scenes array is missing on loading', ->
			project = {
				id: 'projectid'
				data: {}
			}
			dataPackets.nextGets.push project
			dataPackets.nextIds.push sceneId = 'sceneId'
			request = Project.from('projectid')
			expect(request).to.resolve
			request.then (project) -> project.done ->
				expect(project).to.have.property('scenes').that.is.an('array')
				scenes = project.scenes
				expect(scenes).to.have.length(1)
				expect(scenes[0]).to.have.property('id', sceneId)
				expect(project).to.have.property('activeScene').equal(scenes[0])
				expect(dataPackets.createCalls).to.have.length(1)

		it 'should create a scene if scenes array is empty on loading', ->
			project = {
				id: 'projectid'
				data: {
					scenes: []
				}
			}
			dataPackets.nextGets.push project
			dataPackets.nextIds.push sceneId = 'sceneId'
			request = Project.from('projectid')
			expect(request).to.resolve
			request.then (project) -> project.done ->
				expect(project).to.have.property('scenes').that.is.an('array')
				scenes = project.scenes
				expect(scenes).to.have.length(1)
				expect(scenes[0]).to.have.property('id', sceneId)
				expect(project).to.have.property('activeScene').equal(scenes[0])
				expect(dataPackets.createCalls).to.have.length(1)
