modelCache = require '../../client/modelCache'
LegoPipeline = require './pipeline/LegoPipeline'
PipelineSettings = require './pipeline/PipelineSettings'
THREE = require 'three'
Brick = require './pipeline/Brick'
meshlib = require 'meshlib'
CsgExtractor = require './CsgExtractor'
threeHelper = require '../../client/threeHelper'
Spinner = require '../../client/Spinner'

###
# @class NewBrickator
###
class NewBrickator
	constructor: ->
		@pipeline = new LegoPipeline()

	init: (@bundle) => return

	onNodeAdd: (node) =>
		@nodeVisualizer = @bundle.getPlugin 'nodeVisualizer'

		if @bundle.globalConfig.autoLegofy
			@runLegoPipeline node

	runLegoPipeline: (selectedNode) =>
		Spinner.startOverlay @bundle.renderer.getDomElement()
		@_getCachedData(selectedNode).then (cachedData) =>
			#since cached data already contains voxel grid, only run lego
			settings = new PipelineSettings()
			settings.deactivateVoxelizing()

			settings.setModelTransform threeHelper.getTransformMatrix selectedNode

			data = {
				optimizedModel: cachedData.optimizedModel
				grid: cachedData.grid
			}
			results = @pipeline.run data, settings, true
			cachedData.brickGraph = results.accumulatedResults.brickGraph

			@nodeVisualizer?.objectModified selectedNode, cachedData
			Spinner.stop @bundle.renderer.getDomElement()

	###
	# If voxels have been selected as lego / as 3d print, the brick layout
	# needs to be locally regenerated
	# @param cachedData reference to cachedData
	# @param {Array<BrickObject>} modifiedVoxels list of voxels that have
	# been modified
	# @param {Boolean} createBricks creates Bricks if a voxel has no associated
	# brick. this happens when using the lego brush to create new bricks
	###
	relayoutModifiedParts: (selectedNode, modifiedVoxels, createBricks = false) =>
		@_getCachedData(selectedNode)
		.then (cachedData) =>
			modifiedBricks = []
			for v in modifiedVoxels
				if v.gridEntry.brick?
					if v.gridEntry.brick not in modifiedBricks
						modifiedBricks.push v.gridEntry.brick
				else if createBricks
					pos = v.voxelCoords
					modifiedBricks.push cachedData.brickGraph.createBrick pos.x, pos.y, pos.z

			settings = new PipelineSettings()
			settings.onlyRelayout()
			data = {
				optimizedModel: cachedData.optimizedModel
				grid: cachedData.grid
				brickGraph: cachedData.brickGraph
				modifiedBricks: modifiedBricks
			}

			results = @pipeline.run data, settings, true
			cachedData.brickGraph = results.accumulatedResults.brickGraph
			cachedData.csgNeedsRecalculation = true

			@nodeVisualizer?.objectModified selectedNode, cachedData

	_createDataStructure: (selectedNode) =>
		selectedNode.getModel().then (model) =>
			# create grid
			settings = new PipelineSettings()
			settings.setModelTransform threeHelper.getTransformMatrix selectedNode
			settings.deactivateLayouting()

			results = @pipeline.run(
				optimizedModel: model
				settings
				true
			)

			# create visuals
			grid = results.accumulatedResults.grid

			# create datastructure
			data = {
				node: selectedNode
				grid: grid
				optimizedModel: model
				csgNeedsRecalculation: true
			}
			return data

	_checkDataStructure: (selectedNode, data) =>
		return yes

	_getCachedData: (selectedNode) =>
		return selectedNode.getPluginData 'newBrickator'
		.then (data) =>
			if data? and @_checkDataStructure selectedNode, data
				return data
			else
				@_createDataStructure selectedNode
				.then (data) =>
					selectedNode.storePluginData 'newBrickator', data, true
					return data

	getDownload: (selectedNode) =>
		dlPromise = new Promise (resolve) =>
			@_getCachedData(selectedNode).then (cachedData) =>
				detailedCsg = @_createCSG selectedNode, cachedData, true

				optimizedModel = new meshlib.OptimizedModel()
				optimizedModel.fromThreeGeometry(detailedCsg.geometry)

				meshlib
				.model(optimizedModel)
				.export null, (error, binaryStl) ->
					fn = "brickolage-#{selectedNode.name}"
					if fn.indexOf('.stl') < 0
						fn += '.stl'
					resolve { data: binaryStl, fileName: fn }

		return dlPromise

	getCSG: (node, addStuds) =>
		return @_getCachedData(node)
		.then (cachedData) =>
			csg = @_createCSG node, cachedData, addStuds
			return csg

	_createCSG: (selectedNode, cachedData, addStuds = true) =>
		# return cached version if grid was not modified
		if not cachedData.csgNeedsRecalculation
			return cachedData.cachedCsg
		cachedData.csgNeedsRecalculation = false

		# get optimized model and transform to actual position
		if not cachedData.optimizedThreeModel?
			cachedData.optimizedThreeModel=
				cachedData.optimizedModel.convertToThreeGeometry()
			threeModel = cachedData.optimizedThreeModel
			threeModel.applyMatrix threeHelper.getTransformMatrix selectedNode
		else
			threeModel = cachedData.optimizedThreeModel

		# create the intersection of selected voxels and the model mesh
		@csgExtractor ?= new CsgExtractor()

		options = {
			profile: true
			grid: cachedData.grid
			studSize: PipelineSettings.legoStudSize
			addStuds: addStuds
			transformedModel: threeModel
		}

		printThreeMesh = @csgExtractor.extractGeometry(cachedData.grid, options)

		cachedData.cachedCsg = printThreeMesh
		return printThreeMesh

module.exports = NewBrickator
