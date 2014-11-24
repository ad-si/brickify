jade = require 'jade'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
statcalc = require './statisticsCalculator'

templateFile = path.join 'batchTesting', 'reportTemplate', 'report.jade'

module.exports.generateReport = (data, outFileName) ->
	template = fs.readFileSync templateFile
	stats = statcalc.calculateNumericStatistics data
	fn = jade.compile template, {pretty: true}
	html = fn {results: data, stats: stats}
	mkdirp path.dirname outFileName
	fs.writeFileSync outFileName, html
