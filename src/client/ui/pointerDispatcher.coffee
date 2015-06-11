interactionHelper = require '../interactionHelper'
pointerEnums = require './pointerEnums'

class PointerDispatcher
	constructor: (@bundle, @hintUi) ->
		return

	init: =>
		@sceneManager = @bundle.sceneManager
		@brushUi = @bundle.ui.workflowUi.workflow.edit.brushUi
		@initListeners()

	initListeners: =>
		_registerEvent = (element, event) =>
			element.addEventListener event.toLowerCase(), @['on' + event]

		element = @bundle.ui.renderer.getDomElement()
		_registerEvent element, event for event of pointerEnums.events

	onPointerOver: (event) ->
		return

	onPointerEnter: (event) ->
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

		return

	onPointerMove: (event) =>
		# don't call mouse events if there is no selected node
		if not @sceneManager.selectedNode?
			# notify hint Ui of unhandeled event
			@hintUi.pointerMove event, false
			return

		# dispatch event
		handled = @_dispatchEvent event, pointerEnums.events.PointerMove

		# notify hint ui
		@hintUi.pointerMove event, handled

		# stop event if a plugin handled it (else let orbit controls work)
		@_stop event if handled

		return

	onPointerUp: (event) =>
		# Pointer capture will be implicitly released

		# don't call mouse events if there is no selected node
		return unless @sceneManager.selectedNode?

		# dispatch event
		handled = @_dispatchEvent event, pointerEnums.events.PointerUp

		return

	onPointerCancel: (event) =>
		# Pointer capture will be implicitly released
		@_dispatchEvent event, pointerEnums.events.PointerCancel

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

	# call plugin after plugin until a plugin reacts to this pointer event
	# returns false if no plugin handled this event
	_dispatchEvent: (event, type) ->
		for hook in @bundle.pluginHooks.get 'onPointerEvent'
			if hook event, type
				return true
		return false

module.exports = PointerDispatcher
