modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
THREE = require 'three'
NodeVisualization = require './visualization/NodeVisualization'
PipelineSettings = require './PipelineSettings'
THREE = require 'three'
Brick = require './Brick'
meshlib = require('meshlib')
CsgExtractor = require './CsgExtractor'
BrushHandler = require './BrushHandler'
jquery = require '.'

module.exports = class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()
		@gridCache = {}

		@_brickVisibility = true
		@_printVisibility = true
		
		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
			opacity: 0.8
			transparent: true
		})

	init: (@bundle) =>
		@brushHandler = new BrushHandler(@bundle, @)
		@_initBuildButton()

	init3d: (@threejsRootNode) => return

	onNodeRemove: (node) =>
		# remove node visuals (bricks, csg, ...)
		if node.pluginData.newBrickator?
			@_getCachedData(node).then (cachedData) =>
				@threejsRootNode.remove cachedData.threeNode

	onNodeAdd: (node) =>
		if @bundle.globalConfig.autoLegofy
			@runLegoPipeline node

	processFirstObject: (animate) =>
		#ToDo: Add animation to brick/voxel visualization (see #255)
		#TODO: @runLegoPipeline node
		return

	runLegoPipeline: (selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			#since cached data already contains voxel grid, only run lego
			settings = new PipelineSettings()
			settings.deactivateVoxelizing()

			@_applyModelTransforms selectedNode, settings

			data = {
				optimizedModel: cachedData.optimizedModel
				grid: cachedData.grid
			}
			results = @pipeline.run data, settings, true

			# show bricks
			bricks = results.accumulatedResults.bricks
			cachedData.visualization.updateBricks bricks
			cachedData.visualization.showBricks()

			# ToDo: this is a workaround which needs to be fixed in layouter
			# (apply changed bricks directly to grid)
			@_applyBricksToGrid results.accumulatedResults.bricks, cachedData.grid

			@brushHandler.afterPipelineUpdate selectedNode, cachedData

			# instead of creating csg live, show original model semitransparent
			solidRenderer = @bundle.getPlugin('solid-renderer')
			if solidRenderer?
				solidRenderer.setNodeMaterial selectedNode,
					@printMaterial

	_applyModelTransforms: (selectedNode, pipelineSettings) =>
		modelTransform = @_getModelTransforms selectedNode
		pipelineSettings.setModelTransform modelTransform

	_getModelTransforms: (selectedNode) =>
		#ToDo (future): add rotation and scaling (the same way it's done in three)
		#to keep visual consistency

		modelTransform = new THREE.Matrix4()
		pos = selectedNode.positionData.position
		modelTransform.makeTranslation(pos.x, pos.y, pos.z)
		return modelTransform

	getBrushes: () =>
		return @brushHandler.getBrushes()

	_getCachedData: (selectedNode) =>
		# returns Grid, optimized model and other cached data for the selected node
		return new Promise (resolve, reject) =>
			identifier = @_getNodeIdentifier selectedNode
			nodePosition = selectedNode.positionData.position

			# cache is valid if object didn't move
			if @gridCache[identifier]?
				griddata = @gridCache[identifier]

				if griddata.x == nodePosition.x and
				griddata.y == nodePosition.y and
				griddata.z == nodePosition.z
					resolve(griddata)
					return

			modelPromise = modelCache.request(selectedNode.meshHash)
			modelPromise.then (optimizedModel) =>
				# create grid
				settings = new PipelineSettings()
				@_applyModelTransforms selectedNode, settings
				settings.deactivateLayouting()

				data = {
					optimizedModel: optimizedModel
				}
				results = @pipeline.run data, settings, true

				# create visuals
				grid = results.accumulatedResults.grid
				node = new THREE.Object3D()
				@threejsRootNode.add node

				nodeVisualization = new NodeVisualization(@bundle, node, grid)

				# create datastructure
				@gridCache[identifier] = {
					grid: grid
					optimizedModel: optimizedModel
					threeNode: node
					visualization: nodeVisualization
					x: nodePosition.x
					y: nodePosition.y
					z: nodePosition.z
				}

				resolve(@gridCache[identifier])
			modelPromise.catch (error) =>
				reject error

	_applyBricksToGrid: (bricks, grid) =>
		# updates references between voxel --> brick
		for layer in bricks
			for brick in layer
				for x in [brick.position.x..((brick.position.x + brick.size.x) - 1)] by 1
					for y in [brick.position.y..((brick.position.y + brick.size.y) - 1)] by 1
						for z in [brick.position.z..((brick.position.z + brick.size.z) - 1)] by 1
							voxel = grid.zLayers[z][x][y]
							if voxel?
								voxel.brick = brick
							else
								console.log "Brick without voxel at #{x},#{x},#{z}"


	getDownload: (selectedNode) =>
		dlPromise = new Promise (resolve) =>
			@_getCachedData(selectedNode).then (cachedData) =>
				detailedCsg = @_createCSG selectedNode, cachedData, true, null

				optimizedModel = new meshlib.OptimizedModel()
				optimizedModel.fromThreeGeometry(detailedCsg.geometry)

				meshlib
				.model(optimizedModel)
				.export null, (error, binaryStl) ->
					fn = "brickolage-#{selectedNode.fileName}"
					if fn.indexOf('.stl') < 0
						fn += '.stl'
					resolve { data: binaryStl, fileName: fn }

		return dlPromise

	_createCSG: (selectedNode, cachedData, addKnobs = true, csgThreeNode = null) =>
		# get optimized model and transform to actual position
		if not cachedData.optimizedThreeModel?
			cachedData.optimizedThreeModel=
				cachedData.optimizedModel.convertToThreeGeometry()
			threeModel = cachedData.optimizedThreeModel

			modelTransform = @_getModelTransforms selectedNode
			threeModel.applyMatrix(modelTransform)
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

		return printThreeMesh

	_toggleBrickLayer: () =>
		@_brickVisibility = !@_brickVisibility
		for k,v of @gridCache
			if @_brickVisibility
				v.visualization.showAll()
			else
				v.visualization.hideAll()


	_togglePrintedLayer: (isEnabled) =>
		@_printVisibility = isEnabled
		# TODO implement for NodeVisualization

	_getNodeIdentifier: (selectedNode) =>
		if selectedNode.pluginData.newBrickator?.identifier?
			return selectedNode.pluginData.newBrickator.identifier

		if not selectedNode.pluginData.newBrickator?
			selectedNode.pluginData.newBrickator = {}

		identifier = selectedNode.fileName + Math.floor(Math.random() * 10000)
		selectedNode.pluginData.newBrickator.identifier = identifier

		return identifier

	getHotkeys: =>
		return {
			title: 'newBrickator'
			events: [
				{
					hotkey: 'L'
					description: 'toggle Lego visibility'
					callback: =>
						@_toggleBrickLayer()
				}
			]
		}

	_initBuildButton: () =>
		# TODO: refactor after demo on 2015-02-26
		@buildButton = $('#buildButton')
		@buildModeEnabled = false

		@buildContainer = $('#buildContainer')
		@buildContainer.hide()
		@buildContainer.removeClass 'hidden'

		@buildLayerUi = {
			slider: $('#buildSlider')
			decrement: $('#buildDecrement')
			increment: $('#buildIncrement')
			curLayer: $('#currentBuildLayer')
			maxLayer: $('#maxBuildLayer')
			}
		
		@buildLayerUi.slider.on 'input', () =>
			selectedNode = @bundle.ui.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.increment.on 'click', () =>
			selectedNode = @bundle.ui.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v++
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.decrement.on 'click', () =>
			selectedNode = @bundle.ui.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v--
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildButton.click () =>
			selectedNode = @bundle.ui.sceneManager.selectedNode

			if @buildModeEnabled
				@buildContainer.slideUp()
				@buildButton.removeClass('active')
				@_disableBuildMode selectedNode
			else
				@buildContainer.slideDown()
				@buildButton.addClass('active')
				@_enableBuildMode selectedNode

			@buildModeEnabled = !@buildModeEnabled

	_enableBuildMode: (selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			#legofy
			settings = new PipelineSettings()
			settings.deactivateVoxelizing()

			@_applyModelTransforms selectedNode, settings

			data = {
				optimizedModel: cachedData.optimizedModel
				grid: cachedData.grid
			}
			results = @pipeline.run data, settings, true

			# ToDo: this is a workaround which needs to be fixed in layouter
			# (apply changed bricks directly to grid)
			@_applyBricksToGrid results.accumulatedResults.bricks, cachedData.grid

			# show bricks
			bricks = results.accumulatedResults.bricks
			cachedData.visualization.updateBricks bricks
			cachedData.visualization.showBricks()

			# apply grid size to layer view
			@buildLayerUi.slider.attr('min', 0)
			@buildLayerUi.slider.attr('max', cachedData.grid.zLayers.length - 1)
			@buildLayerUi.maxLayer.html(cachedData.grid.zLayers.length)
			
			@buildLayerUi.slider.val(0)
			@_updateBuildLayer selectedNode

	_updateBuildLayer: (selectedNode) =>
		layer = @buildLayerUi.slider.val()
		@buildLayerUi.curLayer.html(Number(layer) + 1)
		@_getCachedData(selectedNode).then (cachedData) =>
			cachedData.visualization.showBrickLayer layer

	_disableBuildMode: (selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.showVoxels()


