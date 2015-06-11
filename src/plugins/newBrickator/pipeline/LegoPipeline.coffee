log = require 'loglevel'

HullVoxelizer = require './HullVoxelizer'
VolumeFiller = require './VolumeFiller'
BrickLayouter = require './BrickLayouter'
Random = require './Random'


module.exports = class LegoPipeline
	constructor: ->
		@voxelizer = new HullVoxelizer()
		@volumeFiller = new VolumeFiller()
		@brickLayouter = new BrickLayouter()

		@pipelineSteps = []
		@pipelineSteps.push {
			name: 'Hull voxelizing'
			decision: (options) -> return options.voxelizing
			worker: (lastResult, options) =>
				return @voxelizer.voxelize lastResult.optimizedModel, options
		}

		@pipelineSteps.push {
			name: 'Volume filling'
			decision: (options) -> return options.voxelizing
			worker: (lastResult, options) =>
				return @volumeFiller.fillGrid lastResult.grid, options
		}

		@pipelineSteps.push {
			name: 'Layout graph initialization'
			decision: (options) -> return options.initLayout
			worker: (lastResult, options) =>
				return @brickLayouter.initializeBrickGraph lastResult.grid
		}

		@pipelineSteps.push {
			name: 'Layout 3L merge'
			decision: (options) -> return options.layouting
			worker: (lastResult, options) =>
				return @brickLayouter.layout3LBricks lastResult.grid
		}

		@pipelineSteps.push {
			name: 'Layout greedy merge'
			decision: (options) -> return options.layouting
			worker: (lastResult, options) =>
				return @brickLayouter.layoutByGreedyMerge lastResult.grid
		}

		@pipelineSteps.push {
			name: 'Final merge pass'
			decision: (options) -> return options.layouting
			worker: (lastResult, options) =>
				return @brickLayouter.finalLayoutPass lastResult.grid
		}

		@pipelineSteps.push {
			name: 'Local reLayout'
			decision: (options) -> return options.reLayout
			worker: (lastResult, options) =>
				@brickLayouter.splitBricksAndRelayoutLocally lastResult.modifiedBricks,
				lastResult.grid
				return lastResult
		}

	run: (data, options = null, profiling = false) =>
		if profiling
			log.debug "Starting Lego Pipeline
			 (voxelizing: #{options.voxelizing}, layouting: #{options.layouting},
			 onlyReLayout: #{options.reLayout})"

			randomSeed = Math.floor Math.random() * 1000000
			Random.setSeed randomSeed
			log.debug 'Using random seed', randomSeed

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
			log.debug "Finished Lego Pipeline in #{sum}ms\n
				------------------------------"

		return {
			profilingResults: profilingResults
			accumulatedResults: accumulatedResults
		}

	runStep: (i, lastResult, options) ->
		step = @pipelineSteps[i]

		if step.decision options
			return step.worker lastResult, options
		return lastResult

	runStepProfiled: (i, lastResult, options) ->
		step = @pipelineSteps[i]

		if step.decision options
			log.debug "Running step #{step.name}"
			start = new Date()
			result = @runStep i, lastResult, options
			stop = new Date() - start
			log.debug "\tfinished in #{stop}ms"
		else
			log.debug "(Skipping step #{step.name})"
			result = lastResult
			stop = 0

		return {
			time: stop
			result: result
		}
