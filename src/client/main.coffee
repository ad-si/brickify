path = require 'path'
globalConfig = require './globals.yaml'

ui = require("./ui")(globalConfig)
ui.init()

renderer = require "./render"
renderer.init(ui)

pluginLoader = require './pluginLoader'
statesync = require './statesync'
objectTree = require '../common/objectTree'

### TODO: move somewhere where it is needed
# geometry functions
degToRad = ( deg ) -> deg * ( Math.PI / 180.0 )
radToDeg = ( rad ) -> deg * ( 180.0 / Math.PI )

normalFormToParamterForm = ( n, p, u, v) ->
	u.set( 0, -n.z, n.y ).normalize()
	v.set( n.y, -n.x, 0 ).normalize()

# utility
String::contains = (str) -> -1 isnt this.indexOf str
###

#test for statesync
statesync.addUpdateCallback (state, delta) ->
	console.log 'UpdatedState: %s, Delta: %s',
		JSON.stringify(state), JSON.stringify(delta)

statesync.init globalConfig, (state) ->
	objectTree.init state
	neededInstances =
		config: globalConfig
		statesync: statesync
		ui: ui
		renderer: renderer

	pluginLoader.init neededInstances
	pluginLoader.loadPlugins()


