Hotkeys = require './hotkeys'
UiSelection = require './uiSelection'
UiToolbar = require './UiToolbar'
VisibilityMenu = require './VisibilityMenu'

###
# @module ui
###

module.exports = class Ui
	constructor: (@bundle) ->
		@renderer = @bundle.renderer
		@pluginHooks = @bundle.pluginHooks
		@selection = new UiSelection(@bundle)
		@toolbar = new UiToolbar(@bundle, @selection)
		@visibilityMenu = new VisibilityMenu(@bundle)
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

	mouseDownHandler: (event) =>
		event.stopPropagation()
		event.preventDefault()

		@_mouseIsDown = true

		for onClickHandler in @pluginHooks.get 'onClick'
			onClickHandler(event)

		@toolbar.handleMouseDown event

	mouseUpHandler: (event) =>
		event.preventDefault()

		@_mouseIsDown = false

		if @toolbar.hasBrushSelected()
			@toolbar.handleMouseUp event

	mouseMoveHandler: (event) =>
		event.preventDefault()

		if @_mouseIsDown
			if @toolbar.hasBrushSelected()
				event.stopPropagation()
				@toolbar.handleMouseMove event

	# Bound to updates to the window size:
	# Called whenever the window is resized.
	windowResizeHandler: (event) ->
		@renderer.windowResizeHandler()

	_init: =>
		@_initListeners()
		@_initScenegraph()
		@_initHotkeys()
		@_initDownload()

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

	_initScenegraph: =>
		@bundle.getPlugin('scene-graph').initUi $('#sceneGraphContainer')
		return

	_initHotkeys: =>
		@hotkeys = new Hotkeys(@pluginHooks)
		@hotkeys.addEvents @selection.getHotkeys()

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

	_initDownload: () =>
		@toolbar.addDownloadListener () =>
			selNode = @selection.selectedNode
			if selNode?
				dl = @bundle.downloadProvider.createDownload selNode
				#ToDo: offer dl as a download (zip file)

	_toggleGridVisibility: () =>
		@bundle.getPlugin('lego-board').toggleVisibility()
		@bundle.getPlugin('coordinate-system').toggleVisibility()
