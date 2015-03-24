require './polyfills'
$ = require 'jquery'

#fade in action buttons when javascript is ready
$('#buttonContainer').fadeTo(500, 1)

# Init quickconvert after basic page functionality has been initialized
globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'
clone = require 'clone'
fileLoader = require './modelLoading/fileLoader'

# Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 388
globalConfig.syncWithServer = false
globalConfig.buildUi = false
globalConfig.autoRotate = true
globalConfig.plugins.dummy = false
globalConfig.plugins.stlImport = false
globalConfig.plugins.coordinateSystem = false
globalConfig.plugins.legoBoard = false

# disable wireframe on landinpage
globalConfig.createVisibleWireframe = false

#autoreplace model when loaded/dropped
globalConfig.autoReplaceModel = true

# clone global config 2 times
config1 = clone globalConfig
config2 = clone globalConfig

# configure left bundle one to only show model
config1.plugins.newBrickator = false

# instantiate 2 lowfab bundles
config1.renderAreaId = 'renderArea1'
bundle1 = new Bundle config1
b1 = bundle1.init().then ->
	controls = bundle1.getControls()
	config2.renderAreaId = 'renderArea2'
	bundle2 = new Bundle config2, controls
	b2 = bundle2.init()

	loadAndConvert = (hash, animate) ->
		b1.then -> bundle1.modelLoader.loadByHash hash
			.then ->
				document.getElementById('renderArea1').style.backgroundImage = 'none'
		b2.then -> bundle2.modelLoader.loadByHash hash
			.then ->
				document.getElementById('renderArea2').style.backgroundImage = 'none'
		$('.applink').prop 'href', "app#initialModel=#{hash}"

	#load and process model
	loadAndConvert('1c2395a3145ad77aee7479020b461ddf', false)

	loadModel = (hash) ->
		b1.then -> bundle1.sceneManager.clearScene()
		b2.then -> bundle2.sceneManager.clearScene()
		loadAndConvert hash, true

	callback = (event) -> fileLoader.onLoadFile(
		event
		document.getElementById('loadButton')
		loadModel
	)

	fileDropper = require './modelLoading/fileDropper'
	fileDropper.init callback

	fileInput = document.getElementById('fileInput')
	fileInput.addEventListener 'change', (event) ->
		callback event
		@value = ''

	$('.dropper').html 'Drop an stl file'
