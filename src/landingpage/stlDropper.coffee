stlLoader = require '../client/plugins/stlImport/stlLoader.coffee'
md5 = require 'md5'
modelCache = require '../client/modelCache'

droptext = null
readingString = 'Reading file
<img src="img/spinner.gif" style="height: 1.2em;">'
uploadString = 'Uploading file
<img src="img/spinner.gif" style="height: 1.2em;">'

module.exports.init = (targetDomObject, text) ->
	bindDropHandler targetDomObject
	droptext = text

bindDropHandler = (target) ->
	target.addEventListener 'drop', onModelDrop, false
	target.addEventListener 'dragover', ignoreEvent, false
	target.addEventListener 'dragleave', ignoreEvent, false

ignoreEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()

onModelDrop = (event) ->
	event.preventDefault()
	event.stopPropagation()

	files = event.target.files ? event.dataTransfer.files
	if files?
		file = files[0]

		fn = file.name.toLowerCase()
		if (fn.search('.stl') == fn.length - 4)
			droptext.html readingString
			loadFile file
		else
			alert 'Only .stl files are supported at the moment'

loadFile = (file) ->
	reader = new FileReader()
	reader.onload = handleLoadedFile(file.name)
	reader.readAsBinaryString(file)


handleLoadedFile = (filename) ->
	loadCallback = 	(event) ->
		console.log "File #{filename} loaded"
		fileContent = event.target.result
		importErrors = false
		errorCallback = () ->
			importErrors = true

		optimizedModel = stlLoader.parse fileContent, errorCallback, true, true
		# happens with empty files
		if !optimizedModel
			alert 'Error loading .stl file'

		optimizedModel.originalFileName = filename

		droptext.html uploadString

		uploadFinishedCallback = (md5hash) ->
			if importErrors
				modelhash += '+errors'
			document.location.hash = ''
			dhref = document.location.href
			dhref = dhref.substring(0, dhref.length - 1) if dhref.endsWith('#')
			dhref += '/' unless dhref.endsWith('/')
			dhref += 'quickconvert#' + md5hash
			document.location.href = dhref
			return

		modelCache.store optimizedModel, uploadFinishedCallback

		return
	return loadCallback
