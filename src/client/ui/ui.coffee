Hotkeys = require '../hotkeys'
PointerDispatcher = require './pointerDispatcher'
WorkflowUi = require './workflowUi/workflowUi.coffee'

###
# @module ui
###

module.exports = class Ui
	constructor: (@bundle) ->
		@renderer = @bundle.renderer
		@pluginHooks = @bundle.pluginHooks
		@workflowUi = new WorkflowUi(@bundle)
		@pointerDispatcher = new PointerDispatcher(@bundle)

	fileLoadHandler: (event) ->
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
		@workflowUi.init()
		@_initListeners()
		@_initHotkeys()

	_initListeners: =>
		@pointerDispatcher.init()

		# event listener
		@renderer.getDomElement().addEventListener(
			'dragover'
			@dragOverHandler
		)

		@renderer.getDomElement().addEventListener(
			'drop'
			@fileLoadHandler.bind @
			false
		)
		$('#loadButton').on 'change', (event) =>
			@fileLoadHandler event

		window.addEventListener(
			'resize'
			@windowResizeHandler
		)

	_initHotkeys: =>
		@hotkeys = new Hotkeys(@pluginHooks, @bundle.sceneManager)
		@hotkeys.addEvents @bundle.sceneManager.getHotkeys()

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
