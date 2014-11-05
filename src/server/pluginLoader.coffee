# File system support
fs = require 'fs'
# Manipulate platform-independent path strings
path = require 'path'
# Recursively process folders and files
readdirp = require 'readdirp'
# Server-side plugins
pluginInstances = []
stateSyncModule = null
# Colorful logger for console
winston = require 'winston'
log = winston.loggers.get('log')

String.prototype.endsWith = (suffix) ->
	return this.indexOf(suffix, this.length - suffix.length) != -1

module.exports.loadPlugins = (stateSync, directory) ->
	stateSyncModule = stateSync
	readdirp root: directory, depth: 0, fileFilter: '*.js', entryType: 'both'
	.on 'data', (entry) -> loadPlugin entry
	.on 'error', (error) -> log.error error
	.on 'warn', (warning) -> log.warn warning
	.on 'end', () -> afterCompileCallback(directory) if afterCompileCallback?

loadPlugin = (entry) ->
		if(entry.stat.isFile())
			pluginMain = entry.fullPath
		else if(entry.stat.isDirectory())
			pluginMain = path.join entry.fullPath, entry.name + '.js'

		instance = require pluginMain
		if checkForPluginMethods instance
			pluginInstances.push instance
			initPluginInstance instance
			log.info "Plugin '#{instance.pluginName}' (#{pluginMain}) loaded"
		else
			log.warn "Plugin '#{entry.name}' (#{pluginMain}) does not contain
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
