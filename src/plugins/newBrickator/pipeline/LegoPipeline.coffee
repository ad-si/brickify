log = require 'loglevel'

HullVoxelizer = require './HullVoxelizer'
VolumeFiller = require './VolumeFiller'
BrickLayouter = require './BrickLayouter'
Random = require './Random'
operative = require 'operative'


module.exports = class LegoPipeline
	constructor: ->
		@voxelizer = new HullVoxelizer()
		@volumeFiller = new VolumeFiller()
		@brickLayouter = new BrickLayouter()

		@pipelineSteps = []
		@pipelineSteps.push
			name: 'Hull voxelizing'
			decision: (options) -> return options.voxelizing
			worker: (lastResult, options) =>
				return @voxelizer.voxelize lastResult.optimizedModel, options

		@pipelineSteps.push
			name: 'Volume filling'
			decision: (options) -> return options.voxelizing
			worker: (lastResult, options) =>
				return @volumeFiller.fillGrid lastResult.grid, options

		@pipelineSteps.push
			name: 'Layout graph initialization'
			decision: (options) -> return options.initLayout
			worker: (lastResult, options) =>
				return @brickLayouter.initializeBrickGraph lastResult.grid

		@pipelineSteps.push
			name: 'Layout greedy merge'
			decision: (options) -> return options.layouting
			worker: (lastResult, options) =>
				return @brickLayouter.layoutByGreedyMerge lastResult.grid

		@pipelineSteps.push
			name: 'Local reLayout'
			decision: (options) -> return options.reLayout
			worker: (lastResult, options) =>
				return @brickLayouter.splitBricksAndRelayoutLocally(
					lastResult.modifiedBricks
					lastResult.grid
				)

	run: (data, options = null, profiling = false) =>
		@terminated = false
		if profiling
			log.debug "Starting Lego Pipeline
			 (voxelizing: #{options.voxelizing}, layouting: #{options.layouting},
			 onlyReLayout: #{options.reLayout})"

			randomSeed = Math.floor Math.random() * 1000000
			Random.setSeed randomSeed
			log.debug 'Using random seed', randomSeed

		start = new Date()

		runPromise = @runPromise 0, data, options, profiling
		.then (result) ->
			if profiling
				log.debug "Finished Lego Pipeline in #{new Date() - start}ms"
			return result

		cancelPromise = new Promise (resolve, @reject) => return

		return Promise.race([runPromise, cancelPromise])

	runPromise: (i, data, options, profiling) =>
		if i >= @pipelineSteps.length or @terminated
			@currentStep = null
			@terminated = true
			return data
		else
			@runStep i, data, options, profiling
				.then (result) =>
					for own key of result
						data[key] = result[key]
					return @runPromise ++i, data, options, profiling

	runStep: (i, lastResult, options, profiling) ->
		step = @pipelineSteps[i]
		@currentStep = step

		if step.decision options
			log.debug "Running step #{step.name}" if profiling
			start = new Date()
			step.worker lastResult, options
			.then (result) ->
				stop = new Date() - start
				log.debug "Step #{step.name} finished in #{stop}ms" if profiling
				return result
		else
			log.debug "(Skipping step #{step.name})" if profiling
			result = lastResult
			Promise.resolve result

	terminate: =>
		return if @terminated
		@terminated = true
		@currentStep?.terminate?()
		@reject? "LegoPipeline was terminated at step #{@currentStep.name}"
		@currentStep = null
		@reject = null
