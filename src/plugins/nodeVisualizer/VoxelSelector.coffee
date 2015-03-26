THREE = require 'three'
interactionHelper = require '../../client/interactionHelper'

###
# @class VoxelSelector
###
class VoxelSelector
	constructor: (brickVisualization) ->
		@renderer = brickVisualization.bundle.renderer
		@node = brickVisualization.voxelsSubnode
		@grid = brickVisualization.grid
		@voxelWireframe = brickVisualization.voxelWireframe
		@level = undefined

		@touchedVoxels = []

	getAllVoxels: =>
		voxels = []
		@grid.forEachVoxel (voxel) => voxels.push voxel.visibleVoxel
		return @touchedVoxels = voxels

	###
	# Gets the voxels to be processed in the given event.
	# @param {Object} event usually a mouse or tap or pointer event
	# @param {Object} options some options for the voxels to be found
	# @param {Boolean} [options.bigBrush=true] should a big brush be used?
	# @param {String} [options.type='lego'] 'lego' or '3d'
	###
	getVoxels: (event, options) =>
		type = options.type || 'lego'

		mainVoxel = @getVoxel event, options
		return null unless mainVoxel?.voxelCoords?

		size = @getBrushSize options.bigBrush
		gridEntries = @grid.getSurrounding mainVoxel.voxelCoords, size, -> true
		voxels = gridEntries
			.map (voxel) -> voxel.visibleVoxel
			.filter (voxel) => @_hasType voxel, type
			.filter (voxel) => voxel not in @touchedVoxels
		@touchedVoxels = @touchedVoxels.concat voxels
		if options.bigBrush
			@level =
				voxelZ: mainVoxel.voxelCoords.z
				worldZ: mainVoxel.position.z
		return voxels

	###
	# Gets the voxel to be processed in the given event.
	# @param {Object} event usually a mouse or tap or pointer event
	# @param {Object} options some options for the voxel to be found
	# @param {String} [options.type='lego'] 'lego' or '3d'
	# @param {Boolean} [options.touch=true] false for highlighting
	###
	getVoxel: (event, options) =>
		type = options.type || 'lego'

		intersections = @_getIntersections event
		voxels = intersections.map (intersection) -> intersection.object.parent

		return @_getLeveledVoxel event, voxels if @level

		voxel = @_getFrontierVoxel voxels, type
		if type is '3d'
			voxel ?= @_getBaseplateVoxel type
			voxel ?= @_getMiddleVoxel event
		return voxel

	_getLeveledVoxel: (event, voxels) ->
		voxel =  voxels.find (voxel) => voxel.voxelCoords.z == @level.voxelZ
		return voxel if voxel
		position = interactionHelper.getPlanePosition(
			event
			@renderer
			@level.worldZ
		)
		voxelCoords = @grid.mapGridToVoxel @grid.mapWorldToGrid position
		position = @grid.mapVoxelToWorld voxelCoords
		pseudoVoxel =
			position: position
			voxelCoords: voxelCoords
		return pseudoVoxel

	_getFrontierVoxel: (voxels, type) ->
		lastTouched = @touchedVoxels[-2...]
		frontier = voxels.findIndex (voxel) -> voxel.isLego()
		return null unless frontier > -1

		prevVoxel = voxels[frontier - 1]
		frontierVoxel = voxels[frontier]

		if type is 'lego' and prevVoxel not in lastTouched or
		type is '3d' and frontierVoxel in lastTouched
			return frontierVoxel
		else
			return prevVoxel

	_getBaseplateVoxel: (type) ->
		baseplatePos = interactionHelper.getGridPosition event, @renderer
		voxelPos = @grid.mapGridToVoxel @grid.mapWorldToGrid baseplatePos
		gridEntry = @grid.zLayers[voxelPos.z]?[voxelPos.x]?[voxelPos.y]
		voxel = gridEntry?.visibleVoxel
		return null unless voxel?

		if @_hasType voxel, type
			return voxel
		else
			return null

	_getMiddleVoxel: (event) ->
		modelIntersects = @voxelWireframe.intersectRay event
		return null unless modelIntersects.length >= 2

		start = modelIntersects[0].point
		end = modelIntersects[1].point

		revTransform = new THREE.Matrix4()
		revTransform.getInverse @renderer.scene.matrix

		middle = new THREE.Vector3(
			(start.x + end.x) / 2
			(start.y + end.y) / 2
			(start.z + end.z) / 2
		)
		middle.applyMatrix4 revTransform
		voxelPos = @grid.mapGridToVoxel @grid.mapWorldToGrid middle
		gridEntry = @grid.zLayers[voxelPos.z]?[voxelPos.x]?[voxelPos.y]
		unless gridEntry?.visibleVoxel?.isLego()
			return gridEntry.visibleVoxel
		else
			return null

	_getIntersections: (event) ->
		return interactionHelper.getIntersections(
			event
			@renderer
			@node.children
		)

	_hasType: (voxel, type) ->
		return voxel.isLego() and type is 'lego' or
			not voxel.isLego() and type is '3d'

	###
	# Gets the brush size to be used dependent on the `bigBrush` flag
	# @param {Boolean} bigBrush should a big Brush be used?
	###
	getBrushSize: (bigBrush) =>
		return x: 1, y: 1, z: 1 unless bigBrush
		length = Math.max @grid.numVoxelsX, @grid.numVoxelsY, @grid.numVoxelsZ
		size = Math.sqrt length
		height = Math.round size * @grid.heightRatio
		return x: size, y: size, z: height

	###
	# Clears the current collection of touched voxels.
	# @return {Array<BrickObject>} the touched voxels before clearing
	###
	clearSelection: =>
		tmp = @touchedVoxels
		@touchedVoxels = []
		@level = undefined
		return tmp

module.exports = VoxelSelector
