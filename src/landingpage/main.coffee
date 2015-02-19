require('es6-promise').polyfill()
$ = require 'jquery'

#fade in action buttons when javascript is ready
$('#buttonContainer').fadeTo(500, 1)

# Init quickconvert after basic page functionality has been initialized
globalConfig = require '../common/globals.yaml'
objectTree = require '../common/state/objectTree'
Bundle = require '../client/bundle'
clone = require 'clone'

# Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 388
globalConfig.syncWithServer = false
globalConfig.buildUi = false
globalConfig.autoRotate = true
globalConfig.plugins.dummy = false
globalConfig.plugins.stlImport = false
globalConfig.plugins.stlExport = false
globalConfig.plugins.coordinateSystem = false
globalConfig.plugins.legoBoard = false
globalConfig.plugins.solidRenderer = true
globalConfig.plugins.newBrickator = true

# clone global config 2 times
config1 = clone globalConfig
config2 = clone globalConfig

# instantiate 2 lowfab bundles
config1.renderAreaId = 'renderArea1'
config1.plugins.newBrickator = false
bundle1 = new Bundle config1
controls = bundle1.getControls()
b1 = bundle1.init()

config2.renderAreaId = 'renderArea2'
config2.plugins.solidRenderer = false
bundle2 = new Bundle config2, controls
b2 = bundle2.init()

loadAndConvert = (hash, animate) ->
	b1.then(() ->
		bundle1.modelLoader.loadByHash hash)
		.then(() ->
			document.getElementById('renderArea1').style.backgroundImage = 'none')
	b2.then(() -> bundle2.modelLoader.loadByHash hash)
		.then(() ->
			nb = bundle2.getPlugin 'newBrickator'
			nb.processFirstObject animate
		).then(() ->
			document.getElementById('renderArea2').style.backgroundImage = 'none')
	$('.applink').prop 'href', "app#initialModel=#{hash}+legofy"

#load and process model
loadAndConvert('1c2395a3145ad77aee7479020b461ddf', false)

loadModel = (hash, errors) ->
	b1.then(() -> bundle1.clearScene())
	b2.then(() -> bundle2.clearScene())
	loadAndConvert(hash, true)

stlDropper = require './stlDropper'
stlDropper.init $('body'), $('.dropper'), $('#dropoverlay'), loadModel

stlFileSelector = require './stlFileSelector'
stlFileSelector.init $('#fileSelector'),  $('.dropper'), loadModel
$('.dropper').html('Select an stl file')
