###
# @module pluginLoader
###

# Load the hook list and initialize the pluginHook management
path = require 'path'
THREE = require 'three'
hooks = require './pluginHooks.yaml'
PluginHooks = require '../common/pluginHooks'

module.exports = class PluginLoader
	constructor: (@bundle) ->
		@pluginHooks = new PluginHooks()
		@pluginHooks.initHooks(hooks)
		@globalConfig = @bundle.globalConfig

	_loadPlugin: (PluginClass, packageData) ->
		instance = new PluginClass()

		for own key, value of packageData
			instance[key] = value

		return instance

	_initPlugin: (instance) ->
		if @pluginHooks.hasHook(instance, 'init')
			instance.init @bundle

		if @pluginHooks.hasHook(instance, 'init3d')
			threeNode = new THREE.Object3D()
			threeNode.associatedPlugin = instance
			instance.init3d threeNode

		@pluginHooks.register instance

		if threeNode?
			@bundle.renderer.addToScene threeNode

	initPlugins: =>
		for plugin in @pluginInstances
			@_initPlugin plugin

	# Since browserify.js does not support dynamic require
	# all plugins must be explicitly written down
	loadPlugins: ->
		@pluginInstances = []

		if @globalConfig.plugins.dummy
			@pluginInstances.push @_loadPlugin(
				require '../plugins/dummy'
				require '../plugins/dummy/package.json'
			)
		if @globalConfig.plugins.coordinateSystem
			@pluginInstances.push @_loadPlugin(
				require '../plugins/coordinateSystem'
				require '../plugins/coordinateSystem/package.json'
			)
		if @globalConfig.plugins.nodeVisualizer
			@pluginInstances.push @_loadPlugin(
				require '../plugins/nodeVisualizer'
				require '../plugins/nodeVisualizer/package.json'
			)
		if @globalConfig.plugins.legoBoard
			@pluginInstances.push @_loadPlugin(
				require '../plugins/legoBoard'
				require '../plugins/legoBoard/package.json'
			)
		if @globalConfig.plugins.newBrickator
			@pluginInstances.push @_loadPlugin(
				require '../plugins/newBrickator'
				require '../plugins/newBrickator/package.json'
			)
		if @globalConfig.plugins.fidelityControl
			@pluginInstances.push @_loadPlugin(
				require '../plugins/fidelityControl'
				require '../plugins/fidelityControl/package.json'
			)
		if @globalConfig.plugins.editController
			@pluginInstances.push @_loadPlugin(
				require '../plugins/editController'
				require '../plugins/editController/package.json'
			)
		if @globalConfig.plugins.csg
			@pluginInstances.push @_loadPlugin(
				require '../plugins/csg'
				require '../plugins/csg/package.json'
			)
		if @globalConfig.plugins.legoInstructions
			@pluginInstances.push @_loadPlugin(
				require '../plugins/legoInstructions'
				require '../plugins/legoInstructions/package.json'
			)

		return @pluginInstances
