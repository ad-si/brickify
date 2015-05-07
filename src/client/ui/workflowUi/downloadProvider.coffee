$ = require 'jquery'
modelCache = require '../../modelLoading/modelCache'
saveAs = require 'filesaver.js'
JSZip = require 'jszip'

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

		promisesArray = @bundle.pluginHooks.getDownload selectedNode, downloadOptions

		Promise.all(promisesArray).then (resultsArray) =>
			files = @_collectFiles resultsArray

			if files.length is 0
				bootbox.alert(
					title: 'No downloads'
					message: 'There is nothing to download at the moment'
				)
			if files.length is 1
				data = files[0].data
				fileName = files[0].fileName
				saveAs data, fileName
			if files.length > 1
				promisesArray = []
				for file in files
					promisesArray.push(
						@_arrayBufferFromBlob file.data, file.fileName
					)

				Promise.all(promisesArray).then (resultsArray) ->
					zip = new JSZip()
					options = binary: true
					for result in resultsArray
						zip.file result.fileName, result.data, options
					zipFile = zip.generate type: 'blob'
					saveAs zipFile, "brickify-#{selectedNode.name}.zip"

	_collectFiles: (array) ->
		files = []
		for entry in array
			if Array.isArray entry
				for subEntry in entry
					if subEntry.fileName.length > 0
						files.push data: subEntry.data, fileName: subEntry.fileName
			else if entry.fileName.length > 0
				files.push data: entry.data, fileName: entry.fileName
		return files

	_arrayBufferFromBlob: (blob, fileName) ->
		reader = new FileReader()
		return new Promise (resolve, reject) ->
			reader.onload = ->
				resolve {data: reader.result, fileName: fileName}
			reader.onerror = reject
			reader.onabort = reject
			reader.readAsArrayBuffer blob
