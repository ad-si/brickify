interactionHelper = require '../interactionHelper'

class PointerDispatcher
	constructor: (@bundle) ->
		return

	init: =>
		@isBrushing = false
		@sceneManager = @bundle.ui.sceneManager
		@objects = @bundle.ui.objects
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
		]

		element = @bundle.ui.renderer.getDomElement()
		_registerEvent element, event for event in events

	onPointerOver: (event) =>
		return

	onPointerEnter: (event) =>
		return

	onPointerDown: (event) =>
		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?
		# ignore interaction with empty space or with the base plane
		plugin = @_getResponsiblePluginFor event
		return if not plugin

		# we have a valid plugin -> we will handle this!
		@_capturePointerFor event
		clickedNode = @_getNodeFor event
		if clickedNode? and clickedNode != @sceneManager.selectedNode
			@sceneManager.select clickedNode

		# perform brush action
		@isBrushing = true
		brush = @objects.getSelectedBrush()
		if brush? and brush.mouseDownCallback?
			brush.mouseDownCallback event, @sceneManager.selectedNode

		@_stop event
		return

	onPointerMove: (event) =>
		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?

		# perform brush action
		brush = @objects.getSelectedBrush()
		return unless brush?

		if @isBrushing and brush.mouseMoveCallback?
			brush.mouseMoveCallback event, @sceneManager.selectedNode
			@_stop event
		else if event.buttons is 0 and brush.mouseHoverCallback?
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
			brush = @objects.getSelectedBrush()
			if brush? and brush.mouseUpCallback?
				brush.mouseUpCallback event, @sceneManager.selectedNode

	onPointerCancel: (event) =>
		# Pointer capture will be implicitly released
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

	_stop: (event) =>
		event.stopPropagation()
		event.preventDefault()

	_getResponsiblePluginFor: (event) =>
		return interactionHelper.getResponsiblePlugin(
			event
			@bundle.ui.renderer
			@bundle.ui.renderer.scene.children
			(plugin) -> plugin.name not in ['lego-board', 'coordinate-system']
		)

	_getNodeFor: (event) =>
		return interactionHelper.getNode(
			event
			@bundle.ui.renderer
			@bundle.ui.renderer.scene.children
		)

module.exports = PointerDispatcher
