log = require 'loglevel'

ThreeCSG = require './threeCsg/ThreeCSG'
VoxelUnion = require './VoxelUnion'


module.exports = class CsgExtractor
	extractGeometry: (grid, options = {}) ->
		# extracts voxel that are not selected for
		# legofication (where enabled = false)
		# intersected with the original mesh
		# as a THREE.Mesh

		# options may be
		# {
		#	profiling: true/false # print performance values
		#	addStuds: true/false # add lego studs to csg (slow!)
		#	studSize: {radius, height} of studs
		# 	holeSize: {radius, height} of holes (to fit lego studs into)
		# }

		log.debug 'Creating CSG...'

		d = new Date()
		legoVoxels = @_analyzeGrid(grid)
		if options.profile
			log.debug "Grid analysis took #{new Date() - d}ms"

		if legoVoxels.length == 0
			return null

		d = new Date()
		voxunion = new VoxelUnion(grid)
		voxelHull = voxunion.run legoVoxels, options
		if options.profile
			log.debug "Voxel Geometrizer took #{new Date() - d}ms"

		d = new Date()
		printGeometry = @_extractPrintGeometry options.transformedModel, voxelHull
		if options.profile
			log.debug "Print geometry took #{new Date() - d}ms"

		return printGeometry

	_analyzeGrid: (grid) ->
		# creates a list of voxels to be legotized
		legoVoxels = []

		grid.forEachVoxel (voxel) ->
			return if not voxel.enabled # ignore 3d printed voxels

			x = voxel.position.x
			y = voxel.position.y
			z = voxel.position.z

			# check if the voxel above is 3d printed.
			# if yes, add a stud to current voxel
			studOnTop = false
			if grid.hasVoxelAt(x, y, z + 1) and not grid.getVoxel(x, y, z + 1).enabled
				studOnTop = true

			# check if the voxel has a 3d printed voxel below it
			# if yes, create space for stud below
			studFromBelow = false
			if (grid.hasVoxelAt(x, y, z - 1) and not grid.getVoxel(x, y, z - 1).enabled)
				studFromBelow = true

			legoVoxels.push {
				x: x
				y: y
				z: z
				studOnTop: studOnTop
				studFromBelow: studFromBelow
			}

		return legoVoxels

	_extractPrintGeometry: (originalModel, voxelHull) ->
		# returns volumetric subtraction (3d Geometry - LegoVoxels)
		modelBsp = new ThreeBSP(originalModel)

		printBsp = modelBsp.subtract(voxelHull)
		return printBsp.toMesh(null)
