PluginLoader = require '../client/pluginLoader'
objectTree = require '../common/objectTree'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'

module.exports = class Bundle
	constructor: (@globalConfig) ->
		return

	init: (createRendererAndUi, syncStateWithServer = true) =>
		@pluginLoader = new PluginLoader(@)
		pluginHooks = @pluginLoader.pluginHooks

		@statesync = new Statesync(pluginHooks, syncStateWithServer)
		@modelLoader = new ModelLoader(@statesync, pluginHooks)

		@statesync.init @globalConfig, (state) =>
			objectTree.init state
			if createRendererAndUi
				@renderer = new Renderer(pluginHooks)
				@ui = new Ui(@globalConfig, @renderer, @statesync, @modelLoader)
				@ui.init()
				@pluginInstances = @pluginLoader.loadPlugins(@renderer)
			else
				@pluginInstances = @pluginLoader.loadPlugins()
