modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
objectTree = require '../../common/objectTree'

module.exports = class NewBrickator
	constructor: () ->
		# smallest lego brick
		@baseBrick = {
			length: 8
			width: 8
			height: 3.2
		}
		@pipeline = new LegoPipeline(@baseBrick)

	init: (@bundle) => return
	init3d: (@threejsRootNode) => return

	getConvertUiSchema: () =>
		legoCallback = (selectedNode) =>
			@runLegoPipelineOnNode selectedNode

		return {
		title: 'NewBrickator'
		type: 'object'
		actions:
			a1:
				title: 'Legofy'
				callback: legoCallback
		}

	onClick: (event) =>
		intersects =
			interactionHelper.getPolygonClickedOn(event
				@threejsRootNode.children
				@bundle.renderer)
		if (intersects.length > 0)
			obj = intersects[0].object
			###
			@threejsRootNode.remove obj
			###
			obj.material = new THREE.MeshLambertMaterial({
				color: 0xdf004c
				opacity: 0.5
				transparent: true
			})
			console.log "Setting debug voxel to:
			x: #{obj.voxelCoords.x} y: #{obj.voxelCoords.y} z: #{obj.voxelCoords.z}"

			@debugVoxel = obj.voxelCoords

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

		settings = {
			debugVoxel: @debugVoxel
		}

		results = @pipeline.run optimizedModel, settings, true
		grid = results.lastResult

		@voxelVisualizer.createVisibleVoxels grid, threeNode, false

	getThreeObjectByNode: (node) =>
		if node.pluginData.newBrickator?
			uuid = node.pluginData.newBrickator.threeObjectUuid
			for node in @threejsRootNode.children
				return node if node.uuid == uuid
		object = new THREE.Object3D()
		@threejsRootNode.add object
		node.pluginData.newBrickator = {'threeObjectUuid': object.uuid}
		object

	getBrushes: =>
		return [{
			text: 'Legofy'
			icon: 'move'
			mouseDownCallback: @_legofyBrushCallback
			#mouseMoveCallback: @_handleMouseMove
			#mouseUpCallback: @_handleMouseUp
		}]

	_legofyBrushCallback: (event, selectedNode) =>
		if selectedNode?
			@runLegoPipelineOnNode selectedNode
