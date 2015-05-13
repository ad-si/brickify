module.exports = class VolumeFiller
	fillGrid: (grid, options) ->
		# fills spaces in the grid. Goes up from z=0 to z=max and looks for
		# voxels facing downwards (start filling), stops when it sees voxels
		# facing upwards

		for x in [0..grid.getNumVoxelsX() - 1] by 1
			for y in [0..grid.getNumVoxelsY() - 1] by 1
				@fillUp grid, x, y

		Promise.resolve {grid: grid}

	fillUp: (grid, x, y) =>
		#fill up from z=0 to z=max
		#fill up from z=0 to z=max
		insideModel = false
		z = 0
		currentFillVoxelQueue = []

		while z < grid.getNumVoxelsZ()
			if grid.hasVoxelAt x, y, z
				# current voxel already exists (shell voxel)
				dir = @calculateVoxelDirection grid, x, y, z

				if dir.definitelyUp
					#fill up voxels and leave model
					for v in currentFillVoxelQueue
						grid.setVoxel v, {inside: true}
					insideModel = false
				else if dir.definitelyDown
					# re-entering model if inside? that seems odd. empty current fill queue
					if insideModel
						currentFillVoxelQueue = []
					#entering model
					insideModel = true
				else
					#if not sure, fill up (precautious people might leave this out?)
					for v in currentFillVoxelQueue
						grid.setVoxel v, {inside: true}
					currentFillVoxelQueue = []

					insideModel = false
			else
				#voxel does not yet exist. create if inside model
				if insideModel
					currentFillVoxelQueue.push {x: x, y: y, z: z}
			z++

	calculateVoxelDirection: (grid, x, y, z, tolerance = 0.1) ->
		# determines whether all polygons related to this voxel are either
		# all aligned upwards or all aligned downwards
		voxel = grid.getVoxel x, y, z
		numUp = 0
		numDown = 0

		for e in voxel.dataEntrys
			# everything smaller than tolerance is considered level
			if e.dZ > tolerance then numUp++ else if e.dZ < -tolerance then numDown++

		if numUp > 0 and numDown == 0
			definitelyUp = true
		else
			definitelyUp = false

		if numDown > 0 and numUp == 0
			definitelyDown = true
		else
			definitelyDown = false

		voxel.definitelyUp = definitelyUp
		voxel.definitelyDown = definitelyDown

		return {
			definitelyUp: definitelyUp
			definitelyDown: definitelyDown
		}
