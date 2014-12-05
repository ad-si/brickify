jade = require 'jade'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
statcalc = require './statisticsCalculator'
git = require 'git-rev'

templateFile = path.join 'batchTesting', 'reportTemplate', 'report.jade'

module.exports.generateReport = (data, outPath, outFileName) ->
	template = fs.readFileSync templateFile
	stats = statcalc.calculateNumericStatistics data
	fn = jade.compile template, {pretty: true}
	getGitInfo (branch, commit) ->
		gitinfo = {branch: branch, commit: commit}
		html = fn {results: data, stats: stats, gitinfo: gitinfo}
		mkdirp path.dirname outFileName
		mergedFilename = generateDateTimeString() + ' ' + outFileName
		fs.writeFileSync path.join(outPath, mergedFilename + '.html'), html

		fileContent =
			gitinfo: gitinfo
			datetime: generateDateTimeString()
			testResults: data
			statistics: stats

		fs.writeFileSync path.join(outPath, mergedFilename + '.json'),
			JSON.stringify fileContent

generateDateTimeString = () ->
	new Date()
		.toJSON()
		.slice(0,-8)
		.replace(':','') + 'Z'

getGitInfo = (callback) ->
	git.long (commit) ->
		git.branch (branch) ->
			callback(branch, commit)


