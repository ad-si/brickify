PluginLoader = require '../client/pluginLoader'
objectTree = require '../common/objectTree'
Ui = require './ui'
Renderer = require './renderer'

class Bundle
	constructor: (@stateInstance, @globalConfig,
								createRendererAndUi = false) ->
		@stateInstance.init @globalConfigInstance, (state) ->
			objectTree.init state
			@pluginLoader = new PluginLoader(@globalConfigInstance)

			if createRendererAndUi
				@renderer = new Renderer(@pluginLoader.pluginHooks)
				@uiInstance = new Ui(@globalConfig, @renderer, @stateInstance)
				@uiInstance.init()
				@pluginInstances = @pluginLoader.loadPlugins(@renderer)
			else
				@pluginInstances = @pluginLoader.loadPlugins()


