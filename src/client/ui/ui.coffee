Hotkeys = require '../hotkeys'
PointerDispatcher = require './pointerDispatcher'
WorkflowUi = require './workflowUi/workflowUi'
fileDropper = require '../modelLoading/fileDropper'
fileLoader = require '../modelLoading/fileLoader'

###
# @module ui
###

module.exports = class Ui
	constructor: (@bundle) ->
		@renderer = @bundle.renderer
		@pluginHooks = @bundle.pluginHooks
		@workflowUi = new WorkflowUi(@bundle)
		@pointerDispatcher = new PointerDispatcher(@bundle)

	fileLoadHandler: (event) =>
		spinnerOptions =
			length: 5
			radius: 3
			width: 2
			shadow: false
		fileLoader.onLoadFile(
			event
			document.getElementById 'loadButtonFeedback'
			spinnerOptions
		).then @bundle.modelLoader.loadByHash

	dragOverHandler: (event) ->
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

		fileDropper.init @fileLoadHandler

		# event listener
		$('#fileInput').on 'change', (event) =>
			@fileLoadHandler event
			$('#fileInput').val('')

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
					callback: @_toggleGridVisibility
				}
				{
					description: 'Toggle stability view'
					hotkey: 's'
					callback: @_toggleStabilityView
				}
			]
		}
		@hotkeys.addEvents gridHotkeys

	_toggleGridVisibility: =>
		@bundle.getPlugin('lego-board').toggleVisibility()
		@bundle.getPlugin('coordinate-system').toggleVisibility()

	_toggleStabilityView: =>
		@workflowUi.toggleStabilityView()
