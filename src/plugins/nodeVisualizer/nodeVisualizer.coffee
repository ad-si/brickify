threeHelper = require '../../client/threeHelper'
BrickVisualization = require './visualization/brickVisualization'
ModelVisualization = require './modelVisualization'
interactionHelper = require '../../client/interactionHelper'

###
# @class NodeVisualizer
###
class NodeVisualizer
	constructor: ->
		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
			opacity: 0.8
			transparent: true
		})

		# remove z-Fighting on baseplate
		@printMaterial.polygonOffset = true
		@printMaterial.polygonOffsetFactor = 5
		@printMaterial.polygonoffsetUnits = 5

	init: (@bundle) => return

	init3d: (@threejsRootNode) =>
		return

	# called by newBrickator when an object's datastructure is modified
	objectModified: (node, newBrickatorData) =>
		@_getCachedData(node)
		.then (cachedData) =>
			if not cachedData.initialized
				@_initializeData node, cachedData, newBrickatorData

			# update brick visualization
			cachedData.brickVisualization.updateBrickVisualization()

			# update voxel coloring and show them
			cachedData.brickVisualization.updateVoxelVisualization()
			cachedData.brickVisualization.showVoxels()

	onNodeAdd: (node) =>
		# link other plugins
		@newBrickator ?= @bundle.getPlugin 'newBrickator'

		# create visible node and zoom to it
		@_getCachedData(node)
		.then (cachedData) =>
			cachedData.modelVisualization.createVisualization()
			if @bundle.globalConfig.showModel
				cachedData.modelVisualization.afterCreation().then =>
					@_zoomToNode cachedData.modelVisualization.getSolid()

	onNodeRemove: (node) =>
		@threejsRootNode.remove threeHelper.find node, @threejsRootNode

	onNodeSelect: (@selectedNode) => return

	onNodeDeselect: => @selectedNode = null

	_zoomToNode: (threeNode) =>
		boundingSphere = threeHelper.getBoundingSphere threeNode
		@bundle.renderer.zoomToBoundingSphere boundingSphere

	# initialize visualization with data from newBrickator
	# change solid renderer appearance
	_initializeData: (node, visualizationData, newBrickatorData) =>
		# init node visualization
		visualizationData.brickVisualization.initialize newBrickatorData.grid
		visualizationData.numZLayers = newBrickatorData.grid.getMaxZ() + 1
		visualizationData.initialized = true

		# instead of creating csg live, show original model semitransparent
		visualizationData.modelVisualization.setSolidMaterial @printMaterial

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

	###
	# Sets the overall display mode
	# @param {Node} selectedNode the currently selected node
	# @param {String} mode the mode: 'legoBrush'/'printBrush'/'stability'/'build'
	###
	setDisplayMode: (selectedNode, mode) =>
		return unless selectedNode?

		return @_getCachedData selectedNode
		.then (cachedData) =>
			switch mode
				when 'legoBrush'
					@_resetStabilityView cachedData
					@_resetBuildMode cachedData
					@_applyLegoBrushMode cachedData
				when 'printBrush'
					@_resetStabilityView cachedData
					@_resetBuildMode cachedData
					@_applyPrintBrushMode cachedData
				when 'stability'
					@_resetBuildMode cachedData
					@_applyStabilityView cachedData
				when 'build'
					@_resetStabilityView cachedData
					return @_applyBuildMode cachedData

	_applyLegoBrushMode: (cachedData) =>
		cachedData.brickVisualization.showVoxels()
		cachedData.brickVisualization.updateVoxelVisualization()
		cachedData.brickVisualization.setPossibleLegoBoxVisibility true
		cachedData.modelVisualization.setShadowVisibility false

	_applyPrintBrushMode: (cachedData) =>
		cachedData.brickVisualization.showVoxels()
		cachedData.brickVisualization.updateVoxelVisualization()
		cachedData.brickVisualization.setPossibleLegoBoxVisibility false
		cachedData.modelVisualization.setShadowVisibility true

	_applyStabilityView: (cachedData) =>
		cachedData.stabilityViewEnabled  = true

		@_showCsg cachedData
		.then ->
			# change coloring to stability coloring
			cachedData.brickVisualization.setStabilityView true
			cachedData.brickVisualization.showBricks()

		cachedData.modelVisualization.setNodeVisibility false

	_resetStabilityView: (cachedData) =>
		if cachedData.stabilityViewEnabled
			cachedData.brickVisualization.setStabilityView false
			cachedData.brickVisualization.hideCsg()
			cachedData.modelVisualization.setNodeVisibility true
			cachedData.stabilityViewEnabled = false

	_applyBuildMode: (cachedData) =>
		# show bricks and csg
		cachedData.brickVisualization.showBricks()
		cachedData.brickVisualization.setPossibleLegoBoxVisibility false

		@_showCsg cachedData

		cachedData.modelVisualization.setNodeVisibility false
		return cachedData.numZLayers

	_resetBuildMode: (cachedData) =>
		cachedData.brickVisualization.hideCsg()
		cachedData.modelVisualization.setNodeVisibility true

	# when build mode is enabled, this tells the visualization to show
	# bricks up to the specified layer
	showBuildLayer: (selectedNode, layer) =>
		return @_getCachedData(selectedNode).then (cachedData) ->
			cachedData.brickVisualization.showBrickLayer layer - 1

	_showCsg: (cachedData) =>
		@csg ?= @bundle.getPlugin 'csg'
		return Promise.resolve() if not @csg?

		return @csg.getCSG(cachedData.node, {addStuds: true})
				.then (csg) -> cachedData.brickVisualization.showCsg csg

	# check whether the pointer is over a model/brick visualization
	pointerOverModel: (event, ignoreInvisible = true) =>
		intersections = interactionHelper.getIntersections(
			event, @bundle.renderer, @threejsRootNode.children
		)
		return intersections.length > 0 unless ignoreInvisible
		visibleIntersections = intersections.filter (intersection) ->
			object = intersection.object
			while object?
				return false unless object.visible
				object = object.parent
			return true

		return visibleIntersections.length > 0

module.exports = NodeVisualizer
