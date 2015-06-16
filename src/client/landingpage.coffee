require './polyfills'
$ = require 'jquery'
window.jQuery = window.$ = $
bootstrap = require 'bootstrap'
piwikTracking = require './piwikTracking'

# Init quickconvert after basic page functionality has been initialized
globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'
clone = require 'clone'
fileLoader = require './modelLoading/fileLoader'
modelCache = require './modelLoading/modelCache'

# Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 300
globalConfig.buildUi = false
globalConfig.orbitControls.autoRotate = true
globalConfig.plugins.dummy = false
globalConfig.plugins.coordinateSystem = false
globalConfig.plugins.legoBoard = false
globalConfig.plugins.editController = false
globalConfig.plugins.csg = false
globalConfig.colors.modelOpacity = globalConfig.colors.modelOpacityLandingPage

# disable wireframe and pipeline on landingpage
globalConfig.rendering.showShadowAndWireframe = false
globalConfig.rendering.usePipeline = false

# clone global config 2 times
config1 = clone globalConfig
config2 = clone globalConfig

# configure left bundle to only show model
config1.plugins.newBrickator = false

# configure right bundle to not show the model
config2.rendering.showModel = false

# instantiate 2 brickify bundles
config1.renderAreaId = 'renderArea1'
bundle1 = new Bundle config1
b1 = bundle1.init().then ->
	controls = bundle1.getControls()
	config2.renderAreaId = 'renderArea2'
	bundle2 = new Bundle config2, controls
	b2 = bundle2.init()

	loadAndConvert = (hash) ->
		b1.then -> bundle1.modelLoader.loadByHash hash
			.then -> $('#' + config1.renderAreaId).css 'backgroundImage', 'none'
		b2.then -> bundle2.modelLoader.loadByHash hash
			.then -> $('#' + config2.renderAreaId).css 'backgroundImage', 'none'
		$('.applink').prop 'href', "app#initialModel=#{hash}"

	#load and process model
	loadAndConvert 'goggles'

	loadFromHash = (hash) ->
		b1.then -> bundle1.sceneManager.clearScene()
		b2.then -> bundle2.sceneManager.clearScene()
		loadAndConvert hash, true

	callback = (event) ->
		files = event.target.files ? event.dataTransfer.files
		if files.length
			piwikTracking.trackEvent 'Landingpage', 'LoadModel', files[0].name
			fileLoader.onLoadFile files, $('#loadButton')[0], shadow: false
			.then loadFromHash
		else
			hash = event.dataTransfer.getData 'text/plain'
			piwikTracking.trackEvent 'Landingpage', 'LoadModelFromImage', hash
			modelCache.exists hash
			.then -> loadFromHash hash
			.catch -> bootbox.alert(
				title: 'This is not a valid model!'
				message: 'You can only drop stl files or our example images.'
			)

	fileDropper = require './modelLoading/fileDropper'
	fileDropper.init callback

	fileInput = document.getElementById('fileInput')
	fileInput.addEventListener 'change', (event) ->
		callback event
		@value = ''

	$('.dropper').text 'Drop an stl file'
	$('#preview img, #preview a').on( 'dragstart'
		(e) ->
			e.originalEvent.dataTransfer.setData(
				'text/plain'
				e.originalEvent.target.getAttribute 'data-hash'
			)
	)

# set not available message
$('#downloadButton').click ->
	piwikTracking.trackEvent 'Landingpage', 'ButtonClick', 'Download'
	bootbox.alert({
		title: 'Not available'
		message: 'This feature is not available yet - please check back later.<br>' +
		'<br>However, you can edit and download the model with our editor '+
		'by clicking the <strong>Customize</strong> Button'
	})
