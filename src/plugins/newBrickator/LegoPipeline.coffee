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
			if options.voxelizing
				return @voxelizer.voxelize lastResult.optimizedModel, options
			else
				return lastResult
		@pipelineSteps.push (lastResult, options) =>
			if options.voxelizing
				return @volumeFiller.fillGrid lastResult.grid, options
			else
				return lastResult

		@pipelineSteps.push (lastResult, options) =>
			if options.layouting
				return @brickLayouter.initializeBrickGraph lastResult.grid
			else
				return lastResult
		@pipelineSteps.push (lastResult, options) =>
			if options.layouting
				return @brickLayouter.layoutByGreedyMerge lastResult.bricks,
				lastResult.bricks
			else
				return lastResult
		###
		@pipelineSteps.push (lastResult, options) =>
			if options.layouting
				return @brickLayouter.optimizeForStability lastResult.bricks
			else
				return lastResult
  	###

		@humanReadableStepNames = []
		@humanReadableStepNames.push 'Hull voxelizing'
		@humanReadableStepNames.push 'Volume filling'
		@humanReadableStepNames.push 'Layout graph initialization'
		@humanReadableStepNames.push 'Layout greedy merge'
		#@humanReadableStepNames.push 'Layout optimize for stability'


	run: (data, options = null, profiling = false) =>
		if profiling
			console.log 'Starting Lego Pipeline'
			profilingResults = []

		accumulatedResults = data

		for i in [0..@pipelineSteps.length - 1] by 1
			if profiling
				r = @runStepProfiled i, accumulatedResults, options
				profilingResults.push r.time
				lastResult = r.result
			else
				lastResult = @runStep i, accumulatedResults, options

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
