require('es6-promise').polyfill()
$ = require 'jquery'

$('#quickConvert').hide()

$('#qcExampleLink').click (event) ->
	$('#quickConvert').slideDown 'slow', () ->
		b1.then(() ->
			bundle1.modelLoader.loadByHash '1c2395a3145ad77aee7479020b461ddf')
		b2.then(() ->
			bundle2.modelLoader.loadByHash '1c2395a3145ad77aee7479020b461ddf')
		b2.then(() ->
			nb = bundle2.getPlugin 'newbrickator'
			##still missing - newBrickator needs to be merged
		)

stlDropper = require './stlDropper'

stlDropper.init document.getElementById('dropzone'), $('#droptext')

# Init quickconvert after basic page functionality has been initialized
globalConfig = require '../client/globals.yaml'
objectTree = require '../common/objectTree'
Bundle = require '../client/bundle'
clone = require 'clone'

# Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 388
globalConfig.syncWithServer = false
globalConfig.buildUi = false

#clone global config 3 times
config1 = clone globalConfig
config2 = clone globalConfig

# instantiate 2 lowfab bundles
config1.renderAreaId = 'renderArea1'
bundle1 = new Bundle config1
b1 = bundle1.init()

config2.renderAreaId = 'renderArea2'
bundle2 = new Bundle config2
b2 = bundle2.init()

