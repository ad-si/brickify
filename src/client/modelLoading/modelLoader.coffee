###
# @module modelLoader
###

md5 = require('blueimp-md5').md5
modelCache = require './modelCache'
Node = require '../../common/project/node'

###
# @class ModelLoader
###
class ModelLoader
	constructor: (@bundle) ->
		return

	readFiles: (files) ->
		@readFile file for file in files

	readFile: (file) ->
		reader = new FileReader()
		reader.readAsArrayBuffer file
		reader.onload = =>
			fileBuffer = reader.result
			@importFile file.name, fileBuffer, (error, model) =>
				if error or not model
					throw error
				else
					@load model

	importFile: (filename, fileBuffer, callback) ->
		# Load with first plugin capable of loading the file
		for loader in @bundle.pluginHooks.get 'importFile'
			loader filename, fileBuffer, (error, model) ->
				if error or not model
					callback error
				else
					callback null, model

	loadByHash: (hash) =>
		modelCache
		.request hash
		.catch (error) ->
			console.error "Could not load model from hash #{hash}"
			console.error error
		.then (model) =>
			return @addModelToScene model, hash

	# Adds a new model to the state
	addModelToScene: (model, hash) ->
		return @_calculateModelPosition model
		.then (modelPosition) ->
			return new Node {
				name: model.model.fileName # Todo: Use promises to get fileName
				modelHash: hash
				transform:
					position: modelPosition
			}
		.then (node) =>
			return @bundle.sceneManager.add node


	_calculateModelPosition: (model) ->
		# get biggest polygon, align it to xy-center
		# align whole model to be on z=0

		#resulting model coordinates
		result = {}

		#area of the biggest polygon
		maxArea = 0

		polygonArea = (xArray, yArray) ->
			# http://stackoverflow.com/questions/16285134/
			area = 0
			j = xArray.length - 1

			for i in [0..yArray.length - 1] by 1
				area += (xArray[j] + xArray[i]) * (yArray[j] - yArray[i])
				j = i
			area = Math.abs(area / 2)
			return area

		model
		.forEachFace (face) ->
			# Find lowest z value (for whole model)
			minZ  = Math.min(
				face.vertices[0].z
				face.vertices[1].z
				face.vertices[2].z
			)

			result.z ?= minZ
			result.z = Math.min result.z, minZ

			xValues = [
				face.vertices[0].x
				face.vertices[1].x
				face.vertices[2].x
			]
			yValues = [
				face.vertices[0].y
				face.vertices[1].y
				face.vertices[2].y
			]

			area = polygonArea(xValues, yValues)

			if area > maxArea
				maxArea = area
				minX = Math.min.apply null, xValues
				minY = Math.min.apply null, yValues
				maxX = Math.max.apply null, xValues
				maxY = Math.max.apply null, yValues

				result.x = minX + (maxX - minX) / 2
				result.y = minY + (maxY - minY) / 2

		.done (modelPromise) ->
			return modelPromise
		.then ->
			return {
			x: -result.x
			y: -result.y
			z: -result.z
			}

module.exports = ModelLoader
