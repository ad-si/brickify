log = require 'loglevel'


class BrushHandler
	constructor: ( @bundle, @nodeVisualizer, @editController ) ->
		@highlightMaterial = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})

		@legoBrushSelected = false
		@bigBrushSelected = false

		document.getElementById('everythingLego').addEventListener 'click', =>
			@_everythingLego @nodeVisualizer.selectedNode

		document.getElementById('everythingPrinted').addEventListener 'click', =>
			@_everythingPrint @nodeVisualizer.selectedNode

	getBrushes: =>
		return [{
			containerId: '#legoBrush'
			selectCallback: @_legoSelect
			mouseDownCallback: @_legoMouseDown
			mouseMoveCallback: @_legoMouseMove
			mouseHoverCallback: @_legoMouseHover
			mouseUpCallback: @_legoMouseUp
			cancelCallback: @_legoCancel
		},{
			containerId: '#printBrush'
			selectCallback: @_printSelect
			mouseDownCallback: @_printMouseDown
			mouseMoveCallback: @_printMouseMove
			mouseHoverCallback: @_printMouseHover
			mouseUpCallback: @_printMouseUp
			cancelCallback: @_printCancel
		}]

	_legoSelect: (selectedNode, @bigBrushSelected) =>
		@legoBrushSelected = true
		return if @editController.interactionDisabled
		@nodeVisualizer.setDisplayMode selectedNode, 'legoBrush'

	_printSelect: (selectedNode, @bigBrushSelected) =>
		@legoBrushSelected = false
		return if @editController.interactionDisabled
		@nodeVisualizer.setDisplayMode selectedNode, 'printBrush'

	_legoMouseDown: (event, selectedNode) =>
		return if @interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxelLego event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_legoMouseMove: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxelLego event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_legoMouseUp: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.brickVisualization.updateModifiedVoxels()

			brush = 'LegoBrush'
			brush += 'Big' if @bigBrushSelected
			_paq.push(['trackEvent', 'Editor', 'BrushAction',  brush, touchedVoxels.length])

			return unless touchedVoxels.length > 0
			log.debug "Will re-layout #{touchedVoxels.length} voxel"

			@editController.relayoutModifiedParts(
				selectedNode, cachedData, touchedVoxels, true
			)
			cachedData.brickVisualization.unhighlightBigBrush()

	_legoMouseHover: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.brickVisualization.
				highlightVoxel event, selectedNode, '3d', @bigBrushSelected

	_legoCancel: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) ->
			cachedData.brickVisualization.resetTouchedVoxelsTo3dPrinted()
			cachedData.brickVisualization.updateVisualization()
			cachedData.brickVisualization.unhighlightBigBrush()

	_everythingLego: (selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			return unless cachedData.brickVisualization.makeAllVoxelsLego selectedNode
			_paq.push(['trackEvent', 'Editor', 'BrushAction', 'MakeEverythingLego'])
			@editController.rerunLegoPipeline selectedNode
			brickVis = cachedData.brickVisualization
			brickVis.updateModifiedVoxels()
			brickVis.updateVisualization(null, true)

	_printMouseDown: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxel3dPrinted event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_printMouseMove: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxel3dPrinted event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_printMouseUp: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.brickVisualization.updateModifiedVoxels()
		
			brush = 'PrintBrush'
			brush += 'Big' if @bigBrushSelected
			_paq.push(['trackEvent', 'Editor', 'BrushAction',  brush, touchedVoxels.length])

			return unless touchedVoxels.length > 0
			log.debug "Will re-layout #{touchedVoxels.length} voxel"

			@editController.relayoutModifiedParts(
				selectedNode, cachedData, touchedVoxels, true
			)
			cachedData.brickVisualization.unhighlightBigBrush()

	_printMouseHover: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.brickVisualization.
				highlightVoxel event, selectedNode, 'lego', @bigBrushSelected

	_printCancel: (event, selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) ->
			cachedData.brickVisualization.resetTouchedVoxelsToLego()
			cachedData.brickVisualization.updateVisualization()
			cachedData.brickVisualization.unhighlightBigBrush()

	_everythingPrint: (selectedNode) =>
		return if @editController.interactionDisabled
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			return unless cachedData.
				brickVisualization.makeAllVoxels3dPrinted selectedNode
			_paq.push(['trackEvent', 'Editor', 'BrushAction', 'MakeEverythingPrint'])
			cachedData.brickVisualization.updateModifiedVoxels()
			@editController.everythingPrint selectedNode

module.exports = BrushHandler
