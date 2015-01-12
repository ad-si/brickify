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
		@modelLoader = new ModelLoader(@statesync, @pluginHooks, @globalConfig)

		@renderer = new Renderer(@pluginHooks, @globalConfig)

		if(@globalConfig.buildUi)
			@ui = new Ui(@)
			@ui.init()
			@pluginUiGenerator = new PluginUiGenerator(@)

	init: =>
		@statesync.init().then(() =>
			@pluginInstances = @pluginLoader.loadPlugins()
			@statesync.handleUpdatedState()
		)
