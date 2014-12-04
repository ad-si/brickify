PluginLoader = require '../client/pluginLoader'
objectTree = require '../common/objectTree'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'

module.exports = class Bundle
	constructor: (@globalConfig) ->
		return
	postInitCallback: (callback) ->
		@postInitCb = callback
	init: (createRendererAndUi, syncStateWithServer = true) ->
		self = @
		@pluginLoader = new PluginLoader(@globalConfig)
		@stateInstance = new Statesync(@pluginLoader.pluginHooks,
			syncStateWithServer)

		@stateInstance.init @globalConfig, (state) ->
			objectTree.init state
			if createRendererAndUi
				self.renderer = new Renderer(self.pluginLoader.pluginHooks)
				self.uiInstance = new Ui(self.globalConfig, self.renderer,
					self.stateInstance, self.pluginLoader.pluginHooks)
				self.uiInstance.init()
				self.pluginInstances = self.pluginLoader.loadPlugins(self.renderer)
			else
				self.pluginInstances = self.pluginLoader.loadPlugins()

			self.postInitCb? state


