$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'
JSZip = require 'jszip'
piwikTracking = require '../../piwikTracking'

module.exports = class DownloadProvider
	constructor: (@bundle) ->
		return

	init: (jqueryString, @exportUi, @sceneManager) =>
		@jqueryObject = $(jqueryString)

		@jqueryObject.on 'click', =>
			selNode = @sceneManager.selectedNode
			if selNode?
				@_createDownload 'stl', selNode

	_createDownload: (fileType, selectedNode) =>
		downloadOptions = {
			fileType: fileType
			studRadius: @exportUi.studRadius
			holeRadius: @exportUi.holeRadius
		}

		if (fileType == 'stl')
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
			if Array.isArray entry
				for subEntry in entry
					if subEntry.fileName.length > 0
						files.push {
							data: subEntry.data
							fileName: subEntry.fileName
						}
			else if entry.fileName.length > 0
				files.push {
					data: entry.data
					fileName: entry.fileName
				}
		return files

	_arrayBufferFromBlob: (blob, fileName) ->
		reader = new FileReader()
		return new Promise (resolve, reject) ->
			reader.onload = ->
				resolve {data: reader.result, fileName: fileName}
			reader.onerror = reject
			reader.onabort = reject
			reader.readAsArrayBuffer blob
