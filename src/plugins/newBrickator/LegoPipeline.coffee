Voxelizer = require './Voxelizer'

module.exports = class LegoPipeline
	constructor: (baseBrick) ->
		@voxelizer = new Voxelizer(baseBrick)

		@pipelineSteps = []
		@pipelineSteps.push (model, options) =>
			@voxelizer.voxelize model, options

		@humanReadableStepNames = []
		@humanReadableStepNames.push 'Voxelizer'


	run: (optimizedModel, options = null, profiling = false) =>
		if profiling
			console.log 'Starting Lego Pipeline'

		for i in [0..@pipelineSteps.length - 1] by 1
			res = []
			if profiling
				res.push @runStepProfiled i, optimizedModel, options
			else
				res.push @runStep i, optimizedModel, options

		if profiling
			sum = 0
			for s in res
				sum += s
			console.log "Finished Lego Pipeline in #{sum}ms"

		return res

	runStep: (i, optimizedModel, options) ->
		return @pipelineSteps[i](optimizedModel, options)

	runStepProfiled: (i, optimizedModel, options) ->
		console.log "Running step #{@humanReadableStepNames[i]}"
		start = new Date()
		@runStep i, optimizedModel, options
		stop = new Date() - start
		console.log "Step #{@humanReadableStepNames[i]} finished in #{stop}ms"
		return stop
