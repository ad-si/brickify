###
# @module pluginLoader
###

# Load the hook list and initialize the pluginHook management
hooks = require('./pluginHooks.yaml')
pluginHooks = require('../common/pluginHooks')
pluginHooks.initHooks(hooks)
renderer = require './renderer'

globalConfigInstance = null

initPluginInstance = (instance) ->
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

loadPlugin = (instance) ->
	initPluginInstance instance

module.exports.init = (globalConfig) ->
	globalConfigInstance = globalConfig


# Since browserify.js does not support dynamic require
# all plugins must be explicitly written down
module.exports.loadPlugins = () ->
	loadPlugin require './plugins/dummy/dummy'
	loadPlugin require './plugins/coordinateSystem/coordinateSystem'
	loadPlugin require './plugins/stlImport/stlImport'
	loadPlugin require './plugins/stlExport/stlExport'
	loadPlugin require './plugins/sceneGraph/sceneGraph'
