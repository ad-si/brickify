log = require 'loglevel'
meshlib = require 'meshlib'
stlParser = require 'stl-parser'

modelCache = require './modelCache'
Spinner = require '../Spinner'

uploadFinishedCallback = null

readingString = 'Reading file'
uploadString = 'Uploading file'
loadedString = 'File loaded!'
errorString = 'Import failed!'

module.exports.onLoadFile = (files, feedbackTarget, spinnerOptions) ->
	return Promise.reject() if files.length < 1

	file = files[0]
	unless file.name.toLowerCase().endsWith '.stl'
		bootbox.alert(
			title: 'Your file does not have the right format!'
			message: 'Only .stl files are supported at the moment.
				We are working on adding more file formats'
		)
		return Promise.reject('Wrong file format')

	return loadFile feedbackTarget, file, spinnerOptions
		.then handleLoadedFile feedbackTarget, file.name, spinnerOptions
		.catch (error) ->
			bootbox.alert(
				title: 'Import failed'
				message:
					"<p>Your file contains errors that we could not fix.</p>
					<p>Details:</br>
					<small>#{error.message}</small>
					</p>"
			)
			feedbackTarget.innerHTML = errorString
			log.error error

loadFile = (feedbackTarget, file, spinnerOptions) ->
	feedbackTarget.innerHTML = readingString
	Spinner.start feedbackTarget, spinnerOptions
	reader = new FileReader()
	return new Promise (resolve, reject) ->
		reader.onload = resolve
		reader.onerror = reject
		reader.onabort = reject
		setTimeout -> reader.readAsArrayBuffer file

handleLoadedFile = (feedbackTarget, filename, spinnerOptions) -> (event) ->
	log.debug "File #{filename} loaded"
	fileContent = event.target.result

	return new Promise (resolve, reject) ->

		stlParserInstance = stlParser(fileContent)

		stlParserInstance.on 'error', (error) ->
			reject error

		stlParserInstance.on 'data', (data) ->
			model = meshlib.Model.fromObject {mesh: data}

			model
			.setFileName filename
			.setName filename
			.calculateNormals()
			.buildFaceVertexMesh()
			.done()
			.then ->
				Spinner.stop feedbackTarget
				feedbackTarget.innerHTML = uploadString
				Spinner.start feedbackTarget, spinnerOptions
				return modelCache.store model

			.then (md5hash) ->
				Spinner.stop feedbackTarget
				feedbackTarget.innerHTML = loadedString
				resolve md5hash

			.catch (error) ->
				reject error
