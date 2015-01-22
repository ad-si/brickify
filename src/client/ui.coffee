Hotkeys = require './hotkeys'

###
# @module ui
###

module.exports = class Ui
	constructor: (@bundle) ->
		@renderer = bundle.renderer
		@pluginHooks = bundle.pluginHooks
		@_init()

	dropHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		files = event.target.files ? event.dataTransfer.files
		@bundle.modelLoader.readFiles files if files?

	dragOverHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		event.dataTransfer.dropEffect = 'copy'

	clickHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		for onClickHandler in @pluginHooks.get 'onClick'
			onClickHandler(event)

	# Bound to updates to the window size:
	# Called whenever the window is resized.
	windowResizeHandler: (event) ->
		@renderer.windowResizeHandler()

	_init: =>
		@_initListeners()
		@_initScenegraph()
		@_initWorkflow()
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
			@clickHandler.bind @
			false
		)

	_initScenegraph: =>
		@bundle.getPlugin('scene-graph').initUi $('#sceneGraphContainer')
		return

	_initWorkflow: =>
		return

	_initHotkeys: =>
		hotkeys = new Hotkeys(@pluginHooks)
