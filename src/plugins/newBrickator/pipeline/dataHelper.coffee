# returns whether or not at least one element of the input
# array in not null/undefined
module.exports.anyDefinedInArray = (array) ->
	return array.some (entry) -> entry?

# returns the union of all sets in the argument
# input sets remain intact
module.exports.union = (arrayOfSets) ->
	union = new Set()
	for set in arrayOfSets
		set.forEach (element) ->
			union.add element
	return union

# returns the intersect of two sets
module.exports.intersection = (set1, set2) ->
	intersection = new Set()
	set1.forEach (element) ->
		intersection.add element if set2.has element
	return intersection

# returns set1 \ set2
module.exports.difference = (set1, set2) ->
	difference = new Set()
	set1.forEach (element) ->
		difference.add element unless set2.has element
	return difference

module.exports.smallestElement = (set) =>
	min = null
	set.forEach (element) ->
		min ?= element
		min = element if element < min
	return min
