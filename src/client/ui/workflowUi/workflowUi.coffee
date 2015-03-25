DownloadProvider = require './downloadProvider'
BrushSelector = require './brushSelector'
perfectScrollbar = require 'perfect-scrollbar'

module.exports = class WorkflowUi
	constructor: (@bundle) ->
		@downloadProvider = new DownloadProvider(@bundle)
		@brushSelector = new BrushSelector(@bundle)
		@numObjects = 0

	# Called by sceneManager when a node is added
	onNodeAdd: (node) =>
		@numObjects++

		# enable rest of UI
		@_enableUiGroups ['load', 'edit', 'preview', 'export']

	# Called by sceneManager when a node is removed
	onNodeRemove: (node) =>
		if @stabilityCheckModeEnabled
			@stabilityCheckModeEnabled = false
			@_enableNonStabilityUi()
			@_setStabilityCheckButtonActive false

		@numObjects--

		if @numObjects == 0
			# disable rest of UI
			@_enableUiGroups ['load']

	onNodeSelect: (node) =>
		@brushSelector.onNodeSelect node

	onNodeDeselect: (node) =>
		@brushSelector.onNodeDeselect node

	init: =>
		@sceneManager = @bundle.sceneManager
		@downloadProvider.init('#downloadButton', @sceneManager)
		@brushSelector.init '#brushContainer'
		@nodeVisualizer = @bundle.getPlugin 'nodeVisualizer'

		@_initStabilityCheck()
		@_initBuildButton()
		@_initNotImplementedMessages()
		@_initScrollbar()

		# only enable load ui until a model is loaded
		@_enableUiGroups ['load']

	_initStabilityCheck: =>
		@stabilityCheckButton = $('#stabilityCheckButton')
		@stabilityCheckModeEnabled = false

		@stabilityCheckButton.on 'click', @toggleStabilityView

	_applyStabilityViewMode: =>
		#disable other UI
		if @stabilityCheckModeEnabled
			@_disableNonStabilityUi()
		else
			@_enableNonStabilityUi()

		@_setStabilityCheckButtonActive @stabilityCheckModeEnabled
		@nodeVisualizer._setStabilityView(
			@sceneManager.selectedNode, @stabilityCheckModeEnabled
		)

	_initBuildButton: =>
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

		@buildLayerUi.slider.on 'input', =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.increment.on 'click', =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v++
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildLayerUi.decrement.on 'click', =>
			selectedNode = @bundle.sceneManager.selectedNode
			v = @buildLayerUi.slider.val()
			v--
			@buildLayerUi.slider.val(v)
			@_updateBuildLayer(selectedNode)

		@buildButton.click =>
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
		@nodeVisualizer.enableBuildMode(selectedNode).then (numZLayers) =>
			# disable other UI
			@_disableNonBuildUi()

			# apply grid size to layer view
			@buildLayerUi.slider.attr('min', 0)
			@buildLayerUi.slider.attr('max', numZLayers)
			@buildLayerUi.maxLayer.html(numZLayers)

			@buildLayerUi.slider.val(1)
			@_updateBuildLayer selectedNode

	_updateBuildLayer: (selectedNode) =>
		layer = @buildLayerUi.slider.val()
		@buildLayerUi.curLayer.html(Number(layer))

		@nodeVisualizer.showBuildLayer(selectedNode, layer)

	_disableBuildMode: (selectedNode) =>
		@nodeVisualizer.disableBuildMode(selectedNode).then =>
			# enable other ui
			@_enableNonBuildUi()


	_disableNonBuildUi: =>
		@_enableUiGroups ['preview']
		@stabilityCheckButton.addClass 'disabled'

	_enableNonBuildUi: =>
		@_enableUiGroups ['load', 'edit', 'preview', 'export']
		@stabilityCheckButton.removeClass 'disabled'

	_disableNonStabilityUi: =>
		@_enableUiGroups ['preview']
		@buildButton.addClass 'disabled'

	_enableNonStabilityUi: =>
		@_enableUiGroups ['load', 'edit', 'preview', 'export']
		@buildButton.removeClass 'disabled'

	_enableUiGroups: (groupsList) =>
		availableGroups = [
			'load', 'edit', 'preview', 'export'
		]

		for group in availableGroups
			if groupsList.indexOf(group) >= 0
				$("##{group}Group").find('.btn, .panel').removeClass 'disabled'
			else
				$("##{group}Group").find('.btn, .panel').addClass 'disabled'

	_setStabilityCheckButtonActive: (active) =>
		@stabilityCheckButton.toggleClass 'active', active

	_initNotImplementedMessages: =>
		alertCallback = ->
			bootbox.alert({
					title: 'Not implemented yet'
					message: 'We are sorry, but this feature is not implemented yet.
					 Please check back later.'
			})

		$('#everythingPrinted').click alertCallback
		$('#everythingLego').click alertCallback
		$('#downloadPdfButton').click alertCallback
		$('#shareButton').click alertCallback

	_initScrollbar: =>
		sidebar = document.getElementById 'leftSidebar'
		perfectScrollbar.initialize sidebar
		window.addEventListener 'resize', -> perfectScrollbar.update sidebar

	toggleStabilityView: =>
		@stabilityCheckModeEnabled = !@stabilityCheckModeEnabled
		@_applyStabilityViewMode()
