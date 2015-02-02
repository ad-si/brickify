HullVoxelizer = require './HullVoxelizer'
VolumeFiller = require './VolumeFiller'
BrickLayouter = require './BrickLayouter'

module.exports = class LegoPipeline
	constructor: () ->
		@voxelizer = new HullVoxelizer()
		@volumeFiller = new VolumeFiller()
		@brickLayouter = new BrickLayouter()

		@pipelineSteps = []
		@pipelineSteps.push (lastResult, options) =>
			@voxelizer.voxelize lastResult, options
		@pipelineSteps.push (lastResult, options) =>
			@volumeFiller.fillGrid lastResult.grid, options

		@pipelineSteps.push (lastResult, options) =>
			@brickLayouter.initializeBrickGraph lastResult.grid
		@pipelineSteps.push (lastResult, options) =>
			@brickLayouter.layoutByGreedyMerge lastResult.bricks

		@humanReadableStepNames = []
		@humanReadableStepNames.push 'Hull voxelizing'
		@humanReadableStepNames.push 'Volume filling'
		@humanReadableStepNames.push 'Layout graph initialization'
		@humanReadableStepNames.push 'Layout greedy merge'


	run: (optimizedModel, options = null, profiling = false) =>
		if profiling
			console.log 'Starting Lego Pipeline'
			profilingResults = []

		accumulatedResults = {}

		lastResult = optimizedModel

		for i in [0..@pipelineSteps.length - 1] by 1
			if profiling
				r = @runStepProfiled i, lastResult, options
				profilingResults.push r.time
				lastResult = r.result
			else
				lastResult = @runStep i, lastResult, options

			for own key of lastResult
				accumulatedResults[key] = lastResult[key]

		if profiling
			sum = 0
			for s in profilingResults
				sum += s
			console.log "Finished Lego Pipeline in #{sum}ms"

		return {
			profilingResults: profilingResults
			accumulatedResults: accumulatedResults
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
