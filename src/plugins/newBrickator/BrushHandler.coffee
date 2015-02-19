module.exports = class BrushHandler
	constructor: ( @bundle, @newBrickator ) ->
		@highlightMaterial = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})

	legoSelect: (selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		cachedData.visualization.updateVoxelVisualization()
		cachedData.visualization.showDeselectedVoxelSuggestions()
		
	printSelect: (selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		cachedData.visualization.updateVoxelVisualization()
		
	legoMouseDown: (event, selectedNode, cachedData) =>
		cachedData.visualization.selectVoxel event

	legoMouseMove: (event, selectedNode, cachedData) =>
		cachedData.visualization.selectVoxel event

	legoMouseHover: (event, selectedNode, cachedData) =>
		cachedData.visualization.highlightVoxel event, (voxel) ->
			return not voxel.isEnabled()

	printMouseDown: (event, selectedNode, cachedData) =>
		cachedData.visualization.deselectVoxel event

	printMouseHover: (event, selectedNode, cachedData) =>
		@_hightlightSelectedVoxel event, selectedNode, cachedData

	printMouseMove: (event, selectedNode, cachedData) =>
		cachedData.visualization.deselectVoxel event

	printMouseUp: (event, selectedNode, cachedData) =>
		cachedData.visualization.updateModifiedVoxels()
		cachedData.visualization.updateVoxelVisualization()

	legoMouseUp: (event, selectedNode, cachedData) =>
		cachedData.visualization.updateVoxelVisualization()
		cachedData.visualization.showDeselectedVoxelSuggestions()

	afterPipelineUpdate: (selectedNode, cachedData) =>
		cachedData.visualization.updateVoxelVisualization()
		@_toggleVoxelVisibility null, selectedNode, cachedData

	_hightlightSelectedVoxel: (event, selectedNode, cachedData) =>
		cachedData.visualization.highlightVoxel event

	_toggleVoxelVisibility: (event, selectedNode, cachedData) =>
		# always show voxel, never show lego bricks
		# (because we don't re-layout after each brush, therefore
		# the lego layout becomes invalid after first brush use)
		cachedData.visualization.showVoxels()
