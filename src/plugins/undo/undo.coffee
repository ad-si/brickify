$ = require 'jquery'

nullData =
	undoTasks: []
	redoTasks: []

nullNode =
	getPluginData: -> Promise.resolve nullData

class Undo
	constructor: ->
		@currentNode = nullNode
		@_initUi()

	onNodeAdd: (node) =>
		nodeData =
			undoTasks: []
			redoTasks: []
		node.storePluginData 'undo', nodeData
		@currentNode = node
		@_updateUi()
		return

	onNodeSelect: (node) =>
		@currentNode = node
		@_updateUi()
		return

	onNodeDeselect: =>
		@currentNode = nullNode
		@_updateUi()
		return

	onNodeRemove: (node) =>
		if node is @currentNode
			@currentNode = nullNode
		@_updateUi()
		return

	addTask: (undo, redo) =>
		@currentNode.getPluginData 'undo'
		.then ({undoTasks, redoTasks}) ->
			undoTasks.push {undo, redo}
			redoTasks.length = 0
		.then @_updateUi

	undo: =>
		@currentNode.getPluginData 'undo'
		.then ({undoTasks, redoTasks}) ->
			action = undoTasks.pop()
			return unless action?

			redoTasks.push action
			action.undo()
		.then @_updateUi

	redo: =>
		@currentNode.getPluginData 'undo'
		.then ({undoTasks, redoTasks}) ->
			action = redoTasks.pop()
			return unless action?

			undoTasks.push action
			action.redo()
		.then @_updateUi

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

	_initUi: =>
		@$undo = $('#undo')
		@$redo = $('#redo')

		@$undo.click @undo
		@$redo.click @redo

	_updateUi: =>
		@currentNode.getPluginData 'undo'
		.then ({undoTasks, redoTasks}) =>
			@$undo.toggleClass('disabled', undoTasks.length is 0)
			@$redo.toggleClass('disabled', redoTasks.length is 0)

module.exports = Undo
