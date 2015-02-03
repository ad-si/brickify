modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
BrickVisualizer = require './BrickVisualizer'
PipelineSettings = require './PipelineSettings'
objectTree = require '../../common/objectTree'
three = require 'three'
Brick = require './Brick'
BrickLayouter = require './BrickLayouter'

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

		threeNode = @getThreeObjectByNode selectedNode
		@voxelVisualizer.clear(threeNode)
		
		settings = new PipelineSettings()

		#ToDo (future): add rotation and scaling (the same way it's done in three)
		#to keep visual consistency
		modelTransform = new THREE.Matrix4()
		pos = selectedNode.positionData.position
		modelTransform.makeTranslation(pos.x, pos.y, pos.z)

		settings.setModelTransform modelTransform
		if @debugVoxel?
			settings.setDebugVoxel @debugVoxel.x, @debugVoxel.y, @debugVoxel.z

		results = @pipeline.run optimizedModel, settings, true

		@voxelVisualizer.createVisibleVoxels(
			results.accumulatedResults.grid
			threeNode
			false
		)

		@brickVisualizer ?= new BrickVisualizer()
		@brickVisualizer.createVisibleBricks(
			threeNode,
			results.accumulatedResults.bricks,
			results.accumulatedResults.grid
		)

	getThreeObjectByNode: (node) =>
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectUuid
			for node in @threejsRootNode.children
				return node if node.uuid == uuid
		object = new THREE.Object3D()
		@threejsRootNode.add object
		node.pluginData.newBrickator = {'threeObjectUuid': object.uuid}
		return object

	getBrushes: () =>
		return [{
			text: 'Make Lego'
			icon: 'move'
			selectCallback: @_selectLegoBrushSelectCallback
			#deselectCallback: -> console.log 'dummy-brush was deselected'
			mouseDownCallback: @_selectLegoMouseDownCallback
			mouseMoveCallback: @_selectLegoMouseMoveCallback
			mouseUpCallback: @_selectLegoMouseUpCallback
		},{
			text: 'Make 3D printed'
			icon: 'move'
			#selectCallback: -> console.log 'dummy-brush was selected'
			#deselectCallback: -> console.log 'dummy-brush was deselected'
			mouseDownCallback: @_legofyBrushCallback
			#mouseMoveCallback: @_handleMouseMove
			#mouseUpCallback: @_handleMouseUp
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
			
		threeNode = @getThreeObjectByNode selectedNode
		settings = new PipelineSettings()

		#ToDo (future): add rotation and scaling (the same way it's done in three)
		#to keep visual consistency
		modelTransform = new THREE.Matrix4()
		pos = selectedNode.positionData.position
		modelTransform.makeTranslation(pos.x, pos.y, pos.z)
		settings.setModelTransform modelTransform
		settings.deactivateLayouting()

		results = @pipeline.run optimizedModel, settings, true

		@gridCache[identifier] = {
			grid: results.accumulatedResults.grid
			threeNode: null
			x: nodePosition.x
			y: nodePosition.y
			z: nodePosition.z
		}
		return @gridCache[identifier]

	_selectLegoBrushSelectCallback: (selectedNode) =>
		# get optimized model that is selected and store in local cache
		if not selectedNode
			return

		id = selectedNode.meshHash

		if @optimizedModelCache[id]?
			return
		else
			modelCache.request(id).then(
				(optimizedModel) =>
					@optimizedModelCache[id] = optimizedModel
			)

	_selectLegoMouseDownCallback: (event, selectedNode) =>
		if not selectedNode
			return

		grid = @_getGrid selectedNode

		if not grid.threeNode
			grid.threeNode = new THREE.Object3D()
			@threejsRootNode.add grid.threeNode
			@voxelVisualizer ?= new VoxelVisualizer()
			@voxelVisualizer.createVisibleVoxels(
				grid.grid
				grid.threeNode
				false
			)
		else
			grid.threeNode.visible = true

	_selectLegoMouseMoveCallback: (event, selectedNode) =>
		###
		intersects =
			interactionHelper.getPolygonClickedOn(event
				@threejsRootNode.children
				@bundle.renderer)
		if (intersects.length > 0)
			obj = intersects[0].object
			obj.material = new THREE.MeshLambertMaterial({
				color: 0xdf004c
				opacity: 0.5
				transparent: true
			})
			console.log "Setting debug voxel to:
			x: #{obj.voxelCoords.x} y: #{obj.voxelCoords.y} z: #{obj.voxelCoords.z}"

			@debugVoxel = obj.voxelCoords
		###
		return

	_selectLegoMouseUpCallback: (event, selectedNode) =>
		if not selectedNode
			return

		grid = @_getGrid selectedNode
		grid.threeNode.visible = false
