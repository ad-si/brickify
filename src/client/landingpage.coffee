require './polyfills'

clone = require 'clone'
$ = require 'jquery'
window.jQuery = window.$ = $
bootstrap = require 'bootstrap'
log = require 'loglevel'
piwikTracking = require './piwikTracking'

globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'
fileDropper = require './modelLoading/fileDropper'
readFiles = require './modelLoading/readFiles'
modelCache = require './modelLoading/modelCache'


# Set renderer size to fit to 3 bootstrap columns
globalConfig.staticRendererSize = true
globalConfig.staticRendererWidth = 388
globalConfig.staticRendererHeight = 300
globalConfig.buildUi = false
globalConfig.orbitControls.autoRotate = true
globalConfig.plugins.dummy = false
globalConfig.plugins.stlImport = false
globalConfig.plugins.coordinateSystem = false
globalConfig.plugins.legoBoard = false
globalConfig.plugins.editController = false
globalConfig.plugins.csg = false
globalConfig.colors.modelOpacity = globalConfig.colors.modelOpacityLandingPage

# disable wireframe and pipeline on landingpage
globalConfig.rendering.showShadowAndWireframe = false
globalConfig.rendering.usePipeline = false

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

	$('.applink').prop 'href', "app#model=#{defaultModelHash}"

	bundles[1].renderer.setupControls(
		config1,
		bundles[0].renderer.getControls()
	)

	fileDropper.init (event) ->
		event.preventDefault()
		event.stopPropagation()
		readFiles event.dataTransfer.files, bundles

	document
	.getElementById 'fileInput'
	.addEventListener 'change', (event) ->

		event.preventDefault()
		event.stopPropagation()
		readFiles event.target.files, bundles

		files = event.target.files

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


	$('.dropper').text 'Drop an STL file'
	$('#preview img').on( 'dragstart', (event) ->
			event.originalEvent.dataTransfer.setData(
				'text/plain'
				event.originalEvent.target.getAttribute 'data-hash'
			)
	)

.catch (error) ->
	console.error error


# set not available message
$('#downloadButton').click ->
	piwikTracking.trackEvent 'Landingpage', 'ButtonClick', 'Download'
	bootbox.alert({
		title: 'Not available'
		message: 'This feature is not available yet - please check back later.<br>' +
		'<br>However, you can edit and download the model with our editor '+
		'by clicking the <strong>Customize</strong> Button'
	})
