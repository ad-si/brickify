objectTree = require '../common/state/objectTree'

class Scene
	constructor: (@bundle) ->
		@selectedNode = null
		@pluginHooks = @bundle.pluginHooks

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
		return

	remove: (node) =>
		@pluginHooks.onNodeRemove node
		return

#
# Selection of nodes
#

	select: (@selectedNode) =>
		@bundle.ui.workflow.showCurrent @selectedNode
		@pluginHooks.onNodeSelect @selectedNode
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
		return if not @selectedNode or @selectedNode.name == 'Scene'

		@bootboxOpen = true
		question = "Do you really want to delete #{@selectedNode.fileName}?"
		bootbox.confirm question, (result) =>
			@bootboxOpen = false
			if result
				@bundle.statesync.performStateAction @_delete(@selectedNode), true
				@deselect()

	_delete: (node) => (state) =>
		objectTree.removeNode state.rootNode, node
		@pluginHooks.onNodeRemove node

	_getDeleteHotkey: ->
		return {
			hotkey: 'del'
			description: 'delete selected model'
			callback: @_deleteCurrentNode
		}

module.exports = Scene
