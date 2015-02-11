interactionHelper = require '../interactionHelper'

module.exports = class MouseDispatcher
	constructor: (@bundle) ->
		return

	init: (@renderer, @objects, @sceneManager) =>
		@mouseDown = false
		@brushActive = false

	handleMouseDown: (event) =>
		event.stopPropagation()
		event.preventDefault()

		@mouseDown = true

		if @_clickedOnPluginObject(event)
			@brushActive = true
			brush = @objects.getSelectedBrush()
			if brush? and brush.mouseDownCallback?
				brush.mouseDownCallback event, @sceneManager.selectedNode

	handleMouseUp: (event) =>
		event.preventDefault()

		if @mouseDown
			@mouseDown = false

		if @brushActive
			@brushActive = false
			brush = @objects.getSelectedBrush()
			if brush? and brush.mouseUpCallback?
				brush.mouseUpCallback event, @sceneManager.selectedNode

	handleMouseMove: (event) =>
		event.preventDefault()
		#console.log "mouseMove (down: #{@mouseDown})"

		brush = @objects.getSelectedBrush()

		if @brushActive
			if brush? and brush.mouseMoveCallback?
				brush.mouseMoveCallback event, @sceneManager.selectedNode
				event.stopPropagation()
		else if not @mouseDown
			if brush? and brush.mouseHoverCallback?
				brush.mouseHoverCallback event, @sceneManager.selectedNode

	_clickedOnPluginObject: (event) =>
		# returns true if the current mouse (event)
		# is over a non-coordinatesystem plugin

		selection = interactionHelper.getPolygonClickedOn event,
			@renderer.scene.children, @renderer

		if selection.length > 0
			obj = selection[0].object
			plugin = null
			while obj.parent and plugin == null
				if obj.associatedPlugin?
					plugin = obj.associatedPlugin
				else
					obj = obj.parent

		if plugin and
		plugin.name != 'lego-board' and
		plugin.name != 'coordinate-system'
			return true

		return false
