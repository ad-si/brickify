GeometryCreator = require './GeometryCreator'
THREE = require 'three'
Coloring = require './Coloring'
interactionHelper = require '../../../client/interactionHelper'

# This class represents the visualization of a node in the scene
module.exports = class NodeVisualization
	constructor: (@bundle, @threeNode, @grid) ->
		@voxelsSubnode = new THREE.Object3D()
		@bricksSubnode = new THREE.Object3D()

		@threeNode.add @voxelsSubnode
		@threeNode.add @bricksSubnode

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

	hideAll: () =>
		@threeNode.visible = false

	showAll: () =>
		@threeNode.visible  = true

	updateVoxelVisualization: (coloring = @defaultColoring, recreate = false) =>
		# (re)creates voxel visualization.
		# hides disabled voxels, updates material and knob visibility

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

	_createVoxelVisualization: (coloring) =>
		# clear and create voxel visualization

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

	highlightVoxel: (event, condition) =>
		# highlights the voxel below mouse and returns it
		voxel = @getVoxel event

		if voxel?
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false

			if condition?
				return if not condition(voxel)

			@currentlyHighlightedVoxel = voxel
			voxel.setHighlight true, @defaultColoring.highlightMaterial

		return voxel

	deselectVoxel: (event) =>
		# disables the voxel below mouse
		voxel = @getVoxel event

		if voxel and voxel.isEnabled()
			voxel.disable()
			voxel.setMaterial @defaultColoring.deselectedMaterial
			@currentlyDeselectedVoxels.push voxel

	selectVoxel: (event) =>
		# enables the voxel below mouse
		voxel = @getVoxel event

		if voxel and not voxel.isEnabled()
			voxel.enable()
			voxel.setMaterial @defaultColoring.selectedMaterial

	updateModifiedVoxels: () =>
		# moves all currenly deselected voxels
		# to modified voxels

		for v in @currentlyDeselectedVoxels
			@modifiedVoxels.push v

		@currentlyDeselectedVoxels = []

	showDeselectedVoxelSuggestions: () =>
		# show one layer of not-enabled (-> to be 3d printed) voxels
		# (one layer = voxel has at least one enabled neighbour)
		# so that users can re-select them

		dir = @_getPrincipalCameraDirection @bundle.renderer.camera

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

			# check if there is an unselected voxel behind this voxel
			# (behind is always relative to the camera's direction)
			# if yes, don't show this voxel
			behindCoords = {
				x: ((c.x - 1) if dir == '-x') || ((c.x + 1) if dir == '+x') || c.x
				y: ((c.y - 1) if dir == '-y') || ((c.y + 1) if dir == '+y') || c.y
				z: ((c.z - 1) if dir == '-z') || ((c.z + 1) if dir == '+z') || c.z
			}
			bc = behindCoords

			freeBehind = true
			if @grid.zLayers[bc.z]?[bc.x]?[bc.y]?
				if  @grid.zLayers[bc.z][bc.x][bc.y].enabled == false
					freeBehind = false

			if freeBehind and connectedToEnabled
				v.setMaterial @defaultColoring.deselectedMaterial
				v.visible = true
			else
				v.visible = false

		@modifiedVoxels = newModifiedVoxel

	getVoxel: (event) =>
		# returns the first voxel below the mouse cursor
		intersects =
			interactionHelper.getPolygonClickedOn(
				event
				@voxelsSubnode.children
				@bundle.renderer)

		if (intersects.length > 0)
			for intersection in intersects
				obj = intersection.object.parent
			
				if obj.visible and obj.voxelCoords
					return obj

		return null

	_getPrincipalCameraDirection: (camera) =>
		# returns the main direction the camera is facing

		# rotate the camera's view vector according to cam rotation
		vecz = new THREE.Vector3(0,0,-1)
		vecz.applyQuaternion camera.quaternion

		# apply inverse scene matrix (to account for that the scene is rotated)
		matrix = new THREE.Matrix4()
		matrix.getInverse(@bundle.renderer.scene.matrix)
		vecz.applyMatrix4(matrix)
		vecz.normalize()

		if vecz.z > 0.5
			return '+z'
		else if vecz.z < -0.5
			return '-z'
		else if vecz.x > 0.5
			return '+x'
		else if vecz.x < -0.5
			return '-x'
		else if vecz.y > 0.5
			return '+y'
		else if vecz.y < -0.5
			return '-y'










