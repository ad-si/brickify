require('es6-promise').polyfill()
fs = require 'fs'
path = require 'path'

jade = require 'jade'
mkdirp = require 'mkdirp'
git = require 'git-rev'


templateFile = path.join __dirname, 'templates', 'report.jade'


module.exports.generateReport = (outputFile) ->

	return new Promise (resolve, reject) ->

		fs.readFile templateFile, (error, template) ->
			if error
				reject(error)
				return

			htmlRenderer = jade.compile template, {pretty: true}

			getGitInfo (branch, commit) ->

				mkdirp path.dirname outputFile

				fs.writeFileSync outputFile, htmlRenderer({
					gitInfo: {
						branch: branch,
						commit: commit
					}
				})

				resolve()

getGitInfo = (callback) ->
	git.long (commit) ->
		git.branch (branch) ->
			callback(branch, commit)
