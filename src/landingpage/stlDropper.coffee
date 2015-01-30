meshlib = require 'meshlib'
modelCache = require '../client/modelCache'
require 'string.prototype.endswith'

droptext = null
uploadFinishedCallback = null

readingString = 'Reading file
<img src="img/spinner.gif" style="height: 1.2em;">'
uploadString = 'Uploading file
<img src="img/spinner.gif" style="height: 1.2em;">'
loadedString = 'File loaded!'

module.exports.init = (targetDomObject, text, finishedCallback) ->
	bindDropHandler targetDomObject
	droptext = text
	uploadFinishedCallback = finishedCallback

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

		optimizedModel = meshlib.parse fileContent, errorCallback, true, true
		# happens with empty files
		if !optimizedModel
			alert 'Error loading .stl file'

		optimizedModel.originalFileName = filename

		droptext.html uploadString

		ufc = (md5hash) ->
			droptext.html loadedString
			if uploadFinishedCallback?
				uploadFinishedCallback(md5hash, importErrors)


		modelCache.store(optimizedModel).then(ufc)

		return

	return loadCallback
