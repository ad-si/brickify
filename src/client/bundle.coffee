PluginLoader = require '../client/pluginLoader'
Ui = require './ui/ui'
Renderer = require './renderer'
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
		@pluginInstances = @pluginLoader.loadPlugins()
		@pluginHooks = @pluginLoader.pluginHooks

		@modelLoader = new ModelLoader(@)
		@sceneManager = new SceneManager(@)
		@renderer = new Renderer(@pluginHooks, @globalConfig)
		@ui = new Ui(@) if @globalConfig.buildUi

	init: =>
		@ui?.init()
		@pluginLoader.initPlugins()
		@renderer.setupControls @globalConfig, @controls
		return @sceneManager
		.init()
		.then =>
			Spinner.stop document.getElementById @globalConfig.renderAreaId
			return @

	getPlugin: (name) =>
		for p in @pluginInstances
			return p if p.name == name
		return null

	getControls: =>
		@renderer.getControls()
