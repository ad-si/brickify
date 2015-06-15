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

		@bricksSubnode = new THREE.Object3D()
		@temporaryVoxels = new THREE.Object3D()
		@brickThreeNode.add @bricksSubnode
		@brickThreeNode.add @temporaryVoxels

		@stabilityColoring = new StabilityColoring()

		@printVoxels = []

		@isStabilityView = false
		@_highlightVoxelVisiblity = true

	initialize: (@grid) =>
		@voxelWireframe = new VoxelWireframe(
			@bundle, @grid, @brickShadowThreeNode, @defaultColoring
		)
		@geometryCreator = new GeometryCreator(@grid)
		@voxelSelector = new VoxelSelector @

		@_highlightVoxel = @geometryCreator.getBrick(
			{x: 0, y: 0, z: 0},
			{x: 1, y: 1, z: 1},
			@defaultColoring.printHighlightMaterial
		)
		@_highlightVoxel.visible = false

		@brickThreeNode.add @_highlightVoxel

	showCsg: (newCsgGeometry) =>
		@csgSubnode.children = []
		if not newCsgGeometry?
			@csgSubnode.visible = false

		for geometry in newCsgGeometry
			csgMesh = new THREE.Mesh geometry, @defaultColoring.csgMaterial
			@csgSubnode.add csgMesh

		@csgSubnode.visible = true

	hideCsg: =>
		@csgSubnode.visible = false

	hideVoxelAndBricks: =>
		@bricksSubnode.visible = false

	showVoxelAndBricks: =>
		@bricksSubnode.visible  = true

	# updates brick and voxel visualization
	updateVisualization: (coloring = @defaultColoring, recreate = false) =>
		# delete temporary voxels
		@temporaryVoxels.children = []

		if recreate
			@bricksSubnode.children = []
		else
			# throw out all visual bricks that have no valid linked brick
			for layer in @bricksSubnode.children
				deletionList = []
				for visualBrick in layer.children
					if not visualBrick.brick? or not visualBrick.brick.isValid()
						deletionList.push visualBrick

				for delBrick in deletionList
					# remove from scenegraph
					layer.remove delBrick
					# delete reference from datastructure brick
					if delBrick.brick?
						delBrick.brick.setVisualBrick null

		# Recreate visible bricks for all bricks in the datastructure that
		# have no linked brick

		# sort layerwise for build view
		brickLayers = []
		@grid.getAllBricks().forEach (brick) ->
			z = brick.getPosition().z
			brickLayers[z] ?= []

			if (not recreate) and (not brick.getVisualBrick()?)
				brickLayers[z].push brick
			if brick.getVisualBrick()?
				brick.getVisualBrick().visible = yes
				brick.getVisualBrick().hasBeenSplit = no

		for z, brickLayer of brickLayers
			# create layer object if it does not exist
			if not @bricksSubnode.children[z]?
				layerObject = new THREE.Object3D()
				@bricksSubnode.add layerObject

			layerObject = @bricksSubnode.children[z]

			for brick in brickLayer
				# create visual brick
				materials = coloring.getMaterialsForBrick brick
				threeBrick = @geometryCreator.getBrick(
					brick.getPosition(), brick.getSize(), materials.color
				)

				# link data <-> visuals
				brick.setVisualBrick threeBrick
				threeBrick.brick = brick

				# add to scene graph
				layerObject.add threeBrick

		# if this coloring differs from the last used coloring, go through
		# all visible bricks to update their material
		if @_oldColoring != coloring
			for layer in @bricksSubnode.children
				for visualBrick in layer.children
					material = coloring.getMaterialsForBrick visualBrick.brick
					visualBrick.setMaterial material.color
		@_oldColoring = coloring

		@unhighlightBigBrush()

		# show not filled lego shape as outline
		outlineCoords = @printVoxels.map (voxel) -> voxel.position
		@voxelWireframe.createWireframe outlineCoords

		#ToDo: hide studs when brick is completely below other brick

	setPossibleLegoBoxVisibility: (isVisible) =>
		@voxelWireframe.setVisibility isVisible

	setStabilityView: (enabled) =>
		@isStabilityView = enabled
		coloring = if @isStabilityView then @stabilityColoring else @defaultColoring
		@updateVisualization(coloring)

		# Turn off possible lego box and highlight during stability view
		if enabled
			@_legoBoxVisibilityBeforeStability = @voxelWireframe.isVisible()
			@voxelWireframe.setVisibility false
			@_highlightVoxel.visible = false
		else
			@voxelWireframe.setVisibility @_legoBoxVisibilityBeforeStability

	showBrickLayer: (layer) =>
		# hide highlight when in build mode
		@_highlightVoxel.visible = false

		for i in [0..@bricksSubnode.children.length - 1] by 1
			if i <= layer
				@bricksSubnode.children[i].visible = true
			else
				@bricksSubnode.children[i].visible = false

	showAllBrickLayers: =>
		for layer in @bricksSubnode.children
			layer.visible = true

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
			@_highlightVoxel.visible = true and @_highlightVoxelVisiblity
			worldPos = @grid.mapVoxelToWorld voxel.position
			@_highlightVoxel.position.set(
				worldPos.x, worldPos.y, worldPos.z
			)
			@_highlightVoxel.material = hVoxel
			@_highlightBigBrush voxel, hBox if bigBrush
		else
			# clear highlight if no voxel is below mouse
			@_highlightVoxel.visible = false
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

		worldPosition = @grid.mapVoxelToWorld voxel.position
		@bigBrushHighlight.position.copy worldPosition
		@bigBrushHighlight.material = material
		@bigBrushHighlight.visible = true

	unhighlightBigBrush: =>
		@bigBrushHighlight?.visible = false

	# makes the voxel below mouse to be 3d printed
	makeVoxel3dPrinted: (event, selectedNode, bigBrush) =>
		# hide highlight voxel since it will be made invisible
		@_highlightVoxel.visible = false

		if bigBrush
			mainVoxel = @voxelSelector.getVoxel event, {type: 'lego'}
			mat = @defaultColoring.getHighlightMaterial '3d'
			@_highlightBigBrush mainVoxel, mat.box if mainVoxel?
		voxels = @voxelSelector.getVoxels event, {type: 'lego', bigBrush: bigBrush}
		return null unless voxels

		for voxel in voxels
			voxel.make3dPrinted()
			# Split visual brick into voxels (only once per brick)
			if (voxel.brick)
				visualBrick = voxel.brick.getVisualBrick()
				if not visualBrick.hasBeenSplit
					voxel.brick.forEachVoxel (voxel) =>
						temporaryVoxel = @geometryCreator.getBrick(
							voxel.position, {x: 1, y: 1, z: 1}, visualBrick.material
						)
						temporaryVoxel.voxelPosition = voxel.position
						@temporaryVoxels.add temporaryVoxel
					visualBrick.hasBeenSplit = true
					visualBrick.visible = false
			# hide visual voxels for 3d printed geometry
			for temporaryVoxel in @temporaryVoxels.children
				if temporaryVoxel.voxelPosition == voxel.position
					temporaryVoxel.visible = false
					break

		return voxels

	###
	# @return {Boolean} true if anything changed, false otherwise
	###
	makeAllVoxels3dPrinted: (selectedNode) =>
		voxels = @voxelSelector.getAllVoxels(selectedNode)
		everything3D = true
		for voxel in voxels
			everything3D = everything3D && !voxel.isLego()
			voxel.make3dPrinted()
		return !everything3D

	resetTouchedVoxelsToLego: =>
		voxel.makeLego() for voxel in @voxelSelector.touchedVoxels
		@voxelSelector.clearSelection()

	# makes the voxel below mouse to be made out of lego
	makeVoxelLego: (event, selectedNode, bigBrush) =>
		# hide highlight
		@_highlightVoxel.visible = false

		if bigBrush
			mainVoxel = @voxelSelector.getVoxel event, {type: '3d'}
			mat = @defaultColoring.getHighlightMaterial 'lego'
			@_highlightBigBrush mainVoxel, mat.box if mainVoxel?
		voxels = @voxelSelector.getVoxels event, {type: '3d', bigBrush: bigBrush}
		return null unless voxels

		for voxel in voxels
			voxel.makeLego()

			# Create a visible temporary voxel at this position
			temporaryVoxel = @geometryCreator.getBrick(
				voxel.position, {x: 1, y: 1, z: 1}, @defaultColoring.selectedMaterial
			)
			temporaryVoxel.voxelPosition = voxel.position
			@temporaryVoxels.add temporaryVoxel
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

	setHighlightVoxelVisibility: (@_highlightVoxelVisiblity) => return

module.exports = BrickVisualization
