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
		#	addStuds: true/fals # add lego studs to csg (slow!)
		#	studSize: {radius, height} of studs
		# 	holeSize: {radius, height} of holes (to fit lego studs into)
		# }

		console.log 'Creating CSG...'

		d = new Date()
		printVoxels = @_analyzeGrid(grid)
		if options.profile
			console.log "Grid analysis took #{new Date() - d}ms"

		if printVoxels.length == 0
			return null

		d = new Date()
		voxunion = new VoxelUnion(grid)
		voxelHull = voxunion.run printVoxels, options
		if options.profile
			console.log "Voxel Geometrizer took #{new Date() - d}ms"

		d = new Date()
		printGeometry = @_extractPrintGeometry options.transformedModel, voxelHull
		if options.profile
			console.log "Print geometry took #{new Date() - d}ms"

		return printGeometry

	_analyzeGrid: (grid) ->
		# creates a list of voxels to be printed
		printVoxels = []

		grid.forEachVoxel (voxel) ->
			return if voxel.enabled # ignore lego voxels

			x = voxel.position.x
			y = voxel.position.y
			z = voxel.position.z

			#check if the voxel above is legofied. if yes, add a stud to current voxel
			studOnTop = false
			if grid.hasVoxelAt(x, y, z + 1) and grid.getVoxel(x, y, z + 1).enabled
				studOnTop = true

			# check if the voxel is the lowest voxel or has a lego brick below it
			# if yes, create space for stud below
			studFromBelow = false
			if z == 0 or
			(grid.hasVoxelAt(x, y, z - 1) and grid.getVoxel(x, y, z - 1).enabled)
				studFromBelow = true

			printVoxels.push {
				x: x
				y: y
				z: z
				studOnTop: studOnTop
				studFromBelow: studFromBelow
			}

		return printVoxels

	_extractPrintGeometry: (originalModel, voxelHull) ->
		# returns the volumetric intersection of the selected voxels and
		# the original model as a THREE.Mesh
		modelBsp = new ThreeBSP(originalModel)
		printBsp = modelBsp.intersect(voxelHull)
		return printBsp.toMesh(null)
