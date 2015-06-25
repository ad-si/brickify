ReadableFileStream = require('filestream').read
stlParser = require 'stl-parser'
meshlib = require 'meshlib'
Nanobar = require 'nanobar'

modelCache = require './modelCache'

averageFaceSize = 240 # Bytes
nanobar = new Nanobar {
	bg: '#acf'
	target: document.getElementById 'loadButton'
	id: 'progressBar'
}
$loadingTextElement = $ '#loadButton span'

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

		console.log file.name

		if not /stl$/i.test file.name
			bootbox.alert(
				title: 'Your file does not have the right format!'
				message: 'Only .stl files are supported at the moment.
					We are working on adding more file formats'
			)
			return Promise.reject('Wrong file format')

		faceCounter = 0

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
		streamingStlParser.on 'data', (data) ->
			# if data-chunk is the header
			if not data.number?
				faceCounter =
					if data.faceCount
					then data.faceCount
					else file.size / averageFaceSize
			# or a face
			else
				progress = (data.number / faceCounter) * 80
				if progress < 80
					nanobar.go progress

		modelBuilder = new meshlib.ModelBuilder()
		modelBuilder.on 'model', (model) ->
			nanobar.go 90
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
					$('#loadButton span').text 'Drop an STL File'
					resolve hash

			# Give time to render text
			setTimeout processModel, 50

		fileStream
		.pipe streamingStlParser
		.pipe modelBuilder
