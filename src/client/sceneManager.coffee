Project = require '../common/project/project'

class SceneManager
	constructor: (@bundle) ->
		@selectedNode = null
		@pluginHooks = @bundle.pluginHooks
		@project = Project.load()
		@scene = @project.then (project) -> project.getScene()

	init: () =>
		@scene
		.then (scene) -> scene.getNodes()
		.then (nodes) => @_notifyAdd node for node in nodes

	getHotkeys: =>
		return {
			title: 'Scene'
			events: [
				@_getDeleteHotkey()
			]
		}

#
# Administration of nodes
#

	add: (node) =>
		@scene
		.then (scene) -> scene.addNode node
		.then => @_notifyAdd node

	_notifyAdd: (node) =>
		@pluginHooks.onNodeAdd node
		@bundle.ui?.objects.onNodeAdd node

	remove: (node) =>
		@scene
		.then (scene) -> scene.removeNode node
		.then =>
			@pluginHooks.onNodeRemove node
			@bundle.ui?.objects.onNodeRemove node

#
# Selection of nodes
#

	select: (@selectedNode) =>
		@pluginHooks.onNodeSelect @selectedNode
		@bundle.ui?.objects.onNodeSelect @selectedNode
		return

	deselect: =>
		if @selectedNode?
			@pluginHooks.onNodeDeselect @selectedNode
			@selectedNode = null
		return

#
# Deletion of nodes
#

	_deleteCurrentNode: =>
		return if @bootboxOpen
		return if not @selectedNode?

		@bootboxOpen = true
		@selectedNode.getName().then (name) =>
			question = "Do you really want to delete #{name}?"
			bootbox.confirm question, (result) =>
				@bootboxOpen = false
				if result
					@remove @selectedNode
					@deselect()

	_getDeleteHotkey: ->
		return {
			hotkey: 'del'
			description: 'delete selected model'
			callback: @_deleteCurrentNode
		}

module.exports = SceneManager
