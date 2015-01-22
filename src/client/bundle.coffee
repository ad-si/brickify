PluginLoader = require '../client/pluginLoader'
Ui = require './ui'
Renderer = require './renderer'
Statesync = require './statesync'
ModelLoader = require './modelLoader'

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

	init: =>
		@statesync.init().then(() =>
			@pluginInstances = @pluginLoader.loadPlugins()
			@ui = new Ui(@) if(@globalConfig.buildUi)
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

	getPlugins: (type) =>
		@pluginInstances.filter (instance) -> instance.lowfab.type == type
