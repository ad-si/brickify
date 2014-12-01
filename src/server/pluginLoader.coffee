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
hooks = yaml.load(
		fs.readFileSync path.join(__dirname, './pluginHooks.yaml'), 'utf8'
	)
pluginHooks = require '../common/pluginHooks'
pluginHooks.initHooks(hooks)

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

		pluginMain = path.join entry.fullPath, entry.name

		try
			instance = require pluginMain
		catch error
			log.error "Plugin #{pluginMain} could not be found.
				Maybe the plugin's filename does not match its folder name?"
			return

		initPluginInstance instance
		log.info "Plugin #{pluginMain} loaded"

initPluginInstance = (pluginInstance) ->
	pluginInstance.init?()
	pluginHooks.register pluginInstance
