BrushHandler = require './BrushHandler'
PointEventHandler = require './pointEventHandler'
pointerEnums = require '../../client/ui/pointerEnums'

class EditController
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
		return false if @interactionDisabled
		return false if not @nodeVisualizer? or not @pointEventHandler?

		ignoreInvisible = event.buttons isnt pointerEnums.buttonStates.right
		if not @nodeVisualizer.pointerOverModel event, ignoreInvisible
			# when we are not above model, call only move and up events
			switch eventType
				when pointerEnums.events.PointerMove
					return @pointEventHandler.pointerMove event
				when pointerEnums.events.PointerUp
					return @pointEventHandler.pointerUp event
			return false

		switch eventType
			when pointerEnums.events.PointerDown
				return @pointEventHandler.pointerDown event
			when pointerEnums.events.PointerMove
				return @pointEventHandler.pointerMove event
			when pointerEnums.events.PointerUp
				return @pointEventHandler.pointerUp event
			when pointerEnums.events.PointerCancel
				return @pointEventHandler.PointerCancel event
		return false

	# Methods called by brush handler
	relayoutModifiedParts: (
		selectedNode, cachedData, touchedVoxels, createBricks) =>
		@newBrickator.relayoutModifiedParts selectedNode, touchedVoxels, createBricks
		cachedData.brickVisualization.updateVisualization()

	rerunLegoPipeline: (selectedNode) =>
		@newBrickator.runLegoPipeline selectedNode

	everythingPrint: (selectedNode) =>
		@newBrickator.everythingPrint selectedNode

module.exports = EditController
