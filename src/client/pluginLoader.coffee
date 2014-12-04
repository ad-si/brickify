###
# @module pluginLoader
###

# Load the hook list and initialize the pluginHook management
path = require 'path'
hooks = require('./pluginHooks.yaml')
pluginHooks = require('../common/pluginHooks')
pluginHooks.initHooks(hooks)
renderer = require './renderer'

globalConfigInstance = null

initPlugin = (instance, packageData) ->
	for own key,value of packageData
		instance[key] = value

	instance.init? globalConfigInstance
	instance.init3d? threeNode = new THREE.Object3D()
	instance.initUi? {
		menuBar: document.getElementById('navbarToggle')
		toolsContainer: document.getElementById('toolsContainer')
		sceneGraphContainer: document.getElementById('sceneGraphContainer')
	}

	pluginHooks.register instance

	if threeNode?
		renderer.addToScene threeNode


module.exports.init = (globalConfig) ->
	globalConfigInstance = globalConfig

# Since browserify.js does not support dynamic require
# all plugins must be explicitly written down
module.exports.loadPlugins = () ->
	initPlugin(
		require('./plugins/dummy'),
		require('./plugins/dummy/package.json')
	)
	initPlugin(
		require('./plugins/coordinateSystem'),
		require('./plugins/coordinateSystem/package.json')
	)
	initPlugin(
		require('./plugins/solidRenderer'),
		require('./plugins/solidRenderer/package.json')
	)
	initPlugin(
		require('./plugins/stlImport'),
		require('./plugins/stlImport/package.json')
	)
	initPlugin(
		require('./plugins/stlExport'),
		require('./plugins/stlExport/package.json')
	)
	initPlugin(
		require('./plugins/sceneGraph'),
		require('./plugins/sceneGraph/package.json')
	)
	initPlugin(
		require('./plugins/voxeliser'),
		require('./plugins/voxeliser/package.json')
	)
