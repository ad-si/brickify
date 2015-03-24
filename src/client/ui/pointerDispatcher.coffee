interactionHelper = require '../interactionHelper'
pointerEnums = require './pointerEnums'

class PointerDispatcher
	constructor: (@bundle) ->
		return

	init: =>
		@isBrushing = false
		@brushToggled = false
		@sceneManager = @bundle.sceneManager
		@brushSelector = @bundle.ui.workflowUi.brushSelector
		@initListeners()

	initListeners: =>
		_registerEvent = (element, event) =>
			element.addEventListener event.toLowerCase(), @['on' + event]

		element = @bundle.ui.renderer.getDomElement()
		_registerEvent element, event for event of pointerEnums.events

	onPointerOver: (event) =>
		return

	onPointerEnter: (event) =>
		return

	onPointerDown: (event) =>
		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?

		# capture event in all cases
		@_capturePointerFor event

		# dispatch event
		handled = @_dispatchEvent event, pointerEnums.events.PointerDown

		# stop event if a plugin handled it (else let orbit controls work)
		@_stop event if handled

		### TODO extract
		# toggle brush if it is the right mouse button
		if(event.buttons & pointerEnums.buttonStates.right)
			@brushToggled = @brushSelector.toggleBrush()

		# perform brush action
		@isBrushing = true
		brush = @brushSelector.getSelectedBrush()
		if brush? and brush.mouseDownCallback?
			brush.mouseDownCallback event, @sceneManager.selectedNode
		###

		return

	onPointerMove: (event) =>
		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?

		# dispatch event
		handled = @_dispatchEvent event, pointerEnums.events.PointerMove
		# stop event if a plugin handled it (else let orbit controls work)
		@_stop event if handled

		### TODO extract
		if event.buttons not in	[
			pointerEnums.buttonStates.none,
			pointerEnums.buttonStates.left,
			pointerEnums.buttonStates.right
		]
			@_cancelBrush event
			return

		# perform brush action
		brush = @brushSelector.getSelectedBrush()
		return unless brush?

		if @isBrushing and brush.mouseMoveCallback?
			brush.mouseMoveCallback event, @sceneManager.selectedNode
			@_stop event
		else if event.buttons is pointerEnums.buttonStates.none and
		brush.mouseHoverCallback?
			brush.mouseHoverCallback event, @sceneManager.selectedNode
			@_stop event
		###

		return

	onPointerUp: (event) =>
		# Pointer capture will be implicitly released

		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?

		# dispatch event
		@_dispatchEvent event, pointerEnums.events.PointerUp

		### TODO extract
		# end brush action
		if @isBrushing
			@isBrushing = false
			brush = @brushSelector.getSelectedBrush()
			if brush? and brush.mouseUpCallback?
				brush.mouseUpCallback event, @sceneManager.selectedNode

			@_untoggleBrush()
		###

		return

	onPointerCancel: (event) =>
		# Pointer capture will be implicitly released
		@_dispatchEvent event, pointerEnums.events.PointerCancel

		### TODO: extract
		@_cancelBrush event
		###
		
		return

	onPointerOut: (event) =>
		return

	onPointerLeave: (event) =>
		return

	onGotPointerCapture: (event) =>
		return

	onLostPointerCapture: (event) =>
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
			@brushSelector.toggleBrush()
			@brushToggled = false

	_cancelBrush: (event) =>
		if @isBrushing
			@isBrushing = false
			brush = @brushSelector.getSelectedBrush()
			if brush? and brush.cancelCallback?
				brush.cancelCallback event, @sceneManager.selectedNode

			@_untoggleBrush()
			@_stop event

	_stop: (event) =>
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

	# call plugin after plugin until a plugin reacts to this pointer event
	# returns fals if no plugin handled this event
	_dispatchEvent: (event, type) ->
		for hook in @bundle.pluginHooks.get 'pointerEvent'
			if hook event, type
				return true
		return false


module.exports = PointerDispatcher
