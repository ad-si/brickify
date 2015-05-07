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

		#init modal
		@downloadModal.modal ({
			backdrop: 'static'
			keyboard: true
			show: false
		})

		#show modal when clicking on download button
		@downloadButton.click =>
			@downloadModal.modal 'show'

	_initDownloadModalContent: =>
		# stl download
		@downloadProvider = new DownloadProvider @workflowUi.bundle
		@downloadProvider.init(
			'#stlDownloadButton', @, @workflowUi.bundle.sceneManager
		)

		@studSizeSelect = $('#studSizeSelect')
		@holeSizeSelect = $('#holeSizeSelect')

		@studSizeSelect.on 'input', =>
			@_updateStudRadius()
		@holeSizeSelect.on 'input', =>
			@_updateStudRadius()

		@_updateStudRadius()

	_updateStudRadius: =>
		studSelection = @studSizeSelect.val()
		holeSelection = @holeSizeSelect.val()

		switch studSelection
			when '-3'
				@studRadius = 2.301
			when '-2'
				@studRadius = 2.334
			when '-1'
				@studRadius = 2.367
			when '0'
				@studRadius = 2.4
			when '+1'
				@studRadius = 2.433
			when '+2'
				@studRadius = 2.466
			when '+3'
				@studRadius = 2.499

		switch holeSelection
			when '-3'
				@holeRadius = 2.534
			when '-2'
				@holeRadius = 2.567
			when '-1'
				@holeRadius = 2.6
			when '0'
				@holeRadius = 2.633
			when '+1'
				@holeRadius = 2.666
			when '+2'
				@holeRadius = 2.699
			when '+3'
				@holeRadius = 2.732


module.exports = ExportUi
