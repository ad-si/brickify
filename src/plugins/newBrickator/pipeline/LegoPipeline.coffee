log = require 'loglevel'

HullVoxelizer = require './HullVoxelizer'
VolumeFiller = require './VolumeFiller'
BrickLayouter = require './Layout/BrickLayouter'
PlateLayouter = require './Layout/PlateLayouter'
LayoutOptimizer = require './Layout/LayoutOptimizer'
Random = require './Random'

module.exports = class LegoPipeline
	constructor: ->
		@voxelizer = new HullVoxelizer()
		@volumeFiller = new VolumeFiller()
		@brickLayouter = new BrickLayouter()
		@plateLayouter = new PlateLayouter()
		@layoutOptimizer = new LayoutOptimizer(@brickLayouter, @plateLayouter)

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
				return lastResult.grid.initializeBricks()

		@pipelineSteps.push
			name: 'Layout Bricks'
			decision: (options) -> return options.layouting
			worker: (lastResult, options) =>
				return @brickLayouter.layout lastResult.grid

		@pipelineSteps.push
			name: 'Layout Plates'
			decision: (options) -> return options.layouting
			worker: (lastResult, options, progressCallback) =>
				return @plateLayouter.layout lastResult.grid

		@pipelineSteps.push
			name: 'Final merge pass'
			decision: (options) -> return options.layouting
			worker: (lastResult, options) =>
				return @plateLayouter.finalLayoutPass lastResult.grid

		@pipelineSteps.push
			name: 'Local reLayout'
			decision: (options) -> return options.reLayout
			worker: (lastResult, options, progressCallback) =>
				return @layoutOptimizer.splitBricksAndRelayoutLocally(
					lastResult.modifiedBricks
					lastResult.grid
				)

		@pipelineSteps.push
			name: 'Stability optimization'
			decision: (options) ->
				return options.layouting or options.reLayout
			worker: (lastResult, options) =>
				return @layoutOptimizer.optimizeLayoutStability lastResult.grid

	run: (data, options = null) =>
		@terminated = false
		log.debug "Starting Lego Pipeline
		 (voxelizing: #{options.voxelizing}, layouting: #{options.layouting},
		 onlyReLayout: #{options.reLayout})"

		randomSeed = Math.floor Math.random() * 1000000
		Random.setSeed randomSeed
		log.debug 'Using random seed', randomSeed

		start = new Date()

		runPromise = @runPromise 0, data, options
		.then (result) ->
			log.debug "Finished Lego Pipeline in #{new Date() - start}ms"
			return result

		cancelPromise = new Promise (resolve, @reject) => return

		return Promise.race([runPromise, cancelPromise])

	runPromise: (i, data, options) =>
		progressCallback = (progress) =>
			overallProgress =
				100 * i / @pipelineSteps.length + progress / @pipelineSteps.length
		finished = i >= @pipelineSteps.length or @terminated
		if finished
			@currentStep = null
			@terminated = true
			return data
		else
			return @runStep i, data, options, progressCallback
				.then (result) =>
					for own key of result
						data[key] = result[key]
					return @runPromise ++i, data, options, progressCallback

	runStep: (i, lastResult, options, progressCallback) ->
		step = @pipelineSteps[i]
		@currentStep = step

		if step.decision options
			log.debug "Running step #{step.name}"
			start = new Date()
			return step.worker lastResult, options, progressCallback
			.then (result) ->
				stop = new Date() - start
				log.debug "Step #{step.name} finished in #{stop}ms"
				return result
		else
			log.debug "(Skipping step #{step.name})"
			return Promise.resolve lastResult

	terminate: =>
		return if @terminated
		@terminated = true
		@currentStep?.terminate?()
		@reject? "LegoPipeline was terminated at step #{@currentStep.name}"
		@currentStep = null
		@reject = null
