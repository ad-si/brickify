SceneManger = require './SceneManager'
Project = require '../../common/project/project'

###
# @class ProjectManager
###
class ProjectManager
	constructor: (@bundle) ->
		@sceneManager = new SceneManger @bundle, @
		@project = Project.load()

	getScene: =>
		return @project.then (project) -> project.getScene()

module.exports = ProjectManager
