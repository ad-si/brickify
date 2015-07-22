class Undo
	constructor: ->
		@clear()

	addAction: (undo, redo) =>
		action = {undo, redo}
		@undo.append action
		@redo = []
		return

	undo: =>
		action = @undo.pop()
		return unless action?

		@redo.append action
		action.undo()

		return

	redo: =>
		action = @redo.pop()
		return unless action?

		@undo.append action
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
		@undo = []
		@redo = []

module.exports = Undo
