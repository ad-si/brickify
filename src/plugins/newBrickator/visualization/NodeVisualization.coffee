GeometryCreator = require './GeometryCreator'
THREE = require 'three'
Coloring = require './Coloring'
interactionHelper = require '../../../client/interactionHelper'
VoxelWireframe = require './VoxelWireframe'

# This class represents the visualization of a node in the scene
module.exports = class NodeVisualization
	constructor: (@bundle, @threeNode, @grid) ->
		@voxelBrickSubnode = new THREE.Object3D()
		@voxelsSubnode = new THREE.Object3D()
		@bricksSubnode = new THREE.Object3D()
		@csgSubnode = new THREE.Object3D()

		@threeNode.add @voxelBrickSubnode
		@voxelBrickSubnode.add @voxelsSubnode
		@voxelBrickSubnode.add @bricksSubnode
		@voxelWireframe = new VoxelWireframe(@grid, @voxelBrickSubnode)

		@threeNode.add @csgSubnode

		@defaultColoring = new Coloring()
		@geometryCreator = new GeometryCreator(@grid)

		@currentlyDeselectedVoxels = []
		@modifiedVoxels = []

	showVoxels: () =>
		@voxelsSubnode.visible = true
		@bricksSubnode.visible = false

	showBricks: () =>
		@bricksSubnode.visible = true
		@voxelsSubnode.visible = false

	showCsg: (newCsgMesh = null) =>
		if newCsgMesh?
			@csgSubnode.children = []
			@csgSubnode.add newCsgMesh
			newCsgMesh.material = @defaultColoring.csgMaterial

		@csgSubnode.visible = true

	hideCsg: () =>
		@csgSubnode.visible = false

	hideVoxelAndBricks: () =>
		@voxelBrickSubnode.visible = false

	showVoxelAndBricks: () =>
		@voxelBrickSubnode.visible  = true

	# (re)creates voxel visualization.
	# hides disabled voxels, updates material and knob visibility
	updateVoxelVisualization: (coloring = @defaultColoring, recreate = false) =>
		if not @voxelsSubnode.children or @voxelsSubnode.children.length == 0 or
		recreate
			@_createVoxelVisualization coloring
			return

		# update materials and show/hide knobs
		for v in @voxelsSubnode.children
			# get material
			material = coloring.getMaterialForVoxel v.gridEntry
			v.setMaterial material
			@_updateVoxel v

		# show not filled lego shape as outline
		outlineVoxels = []
		for v in @modifiedVoxels
			if not v.isEnabled()
				outlineVoxels.push {
					x: v.voxelCoords.x
					y: v.voxelCoords.y
					z: v.voxelCoords.z
				}
		@voxelWireframe.createWireframe outlineVoxels

	setPossibleLegoBoxVisibility: (isVisible) =>
		@voxelWireframe.setVisibility isVisible

	# clear and create voxel visualization
	_createVoxelVisualization: (coloring) =>
		@voxelsSubnode.children = []

		for z in [0..@grid.numVoxelsZ - 1] by 1
			for x in [0..@grid.numVoxelsX - 1] by 1
				for y in [0..@grid.numVoxelsY - 1] by 1
					if @grid.zLayers[z]?[x]?[y]?
						voxel = @grid.zLayers[z][x][y]
						material = coloring.getMaterialForVoxel voxel
						threeBrick = @geometryCreator.getVoxel {x: x, y: y, z: z}, material
						@_updateVoxel threeBrick
						@voxelsSubnode.add threeBrick

	# makes disabled voxels invisible, toggles knob visibility
	_updateVoxel: (threeBrick) =>
		if not threeBrick.isEnabled()
			threeBrick.visible = false

		coords = threeBrick.voxelCoords
		if @grid.getVoxel(coords.x, coords.y, coords.z + 1)?.enabled
			threeBrick.setKnobVisibility false
		else
			threeBrick.setKnobVisibility true

	updateBricks: (@bricks) =>
		@updateBrickVisualization()
		return

	updateBrickVisualization: (coloring = @defaultColoring) =>
		@bricksSubnode.children = []

		for brickLayer in @bricks
			layerObject = new THREE.Object3D()
			@bricksSubnode.add layerObject

			for brick in brickLayer
				material = coloring.getMaterialForBrick brick
				threeBrick = @geometryCreator.getBrick brick.position, brick.size, material
				layerObject.add threeBrick

	showBrickLayer: (layer) =>
		for i in [0..@bricksSubnode.children.length - 1] by 1
			if i <= layer
				@bricksSubnode.children[i].visible = true
			else
				@bricksSubnode.children[i].visible = false

		@showBricks()

	# highlights the voxel below mouse and returns it
	highlightVoxel: (event, condition) =>
		voxel = @getVoxel event

		if voxel?
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false

			if condition?
				return if not condition(voxel)

			@currentlyHighlightedVoxel = voxel
			voxel.setHighlight true, @defaultColoring.highlightMaterial

		return voxel

	# disables the voxel below mouse
	deselectVoxel: (event) =>
		voxel = @getVoxel event

		if voxel and voxel.isEnabled()
			voxel.disable()
			voxel.setRaycasterSelectable false
			voxel.setMaterial @defaultColoring.deselectedMaterial
			@currentlyDeselectedVoxels.push voxel
			return voxel
		return null

	# enables the voxel below mouse
	selectVoxel: (event) =>
		voxel = @getVoxel event

		if voxel and not voxel.isEnabled()
			voxel.enable()
			voxel.visible = true
			voxel.setMaterial @defaultColoring.selectedMaterial
			return voxel
		return null

	# moves all currenly deselected voxels
	# to modified voxels
	updateModifiedVoxels: () =>
		for v in @currentlyDeselectedVoxels
			@modifiedVoxels.push v

		@currentlyDeselectedVoxels = []

	# out of all voxels that can be enabled, create an
	# invisible layer (selectable = true) so that the user can select
	# them via raycaster and the selected voxel can be highlighted
	createInvisibleSuggestionBricks: () =>
		newModifiedVoxel = []

		for v in @modifiedVoxels
			# ignore and removed enabled voxel
			if v.isEnabled()
				continue
			newModifiedVoxel.push v

			c = v.voxelCoords

			#check if there is at least one connection to an enabled voxel
			enabledVoxels = @grid.getNeighbours c.x,
				c.y, c.z, (voxel) ->
					return voxel.enabled

			connectedToEnabled = false
			if enabledVoxels.length > 0
				connectedToEnabled = true

			# has this voxel a not selected voxel below
			# (preventing unselectable voxels)
			# could be optimized by not using the (z-)-layer as "below",
			# but the layer the camera is currently facing towards
			freeBelow = true
			if @grid.zLayers[c.z - 1]?[c.x]?[c.y]?
				if  @grid.zLayers[c.z - 1][c.x][c.y].enabled == false
					freeBelow = false

			if freeBelow and connectedToEnabled
				v.setRaycasterSelectable true
			else
				v.setRaycasterSelectable false

		@modifiedVoxels = newModifiedVoxel

	clearInvisibleSuggestionBricks: () =>
		for v in @modifiedVoxels
			v.setRaycasterSelectable false

	# returns the first visible or selectable voxel below the mouse cursor
	getVoxel: (event) =>
		intersects =
			interactionHelper.getPolygonClickedOn(
				event
				@voxelsSubnode.children
				@bundle.renderer)

		if (intersects.length > 0)
			for intersection in intersects
				obj = intersection.object.parent
			
				if obj.voxelCoords and (obj.visible or obj.raycasterSelectable)
					return obj

		return null






