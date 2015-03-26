class PreviewUi
	constructor: ->
		@$panel = $("#previewGroup")

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

module.exports = PreviewUi
