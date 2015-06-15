DownloadProvider = require './DownloadProvider'
downloadModal = require '../downloadModal'
piwikTracking = require '../../piwikTracking'

class DownloadUi
	constructor: (@bundle) ->
		{@studSize, @holeSize, @exportStepSize} = @bundle.globalConfig

		@_initDownloadModal()
		@_initDownloadModalContent()
		@$panel = $('#downloadButton')

	setEnabled: (enabled) =>
		@$panel.toggleClass 'disabled', !enabled
		@$downloadModal.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

	_initDownloadModal: =>
		@$downloadModal = downloadModal @bundle.globalConfig.downloadSettings
		$('body').append @$downloadModal
		@downloadButton = $('#downloadButton')

		#show modal when clicking on download button
		@downloadButton.click =>
			piwikTracking.trackEvent 'Editor', 'ExportAction', 'DownloadButtonClick'
			@$downloadModal.modal 'show'

	_initDownloadModalContent: =>
		# stl download
		@downloadProvider = new DownloadProvider @bundle
		@downloadProvider.init(
			'#stlDownloadButton', '#downloadInstructionsButton',
			@, @bundle.sceneManager
		)

		@studSizeSelect = $('#studSizeSelect')
		@holeSizeSelect = $('#holeSizeSelect')

		@studSizeSelect.on 'input', =>
			@_updateStudRadius()
		@holeSizeSelect.on 'input', =>
			@_updateHoleRadius()

		@_updateStudRadius()
		@_updateHoleRadius()

	_updateStudRadius: =>
		studSelection = parseInt @studSizeSelect.val()
		@studRadiusSelection = @studSizeSelect.val()
		@studRadius = @studSize.radius + studSelection * @exportStepSize

	_updateHoleRadius: =>
		holeSelection = parseInt @holeSizeSelect.val()
		@holeRadiusSelection = @holeSizeSelect.val()
		@holeRadius = @holeSize.radius + holeSelection * @exportStepSize


module.exports = DownloadUi
