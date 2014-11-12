###
# #Dummy Plugin#
#
# A demo plugin implementation for client-side
#
# We encourage plugin developers to split their plugins in several modules.
# In the end, the coffescript file named like the plugins folder (as in
# `/dummy/` and `/dummy/dummy.coffee`) will be loaded by the lowfab framework.
#
# This file must provide **hook-properties** and **hook-methods** that specify
# the interaction between the lowfab framework and the plugin.
#
# Those **hooks** have to be defined in `module.exports`, e.g.
# `module.exports.pluginName` or `module.exports.update3D()`.
#
# @module dummyClientPlugin
###

# include common plugin functions and data
common = require '../../../common/pluginCommon'

###
# Specifies the plugin's name
# @memberOf dummyClientPlugin
###
module.exports.pluginName = 'Dummy Client Plugin'

###
# Specifies the plugin's category
# (Currently not used)
# @memberOf dummyClientPlugin
###
module.exports.category = common.CATEGORY_IMPORT

###
# The plugin loader will call each plugin's `init` method (if provided) after
# loading the plugin.
#
# It is the first method to be called
# and provides access to the global configuration the state synchronization
# module and the ui module.
#
# @param {Object} globalConfig A key=>value-mapping of the global configuration
# @param {stateSynchronization} stateSync The state synchronization module
# @param {ui} ui The user interface module
# @memberOf dummyClientPlugin
# @see pluginLoader
###
module.exports.init = (globalConfig, stateSync, ui) ->
	console.log 'Dummy Client Plugin initialization'

###
# Each plugin that provides a `init3D` method is able to initialize its 3D
# rendering there and receives a three.js node as argument.
#
# If the plugin needs its node for later use it has to store it in `init3D`
# because it won't be handed the node again later.
#
# @param {ThreeJsNode} threejsNode the plugin's node in the 3D-scenegraph
# @memberOf dummyClientPlugin
# @see pluginLoader
###
module.exports.init3d = (threejsNode) ->
	console.log 'Dummy Client Plugin initializes 3d'

###
# The state synchronization module will call each plugin's
# `updateState` method (if provided) whenever the current state changes
# due to user input or calculation results on either server or client side.
#
# The hook provides both the delta to the previous state and the new complete
# state as arguments.
#
# @param {Object} delta the state changes since the last updateState call
# @param {Object} state the complete current state
# @memberOf dummyClientPlugin
# @see stateSynchronization
###
module.exports.updateState = (delta, state) ->
	console.log 'Dummy Client Plugin state change'


###
# On each render frame the renderer will call the `update3D`
# method of all plugins that provide it. There are no arguments passed.
#
# @memberOf dummyClientPlugin
# @see render
###
module.exports.update3D = () ->
