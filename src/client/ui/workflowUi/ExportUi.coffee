DownloadProvider = require './downloadProvider'
piwikTracking = require '../../piwikTracking'

class ExportUi
	constructor: (@workflowUi) ->
		{@studSize, @holeSize, @exportStepSize} = @workflowUi.bundle.globalConfig

		@$panel = $('#exportGroup')
		@_initDownloadModal()
		@_initDownloadModalContent()

	setEnabled: (enabled) =>
		@$panel.find('.btn, .panel, h4').toggleClass 'disabled', !enabled

	_initDownloadModal: =>
		@downloadButton = $('#downloadButton')
		@downloadModal = $('#downloadModal')

		#show modal when clicking on download button
		@downloadButton.click =>
			piwikTracking.trackEvent 'Editor', 'ExportAction', 'DownloadButtonClick'
			@downloadModal.modal 'show'

	_initDownloadModalContent: =>
		# Stl download
		@downloadProvider = new DownloadProvider {
			bundle: @workflowUi.bundle
			selectorString: '#stlDownloadButton'
			exportUi: @
			sceneManager: @workflowUi.bundle.sceneManager
		}

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


module.exports = ExportUi
