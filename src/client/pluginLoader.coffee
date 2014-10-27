pluginInstances = []
stateSyncModule = null

#since browserify.js does not support dynamic require, all plugins must be written down
module.exports.loadPlugins = (stateSync) ->
	dummyPlugin = require './plugins/dummyClientPlugin'
	loadPlugin stateSync, dummyPlugin

loadPlugin = (stateSync, instance) ->
	stateSyncModule = stateSync

	if checkForPluginMethods instance
		pluginInstances.push instance
		initPluginInstance instance
		console.log 'Plugin "' + instance.pluginName + '" loaded'
	else
		console.log 'Plugin "' + plugin + '" does not contain all necessary methods, will not be loaded'

checkForPluginMethods = (object) ->
	hasAllMethods = true;
	hasAllMethods = object.hasOwnProperty('pluginName') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('init') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('handleStateChange') and hasAllMethods
	return hasAllMethods

initPluginInstance = (pluginInstance) ->
	pluginInstance.init();
	stateSyncModule.addUpdateCallback pluginInstance.handleStateChange