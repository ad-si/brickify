# File system support
fs = require 'fs'
# Manipulate platform-independent path strings
path = require 'path'
# Recursively process folders and files
readdirp = require 'readdirp'
# Server-side plugins
stateSyncModule = null
# Colorful logger for console
winston = require 'winston'
log = winston.loggers.get('log')
# Load the hook list and initialize the pluginHook management
yaml = require 'js-yaml'
pluginHooks = require '../common/pluginHooks'
hooks = yaml.load fs.readFileSync path.join __dirname, 'pluginHooks.yaml'


initPluginInstance = (pluginInstance) ->
	pluginInstance.init?()
	pluginHooks.register pluginInstance

loadPlugin = (entry) ->
	try
		instance = require entry.fullPath

	catch error
		log.error "Plugin #{pluginMain} could not be found.
				Maybe the plugin's filename does not match its folder name?"
		return

	for own key,value of require path.join entry.fullPath, 'package.json'
		instance[key] = value

	initPluginInstance instance
	log.info "Plugin #{instance.name} loaded"


module.exports.loadPlugins = (stateSync, directory) ->
	stateSyncModule = stateSync
	readdirp(
		root: directory,
		depth: 0,
		entryType: 'directories'
	)
	.on 'data', (entry) -> loadPlugin entry
	.on 'error', (error) -> log.error error
	.on 'warn', (warning) -> log.warn warning


pluginHooks.initHooks(hooks)
