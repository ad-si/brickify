BrushHandler = require './BrushHandler'
PointEventHandler = require './pointEventHandler'
pointerEnums = require '../../client/ui/pointerEnums'

class EditControl
	constructor: ->
		@interactionDisabled = false

	init: (@bundle) ->
		@nodeVisualizer = @bundle.getPlugin 'nodeVisualizer'
		@newBrickator = @bundle.getPlugin 'newBrickator'

		@brushHandler = new BrushHandler(@bundle, @nodeVisualizer, @)

		brushUi = @bundle.ui.workflowUi.workflow.edit.brushUi
		brushUi.setBrushes @brushHandler.getBrushes()

		@pointEventHandler = new PointEventHandler(
			@bundle.sceneManager
			brushUi
		)

	# Disables any brush interaction for the user
	disableInteraction: =>
		@interactionDisabled = true

	# Enables brush interaction for the user and sets correct display
	# mode for the currently selected brush
	enableInteraction: =>
		@interactionDisabled = false

		if @brushHandler.legoBrushSelected
			@nodeVisualizer.setDisplayMode(
				@bundle.sceneManager.selectedNode, 'legoBrush'
			)
		else
			@nodeVisualizer.setDisplayMode(
				@bundle.sceneManager.selectedNode, 'printBrush'
			)

	onPointerEvent: (event, eventType) =>
		return false if not @nodeVisualizer? or not @pointEventHandler?

		ignoreInvisible = event.buttons isnt pointerEnums.buttonStates.right
		if not @nodeVisualizer.pointerOverModel event, ignoreInvisible
			# when we are not above model, call only move and up events
			switch eventType
				when pointerEnums.events.PointerMove
					@pointEventHandler.pointerMove event
				when pointerEnums.events.PointerUp
					@pointEventHandler.pointerUp event
			return false

		switch eventType
			when pointerEnums.events.PointerDown
				@pointEventHandler.pointerDown event
				return true
			when pointerEnums.events.PointerMove
				return @pointEventHandler.pointerMove event
			when pointerEnums.events.PointerUp
				@pointEventHandler.pointerUp event
				return true
			when pointerEnums.events.PointerCancel
				@pointEventHandler.PointerCancel event
				return true

	relayoutModifiedParts: (selectedNode, touchedVoxels, createBricks) =>
		@newBrickator.relayoutModifiedParts selectedNode, touchedVoxels, createBricks

module.exports = EditControl
