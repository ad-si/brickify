PluginLoader = require '../client/pluginLoader'
Ui = require './ui/ui'
Renderer = require './rendering/Renderer'
ModelLoader = require './modelLoading/modelLoader'
SceneManager = require './sceneManager'
Spinner = require './Spinner'

SyncObject = require '../common/sync/syncObject'
SyncObject.dataPacketProvider = require './sync/dataPackets'
Node = require '../common/project/node'
Node.modelProvider = require './modelLoading/modelCache'

###
# @class Bundle
###
module.exports = class Bundle
	constructor: (@globalConfig, @controls) ->
		Spinner.startOverlay document.getElementById @globalConfig.renderAreaId
		@pluginLoader = new PluginLoader(@)
		@pluginHooks = @pluginLoader.pluginHooks
		@modelLoader = new ModelLoader(@)
		@sceneManager = new SceneManager(@)
		@renderer = new Renderer(@pluginHooks, @globalConfig)
		@pluginInstances = @pluginLoader.loadPlugins()
		@ui = new Ui(@) if @globalConfig.buildUi

	init: =>
		@pluginLoader.initPlugins()
		@ui?.init()
		@renderer.setupControls @globalConfig, @controls
		return @sceneManager.init()
		.then => Spinner.stop document.getElementById @globalConfig.renderAreaId

	getPlugin: (name) =>
		for p in @pluginInstances
			return p if p.name == name
		return null

	getControls: =>
		@renderer.getControls()
