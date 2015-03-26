class LoadUi
	constructor: ->
		@$panel = $("#loadGroup")

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

module.exports = LoadUi
