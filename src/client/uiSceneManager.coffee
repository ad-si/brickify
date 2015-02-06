objectTree = require '../common/state/objectTree'

class UiSceneManager
	constructor: (@bundle) ->
		@selectedNode = null
		@pluginHooks = @bundle.pluginHooks

	init: () =>

		# call add for existing nodes in state
		for node in @bundle.statesync.state.rootNode.children
			@add(node)

	getHotkeys: =>
		return {
			title: 'Scenegraph'
			events: [
				@_getDeleteHotkey()
			]
		}

#
# Administration of nodes
#

	add: (node) =>
		@pluginHooks.onNodeAdd node
		@bundle.ui.objects.onNodeAdd node
		return

	remove: (node) =>
		@pluginHooks.onNodeRemove node
		@bundle.ui.objects.onNodeRemove node
		return

#
# Selection of nodes
#

	select: (@selectedNode) =>
		@pluginHooks.onNodeSelect @selectedNode
		@bundle.ui.toolbar.onNodeSelect @selectedNode

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
		return if not @selectedNode or @selectedNode.name == 'UiSceneManager'

		@bootboxOpen = true
		question = "Do you really want to delete #{@selectedNode.fileName}?"
		bootbox.confirm question, (result) =>
			@bootboxOpen = false
			if result
				@bundle.statesync.performStateAction @_delete(@selectedNode), true
				@deselect()

	_delete: (node) => (state) =>
		objectTree.removeNode state.rootNode, node
		@remove node

	_getDeleteHotkey: ->
		return {
			hotkey: 'del'
			description: 'delete selected model'
			callback: @_deleteCurrentNode
		}

module.exports = UiSceneManager
