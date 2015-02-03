objectTree = require '../common/objectTree'

class UiSelection
	constructor: (@bundle) ->
		@selectedNode = null
		@selectionCallbacks = []

	select: (@selectedNode) =>
		for s in @selectionCallbacks
			s(@selectedNode)

	deselect: (node) =>
		if not node? or node is @selectedNode
			@selectedNode = null

			for s in @selectionCallbacks
				s(null)
		return

	selectionChange: (callback) =>
		@selectionCallbacks.push callback

	_deleteCurrentNode: () =>
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

	getHotkeys: =>
		return {
			title: 'Scenegraph'
			events: [
				{
					hotkey: 'del'
					description: 'delete selected model'
					callback: @_deleteCurrentNode
				}
			]
		}

module.exports = UiSelection
