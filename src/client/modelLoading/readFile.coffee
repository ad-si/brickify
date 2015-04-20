ReadableFileStream = require('filestream').read
stlParser = require 'stl-parser'
meshlib = require 'meshlib'

modelCache = require './modelCache'


module.exports = (event, bundles, callback) ->
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
			Promise.all [
				bundles[0].modelLoader.loadByHash hash
				bundles[1].modelLoader.loadByHash hash
			]
		.then callback

	fileStream
	.pipe stlParser()
	.pipe modelBuilder
