Hotkeys = require '../hotkeys'
UiSceneManager = require './sceneManager'
UiObjects = require './objects'
MouseDispatcher = require './mouseDispatcher'
DownloadProvider = require './downloadProvider'

###
# @module ui
###

module.exports = class Ui
	constructor: (@bundle) ->
		@renderer = @bundle.renderer
		@pluginHooks = @bundle.pluginHooks
		@objects = new UiObjects(@bundle)
		@sceneManager = new UiSceneManager(@bundle)
		@mouseDispatcher = new MouseDispatcher(@bundle)
		@downloadProvider = new DownloadProvider(@bundle)

	dropHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		files = event.target.files ? event.dataTransfer.files
		@bundle.modelLoader.readFiles files if files?

	dragOverHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		event.dataTransfer.dropEffect = 'copy'

	# Bound to updates to the window size:
	# Called whenever the window is resized.
	windowResizeHandler: (event) ->
		@renderer.windowResizeHandler()

	init: =>
		@_initListeners()
		@_initUiElements()
		@_initHotkeys()
		@downloadProvider.init('#downloadButton', @sceneManager)

	_initListeners: =>
		# mouse dispatcher for mouse events
		@mouseDispatcher.init(@renderer, @objects, @sceneManager)
		
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
			@mouseDispatcher.handleMouseDown
			false
		)

		@renderer.getDomElement().addEventListener(
			'mouseup'
			@mouseDispatcher.handleMouseUp
			false
		)

		@renderer.getDomElement().addEventListener(
			'mousemove'
			@mouseDispatcher.handleMouseMove
			false
		)

	_initUiElements: =>
		@objects.init('#objectsContainer', '#brushContainer')
		@sceneManager.init()

	_initHotkeys: =>
		@hotkeys = new Hotkeys(@pluginHooks, @sceneManager)
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
