DownloadProvider = require './downloadProvider'

class ExportUi
	constructor: (@workflowUi) ->
		@$panel = $('#exportGroup')
		@_initDownloadModal()
		@_initDownloadModalContent()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

	_initDownloadModal: =>
		@downloadButton = $('#downloadButton')
		@downloadModal = $('#downloadModal')
		@downloadCloseButton = $('#downloadCloseButton')

		#init modal
		@downloadModal.modal ({
			backdrop: 'static'
			keybaord: true
			show: false
		})

		#show modal when clicking on download button
		@downloadButton.click =>
			@downloadModal.modal 'show'

		# dismiss modal when clicking on Close
		@downloadCloseButton.click =>
			@downloadModal.modal 'hide'

	_initDownloadModalContent: =>
		@downloadProvider = new DownloadProvider @workflowUi.bundle
		@downloadProvider.init '#downloadButton', @workflowUi.bundle.sceneManager


module.exports = ExportUi
