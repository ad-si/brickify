class ExportUi
	constructor: ->
		@$panel = $("#exportGroup")

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

module.exports = ExportUi
