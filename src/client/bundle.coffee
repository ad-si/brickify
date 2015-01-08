PluginLoader = require '../client/pluginLoader'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'
PluginUiGenerator = require './pluginUiGenerator'

###
# @class Bundle
###
module.exports = class Bundle
	constructor: (@globalConfig) ->
		@pluginLoader = new PluginLoader(@)
		@pluginHooks = @pluginLoader.pluginHooks

		@statesync = new Statesync(@)
		@modelLoader = new ModelLoader(@statesync, @pluginHooks)

		@renderer = new Renderer(@pluginHooks, @globalConfig)

		if(@globalConfig.buildUi)
			@ui = new Ui(@)
			@ui.init()
			@pluginUiGenerator = new PluginUiGenerator(@)

	init: =>
		@statesync.init().then(() =>
			@pluginInstances = @pluginLoader.loadPlugins()
			@statesync.handleUpdatedState()
		).then(@load).then(() =>
			window.addEventListener 'beforeunload', @unload
		)

	load: =>
		@statesync.performStateAction @renderer.loadCamera

	onStateUpdate: (state) =>
		@renderer.onStateUpdate state

	unload: =>
		@statesync.performStateAction @renderer.saveCamera
