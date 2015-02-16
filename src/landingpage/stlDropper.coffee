meshlib = require 'meshlib'
modelCache = require '../client/modelCache'
require 'string.prototype.endswith'

uploadFinishedCallback = null

readingString = 'Reading file
<img src="img/spinner.gif" style="height: 1.2em;">'
uploadString = 'Uploading file
<img src="img/spinner.gif" style="height: 1.2em;">'
loadedString = 'File loaded!'

module.exports.init = (objects, feedbackTarget, finishedCallback) ->
	objects.each (i, el) -> bindDropHandler(el, feedbackTarget)
	uploadFinishedCallback = finishedCallback

bindDropHandler = (target, feedbackTargets) ->
	target.addEventListener 'drop',
		(event) -> onModelDrop(event, feedbackTargets),
		false
	target.addEventListener 'dragover', ignoreEvent, false
	target.addEventListener 'dragleave', ignoreEvent, false

ignoreEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()

onModelDrop = (event, feedbackTargets) ->
	event.preventDefault()
	event.stopPropagation()

	console.log feedbackTargets

	files = event.target.files ? event.dataTransfer.files
	if files?
		file = files[0]

		fn = file.name.toLowerCase()
		if (fn.search('.stl') == fn.length - 4)
			feedbackTargets.each (i, el) -> el.innerHTML = readingString
			loadFile feedbackTargets, file
		else
			alert 'Only .stl files are supported at the moment'

loadFile = (feedbackTargets, file) ->
	reader = new FileReader()
	reader.onload = handleLoadedFile(feedbackTargets, file.name)
	reader.readAsBinaryString(file)


handleLoadedFile = (feedbackTargets, filename) ->
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

		feedbackTargets.each (i, el) -> el.innerHTML = uploadString

		ufc = (md5hash) ->
			feedbackTargets.each (i, el) -> el.innerHTML = loadedString
			if uploadFinishedCallback?
				uploadFinishedCallback(md5hash, importErrors)


		modelCache.store(optimizedModel).then(ufc)

		return

	return loadCallback
