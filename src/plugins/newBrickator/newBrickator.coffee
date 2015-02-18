modelCache = require '../../client/modelCache'
LegoPipeline = require './LegoPipeline'
interactionHelper = require '../../client/interactionHelper'
THREE = require 'three'
VoxelVisualizer = require './VoxelVisualizer'
BrickVisualizer = require './BrickVisualizer'
PipelineSettings = require './PipelineSettings'
objectTree = require '../../common/project/objectTree'
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

		for child in @threejsRootNode.children
				if availableObjects.indexOf(child.uuid) < 0
					@threejsRootNode.remove child

	processFirstObject: () =>
		@bundle.statesync.performStateAction (state) =>
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
			text: 'Make LEGO'
			icon: 'legoBrush.png'
			selectCallback: @_brushSelectCallback
			mouseDownCallback: @_legoMouseDownCallback
			mouseMoveCallback: @_selectLegoMouseMoveCallback
			mouseUpCallback: @_brushMouseUpCallback
			canToggleVisibility: true
			visibilityCallback: @_toggleBrickLayer
			tooltip: 'Select geometry to be made out of LEGO'
		},{
			text: 'Make 3D printed'
			icon: '3dPrintBrush.png'
			# select / deselect are the same for both voxels,
			# but move has a different function
			selectCallback: @_brushSelectCallback
			mouseDownCallback: @_printMouseDownCallback
			mouseMoveCallback: @_select3DMouseMoveCallback
			mouseUpCallback: @_brushMouseUpCallback
			canToggleVisibility: true
			visibilityCallback: @_togglePrintedLayer
			tooltip: 'Select geometry to be 3d-printed'
		}]

	_getCachedData: (selectedNode) =>
		# returns Grid, optimized model and other cached data for the selected node
		return new Promise (resolve, reject) =>
			# ToDo handle modelPromise rejected
			identifier = selectedNode.pluginData.solidRenderer.threeObjectUuid
			nodePosition = selectedNode.positionData.position

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
		@_brushMouseDownCallback(event, selectedNode).then (cachedData) ->
			# show one layer of not-enabled (-> to be 3d printed) voxels
			# (one layer = voxel has at least one enabled neighbour)
			# so that users can re-select them

			for v in cachedData.modifiedVoxels
				c = v.voxelCoords
				
				enabledVoxels = cachedData.grid.getNeighbours c.x,
					c.y, c.z, (voxel) ->
						return voxel.enabled

				if enabledVoxels.length > 0
					v.visible = true

			return

	_printMouseDownCallback: (event, selectedNode) =>
		@_brushMouseDownCallback(event, selectedNode)

	_brushMouseDownCallback: (event, selectedNode) =>
		# create voxel grid, if it does not exist yet
		# show it
		return @_getCachedData(selectedNode).then (cachedData) =>
			threeObjects = @getThreeObjectsByNode(selectedNode)

			if not cachedData.threeNode
				cachedData.threeNode = threeObjects.voxels
				@voxelVisualizer ?= new VoxelVisualizer()
				@voxelVisualizer.createVisibleVoxels(
					cachedData.grid
					cachedData.threeNode
					true
				)
			else
				cachedData.threeNode.visible = true

			# hide bricks
			threeObjects.bricks.visible = false

			return cachedData

	_select3DMouseMoveCallback: (event, selectedNode) =>
		# disable all voxels we touch with the mouse
		obj = @_getSelectedVoxel event, selectedNode
		@_getCachedData(selectedNode).then (cachedData) =>
			if obj
				obj.material = @voxelVisualizer.deselectedMaterial
				c = obj.voxelCoords
				cachedData.grid.zLayers[c.z][c.x][c.y].enabled = false

				if cachedData.lastSelectedVoxels.indexOf(obj) < 0
					cachedData.lastSelectedVoxels.push obj

	_selectLegoMouseMoveCallback: (event, selectedNode) =>
		# enable all voxels we touch with the mouse
		obj = @_getSelectedVoxel event, selectedNode
		@_getCachedData(selectedNode).then (cachedData) =>
			if obj
				obj.material = @voxelVisualizer.selectedMaterial
				c = obj.voxelCoords
				cachedData.grid.zLayers[c.z][c.x][c.y].enabled = true

	_getSelectedVoxel: (event, selectedNode) =>
		# returns the first visible voxel (three.Object3D) that is below
		# the cursor position, if it has a voxelCoords property
		threeNodes = @getThreeObjectsByNode selectedNode

		intersects =
			interactionHelper.getPolygonClickedOn(event
				threeNodes.voxels.children
				@bundle.renderer)

		if (intersects.length > 0)
			for intersection in intersects
				obj = intersection.object
			
				if obj.visible and obj.voxelCoords
					return obj
					
		return null

	_brushMouseUpCallback: (event, selectedNode) =>
		# hide grid, then legofy
		@_getCachedData(selectedNode).then (cachedData) =>
			cachedData.threeNode.visible = false

			# hide voxels that have been deselected in the last brush
			# action to allow to go go into the model
			for v in cachedData.lastSelectedVoxels
				v.visible = false
				cachedData.modifiedVoxels.push v
			cachedData.lastSelectedVoxels = []

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

			#create CSG (todo: move to webWorker)
			printThreeMesh = @_createCSG(selectedNode, cachedData, threeNodes.csg)
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


	_createCSG: (selectedNode, cachedData, csgThreeNode = null) =>
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
			grid: cachedData.grid
			knobSize: PipelineSettings.legoKnobSize
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
