VoxelVisualizer = require './VoxelVisualizer'
interactionHelper = require '../../client/interactionHelper'

module.exports = class BrushHandler
	constructor: ( @bundle, @newBrickator ) ->
		@highlightMaterial = new THREE.MeshLambertMaterial({
			color: 0x00ff00
		})
		@voxelVisualizer = new VoxelVisualizer()

	legoMouseDown: (event, selectedNode, cachedData) =>
		@_initializeVoxelGrid( event, selectedNode, cachedData )
		@_showNotEnabledVoxelSuggestion event, selectedNode, cachedData
		@_enableClickedVoxel event, selectedNode, cachedData

	printMouseDown: (event, selectedNode, cachedData) =>
		@_initializeVoxelGrid( selectedNode, cachedData )
		@_disableSelectedVoxel event, selectedNode, cachedData

	legoMouseMove: (event, selectedNode, cachedData) =>
		@_enableClickedVoxel event, selectedNode, cachedData

	legoMouseHover: (event, selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		@_showNotEnabledVoxelSuggestion event, selectedNode, cachedData
		@_hightlightSelectedVoxel event, selectedNode, cachedData

	printMouseHover: (event, selectedNode, cachedData) =>
		@_toggleVoxelVisibility event, selectedNode, cachedData
		@_hideDisabledVoxels selectedNode, cachedData
		@_hightlightSelectedVoxel event, selectedNode, cachedData

	printMouseMove: (event, selectedNode, cachedData) =>
		@_disableSelectedVoxel event, selectedNode, cachedData

	mouseUp: (event, selectedNode, cachedData) =>
		for v in cachedData.lastSelectedVoxels
			# hide deselected voxels after print brush interaction
			if v.material == @voxelVisualizer.deselectedMaterial
				v.setMaterial @voxelVisualizer.hiddenMaterial

			cachedData.modifiedVoxels.push v
		cachedData.lastSelectedVoxels = []

		cachedData.highlightedVoxel = null

	afterPipelineUpdate: (selectedNode, cachedData) =>
		@_initializeVoxelGrid( selectedNode, cachedData )
		@_toggleVoxelVisibility null, selectedNode, cachedData
		@voxelVisualizer.updateVoxels cachedData.grid, cachedData.threeNode

	_hightlightSelectedVoxel: (event, selectedNode, cachedData) =>
		obj = @_getSelectedVoxel event, selectedNode
		if obj?
			if cachedData.highlightedVoxel?
				cachedData.highlightedVoxel.setHighlight false
			cachedData.highlightedVoxel = obj

			obj.setHighlight true, @highlightMaterial

	_toggleVoxelVisibility: (event, selectedNode, cachedData) =>
		threeNodes = @newBrickator.getThreeObjectsByNode selectedNode

		# always show voxel, never show lego bricks
		# (because we don't re-layout after each brush, therefore
		# the lego layout becomes invalid after first brush use)
		threeNodes.bricks.visible = false
		threeNodes.voxels.visible = true

		return

		obj = @_getSelectedVoxel event, selectedNode

		if not obj
			# hide voxels, show bricks
			# if we are not above an object
			threeNodes.bricks.visible = true
			threeNodes.voxels.visible = false
		else
			#show voxels, hide bricks
			threeNodes.voxels.visible = true
			threeNodes.bricks.visible = false

	_disableSelectedVoxel: (event, selectedNode, cachedData) =>
		# disable all voxels we touch with the mouse
		obj = @_getSelectedVoxel event, selectedNode

		if obj
			obj.setMaterial @voxelVisualizer.deselectedMaterial
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

			connectedToEnabled = false
			if enabledVoxels.length > 0
				connectedToEnabled = true

			# has this voxel a not selected voxel below
			# (preventing unselectable voxels)
			# could be optimized by not using the (z-)-layer as "below",
			# but the layer the camera is currently facing towards
			freeBelow = true
			if cachedData.grid.zLayers[c.z - 1]?[c.x]?[c.y]?
				if cachedData.grid.zLayers[c.z - 1][c.x][c.y].enabled == false
					freeBelow = false

			if freeBelow and connectedToEnabled
				v.setMaterial @voxelVisualizer.deselectedMaterial
				v.visible = true

		cachedData.modifiedVoxels = modifiedVoxelsNew

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
				obj.setMaterial @voxelVisualizer.selectedMaterial
				voxel.enabled = true
			
	_initializeVoxelGrid: (selectedNode, cachedData) =>
		threeObjects = @newBrickator.getThreeObjectsByNode(selectedNode)

		if not cachedData.threeNode
			cachedData.threeNode = threeObjects.voxels
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
				obj = intersection.object.parent
			
				if obj.visible and obj.voxelCoords
					return obj
					
		return null
