BrushHandler = require './BrushHandler'
PointEventHandler = require './pointEventHandler'
pointerEnums = require '../../client/ui/pointerEnums'

class EditControl
	init: (@bundle) ->
		@nodeVisualizer = @bundle.getPlugin 'nodeVisualizer'
		@newBrickator = @bundle.getPlugin 'newBrickator'

		@brushHandler = new BrushHandler(@bundle, @nodeVisualizer)

		brushUi = @bundle.ui.workflowUi.workflow.edit.brushUi
		brushUi.setBrushes @brushHandler.getBrushes()

		@pointEventHandler = new PointEventHandler(
			@bundle.sceneManager
			brushUi
		)

	onPointerEvent: (event, eventType) =>
		return false if not @nodeVisualizer? or not @pointEventHandler?

		if not @nodeVisualizer.pointerOverModel event
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

module.exports = EditControl
