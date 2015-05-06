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
	constructor: (
		@bundle,  @brickThreeNode, @brickShadowThreeNode, @defaultColoring) ->

		@csgSubnode = new THREE.Object3D()
		@brickThreeNode.add @csgSubnode

		@voxelBrickSubnode = new THREE.Object3D()
		@voxelsSubnode = new THREE.Object3D()
		@voxelBrickSubnode.add @voxelsSubnode
		@bricksSubnode = new THREE.Object3D()
		@voxelBrickSubnode.add @bricksSubnode
		@brickThreeNode.add @voxelBrickSubnode

		@stabilityColoring = new StabilityColoring()

		@printVoxels = []

		@isStabilityView = false

	initialize: (@grid) =>
		@voxelWireframe = new VoxelWireframe(
			@bundle, @grid, @brickShadowThreeNode, @defaultColoring
		)
		@geometryCreator = new GeometryCreator(@grid)
		@voxelSelector = new VoxelSelector @

	showVoxels: =>
		@voxelsSubnode.visible = true
		@bricksSubnode.visible = false

	showBricks: =>
		@bricksSubnode.visible = true
		@voxelsSubnode.visible = false

	showCsg: (newCsgGeometry) =>
		@csgSubnode.children = []
		return if not newCsgGeometry?

		csgMesh = new THREE.Mesh newCsgGeometry, @defaultColoring.csgMaterial
		@csgSubnode.add csgMesh

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
		outlineCoords = @printVoxels.map (voxel) -> voxel.voxelCoords
		@voxelWireframe.createWireframe outlineCoords

	setPossibleLegoBoxVisibility: (isVisible) =>
		@voxelWireframe.setVisibility isVisible

	# clear and create voxel visualization
	_createVoxelVisualization: (coloring) =>
		@voxelsSubnode.children = []

		@grid.forEachVoxel (voxel) =>
			material = coloring.getMaterialForVoxel voxel
			p = voxel.position
			threeBrick = @geometryCreator.getVoxel {x: p.x, y: p.y, z: p.z}, material
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

	updateBrickVisualization: (coloring = @defaultColoring) =>
		@bricksSubnode.children = []

		# sort by layer
		brickLayers = []
		@grid.getAllBricks().forEach (brick) ->
			z = brick.getPosition().z
			brickLayers[z] ?= []
			brickLayers[z].push brick

		# Add bricks layer-wise (because of build view)
		for z, brickLayer of brickLayers
			layerObject = new THREE.Object3D()
			@bricksSubnode.add layerObject

			for brick in brickLayer
				material = coloring.getMaterialForBrick brick
				threeBrick = @geometryCreator.getBrick(
					brick.getPosition(), brick.getSize(), material
				)
				layerObject.add threeBrick

	showBrickLayer: (layer) =>
		for i in [0..@bricksSubnode.children.length - 1] by 1
			if i <= layer
				@bricksSubnode.children[i].visible = true
			else
				@bricksSubnode.children[i].visible = false

		@showBricks()

	# highlights the voxel below mouse and returns it
	highlightVoxel: (event, selectedNode, type, bigBrush) =>
		# invert type, because if we are highlighting a 'lego' voxel
		# we want to display it as 'could be 3d printed'
		voxelType = '3d'
		voxelType = 'lego' if type == '3d'

		highlightMaterial = @defaultColoring.getHighlightMaterial voxelType
		hVoxel = highlightMaterial.voxel
		hBox = highlightMaterial.box

		voxel = @voxelSelector.getVoxel event, {type: type}
		if voxel?
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false

			@currentlyHighlightedVoxel = voxel
			voxel.setHighlight true, hVoxel
			@_highlightBigBrush voxel, hBox if bigBrush
		else
			# clear highlight if no voxel is below mouse
			if @currentlyHighlightedVoxel?
				@currentlyHighlightedVoxel.setHighlight false
			@unhighlightBigBrush()

		return voxel


	_highlightBigBrush: (voxel, material) =>
		size = @voxelSelector.getBrushSize true
		dimensions = new THREE.Vector3 size.x, size.y, size.z
		unless @bigBrushHighlight? and
		@bigBrushHighlight.dimensions.equals dimensions
			@brickShadowThreeNode.remove @bigBrushHighlight if @bigBrushHighlight
			@bigBrushHighlight = @geometryCreator.getBrickBox(
				dimensions
				material
			)
			@brickShadowThreeNode.add @bigBrushHighlight

		@bigBrushHighlight.position.copy voxel.position
		@bigBrushHighlight.material = material
		@bigBrushHighlight.visible = true

	unhighlightBigBrush: =>
		@bigBrushHighlight?.visible = false

	# makes the voxel below mouse to be 3d printed
	makeVoxel3dPrinted: (event, selectedNode, bigBrush) =>
		if bigBrush
			mainVoxel = @voxelSelector.getVoxel event, {type: 'lego'}
			mat = @defaultColoring.getHighlightMaterial '3d'
			@_highlightBigBrush mainVoxel, mat.box if mainVoxel?
		voxels = @voxelSelector.getVoxels event, {type: 'lego', bigBrush: bigBrush}
		return null unless voxels

		for voxel in voxels
			voxel.make3dPrinted()
			voxel.visible = false
			coords = voxel.voxelCoords
			voxelBelow = @grid.getVoxel(coords.x, coords.y, coords.z - 1)
			if voxelBelow?.enabled
				voxelBelow.visibleVoxel.setStudVisibility true
		return voxels

	###
	# @return {Boolean} true if anything changed, false otherwise
	###
	makeAllVoxels3dPrinted: (selectedNode) =>
		voxels = @voxelSelector.getAllVoxels(selectedNode)
		anythingChanged = false
		for voxel in voxels
			anythingChanged = anythingChanged || voxel.isLego()
			voxel.make3dPrinted()
			@voxelSelector.touch voxel
		return anythingChanged

	resetTouchedVoxelsToLego: =>
		voxel.makeLego() for voxel in @voxelSelector.touchedVoxels
		@voxelSelector.clearSelection()

	# makes the voxel below mouse to be made out of lego
	makeVoxelLego: (event, selectedNode, bigBrush) =>
		if bigBrush
			mainVoxel = @voxelSelector.getVoxel event, {type: '3d'}
			mat = @defaultColoring.getHighlightMaterial 'lego'
			@_highlightBigBrush mainVoxel, mat.box if mainVoxel?
		voxels = @voxelSelector.getVoxels event, {type: '3d', bigBrush: bigBrush}
		return null unless voxels

		for voxel in voxels
			voxel.makeLego()
			voxel.visible = true
			voxel.setMaterial @defaultColoring.selectedMaterial
		return voxels

	###
	# @return {Boolean} true if anything changed, false otherwise
	###
	makeAllVoxelsLego: (selectedNode) =>
		voxels = @voxelSelector.getAllVoxels(selectedNode)
		everythingLego = true
		for voxel in voxels
			everythingLego = everythingLego && voxel.isLego()
			voxel.makeLego()
			voxel.visible = true
		return !everythingLego

	resetTouchedVoxelsTo3dPrinted: =>
		voxel.make3dPrinted() for voxel in @voxelSelector.touchedVoxels
		@voxelSelector.clearSelection()

	# clears the selection and updates the possibleLegoWireframe
	updateModifiedVoxels: =>
		@printVoxels = @printVoxels
			.concat @voxelSelector.touchedVoxels
			.filter (voxel) -> not voxel.isLego()
		return @voxelSelector.clearSelection()

module.exports = BrickVisualization
