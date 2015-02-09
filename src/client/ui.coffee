Hotkeys = require './hotkeys'
UiSceneManager = require './uiSceneManager'
UiObjects = require './UiObjects'

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

		for onClickHandler in @pluginHooks.get 'onClick'
			onClickHandler(event)

	mouseUpHandler: (event) =>
		event.preventDefault()

	mouseMoveHandler: (event) =>
		event.preventDefault()

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
