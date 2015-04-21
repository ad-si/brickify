require './polyfills'

clone = require 'clone'
$ = require 'jquery'
window.jQuery = window.$ = $
bootstrap = require 'bootstrap'

globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'
fileDropper = require './modelLoading/fileDropper'
readFile = require './modelLoading/readFile'


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
# configure left bundle one to only show model
config0.plugins.newBrickator = false

config1 = clone globalConfig
config1.renderAreaId = 'renderArea2'


loadAndConvert = (hash, bundles) ->
	bundles[0].modelLoader
	.loadByHash hash
	.then ->
		$('#' + config0.renderAreaId).css 'backgroundImage', 'none'

	bundles[1].modelLoader
	.loadByHash hash
	.then ->
		$('#' + config1.renderAreaId).css 'backgroundImage', 'none'

	$('.applink').prop 'href', "app#initialModel=#{hash}"


Promise
.all [
	new Bundle(config0).init(),
	new Bundle(config1).init()
]
.then (bundles) ->
	bundles[1].renderer.setupControls(
	 	config1,
	 	bundles[0].renderer.getControls()
	)

	defaultModelHash = '1c2395a3145ad77aee7479020b461ddf'

	loadAndConvert defaultModelHash, bundles

	fileDropper.init (event) ->
		readFile event, bundles

	document
	.getElementById 'fileInput'
	.addEventListener 'change', (event) ->
		readFile event, bundles

	$('.dropper').html 'Drop an stl file'

# set not available message
$('#downloadButton').click ->
	bootbox.alert({
		title: 'Not available'
		message: 'This feature is not available yet - please check back later.<br>' +
		'<br>However, you can edit and download the model with our editor '+
		'by clicking the <strong>Customize</strong> Button'
	})
