###
  #Fidelity Control Plugin#

  Measures the current FPS and instigates rendering fidelity changes
  accordingly via the `uglify()` and `beautify()` plugin hooks
###

$ = require 'jquery'

minimalAcceptableFps = 20
upgradeThresholdFps = 40
accumulationTime = 200
timesBelowThreshold = 5
fpsDisplayUpdateTime = 1000

###
# @class FidelityControl
###
class FidelityControl
	init: (bundle) =>
		@pluginHooks = bundle.pluginHooks

		@canIncreaseVisualQuality = true
		@canDecreaseVisualQuality = true

		@autoAdjust = true

		@accumulatedFrames = 0
		@accumulatedTime = 0

		@timesBelowMinimumFps = 0

		@_setupFpsDisplay() if process.env.NODE_ENV is 'development'

	on3dUpdate: (timestamp) =>
		if not @_lastTimestamp?
			@_lastTimestamp = timestamp
			return

		delta = timestamp - @_lastTimestamp

		@_lastTimestamp = timestamp
		@accumulatedTime += delta
		@accumulatedFrames++

		if @accumulatedTime > accumulationTime
			fps = (@accumulatedFrames / @accumulatedTime) * 1000
			@accumulatedFrames = 0
			@accumulatedTime %= accumulationTime
			@_adjustFidelity fps
			@_showFps timestamp, fps

	_adjustFidelity: (fps) =>
		return unless @autoAdjust

		if fps < minimalAcceptableFps and @canDecreaseVisualQuality
			# count how often we dropped below the desired fps
			# it has to occur at least @timesBelowThreshold times to cause a change
			@timesBelowMinimumFps++
			return if @timesBelowMinimumFps < timesBelowThreshold

			@timesBelowMinimumFps = 0
			@_decreaseFidelity()

		else if fps > upgradeThresholdFps and @canIncreaseVisualQuality
			# upgrade instantly, but reset downgrade counter
			@timesBelowMinimumFps = 0

			@_increaseFidelity()

	_increaseFidelity: =>
		results = @pluginHooks.beautify()

		# assume that there is a way back if we can increase quality
		@canDecreaseVisualQuality = true

		# if there is no plugin that increased quality (and returned true), then
		# we don't need to try it again
		@canIncreaseVisualQuality = true in results

	_decreaseFidelity: =>
		results = @pluginHooks.uglify()

		# assume that there is a way back if we decreased quality
		@canIncreaseVisualQuality = true

		# if there is no plugin that decreased quality (and returned true), then
		# we don't need to try it again
		@canDecreaseVisualQuality = true in results

	getHotkeys: =>
		return {
			title: 'Visual Complexity'
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

	_setupFpsDisplay: =>
		@lastDisplayUpdate = 0
		@$fpsDisplay = $('<div class="fps-display"></div>')
		$('body').append @$fpsDisplay

	_showFps: (timestamp, fps) =>
		if timestamp - @lastDisplayUpdate > fpsDisplayUpdateTime
			@lastDisplayUpdate = timestamp
			@$fpsDisplay.text Math.round(fps) if @$fpsDisplay?

module.exports = FidelityControl
