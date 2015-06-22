class HintUi
	constructor: ->
		@$hintContainer = $('#usageHintContainer')
		@$moveHint = @$hintContainer.find('#moveHint')
		@$brushHint = @$hintContainer.find('#brushHint')
		@$rotateHint = @$hintContainer.find('#rotateHint')
		@$zoomHint = @$hintContainer.find('#zoomHint')

		if @_userNeedsHint()
			@$hintContainer.show()
			@moveHintVisible = true
			@brushHintVisible = true
			@rotateHintVisible = true
			@zoomHintVisible = true

	pointerDown: (event, handled) =>
		return if event.buttons == 0

		switch event.button
			when 0, 2
				# Left or right mouse button
				if handled
					@$brushHint.fadeOut()
					@brushHintVisible = false

		if not @_anyHintVisible()
			@$hintContainer.hide()
			@_disableHintsOnReload()

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
				if not handled
					@$moveHint.fadeOut()
					@moveHintVisible = false
				else
					@$brushHint.fadeOut()
					@brushHintVisible = false

		if not @_anyHintVisible()
			@$hintContainer.hide()
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
