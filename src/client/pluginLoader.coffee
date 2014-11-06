pluginInstances = []
stateSyncModule = null
uiInstance = null
globalConfigInstance = null
rendererInstance  = null

module.exports.init = (neededInstances) ->
	stateSyncModule = neededInstances.statesync
	globalConfigInstance = neededInstances.config
	uiInstance = neededInstances.ui
	rendererInstance = neededInstances.renderer

# since browserify.js does not support dynamic require
# all plugins must be written down
module.exports.loadPlugins = () ->
	coordinateSystem = require './plugins/coordinateSystem/coordinateSystem'
	dummyPlugin = require './plugins/dummy/dummy'
	stlImport = require './plugins/stlImport/stlImport'

	loadPlugin coordinateSystem
	loadPlugin dummyPlugin
	loadPlugin stlImport

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
			console.log 'Plugin ? (name missing) does not contain all neccessary
				methods, will not be loaded'

checkForPluginMethods = (object) ->
	hasAllMethods = true
	hasAllMethods = object.hasOwnProperty('pluginName') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('init') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('handleStateChange') and hasAllMethods
	return hasAllMethods

initPluginInstance = (pluginInstance) ->
	pluginInstance.init globalConfigInstance, stateSyncModule, uiInstance

	threeNode = new THREE.Object3D()
	uiInstance.scene.add threeNode
	pluginInstance.init3d threeNode

	if pluginInstance.needs3dAnimation == true
		rendererInstance.addToRenderQueue pluginInstance

	stateSyncModule.addUpdateCallback pluginInstance.handleStateChange
