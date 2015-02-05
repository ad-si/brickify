stlLoader = require '../plugins/stlImport/stlLoader'
modelCache = require '../client/modelCache'
require 'string.prototype.endswith'

uploadFinishedCallback = null

readingString = 'Reading file
<img src="img/spinner.gif" style="height: 1.2em;">'
uploadString = 'Uploading file
<img src="img/spinner.gif" style="height: 1.2em;">'
loadedString = 'File loaded!'

module.exports.init = (objects, feedbackTarget, overlay, finishedCallback) ->
	objects.each (i, el) -> bindDropHandler(el, feedbackTarget, overlay)
	uploadFinishedCallback = finishedCallback

bindDropHandler = (target, feedbackTargets, overlay) ->
	target.addEventListener 'drop',
		(event) -> onModelDrop(event, feedbackTargets, overlay),
		false
	target.addEventListener 'dragover',
		(event) -> showOverlay(event, overlay),
		false
	target.addEventListener 'dragleave',
			(event) -> hideOverlay(event, overlay),
			false

showOverlay = (event, overlay) ->
	ignoreEvent event
	overlay.show()

hideOverlay = (event, overlay) ->
	ignoreEvent event
	overlay.hide()

ignoreEvent = (event) ->
	event.preventDefault()
	event.stopPropagation()

onModelDrop = (event, feedbackTargets, overlay) ->
	ignoreEvent event

	overlay.fadeOut()

	files = event.target.files ? event.dataTransfer.files
	if files?
		file = files[0]

		fn = file.name.toLowerCase()
		if (fn.search('.stl') == fn.length - 4)
			feedbackTargets.each (i, el) -> el.innerHTML = readingString
			loadFile feedbackTargets, file
		else
			bootbox.alert({
				title: 'Your file does not have the right format!'
				message: 'Only .stl files are supported at the moment. We are working on
adding more file formats'
			})

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

		optimizedModel = stlLoader.parse fileContent, errorCallback, true, true
		# happens with empty files
		if !optimizedModel
			bootbox.alert({
				title: 'Import failed'
				message: 'Your file contains errors that we could not fix automatically.'
			})

		optimizedModel.originalFileName = filename

		feedbackTargets.each (i, el) -> el.innerHTML = uploadString

		ufc = (md5hash) ->
			feedbackTargets.each (i, el) -> el.innerHTML = loadedString
			if uploadFinishedCallback?
				uploadFinishedCallback(md5hash, importErrors)


		modelCache.store(optimizedModel).then(ufc)

		return

	return loadCallback
