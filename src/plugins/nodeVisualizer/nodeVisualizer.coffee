threeHelper = require '../../client/threeHelper'
BrickVisualization = require './visualization/brickVisualization'
ModelVisualization = require './modelVisualization'
interactionHelper = require '../../client/interactionHelper'
shaderGenerator = require './shaderGenerator'
RenderTargetHelper = require '../../client/rendering/renderTargetHelper'
stencilBits = require '../../client/rendering/stencilBits'
Coloring = require './visualization/Coloring'

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

		@coloring = new Coloring()

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

	onPaint: (@threeRenderer, camera) =>
		threeRenderer = @threeRenderer

		# recreate textures if either they havent been generated yet or
		# the screen size has changed
		if not (@renderTargetsInitialized? and
		RenderTargetHelper.renderTargetHasRightSize(
			@brickSceneTarget.renderTarget, threeRenderer
		))
			# bricks
			@brickSceneTarget = RenderTargetHelper.createRenderTarget(threeRenderer)

			# object
			customFrag = shaderGenerator.buildFragmentMainAdditions(
				{ expandBlack: true }
			)
			@objectsSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer,
				{ opacity: @objectOpacity, fragmentInMain: customFrag },
				THREE.NearestFilter
			)

			# brick shadow
			customFrag = shaderGenerator.buildFragmentMainAdditions(
				{ expandBlack: true, blackAlwaysOpaque: true }
			)
			@brickShadowSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer,
				{ opacity: @brickShadowOpacity, fragmentInMain: customFrag }
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
		threeRenderer.render @brickSceneTarget.quadScene, camera
		
		# everything that is 3d model and hidden gets the third bit set
		# every visible part of the 3d model gets the second bit set
		# (via increase and not being allowed to remove the first bit)
		gl.stencilFunc(gl.ALWAYS, stencilBits.hiddenObjectMask, 0xFF)
		gl.stencilOp(gl.KEEP, gl.REPLACE, gl.INCR)
		gl.stencilMask(stencilBits.visibleObjectMask | stencilBits.hiddenObjectMask)

		# render visible parts
		threeRenderer.render @objectsSceneTarget.quadScene, camera

		# render invisble parts (object behind lego bricks)
		if @brushHandler? and not @brushHandler.legoBrushSelected
			# Adjust object material to be dark and more transparent
			blendMat = @objectSceneTarget.blendingMaterial
			blendMat.uniforms.colorMult.value = @objectShadowColorMult
			blendMat.uniforms.opacity.value = @objectShadowOpacity

			# Only render where hidden 3d model is
			gl.stencilFunc(
				gl.EQUAL, stencilBits.hiddenObjectMask, stencilBits.hiddenObjectMask
			)
			gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)

			gl.disable(gl.DEPTH_TEST)
			threeRenderer.render @objectSceneTarget.quadScene, camera
			gl.enable(gl.DEPTH_TEST)

			# Reset material to non-shadow properties
			blendMat.uniforms.opacity.value = @objectOpacity
			blendMat.uniforms.colorMult.value = @objectColorMult

		# everything shadowy gets the fourth bit set
		gl.stencilFunc(gl.ALWAYS, 0xFF, 0xFF)
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
		gl.stencilMask(stencilBits.visibleShadowMask)

		# render this-could-be-lego-shadows and brush highlight
		threeRenderer.render @brickShadowSceneTarget.quadScene, camera

		gl.disable(gl.STENCIL_TEST)

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
				@bundle, brickThreeNode, brickShadowThreeNode, @coloring
			)
			modelVisualization: new ModelVisualization(
				@bundle.globalConfig, node, modelThreeNode, @coloring
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
				event, @bundle.renderer, @threejsRootNode.children
			)
			return mixedIntersections

module.exports = NodeVisualizer
