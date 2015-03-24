meshlib = require 'meshlib'
modelCache = require './modelCache'

uploadFinishedCallback = null

readingString = 'Reading file
<img src="img/spinner.gif" id="spinner">'
uploadString = 'Uploading file
<img src="img/spinner.gif" id="spinner">'
loadedString = 'File loaded!'
errorString = 'Import failed!'

module.exports.onLoadFile = (event, feedbackTarget, finishedCallback) ->
	uploadFinishedCallback = finishedCallback

	event.preventDefault()
	event.stopPropagation()

	files = event.target.files ? event.dataTransfer.files
	if files?
		file = files[0]

		fn = file.name.toLowerCase()
		if (fn.search('.stl') == fn.length - 4)
			feedbackTarget.innerHTML = readingString
			loadFile feedbackTarget, file
		else
			bootbox.alert({
				title: 'Your file does not have the right format!'
				message: 'Only .stl files are supported at the moment. We are working on
adding more file formats'
			})

loadFile = (feedbackTarget, file) ->
	reader = new FileReader()
	reader.onload = handleLoadedFile(feedbackTarget, file.name)
	reader.readAsArrayBuffer(file)

handleLoadedFile = (feedbackTarget, filename) ->
	loadCallback = 	(event) ->
		console.log "File #{filename} loaded"
		fileContent = event.target.result

		meshlib.parse fileContent, null, (error, optimizedModel) ->
			if error or !optimizedModel
				bootbox.alert({
					title: 'Import failed'
					message: 'Your file contains errors that we could not fix automatically.'
				})
				feedbackTarget.innerHTML = errorString
				return

			optimizedModel.originalFileName = filename

			feedbackTarget.innerHTML = uploadString

			ufc = (md5hash) ->
				feedbackTarget.innerHTML = loadedString
				if uploadFinishedCallback?
					uploadFinishedCallback(md5hash)

			modelCache.store(optimizedModel).then(ufc)

		return

	return loadCallback
