pluginInstances = []
stateSyncModule = null
uiInstance = null
globalConfigInstance = null

# since browserify.js does not support dynamic require
# all plugins must be written down
module.exports.loadPlugins = (ui, globalConfig, stateSync) ->
	uiInstance = ui
	stateSyncModule = stateSync
	globalConfigInstance = globalConfig

	dummyPlugin = require './plugins/dummyClientPlugin'
	stlImport = require './plugins/stlImportPlugin'

	loadPlugin dummyPlugin
	loadPlugin stlImport

loadPlugin = (instance) ->
	if checkForPluginMethods instance
		pluginInstances.push instance
		initPluginInstance instance
		console.log "Plugin #{instance.pluginName} loaded"
	else
		console.log 'Plugin #{plugin} does not contain all
				necessary methods, will not be loaded'

checkForPluginMethods = (object) ->
	hasAllMethods = true
	hasAllMethods = object.hasOwnProperty('pluginName') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('init') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('handleStateChange') and hasAllMethods
	return hasAllMethods

initPluginInstance = (pluginInstance) ->
	pluginInstance.init uiInstance, globalConfigInstance, stateSyncModule
	stateSyncModule.addUpdateCallback pluginInstance.handleStateChange
