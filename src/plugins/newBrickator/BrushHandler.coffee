module.exports = class BrushHandler
	constructor: ( @bundle, @newBrickator ) ->
		@highlightMaterial = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})

	legoMouseDown: (event, selectedNode, cachedData) =>
		#@_initializeVoxelGrid( cachedData )
		@_showNotEnabledVoxelSuggestion event, selectedNode, cachedData
		@_enableClickedVoxel event, selectedNode, cachedData

	printMouseDown: (event, selectedNode, cachedData) =>
		@_initializeVoxelGrid( cachedData )
		@_disableSelectedVoxel event, selectedNode, cachedData

	legoMouseMove: (event, selectedNode, cachedData) =>
		@_enableClickedVoxel event, selectedNode, cachedData

	legoMouseHover: (event, selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		@_showNotEnabledVoxelSuggestion event, selectedNode, cachedData
		cachedData.visualization.highlightVoxel event, (voxel) ->
			return not voxel.isEnabled()

	printMouseHover: (event, selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		@_hideDisabledVoxels selectedNode, cachedData
		@_hightlightSelectedVoxel event, selectedNode, cachedData

	printMouseMove: (event, selectedNode, cachedData) =>
		@_disableSelectedVoxel event, selectedNode, cachedData

	mouseUp: (event, selectedNode, cachedData) =>
		cachedData.visualization.hideDeselectedVoxels()

	afterPipelineUpdate: (selectedNode, cachedData) =>
		@_initializeVoxelGrid( cachedData )
		@_toggleVoxelVisibility null, selectedNode, cachedData
		cachedData.visualization.updateVoxelVisualization()

	_hightlightSelectedVoxel: (event, selectedNode, cachedData) =>
		cachedData.visualization.highlightVoxel event

	_toggleVoxelVisibility: (event, selectedNode, cachedData) =>

		# always show voxel, never show lego bricks
		# (because we don't re-layout after each brush, therefore
		# the lego layout becomes invalid after first brush use)
		cachedData.visualization.showVoxels()

	_disableSelectedVoxel: (event, selectedNode, cachedData) =>
		# disable all voxels we touch with the mouse
		cachedData.visualization.deselectVoxel event

	_showNotEnabledVoxelSuggestion: (event, selectedNode, cachedData) =>
		# show one layer of not-enabled (-> to be 3d printed) voxels
		# (one layer = voxel has at least one enabled neighbour)
		# so that users can re-select them
		
		cachedData.visualization.showDeselectedVoxelSuggestions()

	_hideDisabledVoxels: (selectedNode, cachedData) =>
		# hides all voxels that are disabled
		cachedData.visualization.hideDeselectedVoxels()

	_enableClickedVoxel: (event, selectedNode, cachedData) =>
		cachedData.visualization.selectVoxel event
			
	_initializeVoxelGrid: (cachedData) =>
		cachedData.visualization.updateVoxelVisualization()
