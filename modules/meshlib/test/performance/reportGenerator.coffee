require('es6-promise').polyfill()
fs = require 'fs'
path = require 'path'

jade = require 'jade'
mkdirp = require 'mkdirp'
git = require 'git-rev'

statcalc = require './statisticsCalculator'


templateFile = path.join __dirname, 'templates', 'report.jade'


module.exports.generateReport = (outputFile) ->

	return new Promise (resolve, reject) ->

		fs.readFile templateFile, (error, template) ->
			if error
				reject(error)
				return

			#stats = statcalc.calculateNumericStatistics data

			htmlRenderer = jade.compile template, {pretty: true}

			getGitInfo (branch, commit) ->

				mkdirp path.dirname outputFile

				fs.writeFileSync outputFile, htmlRenderer({
					results: [] #data
					stats: [] #stats
					gitInfo: {
						branch: branch,
						commit: commit
					}
					isWorkInProgress: true #(not isLastReport)
				})

				# fileContent =
				# 	gitInfo: gitInfo
				# 	datetime: generateDateTimeString(beginDate)
				# 	testResults: data
				# 	statistics: stats

				# fs.writeFileSync path.join(outPath, mergedFilename + '.json'),
				# 	JSON.stringify fileContent

				resolve()

getGitInfo = (callback) ->
	git.long (commit) ->
		git.branch (branch) ->
			callback(branch, commit)
