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

		@pluginHooks.register instance

		if threeNode?
			@bundle.renderer.addToScene threeNode

		return instance

	# Since browserify.js does not support dynamic require
	# all plugins must be explicitly written down
	loadPlugins: () ->
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
			require('../plugins/stlExport'),
			require('../plugins/stlExport/package.json')
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
		pluginInstances.push @initPlugin(
			require('../plugins/3dPrint'),
			require('../plugins/3dPrint/package.json')
		)
		pluginInstances.push @initPlugin(
			require('../plugins/legoBoard'),
			require('../plugins/legoBoard/package.json')
		)
		return pluginInstances
