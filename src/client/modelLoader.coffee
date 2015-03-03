###
# @module modelLoader
###

md5 = require('blueimp-md5').md5
modelCache = require './modelCache'
objectTree = require '../common/state/objectTree'

module.exports = class ModelLoader
	constructor: (@bundle) ->
		return

	readFiles: (files) ->
		@readFile file for file in files

	readFile: (file) ->
		reader = new FileReader()
		reader.readAsArrayBuffer file
		reader.onload = () =>
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
		hash = md5(modelData)
		fileName = model.originalFileName
		modelCache.store model
		@addModelToState fileName, hash, model
	loadByHash: (hash) =>
		modelCache
		.request(hash)
		.then(@load)
		.catch (error) ->
			console.error "Could not load model from hash #{hash}"
			console.error error

	# adds a new model to the state
	addModelToState: (fileName, hash, optimizedModel) ->
		loadModelCallback = (state) =>
			# create node structure
			node = objectTree.addChild state.rootNode
			node.fileName = fileName
			node.meshHash = hash
			node.pluginData = { }

			# align model to grid
			@_alignModelToGrid node, optimizedModel

			# add to state
			@bundle.ui?.sceneManager.add node

		# call updateState on all client plugins and sync
		@bundle.statesync.performStateAction loadModelCallback, true

	_alignModelToGrid: (node, optimizedModel) =>
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

		optimizedModel.forEachPolygon (p0, p1, p2, n) =>
			#find lowest z value (for whole model)
			minZ  = Math.min(p0.z, p1.z, p2.z)

			result.z ?= minZ
			result.z = Math.min(result.z, minZ)

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

		node.positionData.position = {
			x: -result.x
			y: -result.y
			z: -result.z
		}
