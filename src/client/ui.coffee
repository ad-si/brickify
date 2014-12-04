###
# @module ui
###

statesync = require './statesync'
objectTree = require '../common/objectTree'
ModelLoader = require './modelLoader'

module.exports = class Ui
	constructor: (globalConfigInstance, rendererInstance,
								statesyncInstance, pluginHooks) ->
		@globalConfig = globalConfigInstance
		@renderer = rendererInstance
		@statesync = statesyncInstance
		@modelLoader = new ModelLoader(statesyncInstance, pluginHooks)
	dropHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		files = event.target.files ? event.dataTransfer.files
		@modelLoader.readFiles files if files?

	dragOverHandler: (event) ->
		event.stopPropagation()
		event.preventDefault()
		event.dataTransfer.dropEffect = 'copy'

	# Bound to updates to the window size:
	# Called whenever the window is resized.
	windowResizeHandler: (event) ->
		@renderer.windowResizeHandler()

	init: ->
		@renderer.init(@globalConfig)

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

