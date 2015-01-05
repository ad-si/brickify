jade = require 'jade'
fs = require 'fs'
path = require 'path'
mkdirp = require 'mkdirp'
statcalc = require './statisticsCalculator'
git = require 'git-rev'
require('es6-promise').polyfill()

templateFile = path.join 'batchTesting', 'reportTemplate', 'report.jade'

module.exports.generateReport = (data, outPath, outFileName,
																 isLastReport, beginDate) ->
	return new Promise (resolve, reject) ->
		fs.readFile templateFile, (error, template) ->
			if error
				reject(error)
				return

			stats = statcalc.calculateNumericStatistics data
			fn = jade.compile template, {pretty: true}
			getGitInfo (branch, commit) ->
				gitinfo = {branch: branch, commit: commit}
				html = fn {
					results: data
					stats: stats
					gitinfo: gitinfo
					isWorkInProgress: (not isLastReport)}

				mkdirp path.dirname outFileName
				mergedFilename = generateDateTimeString(beginDate) + ' ' + outFileName
				fs.writeFileSync path.join(outPath, mergedFilename + '.html'), html

				fileContent =
					gitinfo: gitinfo
					datetime: generateDateTimeString(beginDate)
					testResults: data
					statistics: stats

				fs.writeFileSync path.join(outPath, mergedFilename + '.json'),
					JSON.stringify fileContent

				resolve()

generateDateTimeString = (d) ->
	return d
		.toJSON()
		.slice(0,-8)
		.replace(':','') + 'Z'

getGitInfo = (callback) ->
	git.long (commit) ->
		git.branch (branch) ->
			callback(branch, commit)
