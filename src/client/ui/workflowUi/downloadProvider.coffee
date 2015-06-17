$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'
JSZip = require 'jszip'
log = require 'loglevel'
Spinner = require '../../Spinner'
piwikTracking = require '../../piwikTracking'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	init: (stlButtonId, instructionsButtonId, @exportUi, @sceneManager) =>
		@$stlButton = $(stlButtonId)
		@$stlButton.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				Spinner.startOverlay @$stlButton[0]
				@$stlButton.addClass 'disabled'
				window.setTimeout(
					=> @_createDownload 'stl', selNode
					20
				)

		@$instructionsButton = $(instructionsButtonId)
		@$instructionsButton.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				Spinner.startOverlay @$instructionsButton[0]
				@$instructionsButton.addClass 'disabled'
				window.setTimeout(
					=> @_createDownload 'instructions', selNode
					20
				)

	_createDownload: (type, selectedNode) =>
		downloadOptions = {
			type: type
			studRadius: @exportUi.studRadius
			holeRadius: @exportUi.holeRadius
		}

		if (type == 'stl')
			piwikTracking.trackEvent 'EditorExport', 'DownloadStlClick'
			piwikTracking.trackEvent(
				'EditorExport', 'StudRadius', @exportUi.studRadiusSelection
			)
			piwikTracking.trackEvent(
				'EditorExport', 'HoleRadius', @exportUi.holeRadiusSelection
			)

		promisesArray = @bundle.pluginHooks.getDownload(
			selectedNode
			downloadOptions
		)

		Promise
		.all promisesArray
		.then (resultsArray) =>
			files = @_collectFiles resultsArray

			# Stop showing spinner
			if (type == 'instructions')
				Spinner.stop @$instructionsButton[0]
				@$instructionsButton.removeClass 'disabled'
			else
				Spinner.stop @$stlButton[0]
				@$stlButton.removeClass 'disabled'


			if files.length is 1
				saveAs(
					new Blob([files[0].data])
					files[0].fileName
				)

			else if files.length > 1
				zip = new JSZip()

				files.forEach (file, index) ->
					zip.file(
						index + '_' + file.fileName
						file.data
					)

				saveAs(
					zip.generate {type: 'blob'}
					"brickify-#{selectedNode.name}.zip"
				)

			else
				bootbox.alert(
					title: 'There is nothing to download at the moment'
					message: 'This happens when your whole model
						is made out of LEGO
						and you have not selected anything to be 3D-printed.
						Use the Make 3D-print brush for that.'
				)

		.catch (error) ->
			log error

	_collectFiles: (array) ->
		files = []
		for entry in array
			continue if not entry?
			if Array.isArray entry
				for subEntry in entry
					if subEntry.fileName.length > 0
						files.push subEntry
			else if entry.fileName.length > 0
				files.push entry
		return files

	_convertToZippableType: ({data: data, fileName: fileName}) =>
		if data instanceof Blob
			return @_arrayBufferFromBlob data, fileName, options
		if data instanceof ArrayBuffer
			return Promise.resolve {
				data: data
				fileName: fileName
				options: {
					binary: true
				}
			}
		if (data instanceof String) or (typeof(data) == 'string')
			return Promise.resolve {
				data: data
				fileName: fileName
				options: {
					binary: false
				}
			}

		log.warn "No conversion method found for file #{fileName}"
		return null


	_arrayBufferFromBlob: (blob, fileName) ->
		reader = new FileReader()
		return new Promise (resolve, reject) ->
			reader.onload = ->
				resolve {
					data: reader.result
					fileName: fileName
					options: {
						binary: true
					}
				}
			reader.onerror = reject
			reader.onabort = reject
			reader.readAsArrayBuffer blob
