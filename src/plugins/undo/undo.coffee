nullData =
	undoTasks: []
	redoTasks: []

nullNode =
	getPluginData: -> Promise.resolve nullData

class Undo
	constructor: ->
		@currentNode = nullNode

	onNodeAdd: (node) =>
		nodeData =
			undoTasks: []
			redoTasks: []
		node.storePluginData 'undo', nodeData
		@currentNode = node
		return

	onNodeSelect: (node) =>
		@currentNode = node
		return

	onNodeDeselect: =>
		@currentNode = nullNode
		return

	onNodeRemove: (node) =>
		if node is @currentNode
			@currentNode = nullNode
		return

	addTask: (undo, redo) =>
		@currentNode.getPluginData 'undo'
		.then ({undoTasks, redoTasks}) ->
			undoTasks.push {undo, redo}
			redoTasks.length = 0

	undo: =>
		@currentNode.getPluginData 'undo'
		.then ({undoTasks, redoTasks}) ->
			action = undoTasks.pop()
			return unless action?

			redoTasks.push action
			action.undo()

	redo: =>
		@currentNode.getPluginData 'undo'
		.then ({undoTasks, redoTasks}) ->
			action = redoTasks.pop()
			return unless action?

			undoTasks.push action
			action.redo()

	getHotkeys: =>
		return {
		title: 'Undo/Redo'
		events: [
			{
				description: 'Undo last brush action'
				hotkey: 'ctrl+z'
				callback: @undo
			}
			{
				description: 'Redo last brush action'
				hotkey: 'ctrl+y'
				callback: @redo
			}
		]
		}

module.exports = Undo
