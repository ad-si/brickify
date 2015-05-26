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
		# end brush action
		if @isBrushing
			@isBrushing = false
			@brushUi.getSelectedBrush()?.onBrushUp? event, @sceneManager.selectedNode

			@_untoggleBrush()

	pointerCancel: (event) =>
		if @isBrushing
			@isBrushing = false
			@brushUi.getSelectedBrush()?.onBrushCancel?(
				event, @sceneManager.selectedNode
			)

			@_untoggleBrush()

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

