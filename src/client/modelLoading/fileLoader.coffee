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

module.exports.onLoadFile = (event, feedbackTarget) ->
	event.preventDefault()
	event.stopPropagation()

	files = event.target.files ? event.dataTransfer.files
	if files?
		file = files[0]

		unless file.name.toLowerCase().endsWith '.stl'
			bootbox.alert(
				title: 'Your file does not have the right format!'
				message: 'Only .stl files are supported at the moment.
					We are working on adding more file formats'
			)
			return Promise.reject('Wrong file format')

		return loadFile feedbackTarget, file
			.then handleLoadedFile feedbackTarget, file.name

loadFile = (feedbackTarget, file) ->
	feedbackTarget.innerHTML = readingString
	Spinner.start feedbackTarget, spinnerOptions
	reader = new FileReader()
	return new Promise (resolve, reject) ->
		reader.onload = resolve
		reader.onerror = reject
		reader.onabort = reject
		reader.readAsArrayBuffer file


handleLoadedFile = (feedbackTarget, filename) -> (event) ->
		console.log "File #{filename} loaded"
		fileContent = event.target.result

		return new Promise (resolve, reject) ->
			meshlib.parse fileContent, null, (error, optimizedModel) ->
				Spinner.stop feedbackTarget

				if error or !optimizedModel
					bootbox.alert(
						title: 'Import failed'
						message: 'Your file contains errors that we could not fix.'
					)
					feedbackTarget.innerHTML = errorString
					reject()
					return

				optimizedModel.originalFileName = filename
				feedbackTarget.innerHTML = uploadString
				Spinner.start feedbackTarget, spinnerOptions

				modelCache.store(optimizedModel)
				.then (md5hash) ->
					Spinner.stop feedbackTarget, spinnerOptions
					feedbackTarget.innerHTML = loadedString
					resolve md5hash
				.catch reject

		return
