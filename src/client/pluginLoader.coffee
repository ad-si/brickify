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

	initPlugin: (PluginClass, packageData) ->
		instance = new PluginClass()

		for own key,value of packageData
			instance[key] = value

		if @pluginHooks.hasHook(instance, 'init')
			instance.init @bundle

		if @pluginHooks.hasHook(instance, 'init3d')
			threeNode = new THREE.Object3D()
			instance.init3d threeNode

		if @globalConfig.buildUi and @pluginHooks.hasHook(instance, 'initUi')
			instance.initUi {
				menuBar: document.getElementById 'navbarToggle'
				toolsContainer: document.getElementById 'toolsContainer'
				sceneGraphContainer: document.getElementById(
					'sceneGraphContainer'
				)
			}

		if @pluginHooks.hasHook(instance, 'getUiSchema')
			if @bundle.pluginUiGenerator?
				@bundle.pluginUiGenerator.createPluginUi instance

		@pluginHooks.register instance

		if threeNode?
			@bundle.renderer.addToScene threeNode

		if @hotkeys? and @pluginHooks.hasHook(instance, 'getHotkeys')
			@hotkeys.addEvent(instance.getHotkeys())

		return instance

	# Since browserify.js does not support dynamic require
	# all plugins must be explicitly written down
	loadPlugins: (@hotkeys) ->
		pluginInstances = []

		###pluginInstances.push @initPlugin(
			require('../plugins/dummy'),
			require('../plugins/dummy/package.json')
		)
		pluginInstances.push @initPlugin(
			require('../plugins/example'),
			require('../plugins/example/package.json')
		)###
		pluginInstances.push @initPlugin(
			require('../plugins/coordinateSystem'),
			require('../plugins/coordinateSystem/package.json')
		)
		pluginInstances.push @initPlugin(
			require('../plugins/solidRenderer'),
			require('../plugins/solidRenderer/package.json')
		)
		pluginInstances.push @initPlugin(
			require('../plugins/stlImport'),
			require('../plugins/stlImport/package.json')
		)
		pluginInstances.push @initPlugin(
			require('../plugins/sceneGraph'),
			require('../plugins/sceneGraph/package.json')
		)
		pluginInstances.push @initPlugin(
			require('../plugins/faBrickator'),
			require('../plugins/faBrickator/package.json')
		)
		pluginInstances.push @initPlugin(
			require('../plugins/newBrickator'),
			require('../plugins/newBrickator/package.json')
		)

		return pluginInstances
