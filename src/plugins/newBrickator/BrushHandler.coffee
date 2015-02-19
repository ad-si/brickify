module.exports = class BrushHandler
	constructor: ( @bundle, @newBrickator ) ->
		@highlightMaterial = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})

	getBrushes: () =>
		return [{
			text: 'Make LEGO brush'
			icon: 'legoBrush.png'
			selectCallback: @_legoSelect
			mouseDownCallback: @_legoMouseDown
			mouseMoveCallback: @_legoMouseMove
			mouseHoverCallback: @_legoMouseHover
			mouseUpCallback: @_legoMouseUp
			canToggleVisibility: true
			visibilityCallback: @newBrickator._toggleBrickLayer
			tooltip: 'Select geometry to be made out of LEGO'
		},{
			text: 'Make 3D print brush'
			icon: '3dPrintBrush.png'
			selectCallback: @_printSelect
			mouseDownCallback: @_printMouseDown
			mouseMoveCallback: @_printMouseMove
			mouseHoverCallback: @_printMouseHover
			mouseUpCallback: @_printMouseUp
			canToggleVisibility: true
			visibilityCallback: @newBrickator._togglePrintedLayer
			tooltip: 'Select geometry to be 3d-printed'
		}]

	_checkAndPrepare: (selectedNode, callback) =>
		# ignore if we are currently in build mode
		if @newBrickator.buildModeEnabled
			return

		@newBrickator._getCachedData(selectedNode).then (cachedData) =>
			callback(cachedData)

	_legoSelect: (selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.showVoxels()
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.showDeselectedVoxelSuggestions()
		
	_printSelect: (selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.showVoxels()
			cachedData.visualization.updateVoxelVisualization()
		
	_legoMouseDown: (event, selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.selectVoxel event

	_legoMouseMove: (event, selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.selectVoxel event

	_legoMouseHover: (event, selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.highlightVoxel event, (voxel) ->
				return not voxel.isEnabled()

	_printMouseDown: (event, selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.deselectVoxel event

	_printMouseHover: (event, selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.highlightVoxel event

	_printMouseMove: (event, selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.deselectVoxel event

	_printMouseUp: (event, selectedNode) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.updateModifiedVoxels()
			cachedData.visualization.updateVoxelVisualization()

	_legoMouseUp: (event, selectedNode, cachedData) =>
		@_checkAndPrepare selectedNode, (cachedData) =>
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.showDeselectedVoxelSuggestions()

	afterPipelineUpdate: (selectedNode, cachedData) =>
		cachedData.visualization.updateVoxelVisualization()
		cachedData.visualization.showVoxels()
