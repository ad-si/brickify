class BrushHandler
	constructor: ( @bundle, @brickVisualizer ) ->
		@highlightMaterial = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})
		
		@interactionDisabled = false
		@legoBrushSelected = false

	getBrushes: () =>
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

	_legoSelect: (selectedNode) =>
		@legoBrushSelected = true

		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.visualization.showVoxels()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.setPossibleLegoBoxVisibility true
			cachedData.modelVisualization.setShadowVisibility false

	_printSelect: (selectedNode) =>
		@legoBrushSelected = false

		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.visualization.showVoxels()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.setPossibleLegoBoxVisibility false
			cachedData.modelVisualization.setShadowVisibility true

	_legoMouseDown: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxelLego event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_legoMouseMove: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxelLego event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_legoMouseUp: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.visualization.updateModifiedVoxels()
			console.log "Will re-layout #{touchedVoxels.length} voxel"
			
			@brickVisualizer._relayoutModifiedParts cachedData, touchedVoxels, true

	_legoMouseHover: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.visualization.highlightVoxel event, selectedNode, false

	_legoCancel: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.visualization.resetTouchedVoxelsTo3dPrinted()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.updateBricks cachedData.brickGraph.bricks

	_printMouseDown: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxel3dPrinted event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_printMouseMove: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			voxel = cachedData.visualization.makeVoxel3dPrinted event, selectedNode
			if voxel?
				cachedData.csgNeedsRecalculation = true

	_printMouseUp: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			touchedVoxels = cachedData.visualization.updateModifiedVoxels()
			console.log "Will re-layout #{touchedVoxels.length} voxel"

			@brickVisualizer._relayoutModifiedParts cachedData, touchedVoxels, false

	_printMouseHover: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.visualization.highlightVoxel event, selectedNode, true

	_printCancel: (event, selectedNode) =>
		return if @interactionDisabled
		@brickVisualizer._getCachedData selectedNode
		.then (cachedData) =>
			cachedData.visualization.resetTouchedVoxelsToLego()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.updateBricks cachedData.brickGraph.bricks

module.exports = BrushHandler
