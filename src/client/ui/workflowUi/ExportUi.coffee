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
			show: true
		})

		#show modal when clicking on download button
		@downloadButton.click =>
			@downloadModal.modal 'show'

		# dismiss modal when clicking on Close
		@downloadCloseButton.click =>
			@downloadModal.modal 'hide'

	_initDownloadModalContent: =>
		# stl download
		@downloadProvider = new DownloadProvider @workflowUi.bundle
		@downloadProvider.init(
			'#stlDownloadButton', @, @workflowUi.bundle.sceneManager
		)

		@stripeSlider = $('#stripeSlider')
		@stripeText = $('#stripeText')

		@studRadius = 2.4
		@stripeSlider.on 'input', =>
			v = parseInt(@stripeSlider.val())
			# stud radius is set in mm and to match the test strip
			@studRadius = 2.4 + 0.05 * v
			v = '+' + v if v > 0
			v = '±0' if v == 0
			v = v.toFixed(0) if v < 0
			@stripeText.html(v)

module.exports = ExportUi
