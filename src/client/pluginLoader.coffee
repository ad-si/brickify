###
# @module pluginLoader
###

# Load the hook list and initialize the pluginHook management
hooks = require('./pluginHooks.yaml')
pluginHooks = require('../common/pluginHooks')
pluginHooks.initHooks(hooks)
renderer = require './renderer'

pluginInstances = []
stateSyncModule = null
uiInstance = null
globalConfigInstance = null

checkForPluginMethods = (instance) ->
	instance.hasOwnProperty('pluginName')

initPluginInstance = (instance) ->
	instance.init? globalConfigInstance, stateSyncModule, uiInstance
	instance.init3D? threeNode = new THREE.Object3D()

	pluginHooks.register instance

	if threeNode?
		renderer.addToScene threeNode

loadPlugin = (instance) ->
	if checkForPluginMethods instance
		pluginInstances.push instance
		initPluginInstance instance
		console.log "Plugin #{instance.pluginName} loaded"
	else
		if instance.pluginName?
			console.log "Plugin #{instance.pluginName} does not contain all
					necessary methods, will not be loaded"
		else
			console.log 'Plugin ? (name missing) does not contain all necessary
				methods, will not be loaded'

module.exports.init = (neededInstances) ->
	stateSyncModule = neededInstances.statesync
	globalConfigInstance = neededInstances.config
	uiInstance = neededInstances.ui

# Since browserify.js does not support dynamic require
# all plugins must be written down
module.exports.loadPlugins = () ->
	coordinateSystem = require './plugins/coordinateSystem/coordinateSystem'
	dummyPlugin = require './plugins/dummy/dummy'
	stlImport = require './plugins/stlImport/stlImport'
	stlExport = require './plugins/stlExport/stlExport'

	loadPlugin coordinateSystem
	loadPlugin dummyPlugin
	loadPlugin stlImport
	loadPlugin stlExport
