jade = require 'jade'
fs = require 'fs'

templateFile = './batchTesting/reportTemplate/report.jade'

module.exports.generateReport = (data, outFileName) ->
	template = fs.readFileSync templateFile
	stats = calculateStatistics data
	fn = jade.compile template, {pretty: true}
	html = fn {results: data, stats: stats}
	fs.writeFileSync outFileName, html

# calculates statistics for all individual members
calculateStatistics = (data) ->
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

class NumericStatistic
	constructor: () ->
		@variableName = ''
		@min = 999999
		@max = 0
		@sum = 0
		@numValues = 0
		@avg = 0