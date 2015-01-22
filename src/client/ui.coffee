###
# @module ui
###

module.exports = class Ui
	constructor: (bundle) ->
		@globalConfig = bundle.globalConfig
		@renderer = bundle.renderer
		@statesync = bundle.statesync
		@modelLoader = bundle.modelLoader
		@pluginHooks = bundle.pluginHooks

	dropHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		files = event.target.files ? event.dataTransfer.files
		@modelLoader.readFiles files if files?

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

	init: =>
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
