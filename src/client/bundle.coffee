PluginLoader = require '../client/pluginLoader'
objectTree = require '../common/objectTree'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'

module.exports = class Bundle
	constructor: (@globalConfig) ->
		return
	postInitCallback: (callback) ->
		@postInitCb = callback
	init: (createRendererAndUi, syncStateWithServer = true) ->
		@pluginLoader = new PluginLoader(@globalConfig)
		@stateInstance = new Statesync(@pluginLoader.pluginHooks,
			syncStateWithServer)
		@modelLoader = new ModelLoader(@stateInstance, @pluginLoader.pluginHooks)

		@stateInstance.init @globalConfig, (state) =>
			objectTree.init state
			if createRendererAndUi
				@renderer = new Renderer(@pluginLoader.pluginHooks)
				@uiInstance = new Ui(@globalConfig, @renderer,
					@stateInstance, @modelLoader)
				@uiInstance.init()
				@pluginInstances = @pluginLoader.loadPlugins(@renderer)
			else
				@pluginInstances = @pluginLoader.loadPlugins()

			@postInitCb? state


