PluginLoader = require '../client/pluginLoader'
Ui = require './ui/ui'
Renderer = require './renderer'
ModelLoader = require './modelLoader'
SceneManager = require './sceneManager'

SyncObject = require '../common/sync/syncObject'
SyncObject.dataPacketProvider = require './sync/dataPackets'
Node = require '../common/project/node'
Node.modelProvider = require './modelCache'

###
# @class Bundle
###
module.exports = class Bundle
	constructor: (@globalConfig, @controls) ->
		@pluginLoader = new PluginLoader(@)
		@pluginHooks = @pluginLoader.pluginHooks
		@modelLoader = new ModelLoader(@)
		@sceneManager = new SceneManager(@)
		@renderer = new Renderer(@pluginHooks, @globalConfig)
		@pluginInstances = @pluginLoader.loadPlugins()
		@ui = new Ui(@) if @globalConfig.buildUi

	init: =>
		@ui?.init()
		@renderer.setupControls @globalConfig, @controls
		return @sceneManager.init()

	getPlugin: (name) =>
		for p in @pluginInstances
			return p if p.name == name
		return null

	getPlugins: (type) =>
		return @pluginInstances.filter (instance) -> instance.lowfab.type == type

	getControls: =>
		@renderer.getControls()
