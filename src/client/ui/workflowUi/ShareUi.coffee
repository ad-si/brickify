piwikTracking = require '../../piwikTracking'

class ShareUi
	constructor: ->
		@$shareButton = $('#shareButton')
		@_initNotImplementedMessages()

	_initNotImplementedMessages: ->
		alertCallback = ->
			bootbox.alert({
				title: 'Not implemented yet'
				message: 'We are sorry, but this feature is not implemented yet.
						 Please check back later.'
			})

		@$shareButton.click ->
			piwikTracking.trackEvent(
				'trackEvent', 'Editor', 'ExportAction', 'ShareButtonClick'
			)
			alertCallback()

	setEnabled: (enabled) =>
		@$shareButton.toggleClass 'disabled', !enabled

module.exports = ShareUi
