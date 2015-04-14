modelCache = require '../../client/modelLoading/modelCache'
LegoPipeline = require './pipeline/LegoPipeline'
PipelineSettings = require './pipeline/PipelineSettings'
THREE = require 'three'
Brick = require './pipeline/Brick'
meshlib = require 'meshlib'
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
			cachedData.csgNeedsRecalculation = true

			@nodeVisualizer?.objectModified selectedNode, cachedData
			Spinner.stop @bundle.renderer.getDomElement()

	###
	# If voxels have been selected as lego / as 3d print, the brick layout
	# needs to be locally regenerated
	# @param {Object} cachedData reference to cachedData
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

	everythingPrint: (selectedNode) =>
		@_getCachedData selectedNode
		.then (cachedData) =>
			settings = new PipelineSettings()
			settings.onlyInitLayout()

			data = grid: cachedData.grid

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

	_checkDataStructure: (selectedNode, data) ->
		return yes # Later: Check for node transforms

	_getCachedData: (selectedNode) =>
		return selectedNode.getPluginData 'newBrickator'
		.then (data) =>
			if data? and @_checkDataStructure selectedNode, data
				return data
			else
				@_createDataStructure selectedNode
				.then (data) ->
					selectedNode.storePluginData 'newBrickator', data, true
					return data

	getDownload: (selectedNode, downloadOptions) =>
		options = @_prepareCSGOptions(
			downloadOptions.studRadius, downloadOptions.holeRadius
		)

		@csg ?= @bundle.getPlugin 'csg'
		if not @csg?
			console.warn 'Unable to create download due to CSG Plugin missing'
			resolve { data: '', fileName: '' }
			return

		dlPromise = new Promise (resolve, reject) =>
			@csg.getCSG selectedNode, options
			.then (detailedCsg) ->
				if not detailedCsg?
					resolve { data: '', fileName: '' }
					return

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

	_prepareCSGOptions: (studRadius, holeRadius) =>
		options = {}

		# set stud and hole size
		if studRadius?
			studSize = {
				radius: studRadius
				height: PipelineSettings.legoStudSize.height
			}
		else
			studSize = PipelineSettings.legoStudSize

		if holeRadius?
			holeSize = {
				radius: holeRadius
				height: PipelineSettings.legoHoleSize.height
			}
		else
			holeSize = PipelineSettings.legoHoleSize

		# add studs
		options.addStuds = true

		return options






module.exports = NewBrickator
