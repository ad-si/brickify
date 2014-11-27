###
# @module pluginLoader
###

# Load the hook list and initialize the pluginHook management
hooks = require('./pluginHooks.yaml')
pluginHooks = require('../common/pluginHooks')
pluginHooks.initHooks(hooks)
renderer = require './renderer'

pluginInstances = []
globalConfigInstance = null

checkForPluginMethods = (instance) ->
	instance.hasOwnProperty('pluginName')

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
	if checkForPluginMethods instance
		pluginInstances.push instance
		initPluginInstance instance
		console.log "Plugin #{instance.pluginName} loaded"

	else
		console.warn "Plugin #{instance.pluginName?} does not contain all
				necessary methods, will not be loaded"

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
