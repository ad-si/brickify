class EditUi
	constructor: ->
		@$panel = $("#editGroup")

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel').toggleClass 'disabled', !enabled

module.exports = EditUi
