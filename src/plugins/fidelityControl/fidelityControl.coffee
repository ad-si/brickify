###
  #Fidelity Control Plugin#

  Measures the current FPS and instigates rendering fidelity changes
  accordingly via the `uglify()` and `beautify()` plugin hooks
###

$ = require 'jquery'
piwikTracking = require '../../client/piwikTracking'

minimalAcceptableFps = 20
upgradeThresholdFps = 40
accumulationTime = 200
timesBelowThreshold = 10
fpsDisplayUpdateTime = 1000
maxNoPipelineDecisions = 3
piwikStatInterval = 20

###
# @class FidelityControl
###
class FidelityControl
	@fidelityLevels = [
		'DefaultLow',
		'DefaultMedium',
		'DefaultHigh',
		'PipelineLow',
		'PipelineMedium',
		'PipelineHigh',
		'PipelineUltra'
	]
	@minimalPipelineLevel = 3

	init: (@bundle) =>
		@pluginHooks = @bundle.pluginHooks

		@currentFidelityLevel = 0

		@autoAdjust = true
		@screenShotMode = false

		@accumulatedFrames = 0
		@accumulatedTime = 0

		@currentPiwikStat = 0

		@timesBelowMinimumFps = 0

		@showFps = process.env.NODE_ENV is 'development'
		@_setupFpsDisplay()

		# allow pipeline only if we have the needed extension and a stencil buffer
		# and if the pipeline is enabled in the global config
		usePipeline = @bundle.globalConfig.rendering.usePipeline
		depth = @bundle.renderer.threeRenderer.supportsDepthTextures()
		fragDepth = @bundle.renderer.threeRenderer.extensions.get 'EXT_frag_depth'
		stencilBuffer = @bundle.renderer.threeRenderer.hasStencilBuffer

		capabilites = ''
		capabilites += 'DepthTextures ' if depth?
		capabilites += 'ExtFragDepth ' if fragDepth?
		capabilites += 'stencilBuffer ' if stencilBuffer

		piwikTracking.setCustomSessionVariable 0, 'GpuCapabilities', capabilites

		@pipelineAvailable = usePipeline and depth? and fragDepth? and stencilBuffer
		@noPipelineDecisions = 0

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

			@currentPiwikStat++
			if @currentPiwikStat > piwikStatInterval
				@_sendFpsStats(fps)
				@currentPiwikStat = 0

	_sendFpsStats: (fps) =>
		piwikTracking.trackEvent(
			'FidelityControl', 'FpsAverage',
			FidelityControl.fidelityLevels[@currentFidelityLevel],
			fps
		)

	_adjustFidelity: (fps) =>
		return if @screenShotMode or not @autoAdjust

		if fps < minimalAcceptableFps and @currentFidelityLevel > 0
			# count how often we dropped below the desired fps
			# it has to occur at least @timesBelowThreshold times to cause a change
			@timesBelowMinimumFps++
			return if @timesBelowMinimumFps < timesBelowThreshold

			@timesBelowMinimumFps = 0
			if @currentFidelityLevel is FidelityControl.minimalPipelineLevel
				@noPipelineDecisions++
			@_decreaseFidelity()

		else if fps > upgradeThresholdFps and
		@currentFidelityLevel < FidelityControl.fidelityLevels.length - 1
			# upgrade instantly, but reset downgrade counter
			@timesBelowMinimumFps = 0
			if @currentFidelityLevel is FidelityControl.minimalPipelineLevel - 1
				return if @noPipelineDecisions > maxNoPipelineDecisions
			@_increaseFidelity()

	_increaseFidelity: =>
		# only allow pipeline when we have the extensions needed for it
		return if @currentFidelityLevel == 2 and not @pipelineAvailable

		# Increase fidelity
		@currentFidelityLevel++
		@_setFidelity()

		# Enable pipeline
		if @currentFidelityLevel >= FidelityControl.minimalPipelineLevel
			@bundle.renderer.pipelineEnabled = true

	_decreaseFidelity: =>
		# Decrease fidelity
		@currentFidelityLevel--
		@_setFidelity()

		# Disable pipeline
		if @currentFidelityLevel < FidelityControl.minimalPipelineLevel
			@bundle.renderer.pipelineEnabled = false

	_setFidelity: =>
		@pluginHooks.setFidelity(
			@currentFidelityLevel, FidelityControl.fidelityLevels, {}
		)
		@bundle.renderer.setFidelity(
			@currentFidelityLevel, FidelityControl.fidelityLevels, {}
		)

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
		if @currentFidelityLevel < FidelityControl.fidelityLevels.length - 1
			@_increaseFidelity()

	_manualDecrease: =>
		@autoAdjust = false
		@_decreaseFidelity() if @currentFidelityLevel > 0

	_setupFpsDisplay: =>
		return unless @showFps
		@lastDisplayUpdate = 0
		@$fpsDisplay = $('<div class="fps-display"></div>')
		$('body').append @$fpsDisplay

	_showFps: (timestamp, fps) =>
		return unless @showFps
		if timestamp - @lastDisplayUpdate > fpsDisplayUpdateTime
			@lastDisplayUpdate = timestamp
			levelAbbreviation = FidelityControl.fidelityLevels[@currentFidelityLevel]
				.match(/[A-Z]/g).join('')
			fpsText = Math.round(fps) + '/' + levelAbbreviation
			@$fpsDisplay.text fpsText

	# disables pipeline for screenshots
	enableScreenshotMode: =>
		@screenShotMode = true

		level = FidelityControl.fidelityLevels.indexOf 'DefaultHigh'
		@_levelBeforeScreenshot = @currentFidelityLevel
		@currentFidelityLevel = level

		@pluginHooks.setFidelity(
			level, FidelityControl.fidelityLevels
			screenshotMode: true
		)
		@bundle.renderer.setFidelity(
			level, FidelityControl.fidelityLevels
			screenshotMode: true
		)

	# resets screenshot mode, restores old fidelity level
	disableScreenshotMode: =>
		@screenShotMode = false

		@currentFidelityLevel = @_levelBeforeScreenshot

		@pluginHooks.setFidelity(
			@currentFidelityLevel, FidelityControl.fidelityLevels
			screenshotMode: false
		)
		@bundle.renderer.setFidelity(
			@currentFidelityLevel, FidelityControl.fidelityLevels
			screenshotMode: false
		)

	reset: =>
		@accumulatedFrames = 0
		@accumulatedTime = 0
		@timesBelowMinimumFps = 0
		@_lastTimestamp = null

module.exports = FidelityControl
