modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
THREE = require 'three'
objectTree = require '../../common/state/objectTree'
BrickVisualizer = require './BrickVisualizer'
PipelineSettings = require './PipelineSettings'
objectTree = require '../../common/state/objectTree'
THREE = require 'three'
Brick = require './Brick'
BrickLayouter = require './BrickLayouter'
meshlib = require('meshlib')
CsgExtractor = require './CsgExtractor'
BrushHandler = require './BrushHandler'

module.exports = class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()
		@brickLayouter = new BrickLayouter()
		@gridCache = {}

		@_brickVisibility = true
		@_printVisibility = true
		
		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xe7edaa
			opacity: 0.8
			transparent: true
		})

	init: (@bundle) =>
		@brushHandler = new BrushHandler(@bundle, @)

	init3d: (@threejsRootNode) => return

	onNodeRemove: (node) =>
		# remove node visuals (bricks, csg, ...)
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectUuid
			for threenode in @threejsRootNode.children
				if threenode.uuid == uuid
					@threejsRootNode.remove threenode
					return

	processFirstObject: () =>
		@bundle.statesync.performStateAction (state) =>
			if state.rootNode.children?
				node = state.rootNode.children[0]
				@runLegoPipelineOnNode node
			else
				console.error 'Unable to Legofy first object: state is empty'

	runLegoPipelineOnNode: (selectedNode) =>
		modelCache.request(selectedNode.meshHash).then(
			(optimizedModel) =>
				@runLegoPipeline optimizedModel, selectedNode
		)

	runLegoPipeline: (optimizedModel, selectedNode) =>
		@voxelVisualizer ?= new VoxelVisualizer()

		threeNodes = @getThreeObjectsByNode(selectedNode)
		
		settings = new PipelineSettings()
		@_applyModelTransforms selectedNode, settings

		data = {
			optimizedModel: optimizedModel
		}
		results = @pipeline.run data, settings, true

		@brickVisualizer ?= new BrickVisualizer()
		@brickVisualizer.createVisibleBricks(
			threeNodes.bricks,
			results.accumulatedResults.bricks,
			results.accumulatedResults.grid
		)

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

	getThreeObjectsByNode: (node) =>
		# search for subnode for this object
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectUuid
			for threenode in @threejsRootNode.children
				if threenode.uuid == uuid
					return {
						voxels: threenode.children[0]
						bricks: threenode.children[1]
						csg: threenode.children[2]
					}

		# create three sub-sub nodes, one for the voxels and one for the bricks,
		# the last one for showing the csg
		object = new THREE.Object3D()
		@threejsRootNode.add object

		voxelObject = new THREE.Object3D()
		object.add voxelObject
		brickObject = new THREE.Object3D()
		object.add brickObject
		csgObject = new THREE.Object3D()
		object.add csgObject

		node.pluginData.newBrickator = { threeObjectUuid: object.uuid }

		return {
			voxels: object.children[0]
			bricks: object.children[1]
			csg: object.children[2]
		}

	_forAllThreeObjects: (callback) =>
		for threenode in @threejsRootNode.children
			obj = {
				voxels: threenode.children[0]
				bricks: threenode.children[1]
				csg: threenode.children[2]
			}

			callback obj


	getBrushes: () =>
		return [{
			text: 'LEGO Brush'
			icon: 'legoBrush.png'
			selectCallback: @_brushSelectCallback
			mouseDownCallback: @_legoMouseDownCallback
			mouseMoveCallback: @_selectLegoMouseMoveCallback
			mouseHoverCallback: @_legoMouseHoverCallback
			mouseUpCallback: @_brushMouseUpCallback
			canToggleVisibility: true
			visibilityCallback: @_toggleBrickLayer
			tooltip: 'Select geometry to be made out of LEGO'
		},{
			text: '3D print brush'
			icon: '3dPrintBrush.png'
			# select / deselect are the same for both voxels,
			# but move has a different function
			selectCallback: @_brushSelectCallback
			mouseDownCallback: @_printMouseDownCallback
			mouseMoveCallback: @_select3DMouseMoveCallback
			mouseHoverCallback: @_printMouseHoverCallback
			mouseUpCallback: @_brushMouseUpCallback
			canToggleVisibility: true
			visibilityCallback: @_togglePrintedLayer
			tooltip: 'Select geometry to be 3d-printed'
		}]

	_getCachedData: (selectedNode) =>
		# returns Grid, optimized model and other cached data for the selected node
		return new Promise (resolve, reject) =>
			identifier = selectedNode.pluginData.solidRenderer.threeObjectUuid
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
				settings = new PipelineSettings()
				@_applyModelTransforms selectedNode, settings
				settings.deactivateLayouting()

				data = {
					optimizedModel: optimizedModel
				}
				results = @pipeline.run data, settings, true

				@gridCache[identifier] = {
					grid: results.accumulatedResults.grid
					optimizedModel: optimizedModel
					threeNode: null
					x: nodePosition.x
					y: nodePosition.y
					z: nodePosition.z
					modifiedVoxels: []
					lastSelectedVoxels: []
				}

				resolve(@gridCache[identifier])
			modelPromise.catch (error) =>
				reject error

	_legoMouseDownCallback: (event, selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			@brushHandler.legoMouseDown event, selectedNode, cachedData

	_printMouseDownCallback: (event, selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			@brushHandler.printMouseDown event, selectedNode, cachedData

	_select3DMouseMoveCallback: (event, selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			@brushHandler.printMouseMove event, selectedNode, cachedData

	_selectLegoMouseMoveCallback: (event, selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			@brushHandler.legoMouseMove event, selectedNode, cachedData

	_legoMouseHoverCallback: (event, selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			@brushHandler.legoMouseHover event, selectedNode, cachedData

	_printMouseHoverCallback: (event, selectedNode) =>
		@_getCachedData(selectedNode).then (cachedData) =>
			@brushHandler.printMouseHover event, selectedNode, cachedData

	_brushMouseUpCallback: (event, selectedNode) =>
		# hide grid, then legofy
		@_getCachedData(selectedNode).then (cachedData) =>
			@brushHandler.mouseUp event, selectedNode, cachedData

			# legofy
			settings = new PipelineSettings()
			@_applyModelTransforms selectedNode, settings
			settings.deactivateVoxelizing()

			data = {
				optimizedModel: cachedData.optimizedModel
				grid: cachedData.grid
			}
			results = @pipeline.run data, settings, true

			threeNodes = @getThreeObjectsByNode selectedNode

			@brickVisualizer ?= new BrickVisualizer()
			@brickVisualizer.createVisibleBricks(
				threeNodes.bricks,
				results.accumulatedResults.bricks,
				results.accumulatedResults.grid
			)
			threeNodes.bricks.visible = @_brickVisibility
			@_applyBricksToGrid results.accumulatedResults.bricks, cachedData.grid

			#create quick CSG (without knobs) (todo: move to webWorker)
			printThreeMesh = @_createCSG(selectedNode, cachedData, false, threeNodes.csg)

			@brushHandler.afterPipelineUpdate selectedNode, cachedData

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
					resolve { data: binaryStl, fileName: '3dprinted.stl' }

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

		# show intersected mesh if it exists
		if csgThreeNode?
			csgThreeNode.children = []
			if printThreeMesh?
				printThreeMesh.material = @printMaterial
				printThreeMesh.visible = @_printVisibility
				csgThreeNode.add printThreeMesh

		return printThreeMesh

	_toggleBrickLayer: (isEnabled) =>
		@_brickVisibility = isEnabled
		@_forAllThreeObjects (obj) ->
			if obj.bricks?
				obj.bricks.visible = isEnabled

	_togglePrintedLayer: (isEnabled) =>
		@_printVisibility = isEnabled
		@_forAllThreeObjects (obj) ->
			if obj.csg?
				obj.csg.visible = isEnabled
