DownloadProvider = require './downloadProvider'
UiObjects = require './objects'

module.exports = class WorkflowUi
	constructor: (@bundle) ->
		@downloadProvider = new DownloadProvider(@bundle)
		@objects = new UiObjects(@bundle)

	init: () =>
		@sceneManager = @bundle.sceneManager
		@downloadProvider.init('#downloadButton', @sceneManager)
		@objects.init('#objectsContainer', '#brushContainer', '#visibilityContainer')
		@newBrickator = @bundle.getPlugin 'newBrickator'

		@_initStabilityCheck()
		@_initBuildButton()
		@_initNotImplementedMessages()

	_initStabilityCheck: () =>
		$('#stabilityCheckButton').on 'click', () =>
			$('#stabilityCheckButton').toggleClass 'active'
			@newBrickator._toggleStabilityView @sceneManager.selectedNode

	_initBuildButton: () =>
		@buildButton = $('#buildButton')
		@buildModeEnabled = false

		@buildContainer = $('#buildContainer')
		@buildContainer.hide()
		@buildContainer.removeClass 'hidden'

		@buildLayerUi = {
			slider: $('#buildSlider')
			decrement: $('#buildDecrement')
			increment: $('#buildIncrement')
			curLayer: $('#currentBuildLayer')
			maxLayer: $('#maxBuildLayer')
			}

		@buildLayerUi.slider.on 'input', () =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.increment.on 'click', () =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v++
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.decrement.on 'click', () =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v--
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildButton.click () =>
			selectedNode = @bundle.sceneManager.selectedNode

			if @buildModeEnabled
				@buildContainer.slideUp()
				@buildButton.removeClass('active')
				@_disableBuildMode selectedNode
			else
				@buildContainer.slideDown()
				@buildButton.addClass('active')
				@_enableBuildMode selectedNode

			@buildModeEnabled = !@buildModeEnabled

	_enableBuildMode: (selectedNode) =>
		@newBrickator.enableBuildMode(selectedNode).then (numZLayers) =>
			#hide brushes
			@bundle.ui.workflowUi.objects.hideBrushContainer()
	
			# apply grid size to layer view
			@buildLayerUi.slider.attr('min', 0)
			@buildLayerUi.slider.attr('max', numZLayers)
			@buildLayerUi.maxLayer.html(numZLayers)

			@buildLayerUi.slider.val(1)
			@_updateBuildLayer selectedNode

	_updateBuildLayer: (selectedNode) =>
		layer = @buildLayerUi.slider.val()
		@buildLayerUi.curLayer.html(Number(layer))

		@newBrickator.showBuildLayer(selectedNode, layer)

	_disableBuildMode: (selectedNode) =>
		@newBrickator.disableBuildMode(selectedNode).then () =>
			#show brushes
			@bundle.ui.workflowUi.objects.showBrushContainer()


	_initNotImplementedMessages: () =>
		alertCallback = () ->
			bootbox.alert({
					title: 'Not implemented yet'
					message: 'We are sorry, but this feature is not implemented yet.
					 Please check back later.'
			})

		$('#everythingPrinted').click alertCallback
		$('#everythingLego').click alertCallback
		$('#downloadPdfButton').click alertCallback
		$('#shareButton').click alertCallback


