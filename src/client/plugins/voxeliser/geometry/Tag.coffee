class Tag
	constructor: (tag) ->
		if tag
			for key, value of tag
				@[key] = value

	set_Label: (key, value) ->
		@[key] = value
		@

	set_Labels_of: (obj) ->
		for key, value of obj
			@.set_Label key, value

	get_Label: (key) ->
		@[key]

	remove_Label: (key) ->
			delete @[key]

module.exports = Tag