###
  #Solid Renderer Plugin#

  Renders loaded models with default color inside the scene
###

THREE = require 'three'
objectTree = require '../../common/objectTree'
modelCache = require '../../client/modelCache'

module.exports = class SolidRenderer

	init: (@bundle) ->
		@globalConfig = @bundle.globalConfig

	init3d: (@threejsNode) ->
		return

	# check if there are any threejs objects that haven't been loaded yet
	# if so, load the referenced model from the server
	onStateUpdate: (state) =>
		@removeDeletedObjects state
		return Promise.all(
			objectTree.forAllSubnodes state.rootNode, @loadModelIfNeeded, false
		)

	removeDeletedObjects: (state) ->
		nodeUuids = []
		collectUuid = (node) =>
			if node.pluginData.solidRenderer?
				nodeUuids.push node.pluginData.solidRenderer.threeObjectUuid
		objectTree.forAllSubnodes state.rootNode, collectUuid, false
		threeUuids = @threejsNode.children.map (threenode) -> threenode.name
		deleted = threeUuids.filter (uuid) => uuid not in nodeUuids
		for d in deleted
			obj =  @threejsNode.getObjectByName d
			@threejsNode.remove obj

	loadModelIfNeeded: (node) =>
		if node.pluginData.solidRenderer?
			properties = node.pluginData.solidRenderer
			storedUuid = properties.threeObjectUuid
			threeObject = @threejsNode.getObjectByName storedUuid, true
			if not threeObject?
				return @loadModelFromCache node, properties, true
			else
				@_copyTransformDataToThree node, threeObject
				return Promise.resolve()
		else
			node.pluginData.solidRenderer = {}
			return @loadModelFromCache node, node.pluginData.solidRenderer, false


	loadModelFromCache: (node, properties, reload = false) ->
		#Create object and override name
		success = (optimizedModel) =>
			console.log "Got model #{node.meshHash}"
			threeObject = @addModelToThree optimizedModel
			if reload
				threeObject.name = properties.threeObjectUuid
			else
				properties.threeObjectUuid = threeObject.name

			@_copyTransformDataToThree node, threeObject
			return optimizedModel
		failure = () ->
			console.error "Unable to get model #{node.meshHash}"

		prom = modelCache.request node.meshHash
		prom.catch failure
		return prom.then success

	# parses the binary geometry and adds it to the three scene
	addModelToThree: (optimizedModel) ->
		geometry = optimizedModel.convertToThreeGeometry()
		objectMaterial = new THREE.MeshLambertMaterial(
			{
				color: @globalConfig.colors.object
				ambient: @globalConfig.colors.object
			}
		)
		object = new THREE.Mesh(geometry, objectMaterial)
		object.name = object.uuid
		@latestAddedObject = object

		@threejsNode.add object
		return object

	newBoundingSphere: () =>
		if @latestAddedObject
			@latestAddedObject.geometry.computeBoundingSphere()
			result =
				radius: @latestAddedObject.geometry.boundingSphere.radius
				center: @latestAddedObject.geometry.boundingSphere.center
			@latestAddedObject = null
			return result
		else
			return null

	_copyTransformDataToThree: (node, threeObject) ->
		posd = node.positionData
		threeObject.position.set posd.position.x, posd.position.y, posd.position.z
		threeObject.rotation.set(
			posd.rotation._x,
			posd.rotation._y,
			posd.rotation._z
		)
		threeObject.scale.set posd.scale.x, posd.scale.y, posd.scale.z

	getBrushes: =>
		return [{
			text: 'move'
			icon: 'moveBrush.png'
			mouseDownCallback: @_handleMouseDown
			mouseMoveCallback: @_handleMouseMove
			mouseUpCallback: @_handleMouseUp
		}]

	_getThreeObjectByName: (name) =>
		for obj in @threejsNode.children
			if obj.name == name
				return obj
		return null

	_handleMouseDown: (event, selectedNode) =>
		@mouseStartPosition = @_getGridXY event.clientX, event.clientY

		@originalObjectPosition = selectedNode.positionData.position

	_handleMouseUp: (event, selectedNode) =>
		@mouseStartPosition = null
		return

	_handleMouseMove: (event, selectedNode) =>
		pld = selectedNode.pluginData.solidRenderer

		mouseCurrent = @_getGridXY event.clientX, event.clientY
		delta = {
			x: mouseCurrent.x - @mouseStartPosition.x
			y: mouseCurrent.y - @mouseStartPosition.y
		}
		#console.log delta

		newPosition = {
			x: @originalObjectPosition.x + delta.x
			y: @originalObjectPosition.y + delta.y
		}

		rasterPos = @_rasterizeVector newPosition

		selectedNode.positionData.position.x = mouseCurrent.x
		selectedNode.positionData.position.y = mouseCurrent.y
		
		###
		updateCallback = (state) =>
			selectedNode.positionData.position.x = rasterPos.x
			selectedNode.positionData.position.y = rasterPos.y
			return
		@bundle.statesync.performStateAction updateCallback
		###

		threeObject = @_getThreeObjectByName pld.threeObjectUuid
		@_copyTransformDataToThree selectedNode, threeObject

		#console.log "Mouse moved in 3d: x:#{delta.x}, y:#{delta.y}"
		#console.log "Set raster position to #{rasterPos.x}, #{rasterPos.y}"

	_getGridXY: (screenX, screenY) =>
		# calculates the position on the z=0 plane in 3d space
		# from given screen (mouse) coordinates
		# see http://stackoverflow.com/questions/13055214/
		canvas = @bundle.renderer.threeRenderer.context.canvas

		camera = @bundle.renderer.getCamera()
		vector = new THREE.Vector3()
		relativeX = (screenX / canvas.width) * 2 - 1
		relativeY = (-screenY / canvas.height) * 2 + 1
		vector.set relativeX, relativeY, 0.9
		vector.unproject camera
		
		console.log ''
		console.log "-> Screen:      #{relativeX.toFixed(2)},
			#{relativeY.toFixed(2)}, 0.500"

		console.log "-> Unprojected: #{vector.x.toFixed(2)},
			#{vector.y.toFixed(2)}, #{vector.z.toFixed(2)}"

		dir = vector.sub( camera.position ).normalize()
		distance = -camera.position.z / dir.z
		pos = camera.position.clone().add( dir.multiplyScalar( distance ) )

		console.log "-> Position:    #{pos.x.toFixed(2)},
			#{pos.y.toFixed(2)}, #{pos.z.toFixed(2)}"

		return pos

	_rasterizeVector: (vector, raster = 2) =>
		vector.x = @_rasterize vector.x, raster
		vector.y = @_rasterize vector.y, raster
		return vector

	_rasterize: (value, raster) ->
		mod = value % raster
		if mod > (raster / 2)
			value += (raster - mod)
		else
			value -= mod
		return value
