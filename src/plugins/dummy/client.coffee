###
# Dummy Plugin
###

###
# A demo plugin implementation for client-side
#
# We encourage plugin developers to split their plugins in several modules.
# The main file referenced in the module's `package.json`
# will be loaded by the lowfab framework.
#
# This file must return a class which provides **hook-properties** and
# **hook-methods** that specify the interaction between the lowfab framework
# and the plugin.
# E.g. `dummyPlugin.pluginName` or `dummyPlugin.on3dUpdate()`.#
#
# @module dummyClientPlugin
###

module.exports = class DummyPlugin
	###
	# The plugin loader will call each plugin's `init` method (if provided) after
	# loading the plugin.
	#
	# It is the first method to be called and provides access to the global
	# configuration.
	#
	# @param {Object} globalConfig A key=>value-mapping of the global configuration
	# @memberOf dummyClientPlugin
	# @see pluginLoader
	###
	init: (bundle) ->
		console.log 'Dummy Client Plugin initialization'

	###
	# Each plugin that provides a `init3d` method is able to initialize its 3D
	# rendering there and receives a three.js node as argument.
	#
	# If the plugin needs its node for later use it has to store it in `init3d`
	# because it won't be handed the node again later.
	#
	# @param {ThreeJsNode} threejsNode the plugin's node in the 3D-scenegraph
	# @memberOf dummyClientPlugin
	# @see pluginLoader
	###
	init3d: (threejsNode) =>
		console.log 'Dummy Client Plugin initializes 3d'

	###
	# Provides the plugins the possibility to add elements to the UI.
	# Receives several DOM elements to insert itself into.
	#
	# @param {Object} domElements an object of DOM elements to insert itself into
	# @memberOf dummyClientPlugin
	# @see pluginLoader
	###
	initUi: (domElements) =>
		console.log 'Dummy Client Plugin initializes UI'

	###
	# Returns a json-schema which describes the json
	# the ui-elements of the plugin are supposed to create.
	# [json-editor](https://github.com/jdorn/json-editor) then creates the
	# html elements accordingly.
	###
	getUiSchema: () =>
		console.log('Dummy Client Plugin returns the UI schema.')

		console.log('Example Plugin returns the UI schema.')

		actioncallback = () ->
			console.log 'Dummy Plugin performs an action!'

		return {
		title: 'Dummy Plugin'
		type: 'object'
		properties:
			size:
				description: 'Size of the elements'
				type: 'number'
		actions:
			a1:
				title: 'Derp'
				callback: actioncallback
		}

	uiEnabled: (node) ->
		console.log "Enabled Dummy Ui with node #{node.fileName}"

	uiDisabled: (node) ->
		console.log "Disabled Dummy Ui with node #{node.fileName}"

	###
	# The state synchronization module will call each plugin's
	# `onStateUpdate` method (if provided) whenever the current state changes
	# due to user input or calculation results on either server or client side.
	#
	# The hook provides the new complete state as an argument.
	#
	# `state.toolsValues` contains the values of the associated ui-elements
	# in the tools-container.
	#
	# @param {Object} state the complete current state
	# @param {Callback} done callback to be called when finished state modification
	# @memberOf dummyClientPlugin
	# @see stateSynchronization
	###
	onStateUpdate: (state, done) =>
		console.log 'Dummy Client Plugin state change'
		done()

	###
	# On each render frame the renderer will call the `on3dUpdate`
	# method of all plugins that provide it.
	#
	# @memberOf dummyClientPlugin
	# @param {DOMHighResTimeStamp} timestamp the current time
	# @see renderer
	# @see https://developer.mozilla.org/en-US/docs/Web/API/DOMHighResTimeStamp
	###
	on3dUpdate: (timestamp) =>
		return undefined

	###
	# When a file is loaded into lowfab, the `fileLoader` will try to import
	# it with every plugin that implements importFile until one succeeds.
	# The file's name and its content are provided as arguments.
	#
	# @param {String} fileName the name of the file to import
	# @param {String} fileContent the content of the file to import
	# @memberOf dummyClientPlugin
	# @see fileLoader
	###
	importFile: (fileName, fileContent) ->
		console.log 'Dummy Client Plugin imports a file'
		return undefined
