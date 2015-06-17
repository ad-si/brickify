ShareUi =  require './ShareUi'
DownloadUi = require './DownloadUi'

class ExportUi
	constructor: (workflowUi) ->
		@$panel = $('#exportGroup')
		@bundle = workflowUi.bundle

		@_initShare()
		@_initDownload()

	setEnabled: (enabled) =>
		@$panel.find('h4').toggleClass 'disabled', !enabled
		@shareUi.setEnabled enabled
		@downloadUi.setEnabled enabled

	_initShare: =>
		@shareUi = new ShareUi @

	_initDownload: =>
		@downloadUi = new DownloadUi @

module.exports = ExportUi
