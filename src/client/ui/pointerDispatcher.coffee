interactionHelper = require '../interactionHelper'

BUTTON_STATES =
	none: 0
	left: 1
	right: 2
	middle: 4
	x1: 8
	x2: 16
	eraser: 32

class PointerDispatcher
	constructor: (@bundle) ->
		return

	init: =>
		@isBrushing = false
		@brushToggled = false
		@sceneManager = @bundle.sceneManager
		@brushUi = @bundle.ui.workflowUi.workflow.edit.brushUi
		@initListeners()

	initListeners: =>
		_registerEvent = (element, event) =>
			element.addEventListener event.toLowerCase(), @['on' + event]

		events = [
			'PointerOver'
			'PointerEnter'
			'PointerDown'
			'PointerMove'
			'PointerUp'
			'PointerCancel'
			'PointerOut'
			'PointerLeave'
			'GotPointerCapture'
			'LostPointerCapture'
			'ContextMenu'
		]

		element = @bundle.ui.renderer.getDomElement()
		_registerEvent element, event for event in events

	onPointerOver: (event) ->
		return

	onPointerEnter: (event) ->
		return

	onPointerDown: (event) =>
		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?
		# ignore interaction with empty space or with the base plane
		plugin = @_getResponsiblePluginFor event
		return if not plugin

		# we have a valid plugin -> we will handle this!
		@_capturePointerFor event

		# toggle brush if it is the right mouse button
		if(event.buttons & BUTTON_STATES.right)
			@brushToggled = @brushUi.toggleBrush()

		# perform brush action
		@isBrushing = true
		brush = @brushUi.getSelectedBrush()
		if brush? and brush.mouseDownCallback?
			brush.mouseDownCallback event, @sceneManager.selectedNode

		@_stop event
		return

	onPointerMove: (event) =>
		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?

		if event.buttons not in
		[BUTTON_STATES.none, BUTTON_STATES.left, BUTTON_STATES.right]
			@_cancelBrush event
			return

		# perform brush action
		brush = @brushUi.getSelectedBrush()
		return unless brush?

		if @isBrushing and brush.mouseMoveCallback?
			brush.mouseMoveCallback event, @sceneManager.selectedNode
			@_stop event
		else if event.buttons is BUTTON_STATES.none and brush.mouseHoverCallback?
			brush.mouseHoverCallback event, @sceneManager.selectedNode
			@_stop event

		return

	onPointerUp: (event) =>
		# Pointer capture will be implicitly released

		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?

		# end brush action
		if @isBrushing
			@isBrushing = false
			brush = @brushUi.getSelectedBrush()
			if brush? and brush.mouseUpCallback?
				brush.mouseUpCallback event, @sceneManager.selectedNode

			@_untoggleBrush()
		return

	onPointerCancel: (event) =>
		# Pointer capture will be implicitly released

		@_cancelBrush event
		return

	onPointerOut: (event) ->
		return

	onPointerLeave: (event) ->
		return

	onGotPointerCapture: (event) ->
		return

	onLostPointerCapture: (event) ->
		return

	_capturePointerFor: (event) =>
		element = @bundle.ui.renderer.getDomElement()
		element.setPointerCapture event.pointerId

	_releasePointerFor: (event) =>
		element = @bundle.ui.renderer.getDomElement()
		element.releasePointerCapture event.pointerId

	onContextMenu: (event) =>
		# this event sometimes interferes with right clicks
		@_stop event

	_untoggleBrush: =>
		if @brushToggled
			@brushUi.toggleBrush()
			@brushToggled = false

	_cancelBrush: (event) =>
		if @isBrushing
			@isBrushing = false
			brush = @brushUi.getSelectedBrush()
			if brush? and brush.cancelCallback?
				brush.cancelCallback event, @sceneManager.selectedNode

			@_untoggleBrush()
			@_stop event

	_stop: (event) ->
		event.stopPropagation()
		event.stopImmediatePropagation()
		event.preventDefault()

	_getResponsiblePluginFor: (event) =>
		return interactionHelper.getResponsiblePlugin(
			event
			@bundle.ui.renderer
			@bundle.ui.renderer.scene.children
			(plugin) -> plugin.name not in ['lego-board', 'coordinate-system']
		)

module.exports = PointerDispatcher
