VoxelVisualizer = require './VoxelVisualizer'
interactionHelper = require '../../client/interactionHelper'

module.exports = class BrushHandler
	constructor: ( @bundle, @newBrickator ) ->
		return

	legoMouseDown: (event, selectedNode, cachedData) =>
		@_initializeVoxelGrid( event, selectedNode, cachedData )
		@_showNotEnabledVoxelSuggestion event, selectedNode, cachedData
		@_enableClickedVoxel event, selectedNode, cachedData

	printMouseDown: (event, selectedNode, cachedData) =>
		@_initializeVoxelGrid( event, selectedNode, cachedData )
		@_disableSelectedVoxel event, selectedNode, cachedData

	legoMouseMove: (event, selectedNode, cachedData) =>
		@_enableClickedVoxel event, selectedNode, cachedData

	legoMouseHover: (event, selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		@_showNotEnabledVoxelSuggestion event, selectedNode, cachedData

	printMouseHover: (event, selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		@_hideDisabledVoxels selectedNode, cachedData

	_toggleVoxelVisibility: (event, selectedNode, cachedData) =>
		obj = @_getSelectedVoxel event, selectedNode
		threeNodes = @newBrickator.getThreeObjectsByNode selectedNode

		if not obj
			# hide voxels, show bricks
			# if we are not above an object
			threeNodes.bricks.visible = true
			threeNodes.voxels.visible = false
		else
			#show voxels, hide bricks
			threeNodes.voxels.visible = true
			threeNodes.bricks.visible = false

	printMouseMove: (event, selectedNode, cachedData) =>
		@_disableSelectedVoxel event, selectedNode, cachedData

	mouseUp: (event, selectedNode, cachedData) =>
		for v in cachedData.lastSelectedVoxels
			cachedData.modifiedVoxels.push v
		cachedData.lastSelectedVoxels = []

	afterPipelineUpdate: (selectedNode, cachedData) =>
		@voxelVisualizer.updateVoxels cachedData.grid, cachedData.threeNode

	_disableSelectedVoxel: (event, selectedNode, cachedData) =>
		# disable all voxels we touch with the mouse
		obj = @_getSelectedVoxel event, selectedNode

		if obj
			obj.material = @voxelVisualizer.hiddenMaterial
			c = obj.voxelCoords
			cachedData.grid.zLayers[c.z][c.x][c.y].enabled = false

			if cachedData.lastSelectedVoxels.indexOf(obj) < 0
				cachedData.lastSelectedVoxels.push obj

	_showNotEnabledVoxelSuggestion: (event, selectedNode, cachedData) =>
		# show one layer of not-enabled (-> to be 3d printed) voxels
		# (one layer = voxel has at least one enabled neighbour)
		# so that users can re-select them
		modifiedVoxelsNew = []

		for v in cachedData.modifiedVoxels
			c = v.voxelCoords

			# ignore if this voxel already is enabled
			if cachedData.grid.zLayers[c.z][c.x][c.y].enabled
				continue
			modifiedVoxelsNew.push v
			
			# do we have at least one connection to an enabled voxel?
			enabledVoxels = cachedData.grid.getNeighbours c.x,
				c.y, c.z, (voxel) ->
					return voxel.enabled

			if enabledVoxels.length > 0
				v.material = @voxelVisualizer.deselectedMaterial
				v.visible = true

		cachedData.modifiedVoxels = modifiedVoxelsNew

		#todo unselectable check

	_hideDisabledVoxels: (selectedNode, cachedData) =>
		# hides all voxels that are disabled

		for v in cachedData.modifiedVoxels
			c = v.voxelCoords
			if not cachedData.grid.zLayers[c.z][c.x][c.y].enabled
				v.visible = false

	_enableClickedVoxel: (event, selectedNode, cachedData) =>
		obj = @_getSelectedVoxel event, selectedNode

		if obj
			c = obj.voxelCoords
			voxel = cachedData.grid.zLayers[c.z][c.x][c.y]

			if not voxel.enabled
				obj.material = @voxelVisualizer.selectedMaterial
				voxel.enabled = true
			


	_initializeVoxelGrid: (event, selectedNode, cachedData) =>
		threeObjects = @newBrickator.getThreeObjectsByNode(selectedNode)

		if not cachedData.threeNode
			cachedData.threeNode = threeObjects.voxels
			@voxelVisualizer ?= new VoxelVisualizer()
			@voxelVisualizer.createVisibleVoxels(
				cachedData.grid
				cachedData.threeNode
				true
			)
		else
			cachedData.threeNode.visible = true

		return cachedData

	_getSelectedVoxel: (event, selectedNode) =>
		# returns the first visible voxel (three.Object3D) that is below
		# the cursor position, if it has a voxelCoords property
		threeNodes = @newBrickator.getThreeObjectsByNode selectedNode

		intersects =
			interactionHelper.getPolygonClickedOn(event
				threeNodes.voxels.children
				@bundle.renderer)

		if (intersects.length > 0)
			for intersection in intersects
				obj = intersection.object
			
				if obj.visible and obj.voxelCoords
					return obj
					
		return null
