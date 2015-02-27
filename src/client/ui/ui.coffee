Hotkeys = require '../hotkeys'
UiSceneManager = require './sceneManager'
UiObjects = require './objects'
PointerDispatcher = require './pointerDispatcher'
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
		@pointerDispatcher = new PointerDispatcher(@bundle)
		@downloadProvider = new DownloadProvider(@bundle)

	dropHandler: (event) =>
		event.stopPropagation()
		event.preventDefault()
		files = event.target.files ? event.dataTransfer.files
		@bundle.modelLoader.readFiles files if files?

	dragOverHandler: (event) =>
		event.stopPropagation()
		event.preventDefault()
		event.dataTransfer.dropEffect = 'copy'

	# Bound to updates to the window size:
	# Called whenever the window is resized.
	windowResizeHandler: (event) =>
		@renderer.windowResizeHandler()

	init: =>
		@_initListeners()
		@_initUiElements()
		@_initHotkeys()
		@downloadProvider.init('#downloadButton', @sceneManager)

	_initListeners: =>
		@pointerDispatcher.init()

		# event listener
		@renderer.getDomElement().addEventListener(
			'dragover'
			@dragOverHandler
		)
		@renderer.getDomElement().addEventListener(
			'drop'
			@dropHandler
		)

		window.addEventListener(
			'resize'
			@windowResizeHandler
		)

	_initUiElements: =>
		@objects.init('#objectsContainer', '#brushContainer', '#visibilityContainer')
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
