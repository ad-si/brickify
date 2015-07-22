log = require 'loglevel'
piwikTracking = require '../../client/piwikTracking'

class BrushHandler
	constructor: ( @bundle, @nodeVisualizer, @editController ) ->
		@undo = @bundle.getPlugin 'undo'

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
			onBrushSelect: @_legoSelect
			onBrushDown: @_legoDown
			onBrushMove: @_legoMove
			onBrushOver: @_legoHover
			onBrushUp: @_legoUp
			onBrushCancel: @_legoCancel
		}, {
			containerId: '#printBrush'
			onBrushSelect: @_printSelect
			onBrushDown: @_printDown
			onBrushMove: @_printMove
			onBrushOver: @_printHover
			onBrushUp: @_printUp
			onBrushCancel: @_printCancel
		}]

	_legoSelect: (selectedNode, @bigBrushSelected) =>
		@legoBrushSelected = true
		return if @editController.interactionDisabled
		@nodeVisualizer.setDisplayMode selectedNode, 'legoBrush'

	_printSelect: (selectedNode, @bigBrushSelected) =>
		@legoBrushSelected = false
		return if @editController.interactionDisabled
		@nodeVisualizer.setDisplayMode selectedNode, 'printBrush'

	_applyChanges: (touchedVoxels, selectedNode, cachedData) =>
		return unless touchedVoxels.length > 0
		log.debug "Will re-layout #{touchedVoxels.length} voxel"

		@editController.relayoutModifiedParts(
			selectedNode, cachedData, touchedVoxels, true
		)
		cachedData.brickVisualization.unhighlightBigBrush()

	_buildAction: (touchedVoxels, selectedNode, cachedData) =>
		toLego = =>
			for voxel in touchedVoxels
				voxel.makeLego()
				cachedData.brickVisualization.voxelSelector.touch voxel
			cachedData.brickVisualization.updateModifiedVoxels()
			@_applyChanges touchedVoxels, selectedNode, cachedData

		toPrint = =>
			for voxel in touchedVoxels
				voxel.make3dPrinted()
				cachedData.brickVisualization.voxelSelector.touch voxel
			cachedData.brickVisualization.updateModifiedVoxels()
			@_applyChanges touchedVoxels, selectedNode, cachedData

		return { toLego, toPrint }

	_legoDown: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxelLego event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_legoMove: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxelLego event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_legoUp: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.brickVisualization.updateModifiedVoxels()

			brush = 'LegoBrush'
			brush += 'Big' if @bigBrushSelected
			piwikTracking.trackEvent(
				'Editor', 'BrushAction', brush, touchedVoxels.length
			)

			@_applyChanges touchedVoxels, selectedNode, cachedData

			action = @_buildAction touchedVoxels, selectedNode, cachedData
			@undo?.addTask action.toPrint, action.toLego

	_legoHover: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.brickVisualization.
				highlightVoxel event, selectedNode, '3d', @bigBrushSelected

	_legoCancel: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) ->
			cachedData.brickVisualization.resetTouchedVoxelsTo3dPrinted()
			cachedData.brickVisualization.updateVisualization()
			cachedData.brickVisualization.unhighlightBigBrush()

	_everythingLego: (selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			return unless cachedData.brickVisualization.makeAllVoxelsLego selectedNode
			piwikTracking.trackEvent 'Editor', 'BrushAction', 'MakeEverythingLego'
			@editController.rerunLegoPipeline selectedNode
			brickVis = cachedData.brickVisualization
			brickVis.updateModifiedVoxels()
			brickVis.updateVisualization(null, true)

	_printDown: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxel3dPrinted event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_printMove: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxels = cachedData.brickVisualization.
				makeVoxel3dPrinted event, selectedNode, @bigBrushSelected
			if voxels?
				cachedData.csgNeedsRecalculation = true

	_printUp: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.brickVisualization.updateModifiedVoxels()

			brush = 'PrintBrush'
			brush += 'Big' if @bigBrushSelected
			piwikTracking.trackEvent(
				'Editor', 'BrushAction',  brush, touchedVoxels.length
			)

			@_applyChanges touchedVoxels, selectedNode, cachedData

			action = @_buildAction touchedVoxels, selectedNode, cachedData
			@undo?.addTask action.toLego, action.toPrint

	_printHover: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.brickVisualization.
				highlightVoxel event, selectedNode, 'lego', @bigBrushSelected

	_printCancel: (event, selectedNode) =>
		@nodeVisualizer._getCachedData selectedNode
		.then (cachedData) ->
			cachedData.brickVisualization.resetTouchedVoxelsToLego()
			cachedData.brickVisualization.updateVisualization()
			cachedData.brickVisualization.unhighlightBigBrush()

	_everythingPrint: (node) =>
		@nodeVisualizer._getCachedData node
		.then (cachedData) =>
			changedVoxels = cachedData.brickVisualization.makeAllVoxels3dPrinted node
			return if changedVoxels.length is 0
			piwikTracking.trackEvent 'Editor', 'BrushAction', 'MakeEverythingPrint'
			cachedData.brickVisualization.updateModifiedVoxels()
			@editController.relayoutModifiedParts(
				node, cachedData, changedVoxels, true
			)

module.exports = BrushHandler
