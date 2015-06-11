class HintUi
	constructor: ->
		@hintContainer = $('#usageHintContainer')
		@moveHint = @hintContainer.find('#moveHint')
		@brushHint = @hintContainer.find('#brushHint')
		@rotateHint = @hintContainer.find('#rotateHint')
		@zoomHint = @hintContainer.find('#zoomHint')

	pointerMove: (event, handeled) ->
		# ignore plain mouse movement
		return if event.buttons == 0

		switch event.button
			when 0 
				if not handeled
					@rotateHint.fadeOut()
				else
					@brushHint.fadeOut()
			when 1
				@zoomHint.fadeOut()
			when 2
				@moveHint.fadeOut()

module.exports = HintUi