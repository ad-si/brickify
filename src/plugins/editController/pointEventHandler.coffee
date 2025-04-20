pointerEnums = require '../../client/ui/pointerEnums'

class PointEventHandler
	constructor: (@sceneManager, @brushUi) ->
		@isBrushing = false
		@brushToggled = false

	pointerDown: (event) =>
		return false if not @_validBrushButton event

		# toggle brush if it is the right mouse button
		if(event.buttons & pointerEnums.buttonStates.right)
			@brushToggled = @brushUi.toggleBrush()

		# perform brush action
		@isBrushing = true
		@brushUi.getSelectedBrush()?.onBrushDown? event, @sceneManager.selectedNode
		return true

	pointerMove: (event) =>
		if not @_validBrushButton event
			@pointerCancel event
			return false

		# perform brush action
		brush = @brushUi.getSelectedBrush()
		return false unless brush?

		if @isBrushing
			brush.onBrushMove? event, @sceneManager.selectedNode
			return true
		else if event.buttons is pointerEnums.buttonStates.none
			brush.onBrushOver? event, @sceneManager.selectedNode
			return true

	pointerUp: (event) =>
		return false unless @isBrushing

		# end brush action
		@isBrushing = false
		@brushUi.getSelectedBrush()?.onBrushUp? event, @sceneManager.selectedNode

		@_untoggleBrush()
		return true

	pointerCancel: (event) =>
		return false unless @isBrushing

		@isBrushing = false
		@brushUi.getSelectedBrush()?.onBrushCancel?(
			event, @sceneManager.selectedNode
		)

		@_untoggleBrush()
		return true

	_untoggleBrush: =>
		if @brushToggled
			@brushUi.toggleBrush()
			@brushToggled = false

	_validBrushButton: (event) ->
		return true if event.buttons in	[
			pointerEnums.buttonStates.none,
			pointerEnums.buttonStates.left,
			pointerEnums.buttonStates.right
		]
		return false

module.exports = PointEventHandler
