class PreviewAssemblyUi
	constructor: (@previewUi) ->
		@buildContainer = $('#buildContainer')
		@buildContainer.hide()
		@buildContainer.removeClass 'hidden'

		@buildStepUi = {
			slider: $('#buildSlider')
			decrement: $('#buildDecrement')
			increment: $('#buildIncrement')
			curLayer: $('#currentBuildStep')
			maxLayer: $('#maxBuildStep')
		}

		@buildStepUi.slider.on 'input', =>
			@_updateBuildStep @previewUi.sceneManager.selectedNode

		@buildStepUi.increment.on 'click', =>
			@buildStepUi.slider.val Number(@buildStepUi.slider.val()) + 1
			@_updateBuildStep @previewUi.sceneManager.selectedNode

		@buildStepUi.decrement.on 'click', =>
			@buildStepUi.slider.val Number(@buildStepUi.slider.val()) - 1
			@_updateBuildStep @previewUi.sceneManager.selectedNode

	setEnabled: (enabled) =>
		if enabled
			@_enableBuildMode @previewUi.sceneManager.selectedNode
		else
			@_disableBuildMode @previewUi.sceneManager.selectedNode

	_enableBuildMode: (selectedNode) =>
		@buildContainer.slideDown()

		@preBuildMode = @previewUi.nodeVisualizer.getDisplayMode()
		@previewUi.nodeVisualizer.setDisplayMode selectedNode, 'build'
		.then =>
			@previewUi.nodeVisualizer.getNumberOfBuildSteps selectedNode
			.then (numLayers) =>
				# Last layer is for print geometry
				@buildStepUi.slider.attr 'min', 1
				@buildStepUi.slider.attr 'max', numLayers
				@buildStepUi.maxLayer.text numLayers

				@buildStepUi.slider.val 1
				@_updateBuildStep selectedNode

	_updateBuildStep: (selectedNode) =>
		layer = Number @buildStepUi.slider.val()
		@buildStepUi.curLayer.text layer
		@previewUi.nodeVisualizer.showBuildStep selectedNode, layer

	_disableBuildMode: (selectedNode) =>
		@buildContainer.slideUp()
		@previewUi.nodeVisualizer.setDisplayMode selectedNode, @preBuildMode

module.exports = PreviewAssemblyUi
