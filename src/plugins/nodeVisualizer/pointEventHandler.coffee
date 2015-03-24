pointerEnums = require '../../client/ui/pointerEnums'

class PointEventHandler
	constructor: (@sceneManager, @brushSelector) ->
		@isBrushing = false
		@brushToggled = false

	pointerDown: (event) =>
		# toggle brush if it is the right mouse button
		if(event.buttons & pointerEnums.buttonStates.right)
			@brushToggled = @brushSelector.toggleBrush()

		# perform brush action
		@isBrushing = true
		brush = @brushSelector.getSelectedBrush()
		if brush? and brush.mouseDownCallback?
			brush.mouseDownCallback event, @sceneManager.selectedNode

	pointerMove: (event) =>
		if event.buttons not in	[
			pointerEnums.buttonStates.none,
			pointerEnums.buttonStates.left,
			pointerEnums.buttonStates.right
		]
			@_cancelBrush event
			return false

		# perform brush action
		brush = @brushSelector.getSelectedBrush()
		return false unless brush?

		if @isBrushing and brush.mouseMoveCallback?
			brush.mouseMoveCallback event, @sceneManager.selectedNode
			return true
		else if event.buttons is pointerEnums.buttonStates.none and
		brush.mouseHoverCallback?
			brush.mouseHoverCallback event, @sceneManager.selectedNode
			return true

	pointerUp: (event) =>
		# end brush action
		if @isBrushing
			@isBrushing = false
			brush = @brushSelector.getSelectedBrush()
			if brush? and brush.mouseUpCallback?
				brush.mouseUpCallback event, @sceneManager.selectedNode

			@_untoggleBrush()

	pointerCancel: (event) =>
		if @isBrushing
			@isBrushing = false
			brush = @brushSelector.getSelectedBrush()
			if brush? and brush.cancelCallback?
				brush.cancelCallback event, @sceneManager.selectedNode

			@_untoggleBrush()
			@_stop event

	_untoggleBrush: =>
		if @brushToggled
			@brushSelector.toggleBrush()
			@brushToggled = false

module.exports = PointEventHandler
