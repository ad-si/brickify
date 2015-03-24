meshlib = require 'meshlib'
modelCache = require './modelCache'
Spinner = require '../Spinner'

uploadFinishedCallback = null

readingString = 'Reading file'
uploadString = 'Uploading file'
loadedString = 'File loaded!'
errorString = 'Import failed!'

spinnerOptions =
	lines: 9
	length: 5
	radius: 3
	width: 2

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
			Spinner.start feedbackTarget, spinnerOptions
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
	loadCallback = (event) ->
		console.log "File #{filename} loaded"
		fileContent = event.target.result

		meshlib.parse fileContent, null, (error, optimizedModel) ->
			Spinner.stop feedbackTarget
			if error or !optimizedModel
				bootbox.alert({
					title: 'Import failed'
					message: 'Your file contains errors that we could not fix automatically.'
				})

				feedbackTarget.innerHTML = errorString
				return

			optimizedModel.originalFileName = filename

			feedbackTarget.innerHTML = uploadString
			Spinner.start feedbackTarget, spinnerOptions

			modelCache.store(optimizedModel).then (md5hash) ->
				Spinner.stop feedbackTarget, spinnerOptions
				feedbackTarget.innerHTML = loadedString
				if uploadFinishedCallback?
					uploadFinishedCallback(md5hash)

		return

	return loadCallback
