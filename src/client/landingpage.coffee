require './polyfills'

$ = require 'jquery'
clone = require 'clone'
stlParser = require 'stl-parser'
ReadableFileStream = require('filestream').read
meshlib = require 'meshlib'
modelCache = require './modelLoading/modelCache'

globalConfig = require '../common/globals.yaml'
Bundle = require './bundle'
fileDropper = require './modelLoading/fileDropper'


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


readFile = (event, bundles) ->
	event.preventDefault()
	event.stopPropagation()

	if event instanceof MouseEvent
		files = event.dataTransfer.files
	else
		files = event.target.files

	progress = document.querySelector 'progress'
	progress.setAttribute 'value', 0

	fileStream = new ReadableFileStream files[0]

	fileStream.reader.addEventListener 'progress', (event) ->
		percentageLoaded = 0
		if event.lengthComputable
			percentageLoaded = (event.loaded / event.total).toFixed(2)
			progress.setAttribute 'value', percentageLoaded

	fileStream.on 'error', (error) ->
		console.error error
		bootbox.alert(
			title: 'Import failed'
			message: 'Your file contains errors that we could not fix.'
		)

	modelBuilder = new meshlib.ModelBuilder()

	modelBuilder.on 'model', (model) ->
		model
		.setFileName files[0].name
		.calculateNormals()
		.buildFaceVertexMesh()
		.done (modelPromise) -> modelPromise
		.then ->
			return modelCache
			.store model
		.then (hash) ->
			loadAndConvert hash, bundles

	fileStream
	.pipe stlParser()
	.pipe modelBuilder

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
