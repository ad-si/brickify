Grid = require '../Grid'

VolumeFillWorker = require './VolumeFillWorker'

module.exports = class VolumeFiller
	fillGrid: (grid, gridPOJO, options, progressCallback) ->
		# fills spaces in the grid. Goes up from z=0 to z=max and looks for
		# voxels facing downwards (start filling), stops when it sees voxels
		# facing upwards

		callback = (message) =>
			if message.state is 'progress'
				progressCallback message.progress
			else # if state is 'finished'
				grid.fromPojo message.data
				@resolve grid: grid

		@worker = @_getWorker()
		@worker.fillGrid(
			gridPOJO
			callback
		)

		return new Promise (@resolve, reject) => return

	terminate: =>
		@worker?.terminate()
		@worker = null

	_getWorker: ->
		return @worker if @worker?
		return operative VolumeFillWorker
