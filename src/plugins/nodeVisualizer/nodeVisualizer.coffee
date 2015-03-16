BrushHandler = require './BrushHandler'
threeHelper = require '../../client/threeHelper'
BrickVisualization = require './visualization/brickVisualization'
ModelVisualization = require './modelVisualization'

###
# @class NodeVisualizer
###
class NodeVisualizer
	constructor: () ->
		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
			opacity: 0.8
			transparent: true
		})

		# remove z-Fighting on baseplate
		@printMaterial.polygonOffset = true
		@printMaterial.polygonOffsetFactor = 5
		@printMaterial.polygonoffsetUnits = 5

	init: (@bundle) =>
		@brushHandler = new BrushHandler(@bundle, @)

	init3d: (@threejsRootNode) =>
		return

	getBrushes: () =>
		return @brushHandler.getBrushes()

	# called by newBrickator when an object's datastructure is modified
	objectModified: (node, newBrickatorData) =>
		@_getCachedData(node)
		.then (cachedData) =>
			if not cachedData.initialized
				@_initializeData node, cachedData, newBrickatorData

			# update brick reference for later
			cachedData.brickVisualization.updateBricks newBrickatorData.brickGraph.bricks

			# update voxel coloring and show them
			cachedData.brickVisualization.updateVoxelVisualization()
			cachedData.brickVisualization.showVoxels()

	onNodeAdd: (node) =>
		# link other plugins
		@newBrickator ?= @bundle.getPlugin 'newBrickator'

		# create visible node and zoom on to it
		@_getCachedData(node)
		.then (cachedData) =>
			cachedData.modelVisualization.createVisualization()
			cachedData.modelVisualization.afterCreation().then () =>
				@zoomToNode cachedData.modelVisualization.getSolid()

	onNodeRemove: (node) =>
		@threejsRootNode.remove threeHelper.find node, @threejsRootNode

	zoomToNode: (threeNode) =>
		boundingSphere = threeHelper.getBoundingSphere threeNode
		threeNode.updateMatrix()
		boundingSphere.center.applyProjection threeNode.matrix
		@bundle.renderer.zoomToBoundingSphere boundingSphere

	# initialize visualization with data from newBrickator
	# change solid renderer appearance
	_initializeData: (node, visualizationData, newBrickatorData) =>
		# init node visualization
		visualizationData.brickVisualization.initialize newBrickatorData.grid
		visualizationData.numZLayers = newBrickatorData.grid.zLayers.length
		visualizationData.initialized = true

		# instead of creating csg live, show original model semitransparent
		visualizationData.modelVisualization.setSolidMaterial @printMaterial

	# called by mouse handler
	_relayoutModifiedParts: (cachedData, touchedVoxels, createBricks) =>
		@newBrickator.relayoutModifiedParts cachedData.node,
			touchedVoxels, createBricks

	# returns the node visualization or creates one
	_getCachedData: (selectedNode) =>
		return selectedNode.getPluginData 'brickVisualizer'
		.then (data) =>
			if data?
				return data
			else
				data = @_createNodeDatastructure selectedNode
				selectedNode.storePluginData 'brickVisualizer', data, true
				return data

	# creates visualization datastructures
	_createNodeDatastructure: (node) =>
		threeNode = new THREE.Object3D()
		@threejsRootNode.add threeNode
		threeHelper.link node, threeNode

		data = {
			initialized: false
			node: node
			threeNode: threeNode
			brickVisualization: new BrickVisualization @bundle, threeNode
			modelVisualization: new ModelVisualization(
				@bundle.globalConfig, node, threeNode
			)
		}

		return data

	_setStabilityView: (selectedNode, stabilityViewEnabled) =>
		return if !selectedNode?

		@_getCachedData(selectedNode).then (cachedData) =>
			if stabilityViewEnabled
				# only show bricks and csg
				@_showCsg cachedData
				.then () =>
					# change coloring to stability coloring
					cachedData.brickVisualization.setStabilityView(stabilityViewEnabled)
					cachedData.brickVisualization.showBricks()

				cachedData.modelVisualization.setNodeVisibility false

				@brushHandler.interactionDisabled = true
			else
				#show voxels
				cachedData.brickVisualization.setStabilityView(stabilityViewEnabled)
				cachedData.brickVisualization.hideCsg()
				cachedData.brickVisualization.showVoxels()
				@brushHandler.interactionDisabled = false

				cachedData.modelVisualization.setNodeVisibility true

	# enables the build mode, which means that only bricks and CSG
	# are shown
	enableBuildMode: (selectedNode) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			# disable interaction
			@brushHandler.interactionDisabled = true

			# show bricks and csg
			cachedData.brickVisualization.showBricks()
			cachedData.brickVisualization.setPossibleLegoBoxVisibility false

			@_showCsg cachedData

			cachedData.modelVisualization.setNodeVisibility false

			return cachedData.numZLayers

	# when build mode is enabled, this tells the visualization to show
	# bricks up to the specified layer
	showBuildLayer: (selectedNode, layer) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			cachedData.brickVisualization.showBrickLayer layer - 1

	# disables build mode and shows voxels, hides csg
	disableBuildMode: (selectedNode) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			#enable interaction
			@brushHandler.interactionDisabled = false

			# hide csg, show model, show voxels
			cachedData.brickVisualization.updateVoxelVisualization()
			cachedData.brickVisualization.hideCsg()
			cachedData.modelVisualization.setNodeVisibility true
			cachedData.brickVisualization.showVoxels()
			
			if @brushHandler.legoBrushSelected
				cachedData.brickVisualization.setPossibleLegoBoxVisibility true

	_showCsg: (cachedData) =>
		return @newBrickator.getCSG(cachedData.node, true)
				.then (csg) =>
					cachedData.brickVisualization.showCsg(csg)

module.exports = NodeVisualizer
