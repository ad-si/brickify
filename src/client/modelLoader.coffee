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
		# cheap alignment: move minimum point to origin
		min = {}

		minp = (p) =>
			if min.x?
				min.x = p.x if min.x > p.x
			else
				min.x = p.x
			if min.y?
				min.y = p.y if min.y > p.y
			else
				min.y = p.y
			if min.z?
				min.z = p.z if min.z > p.z
			else
				min.z = p.z

		optimizedModel.forEachPolygon (p0, p1, p2, n) =>
			minp p0
			minp p1
			minp p2

		node.positionData.position = {
			x: -min.x
			y: -min.y
			z: -min.z
		}
