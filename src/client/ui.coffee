Hotkeys = require './hotkeys'
UiSceneManager = require './uiSceneManager'
UiObjects = require './UiObjects'
interactionHelper = require './interactionHelper'

###
# @module ui
###

module.exports = class Ui
	constructor: (@bundle) ->
		@renderer = @bundle.renderer
		@pluginHooks = @bundle.pluginHooks
		@objects = new UiObjects(@bundle)
		@sceneManager = new UiSceneManager(@bundle)

	dropHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		files = event.target.files ? event.dataTransfer.files
		@bundle.modelLoader.readFiles files if files?

	dragOverHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		event.dataTransfer.dropEffect = 'copy'

	mouseDownHandler: (event) =>
		event.stopPropagation()
		event.preventDefault()

		@mouseDown = true

		if @_clickedOnPluginObject(event)
			@brushActive = true
			brush = @objects.getSelectedBrush()
			if brush? and brush.mouseDownCallback?
				brush.mouseDownCallback event, @sceneManager.selectedNode

	mouseUpHandler: (event) =>
		event.preventDefault()

		if @mouseDown
			@mouseDown = false

		if @brushActive
			@brushActive = false
			brush = @objects.getSelectedBrush()
			if brush? and brush.mouseUpCallback?
				brush.mouseUpCallback event, @sceneManager.selectedNode

	mouseMoveHandler: (event) =>
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


	# Bound to updates to the window size:
	# Called whenever the window is resized.
	windowResizeHandler: (event) ->
		@renderer.windowResizeHandler()

	init: =>
		@_initListeners()
		@_initUiElements()
		@_initHotkeys()

	_initListeners: =>
		# event listener
		@renderer.getDomElement().addEventListener(
			'dragover'
			@dragOverHandler.bind @
			false
		)
		@renderer.getDomElement().addEventListener(
			'drop'
			@dropHandler.bind @
			false
		)

		window.addEventListener(
			'resize',
			@windowResizeHandler.bind @,
			false
		)

		@renderer.getDomElement().addEventListener(
			'mousedown'
			@mouseDownHandler.bind @
			false
		)

		@renderer.getDomElement().addEventListener(
			'mouseup'
			@mouseUpHandler.bind @
			false
		)

		@renderer.getDomElement().addEventListener(
			'mousemove'
			@mouseMoveHandler.bind @
			false
		)

	_initUiElements: =>
		@objects.init('#objectsContainer')
		@sceneManager.init()

	_initHotkeys: =>
		@hotkeys = new Hotkeys(@pluginHooks)
		@hotkeys.addEvents @sceneManager.getHotkeys()

		gridHotkeys = {
			title: 'UI'
			events: [
				{
					description: 'Toggle coordinate system / lego plate'
					hotkey: 'g'
					callback: =>
						@_toggleGridVisibility()
				}
			]
		}
		@hotkeys.addEvents gridHotkeys

	_toggleGridVisibility: () =>
		@bundle.getPlugin('lego-board').toggleVisibility()
		@bundle.getPlugin('coordinate-system').toggleVisibility()

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
