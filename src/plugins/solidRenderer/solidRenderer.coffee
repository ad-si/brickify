###
  #Solid Renderer Plugin#

  Renders loaded models with default color inside the scene
###

THREE = require 'three'
threeHelper = require '../../client/threeHelper'
modelCache = require '../../client/modelCache'
LineMatGenerator = require '../newBrickator/visualization/LineMatGenerator'
interactionHelper = require '../../client/interactionHelper'

class SolidRenderer
	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig
		@loadedModelsNodes = []
		@objectMaterial = new THREE.MeshLambertMaterial(
				color: @globalConfig.colors.object
				ambient: @globalConfig.colors.object
		)
		if @globalConfig.createVisibleWireframe
			@shadowMat = new THREE.MeshBasicMaterial(
				color: 0x000000
				transparent: true
				opacity: 0.4
				depthFunc: 'GREATER'
			)
			lineMaterialGenerator = new LineMatGenerator()
			@lineMat = lineMaterialGenerator.generate 0x000000
			@lineMat.linewidth = 2
			@lineMat.transparent = true
			@lineMat.opacity = 0.1
			@lineMat.depthFunc = 'GREATER'
			@lineMat.depthWrite = false

	init3d: (@threejsNode) ->
		return

	onNodeAdd: (node) =>
		_addSolid = (geometry, parent) =>
			solid = new THREE.Mesh geometry, @objectMaterial
			parent.add solid
			parent.solid = solid

		_addWireframe = (geometry, parent) =>
			# ToDo: create fancy shader material / correct rendering pipeline
			wireframe = new THREE.Object3D()

			#shadow
			shadow = new THREE.Mesh geometry, @shadowMat
			wireframe.add shadow

			# visible black lines
			lineObject = new THREE.Mesh geometry
			lines = new THREE.EdgesHelper lineObject, 0x000000, 30
			lines.material = @lineMat
			wireframe.add lines

			parent.wireframe = wireframe

		_addModel = (model) =>
			geometry = model.convertToThreeGeometry()
			object = new THREE.Object3D()

			_addSolid geometry, object
			_addWireframe geometry, object if @globalConfig.createVisibleWireframe

			threeHelper.link node, object
			threeHelper.applyNodeTransforms node, object

			@threejsNode.add object

		node.getModel().then _addModel

	onNodeRemove: (node) =>
		@threejsNode.remove threeHelper.find node, @threejsNode

	newBoundingSphere: () =>
		if @latestAddedObject
			geometry = @latestAddedObject.originalMesh.geometry
			geometry.computeBoundingSphere()
			result =
				radius: geometry.boundingSphere.radius
				center: geometry.boundingSphere.center

			# update center to match moved object
			@latestAddedObject.updateMatrix()
			result.center.applyProjection @latestAddedObject.matrix

			@latestAddedObject = null
			return result
		else
			return null

	setNodeVisibility: (node, visible) =>
		threeHelper.find(node, @threejsNode)?.visible = visible

	setShadowVisibility: (node, visible) =>
		threeHelper.find(node, @threejsNode)?.wireframe?.visible = visible

	setNodeMaterial: (node, threeMaterial) =>
		threeHelper.find(node, @threejsNode)?.solid.material = threeMaterial

	intersectRayWithModel: (event, node) =>
		obj = threeHelper.find(node, @threejsNode)?.solid
		return [] unless obj?

		# set two sided material to catch all sides
		oldMaterialSide = obj.material.side
		obj.material.side = THREE.DoubleSide

		intersections = interactionHelper.getIntersections(
				event
				@bundle.renderer
				[obj]
			)

		obj.material.side = oldMaterialSide

		return intersections

module.exports = SolidRenderer
