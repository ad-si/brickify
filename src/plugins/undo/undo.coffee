class Undo
	constructor: ->
		@clear()

	addTask: (undo, redo) =>
		action = {undo, redo}
		@undoTasks.append action
		@redoTasks = []
		return

	undo: =>
		action = @undoTasks.pop()
		return unless action?

		@redoTasks.append action
		action.undo()

		return

	redo: =>
		action = @redoTasks.pop()
		return unless action?

		@undoTasks.append action
		action.redo()

		return

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

	clear: =>
		@undoTasks = []
		@redoTasks = []

module.exports = Undo
