GeometryCreator = require './GeometryCreator'
THREE = require 'three'
Coloring = require './Coloring'
StabilityColoring = require './StabilityColoring'
interactionHelper = require '../../../client/interactionHelper'
VoxelWireframe = require './VoxelWireframe'

# This class represents the visualization of Voxels and Bricks
module.exports = class BrickVisualization
	constructor: (@bundle, @threeNode) ->
		@csgSubnode = new THREE.Object3D()
		@threeNode.add @csgSubnode

		@voxelBrickSubnode = new THREE.Object3D()
		@voxelsSubnode = new THREE.Object3D()
		@voxelBrickSubnode.add @voxelsSubnode
		@bricksSubnode = new THREE.Object3D()
		@voxelBrickSubnode.add @bricksSubnode

		@defaultColoring = new Coloring()
		@stabilityColoring = new StabilityColoring()

		@currentlyTouchedVoxels = []
		@modifiedVoxels = []

		@isStabilityView = false

	initialize: (@grid) =>
		@voxelWireframe = new VoxelWireframe(@bundle, @grid, @voxelBrickSubnode)
		@threeNode.add @voxelBrickSubnode
		@geometryCreator = new GeometryCreator(@grid)

	showVoxels: =>
		@voxelsSubnode.visible = true
		@bricksSubnode.visible = false

	showBricks: =>
		# update visualization if needed
		if @bricksVisualizationNeedsUpdate
			@updateBrickVisualization()

		@bricksSubnode.visible = true
		@voxelsSubnode.visible = false

	showCsg: (newCsgMesh = null) =>
		if newCsgMesh?
			@csgSubnode.children = []
			@csgSubnode.add newCsgMesh
			newCsgMesh.material = @defaultColoring.csgMaterial

		@csgSubnode.visible = true

	hideCsg: =>
		@csgSubnode.visible = false

	hideVoxelAndBricks: =>
		@voxelBrickSubnode.visible = false

	showVoxelAndBricks: =>
		@voxelBrickSubnode.visible  = true

	# (re)creates voxel visualization.
	# hides disabled voxels, updates material and stud visibility
	updateVoxelVisualization: (coloring = @defaultColoring, recreate = false) =>
		if not @voxelsSubnode.children or @voxelsSubnode.children.length == 0 or
		recreate
			@_createVoxelVisualization coloring
			return

		# update materials and show/hide studs
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

	# makes disabled voxels invisible, toggles stud visibility
	_updateVoxel: (threeBrick) =>
		if not threeBrick.isLego()
			threeBrick.visible = false

		coords = threeBrick.voxelCoords
		if @grid.getVoxel(coords.x, coords.y, coords.z + 1)?.enabled
			threeBrick.setStudVisibility false
		else
			threeBrick.setStudVisibility true

	# updates the brick reference datastructure and marks brick visualization dirty
	# if bricks are not currently shown
	updateBricks: (@bricks) =>
		if @bricksSubnode.visible
			# update visualization instantly because we are looking at bricks
			@updateBrickVisualization()
		else
			# update visualization if we need it
			@bricksVisualizationNeedsUpdate = true
		return

	setStabilityView: (enabled) =>
		@isStabilityView = enabled
		coloring = if @isStabilityView then @stabilityColoring else @defaultColoring
		@updateBrickVisualization(coloring)

		# Turn off possible lego box during stability view
		if enabled
			@_legoBoxVisibilityBeforeStability = @voxelWireframe.isVisible()
			@voxelWireframe.setVisibility false
		else
			@voxelWireframe.setVisibility @_legoBoxVisibilityBeforeStability
		return


	updateBrickVisualization: (coloring = @defaultColoring) =>
		@bricksVisualizationNeedsUpdate = false
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

			@currentlyHighlightedVoxel = voxel
			voxel.setHighlight true, @defaultColoring.highlightMaterial
		else
			# clear highlight if no voxel is below mouse
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false

		return voxel

	# makes the voxel below mouse to be 3d printed
	makeVoxel3dPrinted: (event, selectedNode, bigBrush) =>
		voxels = @getVoxels event, selectedNode, true, bigBrush
		return null unless voxels

		for voxel in voxels
			if voxel and voxel.isLego()
				voxel.make3dPrinted()
				voxel.setMaterial @defaultColoring.deselectedMaterial
				@currentlyTouchedVoxels.push voxel
		return voxels

	resetTouchedVoxelsToLego: =>
		for voxel in @currentlyTouchedVoxels
			voxel.makeLego()
		@currentlyTouchedVoxels = []

	# makes the voxel below mouse to be made out of lego
	makeVoxelLego: (event, selectedNode, bigBrush) =>
		voxels = @getVoxels event, selectedNode, false, bigBrush
		return null unless voxels

		for voxel in voxels
			if voxel and not voxel.isLego()
				voxel.makeLego()
				voxel.visible = true
				voxel.setMaterial @defaultColoring.selectedMaterial
				@currentlyTouchedVoxels.push voxel
		return voxels

	resetTouchedVoxelsTo3dPrinted: =>
		for voxel in @currentlyTouchedVoxels
			voxel.make3dPrinted()
		@currentlyTouchedVoxels = []

	# moves all currenly touched voxels to modified voxels
	updateModifiedVoxels: =>
		for v in @currentlyTouchedVoxels
			@modifiedVoxels.push v

		touchedVoxels = @currentlyTouchedVoxels.slice 0
		@currentlyTouchedVoxels = []
		return touchedVoxels

	getVoxels: (event, selectedNode, needsToBeLego, bigBrush) =>
		mainVoxel = @getVoxel event, selectedNode, needsToBeLego
		return null unless mainVoxel

		voxels = []
		voxels.push mainVoxel
		return voxels

	# returns the first visible or raycasterSelectable voxel below the mouse cursor
	getVoxel: (event, selectedNode, needsToBeLego = false) =>
		# Get the first lego voxel. cancel if we are above a voxel that
		# has been handeled in this brush action
		voxels = @_getIntersectedVoxels event, selectedNode
		return null if not voxels?
		firstLegoVoxel = voxels[0]
		lastNonLegoVoxel = voxels[1]


		# if we may only select lego voxels, we are done
		if needsToBeLego
			return firstLegoVoxel

		# return the last non-visible voxel to prevent occlusion
		if firstLegoVoxel?
			if not lastNonLegoVoxel?
				return null

			# to prevent unecpected selection behavior, it is required
			# that both voxels are neighbors (otherwise strange
			# results appear if selecting lego through model geometry)
			if @_voxelsAreNeighbor lastNonLegoVoxel, firstLegoVoxel
				return lastNonLegoVoxel
		else
			# if there is no lego voxel, maybe we are pointing at the baseplate?
			if @_pointsTowardsBaseplate event
				return lastNonLegoVoxel

		# no lego voxel and not pointing towards the baseplate.
		# return voxel in middle of what could be lego as a last chance
		return @_getVoxelInMiddleOfPossibleLego event, selectedNode


	# returnes the first intersected lego voxel and
	# the last intersected non-lego voxel.
	# returns null, if cursor is above a currently modified voxel
	_getIntersectedVoxels: (event, selectedNode) ->
		voxelIntersects =
			interactionHelper.getIntersections(
				event
				@bundle.renderer
				@voxelsSubnode.children
			)

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

		return [firstLegoVoxel, lastNonLegoVoxel]

	# returns true if both voxels are neigbours, meaning there is
	# a maximum square distance of two
	_voxelsAreNeighbor: (a, b) ->
		c0 = a.voxelCoords
		c1 = b.voxelCoords

		sqDistance = Math.pow (c0.x - c1.x), 2
		sqDistance += Math.pow (c0.y - c1.y), 2
		sqDistance += Math.pow (c0.z - c1.z), 2

		return (sqDistance <= 2)

	# returns true if the mouse points to a baseplate position where there
	# is a voxel in the grid
	_pointsTowardsBaseplate: (event) ->
		baseplatePosition =
			interactionHelper.getGridPosition event, @bundle.renderer
		baseplateVoxelPosition =
			@grid.mapGridToVoxel @grid.mapWorldToGrid baseplatePosition

		bpvp = baseplateVoxelPosition
		return (@grid.zLayers[bpvp.z]?[bpvp.x]?[bpvp.y]?)

	# returns the voxel in the middle of the model
	_getVoxelInMiddleOfPossibleLego: (event, selectedNode) ->
		modelIntersects = @voxelWireframe.intersectRay event

		# calculate the middle of the first two intersections
		# and return voxel at this position
		if modelIntersects.length >= 2
			modelStart = modelIntersects[0]
			modelEnd = modelIntersects[1]

			middle = {
				x: (modelStart.point.x + modelEnd.point.x) / 2
				y: (modelStart.point.y + modelEnd.point.y) / 2
				z: (modelStart.point.z + modelEnd.point.z) / 2
			}

			# reverse scene transform
			revTransform = new THREE.Matrix4()
			revTransform.getInverse @bundle.renderer.scene.matrix
			middle = new THREE.Vector3(middle.x, middle.y, middle.z)
			middle.applyMatrix4(revTransform)

			middleVoxel = @grid.mapGridToVoxel @grid.mapWorldToGrid middle

			gridEntry = @grid.zLayers[middleVoxel.z][middleVoxel.x][middleVoxel.y]
			return gridEntry.visibleVoxel if gridEntry?
			return null
		else
			# no model selected / enough intersections to get a 'middle voxel'
			return null

	# merge together intersects that are nearly at the same position
	# (happens when the cursor is above the edge of two polygons)
	_mergeIdenticalIntersects: (intersects) ->
		newIntersects  = []
		for i in [0..intersects.length - 2] by 1
			intersect1 = intersects[i]
			intersect2 = intersects[i + 1]

			intersectDistance = intersect2.distance - intersect1.distance
			if intersectDistance < 3
				# only push one intersection of two
				newIntersects.push intersect1 if not intersect1.pushed
			else
				# push both if they haven't been pushed to the list
				newIntersects.push intersect1 if not intersect1.pushed
				newIntersects.push intersect2 if not intersect2.pushed

			# mark both intersections as used/pushed
			intersect1.pushed = true
			intersect2.pushed = true
		return newIntersects
