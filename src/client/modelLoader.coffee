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
		# TODO: remove extension check
		if file.name.toLowerCase().search '.stl' >= 0
			reader.onload = @loadFile file.name
			reader.readAsBinaryString file

	loadFile: (filename) =>
		return (event) =>
			fileContent = event.target.result
			optimizedModel = @importFile filename, fileContent
			@load optimizedModel if optimizedModel?

	importFile: (filename, fileContent) ->
		for loader in @bundle.pluginHooks.get 'importFile'
			optimizedModel = loader filename, fileContent
			return optimizedModel if optimizedModel?

	load: (optimizedModel) =>
		modelData = optimizedModel.toBase64()
		hash = md5(modelData)
		fileName = optimizedModel.originalFileName
		modelCache.store optimizedModel
		@addModelToState fileName, hash, optimizedModel

	loadByHash: (hash) =>
		modelCache.request(hash).then(
			@load
			() -> console.error "Could not load model from hash #{hash}"
		)

	# adds a new model to the state
	addModelToState: (fileName, hash, optimizedModel) ->
		loadModelCallback = (state) =>
			# create node structure
			node = objectTree.addChild state.rootNode
			node.fileName = fileName
			node.meshHash = hash
			node.pluginData = {
				uiGen: {selectedPluginKey: @bundle.globalConfig.defaultPlugin}}

			# align model to grid
			@_alignModelToGrid node, optimizedModel

			# add to state
			@bundle.ui?.sceneManager.add node

		# call updateState on all client plugins and sync
		@bundle.statesync.performStateAction loadModelCallback, true

	_alignModelToGrid: (node, optimizedModel) =>
		# get biggest polygon, align it to xy-center
		# align whole model to be on z=0

		res = {}
		maxA = 0
		minAx = null
		minAy = null

		minz = (p) ->
			if res.z?
				res.z = p.z if res.z > p.z
			else
				res.z = p.z

		maxa = (xArray, yArray) ->
			A = 0
			j = xArray.length - 1

			for i in [0..yArray.length - 1] by 1
				A += (xArray[j] + xArray[i]) * (yArray[j] - yArray[i])
				j = i
			A = Math.abs(A / 2)

			minX = Math.min.apply null, xArray
			minY = Math.min.apply null, yArray
			maxX = Math.max.apply null, xArray
			maxY = Math.max.apply null, yArray

			if A > maxA
				maxA = A
				res.x = minX + (maxX - minX) / 2
				res.y = minY + (maxY - minY) / 2

		optimizedModel.forEachPolygon (p0, p1, p2, n) =>
			minz(p0)
			minz(p1)
			minz(p2)
			maxa([p0.x, p1.x, p2.x], [p0.y, p1.y, p2.y])

		console.log "maxA = #{maxA}"
		console.log res

		node.positionData.position = {
			x: -res.x
			y: -res.y
			z: -res.z
		}
