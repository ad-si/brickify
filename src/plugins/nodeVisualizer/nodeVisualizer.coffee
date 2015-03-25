BrushHandler = require './BrushHandler'
threeHelper = require '../../client/threeHelper'
BrickVisualization = require './visualization/brickVisualization'
ModelVisualization = require './modelVisualization'
RenderTargetHelper = require '../../client/rendering/renderTargetHelper'
pointerEnums = require '../../client/ui/pointerEnums'
PointEventHandler = require './pointEventHandler'
interactionHelper = require '../../client/interactionHelper'
stencilBits = require '../../client/rendering/stencilBits'

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
		@printMaterial.polygonOffsetFactor = 5
		@printMaterial.polygonOffsetUnits = 5

		# rendering properties
		@brickShadowOpacity = 0.5
		@objectOpacity = 0.8
		@objectShadowOpacity = 0.5
		@objectColorMult = new THREE.Vector3(1, 1, 1)
		@objectShadowColorMult = new THREE.Vector3(0.1, 0.1, 0.1)

	init: (@bundle) =>
		if @bundle.ui?
			@brushHandler = new BrushHandler(@bundle, @)

			# bind brushes to UI
			brushSelector = @bundle.ui.workflowUi.brushSelector
			brushSelector.setBrushes @brushHandler.getBrushes()

			@pointEventHandler = new PointEventHandler(
				@bundle.sceneManager
				brushSelector
			)

	init3d: (@threejsRootNode) =>
		# Voxels / Bricks are rendered as a first render pass
		@brickScene = @bundle.renderer.getDefaultScene()

		# Objects are rendered in the 2nd / 3rd render pass
		@objectScene = @bundle.renderer.getDefaultScene()

		# LegoShadow is rendered as a 3rd rendering pass
		@brickShadowScene = @bundle.renderer.getDefaultScene()
		
		return

	customRenderPass: (@threeRenderer, camera) =>
		threeRenderer = @threeRenderer

		# First render pass: render Bricks & Voxels
		if not @brickSceneTarget?
			@brickSceneTarget = RenderTargetHelper.createRenderTarget(threeRenderer)
		threeRenderer.render @brickScene, camera, @brickSceneTarget.renderTarget, true

		# Second pass: render object
		if not @objectSceneTarget?
			@objectSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer,
				{ opacity: @objectOpacity, expandBlack: true }
			)
		threeRenderer.render(
			@objectScene, camera, @objectSceneTarget.renderTarget, true
		)

		# Third pass: render shadows
		if not @brickShadowSceneTarget?
			@brickShadowSceneTarget = RenderTargetHelper.createRenderTarget(
				threeRenderer,
				{ opacity: @brickShadowOpacity, blackAlwaysOpaque: true, expandBlack: true }
			)
		threeRenderer.render(
			@brickShadowScene, camera, @brickShadowSceneTarget.renderTarget, true
		)

		# finally render everything (on quads) on screen
		gl = threeRenderer.context

		# everything that is visible lego gets the first bit set
		gl.enable(gl.STENCIL_TEST)
		gl.stencilFunc(gl.ALWAYS, stencilBits.maskBit0, 0xFF)
		gl.stencilOp(gl.ZERO, gl.ZERO, gl.REPLACE)
		gl.stencilMask(0xFF)

		# bricks
		threeRenderer.render @brickSceneTarget.planeScene, camera
		
		# everything that is 3d model and hidden gets the third bit set
		# every visible part of the 3d model gets the second bit set
		# (via increase and not being allowed to remove the first bit)
		gl.stencilFunc(gl.ALWAYS, stencilBits.maskBit2, 0xFF)
		gl.stencilOp(gl.KEEP, gl.REPLACE, gl.INCR)
		gl.stencilMask(stencilBits.maskBit1 | stencilBits.maskBit2)

		# render visible parts
		threeRenderer.render @objectSceneTarget.planeScene, camera

		# render invisble parts (object behind lego bricks)
		if @brushHandler? and not @brushHandler.legoBrushSelected
			# Adjust object material to be dark and more transparent
			blendMat = @objectSceneTarget.blendingMaterial
			blendMat.uniforms.colorMult.value = @objectShadowColorMult
			blendMat.uniforms.opacity.value = @objectShadowOpacity

			# Only render where hidden 3d model is
			gl.stencilFunc(gl.EQUAL, stencilBits.maskBit2, stencilBits.maskBit2)
			gl.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP)

			gl.disable(gl.DEPTH_TEST)
			threeRenderer.render @objectSceneTarget.planeScene, camera
			gl.enable(gl.DEPTH_TEST)

			# Reset material to non-shadow properties
			blendMat.uniforms.opacity.value = @objectOpacity
			blendMat.uniforms.colorMult.value = @objectColorMult

		# everything shadowy gets the fourth bit set
		gl.stencilFunc(gl.ALWAYS, 0xFF, 0xFF)
		gl.stencilOp(gl.KEEP, gl.KEEP, gl.REPLACE)
		gl.stencilMask(stencilBits.maskBit3)

		# render this-could-be-lego-shadows and brush highlight
		threeRenderer.render @brickShadowSceneTarget.planeScene, camera

		gl.disable(gl.STENCIL_TEST)
		

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

	pointerEvent: (event, eventType) =>
		return false if not @pointEventHandler?
		return false if not @_pointerOverModel event

		switch eventType
			when pointerEnums.events.PointerDown
				@pointEventHandler.pointerDown event
				return true
			when pointerEnums.events.PointerMove
				return @pointEventHandler.pointerMove event
			when pointerEnums.events.PointerUp
				@pointEventHandler.pointerUp event
				return true
			when pointerEnums.events.PointerCancel
				@pointEventHandler.PointerCancel event
				return true

	#check whether the pointer is over the model
	_pointerOverModel: (event) =>
		# get NDC coordinates
		return false if not @threeRenderer?

		#Patch THREE nomenclature
		#rendertarget.format is now rendertarget.texture.format
		#but the method is not updated yet
		rt = @objectSceneTarget.renderTarget
		rt.format = rt.texture.format

		rt = @brickSceneTarget.renderTarget
		rt.format = rt.texture.format

		# screen -> ndc
		point = interactionHelper.calculatePositionInCanvasSpace(
			event, @threeRenderer
		)

		#ndc -> renderTarget dimensions
		objTargetDim = {
			hw: @objectSceneTarget.renderTarget.width / 2
			hh: @objectSceneTarget.renderTarget.height / 2
		}
		brickTargetDim = {
			hw: @brickSceneTarget.renderTarget.width / 2
			hh: @brickSceneTarget.renderTarget.height / 2
		}

		pObj = {
			x: Math.round objTargetDim.hw + point.x * objTargetDim.hw
			y: Math.round objTargetDim.hh + point.y * objTargetDim.hh
		}
		pBrick = {
			x: Math.round brickTargetDim.hw + point.x * brickTargetDim.hw
			y: Math.round brickTargetDim.hh + point.y * brickTargetDim.hh
		}

		# get depth values from last renderpass
		pixelDataObject = new Uint8Array(4)
		pixelDataBricks = new Uint8Array(4)
		@threeRenderer.readRenderTargetPixels(
			@objectSceneTarget.renderTarget, pObj.x, pObj.y, 1, 1, pixelDataObject
		)
		@threeRenderer.readRenderTargetPixels(
			@brickSceneTarget.renderTarget, pBrick.x, pBrick.y, 1, 1, pixelDataBricks
		)

		#get the lightest color of both
		col = {
			r: Math.max pixelDataBricks[0], pixelDataObject[0]
			g: Math.max pixelDataBricks[1], pixelDataObject[1]
			b: Math.max pixelDataBricks[2], pixelDataObject[2]
			a: Math.max pixelDataBricks[3], pixelDataObject[3]
		}

		# if it's not transparent and not completely black, there are bricks/object
		# below pointer
		if (col.a > 0.01 && col.r > 0.01 && col.g > 0.01 && col.b > 0.01)
			return true
		return false



module.exports = NodeVisualizer
