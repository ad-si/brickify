ReadableFileStream = require('filestream').read
stlParser = require 'stl-parser'
meshlib = require 'meshlib'

modelCache = require './modelCache'

averageFaceSize = 240 # Bytes


module.exports = (files, bundles, callback) ->

	if not Array.isArray bundles
		bundles = [bundles]

	if files.length > 1
		errorObject = {
			title: 'Import failed'
			message: 'Loading of multiple files is not supported.'
		}
		bootbox.alert errorObject
		throw new Error errorObject.message

	faceCounter = 0

	progressBar = document.querySelector 'progress'
	progressBar.setAttribute 'value', 0

	fileStream = new ReadableFileStream files[0]
	fileStream.on 'error', (error) ->
		console.error error
		bootbox.alert {
			title: 'Import failed'
			message: 'Your file contains errors that we could not fix.'
		}

	streamingStlParser = stlParser {blocking: false}
	streamingStlParser.on 'data', (data) ->
		if not data.number?
			faceCounter =
			if data.faceCount
			then data.faceCount
			else files[0].size / averageFaceSize
		else
			progressBar.setAttribute 'value', String data.number / faceCounter

	streamingStlParser.on 'end', ->
		progressBar.setAttribute 'value', '1'

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
			Promise.all(
				bundles.map (bundle) ->
					return bundle.modelLoader.loadByHash hash
			)
		.then callback

	fileStream
	.pipe streamingStlParser
	.pipe modelBuilder
