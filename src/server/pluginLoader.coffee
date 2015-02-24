# File system support
fs = require 'fs'
# Manipulate platform-independent path strings
path = require 'path'
# Colorful logger for console
winston = require 'winston'
log = winston.loggers.get('log')
# Load the hook list and initialize the pluginHook management
yaml = require 'js-yaml'

PluginHooks = require '../common/pluginHooks'
pluginHooks = new PluginHooks()
module.exports.pluginHooksInstance = pluginHooks

hooks = yaml.load fs.readFileSync path.join __dirname, 'pluginHooks.yaml'
pluginHooks.initHooks(hooks)

initPluginInstance = (pluginInstance) ->
	pluginInstance.init?()
	pluginHooks.register pluginInstance

loadPlugin = (directory) ->
	try
		instance = require directory

	catch error
		if error.code != 'MODULE_NOT_FOUND'
			throw error
		return

	for own key,value of require path.join directory, 'package.json'
		instance[key] = value

	initPluginInstance instance
	log.info "Plugin #{instance.name} loaded"


module.exports.loadPlugins = (directory) ->
	fs.readdir directory, (error, dirs) ->
		if error
			throw error
		dirs.forEach (dir) ->
			loadPlugin path.resolve(__dirname, '../plugins/' + dir)
