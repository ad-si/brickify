globalConfig = require './globals.json'
path = require 'path'

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

globalConfig.stateSession = 0;

ui = require("./ui")(globalConfig)
ui.init()

renderer = require("./render")
renderer(ui)

statesync = require("./statesync")
statesync.init(globalConfig)
statesync.sync()