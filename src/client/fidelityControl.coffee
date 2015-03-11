class FidelityControl
	constructor: (@pluginHooks) ->
		@minimalAcceptableFps = 20
		@upgradeThresholdFps = 50

		@canIncreaseVisualQuality = true
		@canDecreaseVisualQuality = true

		@autoAdjust = true

	updateFps: (fps) =>
		return if not @autoAdjust

		if fps < @minimalAcceptableFps and @canDecreaseVisualQuality
			console.log 'Will decrease visual Quality because of bad framerate'
			results = @pluginHooks.uglify()

			# there must always a way back
			@canIncreaseVisualQuality = true

			# if there is no plugin that can still decrease quality (return true), then
			# we don't need to try it again
			if not results.indexOf(true) >= 0
				@canDecreaseVisualQuality = false

		else if fps > @upgradeThresholdFps and @canIncreaseVisualQuality
			console.log 'Will increase visual quality because of good framerate'
			results = @pluginHooks.beautify()

			@canDecreaseVisualQuality = true

			# same goes for increasing quality
			if not results.indexOf(true) >= 0
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
