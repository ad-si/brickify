PluginLoader = require '../client/pluginLoader'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'
PluginUiGenerator = require './pluginUiGenerator'
Hotkeys = require './Hotkeys'

###
# @class Bundle
###
module.exports = class Bundle
	constructor: (@globalConfig) ->
		@pluginLoader = new PluginLoader(@)
		@pluginHooks = @pluginLoader.pluginHooks

		@statesync = new Statesync(@)
		@modelLoader = new ModelLoader(@statesync, @pluginHooks, @globalConfig)

		@renderer = new Renderer(@pluginHooks, @globalConfig)

		if(@globalConfig.buildUi)
			@hotkeys = new Hotkeys()
			@ui = new Ui(@)
			@ui.init()
			@pluginUiGenerator = new PluginUiGenerator(@)

	init: =>
		@statesync.init().then(() =>
			@pluginInstances = @pluginLoader.loadPlugins(@hotkeys)
			@statesync.handleUpdatedState()
		).then(@load).then(() =>
			window.addEventListener 'beforeunload', @unload
		)

	load: =>
		@statesync.performStateAction @renderer.loadCamera

	onStateUpdate: (state) =>
		@renderer.onStateUpdate state

	unload: =>
		@saveChanges()

	saveChanges: =>
		@statesync.performStateAction @renderer.saveCamera

	getPlugin: (name) =>
		for p in @pluginInstances
			if p.name == name
				return p
		return null
