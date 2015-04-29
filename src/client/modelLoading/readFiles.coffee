ReadableFileStream = require('filestream').read
stlParser = require 'stl-parser'
meshlib = require 'meshlib'
Nanobar = require 'nanobar'

modelCache = require './modelCache'

averageFaceSize = 240 # Bytes
nanobar = new Nanobar {
	bg: '#acf'
	target: document.getElementById('loadButton')
	id: 'mynano'
}
$loadingTextElement = $('#loadButton span')

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

	nanobar.go 0
	$loadingTextElement.text 'Loading…'

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
			nanobar.go	(data.number / faceCounter) * 100

	modelBuilder = new meshlib.ModelBuilder()
	modelBuilder.on 'model', (model) ->
		nanobar.go 100
		$loadingTextElement.text 'Processing…'

		# Give time to render text
		setTimeout ->
			model
			.setFileName files[0].name
			.calculateNormals()
			.buildFaceVertexMesh()
			.done (modelPromise) -> modelPromise
			.then ->
				$loadingTextElement.text 'Opening…'
				return modelCache
				.store model
			.then (hash) ->
				$('.applink').prop 'href', "app#model=#{hash}"
				Promise.all(
					bundles.map (bundle) ->
						return bundle.modelLoader.loadByHash hash
				)
			.then (bundles) ->
				$('#loadButton span').text 'Drop an STL File'
				callback bundles
		, 50

	fileStream
	.pipe streamingStlParser
	.pipe modelBuilder
