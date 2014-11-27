jade = require 'jade'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
statcalc = require './statisticsCalculator'

templateFile = path.join 'batchTesting', 'reportTemplate', 'report.jade'

module.exports.generateReport = (data, outPath, outFileName) ->
	template = fs.readFileSync templateFile
	stats = statcalc.calculateNumericStatistics data
	fn = jade.compile template, {pretty: true}
	html = fn {results: data, stats: stats}
	mkdirp path.dirname outFileName
	mergedFilename = generateDateTimeString() + ' ' + outFileName
	fs.writeFileSync path.join(outPath, mergedFilename + '.html'), html
	fs.writeFileSync path.join(outPath, mergedFilename + '.json'),
		JSON.stringify data
	fs.writeFileSync path.join(outPath, mergedFilename + '-statistics.json'),
		JSON.stringify stats

generateDateTimeString = () ->
	new Date()
		.toJSON()
		.slice(0,-8)
		.replace(':','') + 'Z'
