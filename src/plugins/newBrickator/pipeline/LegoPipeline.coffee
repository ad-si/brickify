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
			worker: (lastResult, options, progressCallback) =>
				return @voxelizer.voxelize(
					lastResult.optimizedModel
					options
					progressCallback
				)

		@pipelineSteps.push
			name: 'Volume filling'
			decision: (options) -> return options.voxelizing
			worker: (lastResult, options, progressCallback) =>
				return @volumeFiller.fillGrid(
					lastResult.grid
					lastResult.gridPOJO
					options
					progressCallback
				)

		@pipelineSteps.push
			name: 'Layout graph initialization'
			decision: (options) -> return options.initLayout
			worker: (lastResult, options, progressCallback) =>
				return @brickLayouter.initializeBrickGraph lastResult.grid

		@pipelineSteps.push
			name: 'Layout greedy merge'
			decision: (options) -> return options.layouting
			worker: (lastResult, options, progressCallback) =>
				return @brickLayouter.layoutByGreedyMerge lastResult.grid

		@pipelineSteps.push
			name: 'Local reLayout'
			decision: (options) -> return options.reLayout
			worker: (lastResult, options, progressCallback) =>
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

		progressCallback = (progress) ->
			log.debug progress

		runPromise = @runPromise 0, data, options, profiling, progressCallback
		.then (result) ->
			log.debug "Finished Lego Pipeline in #{new Date() - start}ms" if profiling
			return result

		cancelPromise = new Promise (resolve, @reject) => return

		return Promise.race([runPromise, cancelPromise])

	runPromise: (i, data, options, profiling, progressCallback) =>
		finished = i >= @pipelineSteps.length or @terminated
		if finished
			@currentStep = null
			@terminated = true
			return data
		else
			return @runStep i, data, options, profiling, progressCallback
				.then (result) =>
					for own key of result
						data[key] = result[key]
					return @runPromise ++i, data, options, profiling, progressCallback

	runStep: (i, lastResult, options, profiling, progressCallback) ->
		step = @pipelineSteps[i]
		@currentStep = step

		if step.decision options
			log.debug "Running step #{step.name}" if profiling
			start = new Date()
			return step.worker lastResult, options, progressCallback
			.then (result) ->
				stop = new Date() - start
				log.debug "Step #{step.name} finished in #{stop}ms" if profiling
				return result
		else
			log.debug "(Skipping step #{step.name})" if profiling
			return Promise.resolve lastResult

	terminate: =>
		return if @terminated
		@terminated = true
		@currentStep?.terminate?()
		@reject? "LegoPipeline was terminated at step #{@currentStep.name}"
		@currentStep = null
		@reject = null
