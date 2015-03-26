class PreviewUi
	constructor: ->
		@$panel = $("#previewGroup")

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

module.exports = PreviewUi
