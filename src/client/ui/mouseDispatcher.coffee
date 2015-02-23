interactionHelper = require '../interactionHelper'

module.exports = class MouseDispatcher
	constructor: (@bundle) ->
		return

	init: (@renderer, @objects, @sceneManager) =>
		@mouseDown = false
		@brushActive = false

	handleMouseDown: (event) =>
		# don't call mouse events if there is no selected node
		if not @sceneManager.selectedNode?
			return

		@mouseDown = true

		# brush action if we clicked on some plugin geometry (and not void / grid)
		if @_clickedOnPluginObject(event)
			event.stopPropagation()
			event.preventDefault()

			# override object selection if we clicked on another object
			clickedNode = @_getClickedNode event
			if clickedNode? and clickedNode != @sceneManager.selectedNode
				@objects.selectNode clickedNode

			# perform brush action
			@brushActive = true
			brush = @objects.getSelectedBrush()
			if brush? and brush.mouseDownCallback?
				brush.mouseDownCallback event, @sceneManager.selectedNode

	handleMouseUp: (event) =>
		# don't call mouse events if there is no selected node
		if not @sceneManager.selectedNode?
			return

		if @mouseDown
			@mouseDown = false

		if @brushActive
			@brushActive = false
			brush = @objects.getSelectedBrush()
			if brush? and brush.mouseUpCallback?
				brush.mouseUpCallback event, @sceneManager.selectedNode

	handleMouseMove: (event) =>
		# don't call mouse events if there is no selected node
		if not @sceneManager.selectedNode?
			return

		brush = @objects.getSelectedBrush()

		if @brushActive
			if brush? and brush.mouseMoveCallback?
				event.stopPropagation()
				event.preventDefault()
				
				brush.mouseMoveCallback event, @sceneManager.selectedNode
		else if not @mouseDown
			if brush? and brush.mouseHoverCallback?
				event.stopPropagation()
				event.preventDefault()
				
				brush.mouseHoverCallback event, @sceneManager.selectedNode

	_clickedOnPluginObject: (event) =>
		# returns true if the current mouse (event)
		# is over a non-coordinatesystem plugin

		# BUG: after page reload, the raycaster in interactionHelper
		# does not recognize the last object

		selection = interactionHelper.getPolygonClickedOn event,
			@renderer.scene.children, @renderer

		if selection.length > 0
			for geometry in selection
				obj = geometry.object

				while obj.parent
					if obj.associatedPlugin?
						plugin = obj.associatedPlugin

						if plugin and
						plugin.name != 'lego-board' and
						plugin.name != 'coordinate-system'
							return true

					obj = obj.parent

		return false

	_getClickedNode: (event) =>
		# relies on the fact that solidRenderer sets an 'associatedNode' property
		# for three nodes added

		selection = interactionHelper.getPolygonClickedOn event,
			@renderer.scene.children, @renderer

		if selection.length > 0
			for geometry in selection
				object = geometry.object

				if object.associatedNode?
					return object.associatedNode

				while object.parent?
					object = object.parent
					if object.associatedNode?
						return object.associatedNode
		return null
