PluginLoader = require '../client/pluginLoader'
objectTree = require '../common/objectTree'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'
PluginUiGenerator = require './pluginUiGenerator'

module.exports = class Bundle
	constructor: (@globalConfig, syncStateWithServer = true) ->
		@pluginLoader = new PluginLoader(@)
		pluginHooks = @pluginLoader.pluginHooks

		@statesync = new Statesync(pluginHooks, syncStateWithServer)
		@modelLoader = new ModelLoader(@statesync, pluginHooks)

		@renderer = new Renderer(pluginHooks)
		@ui = new Ui(@globalConfig, @renderer, @statesync, @modelLoader)
		@ui.init()
		@pluginUiGenerator = new PluginUiGenerator(@)

	init: =>
		@statesync.init @globalConfig, (state) =>
			objectTree.init state
			@pluginInstances = @pluginLoader.loadPlugins()
