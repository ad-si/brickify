ThreeCSG = require './threeCSG/ThreeCSG'
VoxelGeometrizer = require './VoxelGeometrizer'

module.exports = class CsgExtractor
	extractGeometry: (grid, options = {}) ->
		# extracts voxel that are not selected for
		# legofication (where enabled = false)
		# intersected with the original mesh
		# as a 3d geometry

		console.log 'Creating CSG...'

		d = new Date()
		printVoxels = @_analyzeGrid(grid)
		if options.profile
			console.log "Grid analysis took #{new Date() - d}ms"

		if printVoxels.length == 0
			return null

		d = new Date()
		geometrizer = new VoxelGeometrizer(grid)
		voxelHull = geometrizer.run printVoxels, options
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

		grid.forEachVoxel (voxel, x, y, z) =>
			if not voxel.enabled
				#check if the voxel above is legofied. if yes, add a knob to current voxel
				knobOnTop = false
				if grid.zLayers[z + 1]?[x]?[y]? and grid.zLayers[z + 1][x][y].enabled
					knobOnTop = true

				# check if the voxel is the lowest voxel or has a lego brick below it
				# if yes, create space for knob below
				knobFromBelow = false
				if z == 0 or
				(grid.zLayers[z - 1]?[x]?[y]? and grid.zLayers[z - 1][x][y].enabled)
					knobFromBelow = true

				printVoxels.push {
					x: x
					y: y
					z: z
					knobOnTop: knobOnTop
					knobFromBelow: knobFromBelow
				}

		return printVoxels

	_extractPrintGeometry: (originalModel, voxelHull) ->
		return voxelHull.toMesh(null)

		# returns the volumetric intersection of the selected voxels and
		# the original model as a THREE.Mesh
		modelBsp = new ThreeBSP(originalModel)
		printBsp = modelBsp.intersect(voxelHull)
		return printBsp.toMesh(null)
