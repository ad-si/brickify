class ExportUi
	constructor: ->
		@$panel = $("#exportGroup")

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

module.exports = ExportUi
