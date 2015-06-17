# Removes the first occurence of the given object from the given array
module.exports.removeFirstOccurenceFromArray = (object, array) ->
	i = array.indexOf object
	if i != -1
		array.splice i, 1
	return

# Returns an array where all duplicate entries have been removed
module.exports.removeDuplicates = (array) ->
	a = array.concat()
	i = 0

	while i < a.length
		j = i + 1
		while j < a.length
			a.splice j--, 1  if a[i] is a[j]
			++j
		++i
	return a


module.exports.union = (arrayOfSets) ->
	union = new Set()
	for set in arrayOfSets
		set.forEach (element) ->
			union.add element
	return union

module.exports.minElement = (set) =>
	min = null
	set.forEach (element) ->
		min ?= element
		min = element if element < min
	return min