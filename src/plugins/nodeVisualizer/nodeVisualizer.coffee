threeHelper = require '../../client/threeHelper'
BrickVisualization = require './visualization/brickVisualization'
ModelVisualization = require './modelVisualization'
interactionHelper = require '../../client/interactionHelper'
shaderGenerator = require './shaderGenerator'

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
		@usePipeline = false

		# Voxels / Bricks are rendered as a first render pass
		@brickScene = @bundle.renderer.getDefaultScene()
		@brickRootNode = new THREE.Object3D()
		@threejsRootNode.add @brickRootNode

		# Objects are rendered in the 2nd / 3rd render pass
		@objectsScene = @bundle.renderer.getDefaultScene()
		@objectsRootNode = new THREE.Object3D()
		@threejsRootNode.add @objectsRootNode

		# LegoShadow is rendered as a 3rd rendering pass
		@brickShadowScene = @bundle.renderer.getDefaultScene()
		@brickShadowRootNode = new THREE.Object3D()
		@threejsRootNode.add @brickShadowRootNode

		return

	setFidelity: (fidelityLevel, availableLevels) =>
		# Determine whether to use the pipeline or not
		if fidelityLevel >= availableLevels.indexOf 'PipelineLow'
			if not @usePipeline
				@usePipeline = true

				# move all subnodes to the pipeline scenes
				@threejsRootNode.remove @brickRootNode
				@threejsRootNode.remove @brickShadowRootNode
				@threejsRootNode.remove @objectsRootNode

				@brickScene.add @brickRootNode
				@objectsScene.add @objectsRootNode
				@brickShadowScene.add @brickShadowRootNode
		else
			if @usePipeline
				@usePipeline = false

				# move all subnodes to conventional rendering
				@brickScene.remove @brickRootNode
				@brickShadowScene.remove @brickShadowRootNode
				@objectsScene.remove @objectsRootNode

				@threejsRootNode.add @brickRootNode
				@threejsRootNode.add @objectsRootNode
				@threejsRootNode.add @brickShadowRootNode

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

		# create visible node and zoom on to it
		@_getCachedData(node)
		.then (cachedData) =>
			cachedData.modelVisualization.createVisualization()
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
		brickThreeNode = new THREE.Object3D()
		brickShadowThreeNode = new THREE.Object3D()
		modelThreeNode = new THREE.Object3D()

		@brickRootNode.add brickThreeNode
		@brickShadowRootNode.add brickShadowThreeNode
		@objectsRootNode.add modelThreeNode

		threeHelper.link node, brickThreeNode
		threeHelper.link node, brickShadowThreeNode
		threeHelper.link node, modelThreeNode

		data = {
			initialized: false
			node: node
			brickThreeNode: brickThreeNode
			brickShadowThreeNode: brickShadowThreeNode
			modelThreeNode: modelThreeNode
			brickVisualization: new BrickVisualization(
				@bundle, brickThreeNode, brickShadowThreeNode
			)
			modelVisualization: new ModelVisualization(
				@bundle.globalConfig, node, modelThreeNode
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
