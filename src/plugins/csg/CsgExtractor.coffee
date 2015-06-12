log = require 'loglevel'

ThreeCSG = require './threeCsg/ThreeCSG'
VoxelUnion = require './VoxelUnion'


module.exports = class CsgExtractor
	extractGeometry: (grid, options = {}) ->
		# extracts voxel that are not selected for
		# legofication (where enabled = false)
		# intersected with the original geometry
		# as a THREE.Geometry

		# options may be
		# {
		#	profiling: true/false # print performance values
		#	addStuds: true/false # add lego studs to csg (slow!)
		#	studSize: {radius, height} of studs
		# 	holeSize: {radius, height} of holes (to fit lego studs into)
		# }

		log.debug 'Creating CSG...'

		d = new Date()
		gridAnalysis = @_analyzeGrid(grid)
		if options.profile
			log.debug "Grid analysis took #{new Date() - d}ms"

		if gridAnalysis.everythingBricks
			log.debug 'Everything is made out of bricks. Skipped CSG.'
			return {
				modelBsp: options.modelBsp
				csg: null
				isOriginalModel: false
			}

		if gridAnalysis.legoVoxels.length == 0
			return {
				modelBsp: options.modelBsp
				csg: options.transformedModel
				isOriginalModel: true
			}

		d = new Date()
		voxunion = new VoxelUnion(grid)
		voxelHull = voxunion.run gridAnalysis.legoVoxels, options
		if options.profile
			log.debug "Voxel Geometrizer took #{new Date() - d}ms"

		extraction = @_extractPrintGeometry(
			options.modelBsp
			options.transformedModel
			voxelHull
			options.profile
		)

		return {
			modelBsp: extraction.modelBsp
			csg: extraction.printGeometry
			isOriginalModel: false
		}

	_analyzeGrid: (grid) ->
		# creates a list of voxels to be legotized
		legoVoxels = []
		everythingBricks = true

		grid.forEachVoxel (voxel) ->
			if not voxel.enabled
				everythingBricks = false
				return

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

		return {
			legoVoxels: legoVoxels
			everythingBricks: everythingBricks
		}

	_extractPrintGeometry: (modelBsp, originalModel, voxelHull, profiling) ->
		# returns volumetric subtraction (3d Geometry - LegoVoxels)
		if not modelBsp
			d = new Date()
			modelBsp = new ThreeBSP(originalModel)
			if profiling
				log.debug "ThreeBsp generation took #{new Date() - d}ms"
		else if profiling
			log.debug 'ThreeBSP already exists. Skipped ThreeBSP generation.'

		d = new Date()
		printBsp = modelBsp.subtract(voxelHull)
		if profiling
			log.debug "Print geometry took #{new Date() - d}ms"

		return {
			modelBsp: modelBsp
			printGeometry: printBsp.toGeometry()
		}
