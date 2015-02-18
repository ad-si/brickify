require('es6-promise').polyfill()
$ = require 'jquery'

#fade in action buttons when javascript is ready
$('#buttonContainer').fadeTo(500, 1)

# Init quickconvert after basic page functionality has been initialized
globalConfig = require '../common/globals.yaml'
objectTree = require '../common/project/objectTree'
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

loadAndConvert = (hash) =>
	b1.then(() -> bundle1.modelLoader.loadByHash hash)
	b2.then(() -> bundle2.modelLoader.loadByHash hash)
		.then(() ->
			nb = bundle2.getPlugin 'newBrickator'
			nb.processFirstObject()
		)
	$('.applink').prop 'href', "app#initialModel=#{hash}+legofy"

#load and process model
loadAndConvert('1c2395a3145ad77aee7479020b461ddf')

loadModel = (hash, errors) =>
	b1.then(() -> bundle1.clearScene())
	b2.then(() -> bundle2.clearScene())
	loadAndConvert(hash)

stlDropper = require './stlDropper'
stlDropper.init $('#teaser-carousel .dropper'), loadModel
