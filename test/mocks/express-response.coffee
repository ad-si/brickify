class Response
	constructor: ->
		@whenSent = new Promise((resolve, reject) =>
			@setContent = (type) => (@content) =>
				@type = type
				resolve()
		)

	status: (@code) =>
		return {
		json: @setContent 'json'
		send: @setContent 'text'
		}

	location: (@location) =>
		return @

module.exports = Response
