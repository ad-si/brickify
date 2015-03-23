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

		@touchedVoxels = []

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
		@touchedVoxels = @touchedVoxels.concat voxels
		return voxels

	###
	# Gets the voxel to be processed in the given event.
	# @param {Object} event usually a mouse or tap or pointer event
	# @param {Object} options some options for the voxel to be found
	# @param {String} [options.type='lego'] 'lego' or '3d'
	###
	getVoxel: (event, options) =>
		type = options.type || 'lego'

		intersections = @_getIntersections event
		voxels = intersections.map (intersection) -> intersection.object.parent

		voxel = @_getFrontierVoxel voxels, type
		voxel ?= @_getBaseplateVoxel type
		if type is '3d'
			voxel ?= @_getMiddleVoxel event

		@touchedVoxels.push voxel if voxel?
		return voxel

	_getFrontierVoxel: (voxels, type) ->
		frontier = voxels.findIndex (voxel) -> voxel.isLego()
		return null unless frontier > -1

		if type is 'lego'
			return voxels[frontier]
		else
			return voxels[frontier - 1]

	_getBaseplateVoxel: (type) =>
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

	_getIntersections: (event) =>
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

module.exports = VoxelSelector
