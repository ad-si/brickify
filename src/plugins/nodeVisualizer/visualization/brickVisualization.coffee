GeometryCreator = require './GeometryCreator'
THREE = require 'three'
Coloring = require './Coloring'
StabilityColoring = require './StabilityColoring'
interactionHelper = require '../../../client/interactionHelper'
VoxelWireframe = require './VoxelWireframe'
VoxelSelector = require '../VoxelSelector'

###
# This class provides visualization for Voxels and Bricks
# @class BrickVisualization
###
class BrickVisualization
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

		@modifiedVoxels = []

		@isStabilityView = false

	initialize: (@grid) =>
		@voxelWireframe = new VoxelWireframe(@bundle, @grid, @voxelBrickSubnode)
		@threeNode.add @voxelBrickSubnode
		@geometryCreator = new GeometryCreator(@grid)
		@voxelSelector = new VoxelSelector @

	showVoxels: =>
		@voxelsSubnode.visible = true
		@bricksSubnode.visible = false

	showBricks: =>
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
		@unhighlightBigBrush()
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

	# updates the brick reference datastructure and updates
	# visible brick visualization
	updateBricks: (@bricks) =>
			@updateBrickVisualization()

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
	highlightVoxel: (event, selectedNode, needsToBeLego, bigBrush) =>
		voxel = @voxelSelector.getVoxel event, {type: if needsToBeLego then 'lego' else '3d'}
		if voxel?
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false

			@currentlyHighlightedVoxel = voxel
			voxel.setHighlight true, @defaultColoring.highlightMaterial
			@_highlightBigBrush voxel if bigBrush
		else
			# clear highlight if no voxel is below mouse
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false
			@unhighlightBigBrush()

		return voxel

	_highlightBigBrush: (voxel) =>
		size = @voxelSelector.getBrushSize true
		dimensions = new THREE.Vector3 size.x, size.y, size.z
		unless @bigBrushHighlight? and
		@bigBrushHighlight.dimensions.equals dimensions
			@voxelBrickSubnode.remove @bigBrushHighlight if @bigBrushHighlight
			@bigBrushHighlight = @geometryCreator.getBrickBox(
				dimensions
				@defaultColoring.boxHighlightMaterial
			)
			@voxelBrickSubnode.add @bigBrushHighlight

		@bigBrushHighlight.position.copy voxel.position
		@bigBrushHighlight.visible = true

	unhighlightBigBrush: =>
		@bigBrushHighlight?.visible = false

	# makes the voxel below mouse to be 3d printed
	makeVoxel3dPrinted: (event, selectedNode, bigBrush) =>
		if bigBrush
			mainVoxel = @voxelSelector.getVoxel event, {type: 'lego'}
			@_highlightBigBrush mainVoxel if mainVoxel?
		voxels = @voxelSelector.getVoxels event, {type: 'lego', bigBrush: bigBrush}
		return null unless voxels

		for voxel in voxels
			voxel.make3dPrinted()
			voxel.setMaterial @defaultColoring.deselectedMaterial
		return voxels

	resetTouchedVoxelsToLego: =>
		voxel.makeLego() for voxel in @voxelSelector.touchedVoxels
		@voxelSelector.clearSelection()

	# makes the voxel below mouse to be made out of lego
	makeVoxelLego: (event, selectedNode, bigBrush) =>
		if bigBrush
			mainVoxel = @voxelSelector.getVoxel event, {type: '3d'}
			@_highlightBigBrush mainVoxel if mainVoxel?
		voxels = @voxelSelector.getVoxels event, {type: '3d', bigBrush: bigBrush}
		return null unless voxels

		for voxel in voxels
			voxel.makeLego()
			voxel.visible = true
			voxel.setMaterial @defaultColoring.selectedMaterial
		return voxels

	resetTouchedVoxelsTo3dPrinted: =>
		voxel.make3dPrinted() for voxel in @voxelSelector.touchedVoxels
		@voxelSelector.clearSelection()

	# moves all currenly touched voxels to modified voxels
	updateModifiedVoxels: =>
		@modifiedVoxels = @modifiedVoxels.concat @voxelSelector.touchedVoxels
		return @voxelSelector.clearSelection()

module.exports = BrickVisualization
