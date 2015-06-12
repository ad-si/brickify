class HintUi
	constructor: ->
		@hintContainer = $('#usageHintContainer')
		@moveHint = @hintContainer.find('#moveHint')
		@brushHint = @hintContainer.find('#brushHint')
		@rotateHint = @hintContainer.find('#rotateHint')
		@zoomHint = @hintContainer.find('#zoomHint')

		if not @_userNeedsHint()
			@moveHint.hide()
			@brushHint.hide()
			@rotateHint.hide()
			@zoomHint.hide()

	pointerMove: (event, handeled) =>
		# ignore plain mouse movement
		return if event.buttons == 0

		switch event.button
			when 0
				# left mouse button
				if not handeled
					@rotateHint.fadeOut()
				else
					@brushHint.fadeOut()
			when 1
				# middle mouse button
				@zoomHint.fadeOut()
			when 2
				# right mouse button
				@moveHint.fadeOut()

	mouseWheel: =>
		@zoomHint.fadeOut()

	# Checks whether a cookie for hints exists,
	# sets one if it does not exist
	_userNeedsHint: ->
		if document.cookie.indexOf('usageHintsShown=yes') >= 0
			return false

		d = new Date()
		# Let cookie expire in 5 days
		d.setDate(d.getDate() + 5)

		cookieString = 'usageHintsShown=yes; expires='
		cookieString += d.toUTCString()

		document.cookie = cookieString
		return true


module.exports = HintUi
