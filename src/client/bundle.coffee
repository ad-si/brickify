PluginLoader = require '../client/pluginLoader'
objectTree = require '../common/objectTree'
Ui = require './ui'
Renderer = require './renderer'

module.exports = class Bundle
	constructor: (@stateInstance, @globalConfig) ->
		return
	postInitCallback: (callback) ->
		@postInitCb = callback
	init: (createRendererAndUi) ->
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

			@postInitCb? state


