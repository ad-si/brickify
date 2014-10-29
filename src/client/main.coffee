path = require 'path'
globalConfig = require './globals.yaml'

globalConfig.stateSession = 0

ui = require("./ui")(globalConfig)
renderer = require "./render"
pluginLoader = require './pluginLoader'
statesync = require './statesync'

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


ui.init()

renderer(ui)

statesync.init globalConfig

#test for statesync
statesync.addUpdateCallback (state, delta) ->
	console.log 'UpdatedState: %s, Delta: %s',
		JSON.stringify(state), JSON.stringify(delta)

pluginLoader.loadPlugins statesync

#statesync.sync(true)
