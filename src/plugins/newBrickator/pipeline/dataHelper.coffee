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

# returns whether or not at least one element of the input
# array in not null/undefined
module.exports.anyDefinedInArray = (array) ->
	return array.some (entry) -> entry?

# returns the union of all sets in the argument
# input sets remain intact
module.exports.setUnion = (arrayOfSets) ->
	union = new Set()
	for set in arrayOfSets
		set.forEach (element) ->
			union.add element
	return union

# returnsthe intersect of two sets
module.exporst.setIntersection = (set1, set2) ->
	intersection = new Set()
	set1.forEach (element) ->
		intersection.add element if set2.has element
	return intersection

#returns set1 \ set2
module.exports.setDifference = (set1, set2) ->
	difference = new Set()
	set1.forEach (element) ->
		difference.add element unless set2.has element
	return difference