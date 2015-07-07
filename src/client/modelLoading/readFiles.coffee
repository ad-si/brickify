ReadableFileStream = require('filestream').read
stlParser = require 'stl-parser'
meshlib = require 'meshlib'
Nanobar = require 'nanobar'
log = require 'loglevel'

modelCache = require './modelCache'

averageFaceSize = 240 # Bytes
nanobar = new Nanobar {
	bg: '#acf'
	target: document.getElementById 'loadButton'
	id: 'progressBar'
}
loadingPercentage = 80
processingPercentage = 90
$loadingTextElement = $ '#loadingStatus'

module.exports = (files) ->

	return new Promise (resolve, reject) ->

		if files.length > 1
			errorObject = {
				title: 'Import failed'
				message: 'Loading of multiple files is not supported.'
			}
			bootbox.alert errorObject
			return reject errorObject

		file = files[0]

		if not /stl$/i.test file.name
			bootbox.alert(
				title: 'Your file does not have the right format!'
				message: 'Only .stl files are supported at the moment.
					We are working on adding more file formats'
			)
			return Promise.reject('Wrong file format')

		faceCounter = file.size / averageFaceSize

		nanobar.go 0
		$loadingTextElement.text 'Loading File'

		fileStream = new ReadableFileStream file
		fileStream.on 'error', (error) ->
			bootbox.alert {
				title: 'Import failed'
				message: 'Your file contains errors that we could not fix.
					You can try to fix your model with e.g.
					<a href=http://meshlab.sourceforge.net>meshlab</a>
					before uploading it.'
			}
			reject error

		streamingStlParser = stlParser {blocking: false}
		modelBuilder = new meshlib.ModelBuilder()

		streamingStlParser.on 'data', (data) ->
			# if data-chunk is the header
			if data.faceCount?
				faceCounter = data.faceCount
			# or a face
			else
				progress = (data.number / faceCounter) * loadingPercentage
				if progress < loadingPercentage
					nanobar.go progress

		streamingStlParser.on 'warning', log.warn

		modelBuilder.on 'model', (model) ->
			nanobar.go processingPercentage
			$loadingTextElement.text 'Processing Geometry'

			processModel = ->
				model
				.setFileName file.name
				.calculateNormals()
				.buildFaceVertexMesh()
				.done()
				.then ->
					$loadingTextElement.text 'Preparing View'
					return modelCache.store model
				.then (hash) ->
					nanobar.go 100
					$loadingTextElement.text 'Drop an STL File'
					resolve hash

			# Give time to render text
			setTimeout processModel, 50

		fileStream
		.pipe streamingStlParser
		.pipe modelBuilder
