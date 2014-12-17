log = (content) -> console.log content if Debug

Array::merge = (other) -> Array::push.apply @, other; @

Array::unique = ->
	output = {}
	output[@[key]] = @[key] for key in [0...@length]
	value for key, value of output

Array::is = (other_array) ->
	@.length is other_array.length and @.every (elem, i) -> elem is other_array[i]

Array::fillWith = (content) ->
	for slot in @
		slot = content

Array::shuffle = ->
	copy = @.slice(0)
	copy.splice(Math.floor(randomNumber() * key), 1)[0] for key in [@length..1]

Array::merge = (other) -> Array::push.apply @, other

Array::is_empty = () -> @.length == 0
Array::is_not_empty = () -> @.length > 0

Array::first = () -> @[0]
Array::second = () -> @[1]
Array::third = () -> @[2]
Array::last = () -> @[@.length - 1]

Array::includes = (element) -> -1 != @.indexOf element
Array::add = (element) -> @.push element

Array::add_unique = (element) -> @.add element unless @.includes element

Array::clone = -> @.slice 0

Array::remove = (element) ->
	index = @.indexOf element
	@.splice index, 1 if index != -1
	@


Math.between = (value, min, max) -> Math.min Math.max(value, min), max
