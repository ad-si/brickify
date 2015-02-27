module.exports.removeFirstOccurenceFromArray = (object, array) ->
	i = array.indexOf object
	if i != -1
		array.splice i, 1
	return