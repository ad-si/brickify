PluginLoader = require '../client/pluginLoader'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'
PluginUiGenerator = require './pluginUiGenerator'

module.exports = class Bundle
	constructor: (@globalConfig, syncStateWithServer = true) ->
		@pluginLoader = new PluginLoader(@)
		@pluginHooks = @pluginLoader.pluginHooks

		@statesync = new Statesync(@, syncStateWithServer)
		@modelLoader = new ModelLoader(@statesync, @pluginHooks)

		@renderer = new Renderer(@pluginHooks)
		@ui = new Ui(@)
		@ui.init()
		@pluginUiGenerator = new PluginUiGenerator(@)

	init: =>
		@statesync.init (state) =>
			@pluginInstances = @pluginLoader.loadPlugins()
			@statesync.handleUpdatedState()
