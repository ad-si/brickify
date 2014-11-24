# expects an array of uniform elements (=all elements have the same
# properties/variables) and calculates numeric (min max avg...)
# statistics for each property based on all objects in the array
calculateNumericStatistics = (data) ->
	keys = Object.keys data[0]
	result = []
	for key in keys
		if key == 'fileName'
			continue

		stats = new NumericStatistic()
		stats.key = key
		for obj in data
			value = obj[key]
			if value?
				if stats.min > value
					stats.min = value
				if stats.max < value
					stats.max  = value
				stats.sum += value
				stats.numValues++
				stats.avg += value
		stats.avg = stats.avg / stats.numValues
		result.push stats
	return result
module.exports.calculateNumericStatistics = calculateNumericStatistics

class NumericStatistic
	constructor: () ->
		@variableName = ''
		@min = 999999
		@max = 0
		@sum = 0
		@numValues = 0
		@avg = 0
module.exports.NumericStatistic = NumericStatistic
