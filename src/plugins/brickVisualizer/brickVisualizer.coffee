BrushHandler = require './BrushHandler'
threeHelper = require '../../client/threeHelper'
NodeVisualization = require './visualization/NodeVisualization'

###
# @class BrickVisualizer
###
class BrickVisualizer
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

		@_brickVisibility = true
		@_printVisibility = true

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
			# initialize visualization with data from newBrickator
			if not cachedData.initialized
				cachedData.visualization.initialize newBrickatorData.grid
				cachedData.numZLayers = newBrickatorData.grid.zLayers.length
				cachedData.initialized = true
				
			# update bricks and make voxel same colors as bricks
			cachedData.visualization.updateBricks newBrickatorData.brickGraph.bricks
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.showVoxels()

			# instead of creating csg live, show original model semitransparent
			@solidRenderer ?= @bundle.getPlugin('solid-renderer')
			@solidRenderer?.setNodeMaterial node, @printMaterial

			@_applyPrintVisibility cachedData

	# called by mouse handler
	_relayoutModifiedParts: (cachedData, touchedVoxels, createBricks) =>
		@newBrickator ?= @bundle.getPlugin 'newBrickator'
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

	_createNodeDatastructure: (node) =>
		threeNode = new THREE.Object3D()
		@threejsRootNode.add threeNode
		threeHelper.link node, threeNode

		data = {
			initialized: false
			node: node
			threeNode: threeNode
			visualization: new NodeVisualization @bundle, threeNode
		}

		return data

	getHotkeys: =>
		return {
			title: 'Bricks'
			events: [
				{
					hotkey: 's'
					description: 'toggle stability view'
					callback: @_toggleStabilityView
				}
			]
		}

	_setStabilityView: (selectedNode, stabilityViewEnabled) =>
		return if !selectedNode?

		@_getCachedData(selectedNode).then (cachedData) =>
			if stabilityViewEnabled
				# only show bricks and csg
				@_showCsg cachedData
				.then () =>
					# change coloring to stability coloring
					cachedData.visualization.setStabilityView(stabilityViewEnabled)
					cachedData.visualization.showBricks()

				@solidRenderer?.setNodeVisibility cachedData.node, false

				@brushHandler.interactionDisabled = true
			else
				#show voxels
				cachedData.visualization.setStabilityView(stabilityViewEnabled)
				cachedData.visualization.hideCsg()
				cachedData.visualization.showVoxels()
				@brushHandler.interactionDisabled = false

				@solidRenderer?.setNodeVisibility cachedData.node, true

	# enables the build mode, which means that only bricks and CSG
	# are shown
	enableBuildMode: (selectedNode) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			# disable interaction
			@brushHandler.interactionDisabled = true

			# show bricks and csg
			cachedData.visualization.showBricks()
			cachedData.visualization.setPossibleLegoBoxVisibility false

			@_showCsg cachedData

			@solidRenderer?.setNodeVisibility cachedData.node, false

			return cachedData.numZLayers

	# when build mode is enabled, this tells the visualization to show
	# bricks up to the specified layer
	showBuildLayer: (selectedNode, layer) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			cachedData.visualization.showBrickLayer layer - 1

	# disables build mode and shows voxels, hides csg
	disableBuildMode: (selectedNode) =>
		return @_getCachedData(selectedNode).then (cachedData) =>
			#enable interaction
			@brushHandler.interactionDisabled = false

			# hide csg, show model, show voxels
			cachedData.visualization.updateVoxelVisualization()
			cachedData.visualization.hideCsg()
			@solidRenderer?.setNodeVisibility cachedData.node, true
			cachedData.visualization.showVoxels()
			
			if @brushHandler.legoBrushSelected
				cachedData.visualization.setPossibleLegoBoxVisibility true

	_applyVoxelAndBrickVisibility: (cachedData) =>
		solidRenderer = @bundle.getPlugin('solid-renderer')

		if @_brickVisibility
			cachedData.visualization.showVoxelAndBricks()
			# if bricks are shown, show whole model instead of csg (faster)
			cachedData.visualization.hideCsg()
			if solidRenderer? and @_printVisibility
				solidRenderer.setNodeVisibility(cachedData.node, true)
		else
			# if bricks are hidden, csg has to be generated because
			# the user would else see the whole original model
			if @_printVisibility
				@_showCsg cachedData

			if solidRenderer?
				solidRenderer.setNodeVisibility(cachedData.node, false)
			cachedData.visualization.hideVoxelAndBricks()

	_applyPrintVisibility: (cachedData) =>
		if @_printVisibility
			if @_brickVisibility
				# show face csg (original model) when bricks are visible
				cachedData.visualization.hideCsg()
				@solidRenderer?.setNodeVisibility(cachedData.node, true)
			else
				# show real csg
				@_showCsg cachedData
		else
			cachedData.visualization.hideCsg()
			@solidRenderer?.setNodeVisibility cachedData.node, false

	_showCsg: (cachedData) =>
		return @newBrickator.getCSG(cachedData.node, true)
				.then (csg) =>
					cachedData.visualization.showCsg(csg)

module.exports = BrickVisualizer
