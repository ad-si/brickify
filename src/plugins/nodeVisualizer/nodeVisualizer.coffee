BrushHandler = require './BrushHandler'
threeHelper = require '../../client/threeHelper'
BrickVisualization = require './visualization/brickVisualization'
ModelVisualization = require './modelVisualization'
RenderTargetQuadGenerator = require './RenderTargetQuadGenerator'

###
# @class NodeVisualizer
###
class NodeVisualizer
	constructor: ->
		@printMaterial = new THREE.MeshLambertMaterial({
			color: 0xeeeeee
		})

		# remove z-Fighting on baseplate
		@printMaterial.polygonOffset = true
		@printMaterial.polygonOffsetFactor = 1
		@printMaterial.polygonoffsetUnits = 1

	init: (@bundle) =>
		@brushHandler = new BrushHandler(@bundle, @)

	init3d: (@threejsRootNode) =>
		# Voxels / Bricks are rendered as a first render pass
		@brickScene = @bundle.renderer.getDefaultScene()

		# Objects are rendered in the 2nd / 3rd render pass
		@objectScene = @bundle.renderer.getDefaultScene()

		# LegoShadow is rendered as a 3rd rendering pass
		@brickShadowScene = @bundle.renderer.getDefaultScene()
		
		return

	customRenderPass: (threeRenderer, camera) =>
		# First render pass: render Bricks & Voxels
		if not @brickSceneTarget?
			@brickSceneTarget = @_createRenderTarget(threeRenderer)
		threeRenderer.render @brickScene, camera, @brickSceneTarget.renderTarget, true

		# Second pass: render object
		if not @objectSceneTarget?
			@objectSceneTarget = @_createRenderTarget(threeRenderer, { opacity: 0.8 })
		threeRenderer.render(
			@objectScene, camera, @objectSceneTarget.renderTarget, true
		)

		# Third pass: render shadows
		if not @brickShadowSceneTarget?
			@brickShadowSceneTarget = @_createRenderTarget(
				threeRenderer, { opacity: 0.5 }
			)
		threeRenderer.render(
			@brickShadowScene, camera, @brickShadowSceneTarget.renderTarget, true
		)

		# finally render everything (on planes) on screen
		gl = threeRenderer.context

		# bricks
		threeRenderer.render @brickSceneTarget.planeScene, camera
		
		# the visible parts of the object
		# set stencil to 1 if object fails depth test
		gl.enable(gl.STENCIL_TEST)
		gl.stencilFunc(gl.ALWAYS, 1, 0xFF)
		gl.stencilOp(gl.ZERO, gl.REPLACE, gl.ZERO)
		gl.stencilMask(0xFF)
		threeRenderer.render @objectSceneTarget.planeScene, camera
		gl.stencilMask(0x00)

		# Object behind lego		
		if not @brushHandler.legoBrushSelected
			# Only render where stencil is 1, set whole stencil buffer to 0
			gl.disable(gl.DEPTH_TEST)
			gl.enable(gl.STENCIL_TEST)
			gl.stencilFunc(gl.EQUAL, 1, 0xFF)
			gl.stencilOp(gl.ZERO, gl.ZERO, gl.ZERO)
			gl.stencilMask(0x00)

			blendMat = @objectSceneTarget.planeScene.children[0].material
			blendMat.uniforms.colorMult.value = new THREE.Vector3(0.1, 0.1, 0.1)
			threeRenderer.render @objectSceneTarget.planeScene, camera
			blendMat.uniforms.colorMult.value = new THREE.Vector3(1, 1, 1)

			gl.disable(gl.STENCIL_TEST)
			gl.enable(gl.DEPTH_TEST)
		
		# this-could-be-lego-shadows and brush highlight
		gl.disable(gl.STENCIL_TEST)
		threeRenderer.render @brickShadowSceneTarget.planeScene, camera
		return

	_createRenderTarget: (threeRenderer, shaderOptions) ->
		# Create rendertarget
		renderWidth = threeRenderer.domElement.width
		renderHeight = threeRenderer.domElement.height

		depthTexture = new THREE.DepthTexture renderWidth, renderHeight
		renderTargetTexture = new THREE.WebGLRenderTarget(
			renderWidth
			renderHeight
			{
				minFilter: THREE.LinearFilter
				magFilter: THREE.NearestFilter
				format: THREE.RGBFormat
				depthTexture: depthTexture
			}
		)

		#create scene to render texture
		planeScene = new THREE.Scene()
		rttPlane = RenderTargetQuadGenerator.generateQuad(
			renderTargetTexture, depthTexture, shaderOptions
		)
		planeScene.add rttPlane

		return {
			depthTexture: depthTexture
			renderTarget: renderTargetTexture
			planeScene: planeScene
			blendingMaterial: rttPlane.material
		}
		 

	getBrushes: =>
		return @brushHandler.getBrushes()

	# called by newBrickator when an object's datastructure is modified
	objectModified: (node, newBrickatorData) =>
		@_getCachedData(node)
		.then (cachedData) =>
			if not cachedData.initialized
				@_initializeData node, cachedData, newBrickatorData

			# update brick references and visualization
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
			cachedData.modelVisualization.afterCreation().then =>
				@zoomToNode cachedData.modelVisualization.getSolid()

	onNodeRemove: (node) =>
		@brickScene.remove threeHelper.find node, @brickScene
		@brickShadowScene.remove threeHelper.find node, @brickShadowScene
		@objectScene.remove threeHelper.find node, @objectScene

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
		brickThreeNode = new THREE.Object3D()
		@brickScene.add brickThreeNode

		brickShadowThreeNode = new THREE.Object3D()
		@brickShadowScene.add brickShadowThreeNode
		
		modelThreeNode = new THREE.Object3D()
		@objectScene.add modelThreeNode

		threeHelper.link node, brickThreeNode
		threeHelper.link node, brickShadowThreeNode
		threeHelper.link node, modelThreeNode

		data = {
			initialized: false
			node: node
			brickVisualization: new BrickVisualization(
				@bundle, brickThreeNode, brickShadowThreeNode
			)
			modelVisualization: new ModelVisualization(
				@bundle.globalConfig, node, modelThreeNode
			)
		}

		return data

	_setStabilityView: (selectedNode, stabilityViewEnabled) =>
		return if !selectedNode?

		@_getCachedData(selectedNode).then (cachedData) =>
			if stabilityViewEnabled
				# only show bricks and csg
				@_showCsg cachedData
				.then =>
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
