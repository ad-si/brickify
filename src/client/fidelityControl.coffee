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
			results = @pluginHooks.decreaseVisualQuality()

			# there must always a way back
			@canIncreaseVisualQuality = true

			# if there is no plugin that can still decrease quality (return true), then
			# we don't need to try it again
			if not @_anyTrue results
				@canDecreaseVisualQuality = false

		else if fps > @upgradeThresholdFps and @canIncreaseVisualQuality
			console.log 'Will increase visual quality because of good framerate'
			results = @pluginHooks.increaseVisualQuality()

			@canDecreaseVisualQuality = true

			# same goes for increasing quality
			if not @_anyTrue results
				@canIncreaseVisualQuality = false

	_anyTrue: (arrayOfBoolean) ->
		return false if arrayOfBoolean.length == 0
		return arrayOfBoolean.some (value) -> return value

	getHotkeys: () =>
		return {
			title: 'Visual Quality'
			events: [
				{
					description: 'Increase visual quality (turns off automatic adjustment)'
					hotkey: 'i'
					callback: @_manualIncrease
				}
				{
					description: 'Decrease visual quality (turns off automatic adjustment)'
					hotkey: 'd'
					callback: @_manualDecrease
				}
			]
		}

	_manualIncrease: =>
		@autoAdjust = false
		@pluginHooks.increaseVisualQuality()

	_manualDecrease: =>
		@autoAdjust = false
		@pluginHooks.decreaseVisualQuality()

module.exports = FidelityControl
