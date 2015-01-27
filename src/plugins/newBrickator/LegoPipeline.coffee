HullVoxelizer = require './HullVoxelizer'
VolumeFiller = require './VolumeFiller'

module.exports = class LegoPipeline
	constructor: () ->
		@voxelizer = new HullVoxelizer()
		@volumeFiller = new VolumeFiller()

		@pipelineSteps = []
		@pipelineSteps.push (lastResult, options) =>
			@voxelizer.voxelize lastResult, options
		@pipelineSteps.push (lastResult, options) =>
			@volumeFiller.fillGrid lastResult, options

		@humanReadableStepNames = []
		@humanReadableStepNames.push 'Hull voxelizing'
		@humanReadableStepNames.push 'Volume filling'


	run: (optimizedModel, options = null, profiling = false) =>
		if profiling
			console.log 'Starting Lego Pipeline'
			profilingResults = []

		lastResult = optimizedModel

		for i in [0..@pipelineSteps.length - 1] by 1
			if profiling
				r = @runStepProfiled i, lastResult, options
				profilingResults.push r.time
				lastResult = r.result
			else
				 lastResult = @runStep i, lastResult, options

		if profiling
			sum = 0
			for s in profilingResults
				sum += s
			console.log "Finished Lego Pipeline in #{sum}ms"

		return {
			profilingResults: profilingResults
			lastResult: lastResult
		}

	runStep: (i, lastResult, options) ->
		return @pipelineSteps[i](lastResult, options)

	runStepProfiled: (i, lastResult, options) ->
		console.log "Running step #{@humanReadableStepNames[i]}"
		start = new Date()
		result = @runStep i, lastResult, options
		stop = new Date() - start
		console.log "Step #{@humanReadableStepNames[i]} finished in #{stop}ms"

		return {
			time: stop
			result: result
		}
