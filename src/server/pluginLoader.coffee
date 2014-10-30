fs = require 'fs'
pluginInstances = []
stateSyncModule = null
winston = require 'winston'
log = winston.loggers.get('log')

module.exports.loadPlugins = (stateSync, directory) ->
	stateSyncModule = stateSync

	files = fs.readdirSync directory
	for file in files
		instance = require (directory + file)
		if checkForPluginMethods instance
			pluginInstances.push instance
			initPluginInstance instance
			log.info "Plugin '#{instance.pluginName}' (#{file}) loaded"
		else
			log.warn "Plugin '#{file}' does not contain
							all necessary methods and will not be loaded"

checkForPluginMethods = (object) ->
	hasAllMethods = true
	hasAllMethods = object.hasOwnProperty('pluginName') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('init') and hasAllMethods
	hasAllMethods = object.hasOwnProperty('handleStateChange') and hasAllMethods
	return hasAllMethods

initPluginInstance = (pluginInstance) ->
	pluginInstance.init()
	stateSyncModule.addUpdateCallback pluginInstance.handleStateChange
