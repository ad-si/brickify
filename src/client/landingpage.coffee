require './polyfills'

clone = require 'clone'
$ = require 'jquery'
window.jQuery = window.$ = $
bootstrap = require 'bootstrap'
log = require 'loglevel'

globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'
fileDropper = require './modelLoading/fileDropper'
readFiles = require './modelLoading/readFiles'


# Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 300
globalConfig.buildUi = false
globalConfig.autoRotate = true
globalConfig.plugins.dummy = false
globalConfig.plugins.stlImport = false
globalConfig.plugins.coordinateSystem = false
globalConfig.plugins.legoBoard = false
globalConfig.plugins.editController = false
globalConfig.colors.modelOpacity = globalConfig.colors.modelOpacityLandingPage

# disable wireframe on landinpage
globalConfig.createVisibleWireframe = false

config0 = clone globalConfig
config0.renderAreaId = 'renderArea1'
config0.plugins.newBrickator = false # Don't show bricks in left canvas

config1 = clone globalConfig
config1.renderAreaId = 'renderArea2'
config1.showModel = false # Don't show 3d-model in right canvas

defaultModelHash = '1c2395a3145ad77aee7479020b461ddf'


Promise
.all [
	new Bundle(config0).init(),
	new Bundle(config1).init()
]
.then (bundles) ->

	Promise
	.all [
		bundles[0]
		.modelLoader
		.loadByHash(defaultModelHash)
		.then(->
			$('#' + config0.renderAreaId).css 'backgroundImage', 'none'
			return bundles[0]
		)
		,
		bundles[1]
		.modelLoader
		.loadByHash(defaultModelHash)
		.then(->
			$('#' + config1.renderAreaId).css 'backgroundImage', 'none'
			return bundles[1]
		)
	]
.then (bundles) ->

	#console.log(bundlePromises)

	$('.applink').prop 'href', "app#initialModel=#{defaultModelHash}"

	bundles[1].renderer.setupControls(
	    config1,
	    bundles[0].renderer.getControls()
	)

	fileDropper.init (event) ->
		readFiles event, bundles

	document
	.getElementById 'fileInput'
	.addEventListener 'change', (event) ->
		readFiles event, bundles

	$('.dropper').html 'Drop an stl file'

.catch (error) ->
	console.error error


# set not available message
$('#downloadButton').click ->
	bootbox.alert({
		title: 'Not available'
		message: 'This feature is not available yet - please check back later.<br>' +
		'<br>However, you can edit and download the model with our editor '+
		'by clicking the <strong>Customize</strong> Button'
	})
