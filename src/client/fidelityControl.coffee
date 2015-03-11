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
			results = @pluginHooks.uglify()

			# assume that there is a way back if we can decrease quality
			@canIncreaseVisualQuality = true

			# if there is no plugin that can still decrease quality (return true), then
			# we don't need to try it again
			if not true in results
				@canDecreaseVisualQuality = false

		else if fps > @upgradeThresholdFps and @canIncreaseVisualQuality
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
