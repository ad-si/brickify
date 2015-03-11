class FidelityControl
	constructor: (@pluginHooks) ->
		@minimalAcceptableFps = 20
		@upgradeThresholdFps = 50

		@canIncreaseVisualQuality = true
		@canDecreaseVisualQuality = true

		@autoAdjust = true

		@fpsAverage = 1
		@accumulatedFrames = 0
		@accumulatedTime = 0
		@accumulationTime = 200

		@timesBelowMinimumFps = 0
		@timesBelowThreshold = 5

	renderTick: (timestamp) =>
		if not @_lastTimestamp?
			@_lastTimestamp = timestamp
			return

		delta = timestamp - @_lastTimestamp

		@_lastTimestamp = timestamp
		@accumulatedTime += delta
		@accumulatedFrames++

		if @accumulatedTime > @accumulationTime
			@fpsAverage = (@accumulatedFrames / @accumulatedTime) * 1000
			@accumulatedFrames = 0
			@accumulatedTime = 0
			@_adjustFidelity @fpsAverage

	_adjustFidelity: (fps) =>
		return if not @autoAdjust

		if fps < @minimalAcceptableFps and @canDecreaseVisualQuality
			# we were one measurement below desired fps
			@timesBelowMinimumFps++
			return if @timesBelowMinimumFps < @timesBelowThreshold
			@timesBelowMinimumFps = 0

			results = @pluginHooks.uglify()

			# assume that there is a way back if we can decrease quality
			@canIncreaseVisualQuality = true

			# if there is no plugin that decreased quality (return true), then
			# we don't need to try it again
			if not true in results
				@canDecreaseVisualQuality = false

		else if fps > @upgradeThresholdFps and @canIncreaseVisualQuality
			# upgrade instantly, but reset downgrade counter
			@timesBelowMinimumFps = 0
			
			results = @pluginHooks.beautify()

			@canDecreaseVisualQuality = true

			# same goes for increasing quality
			if not true in results
				@canIncreaseVisualQuality = false

	getHotkeys: () =>
		return {
			title: 'Visual Quality'
			events: [
				{
					description: 'Increase visual complexity (turns off automatic adjustment)'
					hotkey: 'i'
					callback: @_manualIncrease
				}
				{
					description: 'Decrease visual complexity (turns off automatic adjustment)'
					hotkey: 'd'
					callback: @_manualDecrease
				}
			]
		}

	_manualIncrease: =>
		@autoAdjust = false
		@pluginHooks.beautify()

	_manualDecrease: =>
		@autoAdjust = false
		@pluginHooks.uglify()

module.exports = FidelityControl
