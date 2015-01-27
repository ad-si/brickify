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
		stats.variableName = key
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

	# search the numPolygons sum and calculate the average for 1000 polygons
	sumPoly = 0
	for s in result
		if s.variableName == 'numPolygons'
			sumPoly = s.sum
			break

	for s in result
		s.avgPer1000Polys = (s.sum / sumPoly) * 1000

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
		@avgPer1000Polys = 0
module.exports.NumericStatistic = NumericStatistic
