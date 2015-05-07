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
			promisesArray = []
			for result in resultsArray
				if Array.isArray result
					for subResult in result
						if subResult.fileName.length > 0
							promisesArray.push(
								@_arrayBufferFromBlob subResult.data, subResult.fileName
							)
				else if result.fileName.length > 0
					promisesArray.push(
						@_arrayBufferFromBlob subResult.data, subResult.fileName
					)

			Promise.all(promisesArray).then (resultsArray) ->
				zip = new JSZip()
				options = binary: true
				for result in resultsArray
					zip.file result.fileName, result.arrayBuffer, options
				zipFile = zip.generate type: 'blob'
				saveAs zipFile, "brickify-#{selectedNode.name}.zip"

	_arrayBufferFromBlob: (blob, fileName) ->
		reader = new FileReader()
		return new Promise (resolve, reject) ->
			reader.onload = ->
				resolve {arrayBuffer: reader.result, fileName: fileName}
			reader.onerror = reject
			reader.onabort = reject
			reader.readAsArrayBuffer blob
