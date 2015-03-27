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

	load: (model) =>
		modelData = model.toBase64()
		hash = md5 modelData
		fileName = model.originalFileName
		modelCache.store model
		@addModelToScene fileName, hash, model

	loadByHash: (hash) =>
		modelCache
		.request hash
		.then @load
		.catch (error) ->
			console.error "Could not load model from hash #{hash}"
			console.error error

	# adds a new model to the state
	addModelToScene: (fileName, hash, model) ->
		transform = position: @_calculateModelPosition model
		node = new Node name: fileName, modelHash: hash, transform: transform
		@bundle.sceneManager.add node

	_calculateModelPosition: (model) ->
		# get biggest polygon, align it to xy-center
		# align whole model to be on z=0

		#resulting model coordinates
		result = {}

		#area of the biggest polygon
		maxArea = 0

		polygonArea = (xArray, yArray) ->
			# http://stackoverflow.com/questions/16285134/
			Area = 0
			j = xArray.length - 1

			for i in [0..yArray.length - 1] by 1
				Area += (xArray[j] + xArray[i]) * (yArray[j] - yArray[i])
				j = i
			Area = Math.abs(Area / 2)
			return Area

		model.forEachPolygon (p0, p1, p2, n) ->
			#find lowest z value (for whole model)
			minZ  = Math.min p0.z, p1.z, p2.z

			result.z ?= minZ
			result.z = Math.min result.z, minZ

			xValues = [p0.x, p1.x, p2.x]
			yValues = [p0.y, p1.y, p2.y]

			area = polygonArea(xValues, yValues)

			if area > maxArea
				maxArea = area
				minX = Math.min.apply null, xValues
				minY = Math.min.apply null, yValues
				maxX = Math.max.apply null, xValues
				maxY = Math.max.apply null, yValues

				result.x = minX + (maxX - minX) / 2
				result.y = minY + (maxY - minY) / 2

		return {
			x: -result.x
			y: -result.y
			z: -result.z
		}

module.exports = ModelLoader
