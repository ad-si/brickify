GeometryCreator = require './GeometryCreator'
THREE = require 'three'
Coloring = require './Coloring'
interactionHelper = require '../../../client/interactionHelper'
VoxelWireframe = require './VoxelWireframe'

# This class represents the visualization of a node in the scene
module.exports = class NodeVisualization
	constructor: (@bundle, @threeNode, @grid) ->
		@csgSubnode = new THREE.Object3D()
		@threeNode.add @csgSubnode

		@voxelBrickSubnode = new THREE.Object3D()
		@voxelsSubnode = new THREE.Object3D()
		@voxelBrickSubnode.add @voxelsSubnode
		@bricksSubnode = new THREE.Object3D()
		@voxelBrickSubnode.add @bricksSubnode

		@voxelWireframe = new VoxelWireframe(@grid, @voxelBrickSubnode)
		@threeNode.add @voxelBrickSubnode

		@defaultColoring = new Coloring()
		@geometryCreator = new GeometryCreator(@grid)

		@currentlyTouchedVoxels = []
		@modifiedVoxels = []

		@solidRenderer = @bundle.getPlugin('solid-renderer')
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
			if not v.isLego()
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
		if not threeBrick.isLego()
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
	highlightVoxel: (event, selectedNode, needsToBeLego) =>
		voxel = @getVoxel event, selectedNode, needsToBeLego
		if voxel?
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false

			if condition?
				return if not condition(voxel)

			@currentlyHighlightedVoxel = voxel
			voxel.setHighlight true, @defaultColoring.highlightMaterial

		return voxel

	# makes the voxel below mouse to be 3d printed
	makeVoxel3dPrinted: (event, selectedNode) =>
		voxel = @getVoxel event, selectedNode, true

		if voxel and voxel.isLego()
			voxel.make3dPrinted()
			voxel.setMaterial @defaultColoring.deselectedMaterial
			@currentlyTouchedVoxels.push voxel
			return voxel
		return null

	# makes the voxel below mouse to be made out of lego
	makeVoxelLego: (event, selectedNode) =>
		voxel = @getVoxel event, selectedNode, false
		if voxel and not voxel.isLego()
			voxel.makeLego()
			voxel.visible = true
			voxel.setMaterial @defaultColoring.selectedMaterial
			@currentlyTouchedVoxels.push voxel
			return voxel
		return null

	# moves all currenly touched voxels to modified voxels
	updateModifiedVoxels: () =>
		for v in @currentlyTouchedVoxels
			@modifiedVoxels.push v

		@currentlyTouchedVoxels = []

	# returns the first visible or raycasterSelectable voxel below the mouse cursor
	getVoxel: (event, selectedNode, needsToBeLego = false) =>
		voxelIntersects =
			interactionHelper.getPolygonClickedOn(
				event
				@voxelsSubnode.children
				@bundle.renderer)

		# Get the first lego voxel. cancel if we are above a voxel that
		# has been handeled in this brush action
		firstLegoVoxel = null
		lastNonLegoVoxel = null
		for intersection in voxelIntersects
			voxel = intersection.object.parent
			continue if not voxel.voxelCoords?
			# cancel if we are above a voxel we just modified
			return null if @currentlyTouchedVoxels.indexOf(voxel) >= 0

			if voxel.isLego()
				firstLegoVoxel = voxel
				break
			else
				lastNonLegoVoxel = voxel

		# if we may only select visible voxels, we are done
		if needsToBeLego
			return firstLegoVoxel

		if firstLegoVoxel?
			# return the last non-visible voxel (to prevent occlusion)
			return lastNonLegoVoxel
		else
			# either, we are pointing at the baseplate, then return
			# the voxel on the baseplate. or, if we are pointing into the model
			# return the voxel in the middle of the model
			baseplatePosition =
				@bundle.renderer.getGridPosition(event.pageX, event.pageY)
			baseplateVoxelPosition =
				@grid.mapGridToVoxel @grid.mapWorldToGrid baseplatePosition

			bpvp = baseplateVoxelPosition
			if @grid.zLayers[bpvp.z]?[bpvp.x]?[bpvp.y]?
				return lastNonLegoVoxel

			# this is not pointing towards the baseplate. return voxel in middle of model
			# Model material needs to be side = THREE.DoubleSide
			# TODO: intersectionCoordinates are somehow broken, does not work yet
			if @solidRenderer?
				modelIntersects = @solidRenderer.intersectRayWithModel event, selectedNode
			else
				modelIntersects = []

			console.log "Model intersects: #{modelIntersects.length}"

			if modelIntersects.length >= 2
				modelStart = modelIntersects[0]
				modelEnd = modelIntersects[1]

				middle = {
					x: (modelStart.point.x + modelEnd.point.x) / 2
					y: (modelStart.point.y + modelEnd.point.y) / 2
					z: (modelStart.point.z + modelEnd.point.z) / 2
				}

				middleVoxel = @grid.mapGridToVoxel @grid.mapWorldToGrid middle

				#return if valid grid coordinates (should always be the case)
				if @grid.zLayers[middleVoxel.z]?[middleVoxel.x]?[middleVoxel.y]?
					gridEntry = @grid.zLayers[middleVoxel.z][middleVoxel.x][middleVoxel.y]
					return gridEntry.visibleVoxel
				else
					console.warn 'Middle of model seemed not to be filled with voxel'
					console.warn middle
					console.warn middleVoxel
			else
				# we didn't point at anything useful
				return null









