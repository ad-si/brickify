modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
objectTree = require '../../common/state/objectTree'
BrickVisualizer = require './BrickVisualizer'
PipelineSettings = require './PipelineSettings'
objectTree = require '../../common/state/objectTree'
THREE = require 'three'
Brick = require './Brick'
BrickLayouter = require './BrickLayouter'
meshlib = require('meshlib')
CsgExtractor = require './CsgExtractor'

module.exports = class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()
		@brickLayouter = new BrickLayouter()
		@gridCache = {}
		@optimizedModelCache = {}
		@csgCache = {}

		@_brickVisibility = true
		@_printVisibility = true
		
		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xfd482f #redish
		})

	init: (@bundle) => return
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
			console.log state
			node = state.rootNode.children[0]
			@runLegoPipelineOnNode node

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
			text: 'Make Lego'
			icon: 'legoBrush.png'
			selectCallback: @_brushSelectCallback
			mouseDownCallback: @_brushMouseDownCallback
			mouseMoveCallback: @_selectLegoMouseMoveCallback
			mouseUpCallback: @_brushMouseUpCallback
		},{
			text: 'Make 3D printed'
			icon: '3dPrintBrush.png'
			# select / deselect are the same for both voxels,
			# but move has a different function
			selectCallback: @_brushSelectCallback
			mouseDownCallback: @_brushMouseDownCallback
			mouseMoveCallback: @_select3DMouseMoveCallback
			mouseUpCallback: @_brushMouseUpCallback
		}]

	_getGrid: (selectedNode) =>
		# returns the voxel grid for the selected node
		# if the node has not changed position and the grid exists,
		# the cached instance is returned

		identifier = selectedNode.pluginData.solidRenderer.threeObjectUuid
		nodePosition = selectedNode.positionData.position

		if @gridCache[identifier]?
			griddata = @gridCache[identifier]

			if griddata.x == nodePosition.x and
			griddata.y == nodePosition.y and
			griddata.z == nodePosition.z
				return griddata

		optimizedModel = @optimizedModelCache[selectedNode.meshHash]
		if not optimizedModel?
			return null
			
		settings = new PipelineSettings()
		@_applyModelTransforms selectedNode, settings
		settings.deactivateLayouting()

		data = {
			optimizedModel: optimizedModel
		}
		results = @pipeline.run data, settings, true

		@gridCache[identifier] = {
			grid: results.accumulatedResults.grid
			threeNode: null
			x: nodePosition.x
			y: nodePosition.y
			z: nodePosition.z
		}
		return @gridCache[identifier]

	_brushSelectCallback: (selectedNode) =>
		# get optimized model that is selected and store in local cache
		id = selectedNode.meshHash

		if @optimizedModelCache[id]?
			return
		else
			modelCache.request(id).then(
				(optimizedModel) =>
					@optimizedModelCache[id] = optimizedModel
			)

	_brushMouseDownCallback: (event, selectedNode) =>
		# create voxel grid, if it does not exist yet
		# show it
		grid = @_getGrid selectedNode
		threeObjects = @getThreeObjectsByNode(selectedNode)

		if not grid.threeNode
			grid.threeNode = threeObjects.voxels
			@voxelVisualizer ?= new VoxelVisualizer()
			@voxelVisualizer.createVisibleVoxels(
				grid.grid
				grid.threeNode
				false
			)
		else
			grid.threeNode.visible = true

		# hide bricks
		threeObjects.bricks.visible = false

	_select3DMouseMoveCallback: (event, selectedNode) =>
		# disable all voxels we touch with the mouse
		obj = @_getSelectedVoxel event, selectedNode
		grid = @_getGrid selectedNode

		if obj
			obj.material = @voxelVisualizer.deselectedMaterial
			c = obj.voxelCoords
			grid.grid.zLayers[c.z][c.x][c.y].enabled = false

	_selectLegoMouseMoveCallback: (event, selectedNode) =>
		# enable all voxels we touch with the mouse
		obj = @_getSelectedVoxel event, selectedNode
		grid = @_getGrid selectedNode

		if obj
			obj.material = @voxelVisualizer.selectedMaterial
			c = obj.voxelCoords
			grid.grid.zLayers[c.z][c.x][c.y].enabled = true

	_getSelectedVoxel: (event, selectedNode) =>
		# returns the first visible voxel (three.Object3D) that is below
		# the cursor position, if it has a voxelCoords property
		threeNodes = @getThreeObjectsByNode selectedNode

		intersects =
			interactionHelper.getPolygonClickedOn(event
				threeNodes.voxels.children
				@bundle.renderer)

		if (intersects.length > 0)
			obj = intersects[0].object
			
			if obj.voxelCoords
				return obj
		return null


	_brushMouseUpCallback: (event, selectedNode) =>
		# hide grid, then legofy
		grid = @_getGrid selectedNode
		grid.threeNode.visible = false

		# legofy
		settings = new PipelineSettings()
		@_applyModelTransforms selectedNode, settings
		settings.deactivateVoxelizing()

		optimizedModel = @optimizedModelCache[selectedNode.meshHash]
		if not optimizedModel
			return

		data = {
			optimizedModel: optimizedModel
			grid: grid.grid
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

		#create CSG (todo: move to webWorker)
		printThreeMesh = @_createCSG(selectedNode, threeNodes.csg)
		@csgCache[selectedNode] = printThreeMesh

	snapToGrid: (vec3) =>
		@gridSpacing ?= (new PipelineSettings()).gridSpacing
		snapCoord = (coord) =>
			vec3[coord] =
				Math.round(vec3[coord] / @gridSpacing[coord]) * @gridSpacing[coord]
		snapCoord 'x'
		snapCoord 'y'
		snapCoord 'z'
		return vec3
	
	getDownload: (selectedNode) =>
		printMesh = @csgCache[selectedNode]

		optimizedModel = new meshlib.OptimizedModel()
		optimizedModel.fromThreeGeometry(printMesh.geometry)

		dlPromise = new Promise (resolve) =>
			meshlib
			.model(optimizedModel)
			.export null, (error, binaryStl) ->
				resolve { data: binaryStl, fileName: '3dprinted.stl' }

		return dlPromise


	_createCSG: (selectedNode, csgThreeNode = null) =>
		# get optimized model and transform to actual position
		optimizedModel = @optimizedModelCache[selectedNode.meshHash]
		if not optimizedModel
			return

		threeModel = optimizedModel.convertToThreeGeometry()
		modelTransform = @_getModelTransforms selectedNode
		threeModel.applyMatrix(modelTransform)

		# create the intersection of selected voxels and the model mesh
		grid = @_getGrid(selectedNode).grid
		@csgExtractor ?= new CsgExtractor()

		options = {
			grid: grid
			knobSize: PipelineSettings.legoKnobSize
			transformedModel: threeModel
		}

		printThreeMesh = @csgExtractor.extractGeometry(grid, options)

		# show intersected mesh
		if csgThreeNode?
			printThreeMesh.material = @printMaterial
			printThreeMesh.visible = @_printVisibility
			csgThreeNode.children = []
			csgThreeNode.add printThreeMesh

		return printThreeMesh

	getVisibilityLayers: () =>
		return [
			{
				text: 'Bricks'
				callback: @_toggleBrickLayer
			},
			{
				text: '3D-printed Geometry'
				callback: @_togglePrintedLayer
			}
		]

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
