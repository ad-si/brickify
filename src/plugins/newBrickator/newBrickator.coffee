modelCache = require '../../client/modelCache'
LegoPipeline = require './pipeline/LegoPipeline'
THREE = require 'three'
NodeVisualization = require './visualization/NodeVisualization'
PipelineSettings = require './pipeline/PipelineSettings'
THREE = require 'three'
Brick = require './pipeline/Brick'
meshlib = require 'meshlib'
CsgExtractor = require './CsgExtractor'
BrushHandler = require './BrushHandler'
$ = require 'jquery'
threeHelper = require '../../client/threeHelper'

###
# @class NewBrickator
###
class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()

		@_brickVisibility = true
		@_printVisibility = true

		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
			opacity: 0.8
			transparent: true
		})

		# remove z-Fighting on baseplate
		@printMaterial.polygonOffset = true
		@printMaterial.polygonOffsetFactor = 5
		@printMaterial.polygonoffsetUnits = 5

	init: (@bundle) =>
		@brushHandler = new BrushHandler(@bundle, @)

	init3d: (@threejsRootNode) => return

	onNodeRemove: (node) =>
		@threejsRootNode.remove threeHelper.find node, @threejsRootNode

	onNodeAdd: (node) =>
		if @bundle.globalConfig.autoLegofy
			@runLegoPipeline node

	runLegoPipeline: (selectedNode) =>
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
			@_updateBricks cachedData, results.accumulatedResults.brickGraph

			@brushHandler.afterPipelineUpdate selectedNode, cachedData

			# instead of creating csg live, show original model semitransparent
			solidRenderer = @bundle.getPlugin('solid-renderer')
			if solidRenderer?
				solidRenderer.setNodeMaterial selectedNode, @printMaterial
			@_applyPrintVisibility cachedData

	###
	# If voxels have been selected as lego / as 3d print, the brick layout
	# needs to be locally regenerated
	# @param cachedData reference to cachedData
	# @param {Array<BrickObject>} modifiedVoxels list of voxels that have
	# been modified
	# @param {Boolean} createBricks creates Bricks if a voxel has no associated
	# brick. this happens when using the lego brush to create new bricks
	###
	relayoutModifiedParts: (cachedData, modifiedVoxels, createBricks = false) =>
		modifiedBricks = []
		for v in modifiedVoxels
			if v.gridEntry.brick?
				if modifiedBricks.indexOf(v.gridEntry.brick) < 0
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
		@_updateBricks cachedData, results.accumulatedResults.brickGraph

	# stores bricks in cached data, updates references in grid and updates
	# brick visuals
	_updateBricks: (cachedData, brickGraph) =>
		cachedData.brickGraph = brickGraph

		# update bricks and make voxel same colors as bricks
		cachedData.visualization.updateBricks cachedData.brickGraph.bricks
		cachedData.visualization.updateVoxelVisualization()
		cachedData.visualization.showVoxels()
		@_applyVoxelAndBrickVisibility cachedData

	getBrushes: () =>
		return @brushHandler.getBrushes()

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
			node = new THREE.Object3D()
			@threejsRootNode.add node
			threeHelper.link selectedNode, node

			nodeVisualization = new NodeVisualization @bundle, node, grid

			# create datastructure
			data = {
				node: selectedNode
				grid: grid
				optimizedModel: model
				threeNode: node
				visualization: nodeVisualization
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

	_createCSG: (selectedNode, cachedData, addKnobs = true) =>
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
			knobSize: PipelineSettings.legoKnobSize
			addKnobs: addKnobs
			transformedModel: threeModel
		}

		printThreeMesh = @csgExtractor.extractGeometry(cachedData.grid, options)

		cachedData.cachedCsg = printThreeMesh
		return printThreeMesh

	getHotkeys: =>
		return {
			title: 'Bricks'
			events: [
				{
					hotkey: 's'
					description: 'toggle stability view'
					callback: @_toggleStabilityView
				}
			]
		}

	_setStabilityView: (selectedNode, stabilityViewEnabled) =>
		return if !selectedNode?

		@_getCachedData(selectedNode).then (cachedData) =>
			cachedData.visualization.setStabilityView(stabilityViewEnabled)
			if stabilityViewEnabled
				cachedData.visualization.showBricks()
				@brushHandler.interactionDisabled = true
			else
				cachedData.visualization.showVoxels()
				@brushHandler.interactionDisabled = false

	_applyVoxelAndBrickVisibility: (cachedData) =>
		solidRenderer = @bundle.getPlugin('solid-renderer')

		if @_brickVisibility
			cachedData.visualization.showVoxelAndBricks()
			# if bricks are shown, show whole model instead of csg (faster)
			cachedData.visualization.hideCsg()
			if solidRenderer? and @_printVisibility
				solidRenderer.setNodeVisibility(cachedData.node, true)
		else
			# if bricks are hidden, csg has to be generated because
			# the user would else see the whole original model
			if @_printVisibility
				csg = @_createCSG cachedData.node, cachedData, true
				cachedData.visualization.showCsg(csg)

			if solidRenderer?
				solidRenderer.setNodeVisibility(cachedData.node, false)
			cachedData.visualization.hideVoxelAndBricks()

	_applyPrintVisibility: (cachedData) =>
		solidRenderer = @bundle.getPlugin('solid-renderer')

		if @_printVisibility
			if @_brickVisibility
				# show face csg (original model) when bricks are visible
				cachedData.visualization.hideCsg()
				if solidRenderer?
					solidRenderer.setNodeVisibility(cachedData.node, true)
			else
				# show real csg
				csg = @_createCSG cachedData.node, cachedData, true
				cachedData.visualization.showCsg(csg)
		else
			cachedData.visualization.hideCsg()
			if solidRenderer?
				solidRenderer.setNodeVisibility(cachedData.node, false)

	# enables the build mode, which means that only bricks and CSG
	# are shown
	enableBuildMode: (selectedNode) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			# disable interaction
			@brushHandler.interactionDisabled = true

			# show bricks and csg
			cachedData.visualization.showBricks()
			cachedData.visualization.setPossibleLegoBoxVisibility false

			csg = @_createCSG cachedData.node, cachedData, true
			cachedData.visualization.showCsg(csg)
			solidRenderer = @bundle.getPlugin('solid-renderer')
			solidRenderer?.setNodeVisibility cachedData.node, false

			return cachedData.grid.zLayers.length

	# when build mode is enabled, this tells the visualization to show
	# bricks up to the specified layer
	showBuildLayer: (selectedNode, layer) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			cachedData.visualization.showBrickLayer layer - 1

	# disables build mode and shows voxels, hides csg
	disableBuildMode: (selectedNode) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			#enable interaction
			@brushHandler.interactionDisabled = false

			# hide csg, show model, show voxels
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.hideCsg()
			solidRenderer = @bundle.getPlugin('solid-renderer')
			solidRenderer?.setNodeVisibility cachedData.node, true
			cachedData.visualization.showVoxels()
			
			if @brushHandler.legoBrushSelected
				cachedData.visualization.setPossibleLegoBoxVisibility true


module.exports = NewBrickator
