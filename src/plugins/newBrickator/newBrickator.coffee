modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
BrickVisualizer = require './BrickVisualizer'
PipelineSettings = require './PipelineSettings'
objectTree = require '../../common/objectTree'
THREE = require 'three'
Brick = require './Brick'
BrickLayouter = require './BrickLayouter'
ThreeCSG = require './threeCSG/ThreeCSG'

module.exports = class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()
		@brickLayouter = new BrickLayouter()
		@gridCache = {}
		@optimizedModelCache = {}

	init: (@bundle) => return
	init3d: (@threejsRootNode) => return

	onStateUpdate: (state) =>
		#delete voxel visualizations for deleted objects
		availableObjects = []
		objectTree.forAllSubnodeProperties state.rootNode,
			'newBrickator',
			(property) ->
				availableObjects.push property.threeObjectUuid

		for child in @threejsRootNode.children
				if availableObjects.indexOf(child.uuid) < 0
					@threejsRootNode.remove @threeObjects[key]

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
		#ToDo (future): add rotation and scaling (the same way it's done in three)
		#to keep visual consistency

		modelTransform = new THREE.Matrix4()
		pos = selectedNode.positionData.position
		modelTransform.makeTranslation(pos.x, pos.y, pos.z)
		pipelineSettings.setModelTransform modelTransform

	getThreeObjectsByNode: (node) =>
		# search for subnode for this object
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectUuid
			for threenode in @threejsRootNode.children
				if threenode.uuid == uuid
					return { voxels: threenode.children[0], bricks: threenode.children[1] }

		#create two sub-sub nodes, one for the voxels and one for the bricks
		object = new THREE.Object3D()
		@threejsRootNode.add object

		voxelObject = new THREE.Object3D()
		object.add voxelObject
		brickObject = new THREE.Object3D()
		object.add brickObject
		node.pluginData.newBrickator = { threeObjectUuid: object.uuid }

		return { voxels: object.children[0], bricks: object.children[1] }

	getBrushes: () =>
		return [{
			text: 'Make Lego'
			icon: 'legoBrush.png'
			selectCallback: @_brushSelectCallback
			#deselectCallback: -> console.log 'dummy-brush was deselected'
			mouseDownCallback: @_brushMouseDownCallback
			mouseMoveCallback: @_selectLegoMouseMoveCallback
			mouseUpCallback: @_brushMouseUpCallback
		},{
			text: 'Make 3D printed'
			icon: '3dPrintBrush.png'
			# select / deselect are the same for both voxels,
			# but move has a different function
			selectCallback: @_brushSelectCallback
			#deselectCallback: -> console.log 'dummy-brush was deselected'
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
		threeNodes.bricks.visible = true

	getSubtractiveCsg: (selectedNode) =>
		# return lego brick csg for this node, so that only
		# parts that are not created with lego get 3d printed
		# ToDo

		return null
