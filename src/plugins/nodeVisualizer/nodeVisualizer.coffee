log = require 'loglevel'

threeHelper = require '../../client/threeHelper'
BrickVisualization = require './visualization/brickVisualization'
ModelVisualization = require './modelVisualization'
interactionHelper = require '../../client/interactionHelper'

RenderTargetHelper = require '../../client/rendering/renderTargetHelper'
stencilBits = require '../../client/rendering/stencilBits'
Coloring = require './visualization/Coloring'
ColorMultPart = require '../../client/rendering/shader/ColorMultPart'
ExpandBlackPart = require '../../client/rendering/shader/ExpandBlackPart'


###
# @class NodeVisualizer
###
class NodeVisualizer
	constructor: ->
		# rendering properties
		@brickShadowOpacity = 0.5
		@objectOpacity = 0.8
		@objectShadowOpacity = 0.5
		@objectColorMult = new THREE.Vector3(1, 1, 1)
		@objectShadowColorMult = new THREE.Vector3(0.1, 0.1, 0.1)

	init: (@bundle) =>
		@coloring = new Coloring(@bundle.globalConfig)
		if @bundle.globalConfig.buildUi
			@brickCounter = $ '#brickCount'
			@timeEstimate = $ '#timeEstimate'

	init3d: (@threeJsRootNode) =>
		@usePipeline = false

		# Voxels / Bricks are rendered as a first render pass
		@brickScene = @bundle.renderer.getDefaultScene()
		@brickRootNode = new THREE.Object3D()
		@threeJsRootNode.add @brickRootNode

		# Objects are rendered in the 2nd / 3rd render pass
		@objectsScene = @bundle.renderer.getDefaultScene()
		@objectsRootNode = new THREE.Object3D()
		@threeJsRootNode.add @objectsRootNode

		# LegoShadow is rendered as a 3rd rendering pass
		@brickShadowScene = @bundle.renderer.getDefaultScene()
		@brickShadowRootNode = new THREE.Object3D()
		@threeJsRootNode.add @brickShadowRootNode

	onPaint: (@threeRenderer, camera, target, config) =>
		threeRenderer = @threeRenderer

		# recreate textures if either they haven't been generated yet or
		# the screen size has changed
		if not (@renderTargetsInitialized and
		RenderTargetHelper.renderTargetHasRightSize(
			@brickSceneTarget.renderTarget, threeRenderer, config.useBigTargets
		))
			# bricks
			@brickSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer,
				null,
				null,
				1.0,
				config.useBigTargets
			)

			# object target
			@objectsSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer,
				[new ExpandBlackPart(2), new ColorMultPart()],
				{colorMult: {type: 'v3', value: new THREE.Vector3(1, 1, 1)}},
				@objectOpacity
	  			config.useBigTargets
			)

			# brick shadow target
			@brickShadowSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer,
				null,
				null,
				@brickShadowOpacity,
				config.useBigTargets
			)

			@renderTargetsInitialized = true

		# First render pass: render Bricks & Voxels
		threeRenderer.render @brickScene, camera, @brickSceneTarget.renderTarget, true

		# Second pass: render object
		threeRenderer.render(
			@objectsScene, camera, @objectsSceneTarget.renderTarget, true
		)

		# Third pass: render shadows
		threeRenderer.render(
			@brickShadowScene, camera, @brickShadowSceneTarget.renderTarget, true
		)

		# finally render everything (on quads) on screen
		gl = threeRenderer.context

		# everything that is visible lego gets the first bit set
		gl.enable(gl.STENCIL_TEST)
		gl.stencilFunc(gl.ALWAYS, stencilBits.legoMask, 0xFF)
		gl.stencilOp(gl.ZERO, gl.ZERO, gl.REPLACE)
		gl.stencilMask(0xFF)

		# bricks
		threeRenderer.render @brickSceneTarget.quadScene, camera, target, false

		# everything that is 3d model and hidden gets the third bit set
		# every visible part of the 3d model gets the second bit set
		# (via increase and not being allowed to remove the first bit)
		gl.stencilFunc(gl.ALWAYS, stencilBits.hiddenObjectMask, 0xFF)
		gl.stencilOp(gl.KEEP, gl.REPLACE, gl.INCR)
		gl.stencilMask(stencilBits.visibleObjectMask | stencilBits.hiddenObjectMask)

		# render visible parts
		threeRenderer.render @objectsSceneTarget.quadScene, camera, target, false

		# render invisible parts (object behind lego bricks)
		if @visualizationMode? and @visualizationMode == 'printBrush'
			# Adjust object material to be dark and more transparent
			blendMat = @objectsSceneTarget.blendingMaterial
			blendMat.uniforms.colorMult.value = @objectShadowColorMult
			blendMat.uniforms.opacity.value = @objectShadowOpacity

			# Only render where there is hidden 3d model
			gl.stencilFunc(
				gl.EQUAL, stencilBits.hiddenObjectMask, stencilBits.hiddenObjectMask
			)
			gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)

			gl.disable(gl.DEPTH_TEST)
			threeRenderer.render @objectsSceneTarget.quadScene, camera, target, false
			gl.enable(gl.DEPTH_TEST)

			# Reset material to non-shadow properties
			blendMat.uniforms.opacity.value = @objectOpacity
			blendMat.uniforms.colorMult.value = @objectColorMult

		# everything shadowy gets the fourth bit set
		gl.stencilFunc(gl.ALWAYS, 0xFF, 0xFF)
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
		gl.stencilMask(stencilBits.visibleShadowMask)

		# render this-could-be-lego-shadows and brush highlight
		threeRenderer.render @brickShadowSceneTarget.quadScene, camera, target, false

		gl.disable(gl.STENCIL_TEST)

	setFidelity: (fidelityLevel, availableLevels) =>
		# Determine whether to use the pipeline or not
		if fidelityLevel >= availableLevels.indexOf 'PipelineLow'
			if not @usePipeline
				@usePipeline = true

				# move all subnodes to the pipeline scenes
				@threeJsRootNode.remove @brickRootNode
				@threeJsRootNode.remove @brickShadowRootNode
				@threeJsRootNode.remove @objectsRootNode

				@brickScene.add @brickRootNode
				@objectsScene.add @objectsRootNode
				@brickShadowScene.add @brickShadowRootNode

				# change material properties
				@coloring.setPipelineMode true
		else
			if @usePipeline
				@usePipeline = false

				# move all subnodes to conventional rendering
				@brickScene.remove @brickRootNode
				@brickShadowScene.remove @brickShadowRootNode
				@objectsScene.remove @objectsRootNode

				@threeJsRootNode.add @brickRootNode
				@threeJsRootNode.add @objectsRootNode
				@threeJsRootNode.add @brickShadowRootNode

				# change material properties
				@coloring.setPipelineMode false

	# called by newBrickator when an object's data structure is modified
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
			@_updateBrickCount cachedData.brickVisualization.grid.getAllBricks()

	onNodeAdd: (node) =>
		# link other plugins
		@newBrickator ?= @bundle.getPlugin 'newBrickator'

		# create visible node and zoom to it
		@_getCachedData(node)
		.then (cachedData) =>
			return cachedData.modelVisualization
				.createVisualization()
				.getSolid()
		.then (solid) =>
			@_zoomToNode solid if solid?
		.catch (error) =>
			log.error error

	onNodeRemove: (node) =>
		@brickRootNode.remove threeHelper.find node, @brickRootNode
		@brickShadowRootNode.remove threeHelper.find node, @brickShadowRootNode
		@objectsRootNode.remove threeHelper.find node, @objectsRootNode

	onNodeSelect: (@selectedNode) => return

	onNodeDeselect: => @selectedNode = null

	_zoomToNode: (threeNode) =>
		boundingSphere = threeHelper.getBoundingSphereWorld threeNode
		@bundle.renderer.zoomToBoundingSphere boundingSphere


	# initialize visualization with data from newBrickator
	# change solid renderer appearance
	_initializeData: (node, visualizationData, newBrickatorData) =>
		# init node visualization
		visualizationData.brickVisualization.initialize newBrickatorData.grid
		visualizationData.numZLayers = newBrickatorData.grid.getMaxZ() + 1
		visualizationData.initialized = true


		# instead of creating csg live, show original semitransparent model
		visualizationData.modelVisualization.setSolidMaterial(
			@coloring.objectPrintMaterial
		)

	# returns the node visualization or creates one
	_getCachedData: (selectedNode) =>
		return selectedNode
		.getPluginData 'brickVisualizer'
		.then (data) =>
			if data?
				return data
			else
				data = @createNodeDataStructure selectedNode
				selectedNode.storePluginData 'brickVisualizer', data, true
				return data


	# creates visualization data structures
	createNodeDataStructure: (node) =>
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
				@bundle, brickThreeNode, brickShadowThreeNode, @coloring
			)
			modelVisualization: new ModelVisualization(
				@bundle.globalConfig,
				node,
				modelThreeNode,
				@coloring
			)
		}

		return data

	###
	# Sets the overall display mode
	# @param {Node} selectedNode the currently selected node
	# @param {String} mode the mode: 'legoBrush'/'printBrush'/'stability'/'build'
	###
	setDisplayMode: (selectedNode, @visualizationMode) =>
		return unless selectedNode?

		return @_getCachedData selectedNode
		.then (cachedData) =>
			switch @visualizationMode
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

	_updateBrickCount: (bricks) =>
		@brickCounter?.text bricks.size

	_updatePrintTime: (csg) =>
		if csg?.geometry?
			time = @csg.getPrintingTimeEstimate csg.geometry
			@timeEstimate?.text Math.round(time)
		else
			@timeEstimate?.text 0

	_showCsg: (cachedData) =>
		@csg ?= @bundle.getPlugin 'csg'
		return Promise.resolve() if not @csg?

		return @csg
				.getCSG(cachedData.node, {addStuds: true})
				.then (csg) =>
					cachedData.brickVisualization.showCsg csg
					@_updatePrintTime csg

	# check whether the pointer is over a model/brick visualization
	pointerOverModel: (event, ignoreInvisible = true) =>
		intersections = @_getPointerIntersections event

		return intersections.length > 0 unless ignoreInvisible
		visibleIntersections = intersections.filter (intersection) ->
			object = intersection.object
			while object?
				return false unless object.visible
				object = object.parent
			return true

		return visibleIntersections.length > 0

	_getPointerIntersections: (event) =>
		if @usePipeline
			modelIntersections = interactionHelper.getIntersections(
				event, @bundle.renderer, @objectsRootNode.children
			)
			if modelIntersections.length > 0
				return modelIntersections

			brickIntersections = interactionHelper.getIntersections(
				event, @bundle.renderer, @brickRootNode.children
			)
			return brickIntersections
		else
			mixedIntersections = interactionHelper.getIntersections(
				event, @bundle.renderer, @threeJsRootNode.children
			)
			return mixedIntersections

module.exports = NodeVisualizer
