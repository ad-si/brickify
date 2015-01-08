PluginLoader = require '../client/pluginLoader'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'
PluginUiGenerator = require './pluginUiGenerator'

###
# @class Bundle
###
module.exports = class Bundle
	constructor: (@globalConfig, syncStateWithServer = true) ->
		@pluginLoader = new PluginLoader(@)
		@pluginHooks = @pluginLoader.pluginHooks

		@statesync = new Statesync(@, syncStateWithServer)
		@modelLoader = new ModelLoader(@statesync, @pluginHooks)

		@renderer = new Renderer(@pluginHooks)
		@ui = new Ui(@)
		@ui.init()
		@pluginUiGenerator = new PluginUiGenerator(@)

	init: =>
		@statesync.init().then(() =>
			@pluginInstances = @pluginLoader.loadPlugins()
			@statesync.handleUpdatedState()
		).then(@load).then(() =>
			window.addEventListener 'beforeunload', @unload
		)

	load: =>
		@statesync.performStateAction @renderer.loadCamera

	unload: =>
		@statesync.performStateAction @renderer.saveCamera
