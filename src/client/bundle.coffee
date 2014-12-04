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

		self = @
		@stateInstance.init @globalConfig, (state) ->
			objectTree.init state
			if createRendererAndUi
				self.renderer = new Renderer(self.pluginLoader.pluginHooks)
				self.uiInstance = new Ui(self.globalConfig, self.renderer,
					self.stateInstance, self.modelLoader)
				self.uiInstance.init()
				self.pluginInstances = self.pluginLoader.loadPlugins(self.renderer)
			else
				self.pluginInstances = self.pluginLoader.loadPlugins()

			self.postInitCb? state


