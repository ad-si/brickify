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
		if(entry.stat.isFile())
			pluginMain = entry.fullPath
		else if(entry.stat.isDirectory())
			pluginMain = path.join entry.fullPath, entry.name + '.js'
		try
			instance = require pluginMain
		catch error
			log.error "Plugin #{pluginMain} could not be found. Maybe the plugin's
				main filename does not match its folder name?"
			return
		if checkForPluginMethods instance
			pluginInstances.push instance
			initPluginInstance instance
			log.info "Plugin '#{instance.pluginName}' (#{pluginMain}) loaded"
		else
			if instance.pluginName?
				console.log "Plugin '#{instance.pluginName}' (#{pluginMain}) does not
									contain all necessary methods, will not be loaded"
			else
				console.log 'Plugin ? (name missing) (#{pluginMain}) does not contain
								all necessary methods, will not be loaded'

checkForPluginMethods = (object) ->
	object.hasOwnProperty('pluginName')

initPluginInstance = (pluginInstance) ->
	pluginInstance.init?()
	pluginHooks.register pluginInstance
