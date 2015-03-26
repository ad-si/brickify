class EditUi
	constructor: ->
		@$panel = $("#editGroup")

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

module.exports = EditUi
