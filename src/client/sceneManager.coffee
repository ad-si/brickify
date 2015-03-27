Project = require '../common/project/project'

###
# @class SceneManager
###
class SceneManager
	constructor: (@bundle) ->
		@selectedNode = null
		@pluginHooks = @bundle.pluginHooks
		@project = Project.load()
		@scene = @project.then (project) -> project.getScene()

	init: =>
		@scene
		.then (scene) -> scene.getNodes()
		.then (nodes) => @_notify 'onNodeAdd', node for node in nodes

	getHotkeys: =>
		return {
			title: 'Scene'
			events: [
				@_getDeleteHotkey()
			]
		}

	_notify: (hook, node) =>
		Promise.all @pluginHooks[hook] node
		.then => @bundle.ui?.workflowUi[hook]? node

#
# Administration of nodes
#

	add: (node) =>
		@scene
		.then (scene) =>
			@remove scene.nodes[0] if scene.nodes.length > 0
			@_addNodeToScene node

	_addNodeToScene: (node) =>
		@scene
		.then (scene) -> scene.addNode node
		.then => @_notify 'onNodeAdd', node
		.then => @select node

	remove: (node) =>
		@scene
		.then (scene) -> scene.removeNode node
		.then => @_notify 'onNodeRemove',  node
		.then =>
			if node == @selectedNode
				@deselect node

	clearScene: =>
		@scene
		.then (scene) -> scene.getNodes()
		.then (nodes) => @remove node for node in nodes

#
# Selection of nodes
#

	select: (@selectedNode) =>
		@_notify 'onNodeSelect', @selectedNode
		return

	deselect: =>
		if @selectedNode?
			@_notify 'onNodeDeselect', @selectedNode
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
