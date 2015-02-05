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
ThreeCSG = require './threeCSG/ThreeCSG'
meshlib = require('meshlib')

module.exports = class NewBrickator
	constructor: () ->
		@pipeline = new LegoPipeline()
		@brickLayouter = new BrickLayouter()
		@gridCache = {}
		@optimizedModelCache = {}
		@csgCache = {}

		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xfd482f #redish
		})

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
		threeNodes.bricks.visible = true

		#create CSG (todo: move to webWorker)
		geo = @_createCSG(selectedNode, threeNodes.csg)
		@csgCache[selectedNode] = geo

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
		printGeometry = @csgCache[selectedNode]

		threeGeometry = printGeometry.toMesh(null).geometry

		optimizedModel = new meshlib.OptimizedModel()
		optimizedModel.fromThreeGeometry(threeGeometry)

		dlPromise = new Promise (resolve) =>
			meshlib
			.model(optimizedModel)
			.export null, (error, binaryStl) ->
				resolve { data: binaryStl, fileName: '3dprinted.stl' }

		return dlPromise


	_createCSG: (selectedNode, csgThreeNode = null) =>
		# create the intersection of selected voxels and the model mesh

		printVoxels = []
		zRange = {}

		genKey = (x, y) ->
			return "#{x}-#{y}"

		grid = @_getGrid(selectedNode).grid

		grid.forEachVoxel (voxel, x, y, z) =>
			if not voxel.enabled
				printVoxels.push {x: x, y: y, z: z}

				range = zRange[genKey(x,y)]

				if not range?
					range = {
						lowest: z
						highest: z
					}
				if range.lowest > z
					range.lowest = z
				if range.highest < z
					range.highest = z

				zRange[genKey(x,y)] = range

		if printVoxels.length == 0
			return null

		# ToDo: merge voxels into one geometry, see issue #202

		# create voxel csg
		voxGeometry = new THREE.BoxGeometry(
			grid.spacing.x, grid.spacing.y, grid.spacing.z
		)

		knobSize = PipelineSettings.legoKnobSize

		knobRotation = new THREE.Matrix4().makeRotationX( 3.14159 / 2 )
				

		dzBottom = -(grid.spacing.z / 2) + (knobSize.height / 2)
		knobTranslationBottom = new THREE.Matrix4().makeTranslation(0,0,dzBottom)
		dzTop = (grid.spacing.z / 2) + (knobSize.height / 2)
		knobTranslationTop = new THREE.Matrix4().makeTranslation(0,0,dzTop)
		
		knobGeometryBottom = new THREE.CylinderGeometry(
			knobSize.radius, knobSize.radius, knobSize.height, 20
		)
		knobGeometryTop = new THREE.CylinderGeometry(
			knobSize.radius, knobSize.radius, knobSize.height, 20
		)

		knobGeometryBottom.applyMatrix(knobRotation)
		knobGeometryTop.applyMatrix(knobRotation)
		knobGeometryBottom.applyMatrix(knobTranslationBottom)
		knobGeometryTop.applyMatrix(knobTranslationTop)

		for voxel in printVoxels
			mesh = new THREE.Mesh(voxGeometry, null)
			mesh.translateX( grid.origin.x + grid.spacing.x * voxel.x)
			mesh.translateY( grid.origin.y + grid.spacing.y * voxel.y)
			mesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z)
			meshBsp = new ThreeBSP(mesh)

			if unionBsp?
				unionBsp = unionBsp.union(meshBsp)
			else
				unionBsp = meshBsp

			# if this is the lowes voxel to be printed, subtract a knob
			# to make it fit to lego bricks
			range = zRange[genKey(voxel.x,voxel.y)]
			if voxel.z == range.lowest
				knobMesh = new THREE.Mesh(knobGeometryBottom, null)
				knobMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
				knobMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
				knobMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

				knobBsp = new ThreeBSP(knobMesh)
				unionBsp = unionBsp.subtract knobBsp

			# if this is the highest voxel to be printed,
			# add knobs (for connecting with lego above this geometry)
			if voxel.z == range.highest
				knobMesh = new THREE.Mesh(knobGeometryTop, null)
				knobMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
				knobMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
				knobMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

				knobBsp = new ThreeBSP(knobMesh)
				unionBsp = unionBsp.union knobBsp

		#intersect with original mesh to get 3d printed stuff
		optimizedModel = @optimizedModelCache[selectedNode.meshHash]
		if not optimizedModel
			return

		modelModel = optimizedModel.convertToThreeGeometry()
		modelTransform = @_getModelTransforms selectedNode
		modelModel.applyMatrix(modelTransform)

		modelBsp = new ThreeBSP(modelModel)

		printBsp = modelBsp.intersect(unionBsp)

		#debug: show intersected mesh
		if csgThreeNode?
			printMesh = printBsp.toMesh( @printMaterial )
			csgThreeNode.children = []
			csgThreeNode.add printMesh

		return printBsp

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
		@_forAllThreeObjects (obj) ->
			if obj.bricks?
				obj.bricks.visible = isEnabled

	_togglePrintedLayer: (isEnabled) =>
		@_forAllThreeObjects (obj) ->
			if obj.csg?
				obj.csg.visible = isEnabled
