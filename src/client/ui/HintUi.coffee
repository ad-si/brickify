class HintUi
	constructor: ->
		@$hintContainer = $('#usageHintContainer')
		@$moveHint = @$hintContainer.find('#moveHint')
		@moveHintVisible = true
		@$brushHint = @$hintContainer.find('#brushHint')
		@brushHintVisible = true
		@$rotateHint = @$hintContainer.find('#rotateHint')
		@rotateHintVisible = true
		@$zoomHint = @$hintContainer.find('#zoomHint')
		@zoomHintVisible = true

		if not @_userNeedsHint()
			@$moveHint.hide()
			@$brushHint.hide()
			@$rotateHint.hide()
			@$zoomHint.hide()

	pointerMove: (event, handled) =>
		# Ignore plain mouse movement
		return if event.buttons == 0

		switch event.button
			when 0
				# Left mouse button
				if not handled
					@$rotateHint.fadeOut()
					@rotateHintVisible = false
				else
					@$brushHint.fadeOut()
					@brushHintVisible = false
			when 1
				# Middle mouse button
				@$zoomHint.fadeOut()
				@zoomHintVisible = false
			when 2
				# Right mouse button
				@$moveHint.fadeOut()
				@moveHintVisible = false

		if not @_anyHintVisible()
			@_disableHintsOnReload()

	mouseWheel: =>
		@$zoomHint.fadeOut()
		@zoomHintVisible = false

	# Checks whether a cookie for hints exists,
	# sets one if it does not exist
	_userNeedsHint: ->
		return document.cookie.indexOf('usageHintsShown=yes') < 0

	# Disables the hints for the next 5 days
	_disableHintsOnReload: ->
		d = new Date()
		d.setDate(d.getDate() + 5)

		cookieString = 'usageHintsShown=yes; expires='
		cookieString += d.toUTCString()

		document.cookie = cookieString

	_anyHintVisible: =>
		return @moveHintVisible or @brushHintVisible or
		@zoomHintVisible or @rotateHintVisible

module.exports = HintUi
