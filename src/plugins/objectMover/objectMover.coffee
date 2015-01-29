THREE = require 'three'

module.exports = class ObjectMover
	init: (@bundle) =>
		return
	init3d: (@threejsNode) =>
		return
	onStateUpdate: (state) =>
		return
	on3dUpdate: (timestamp) =>
		return
	getBrushes: =>
		return [{
			text: 'move'
			icon: 'move'
			clickCallback: -> console.log 'move-brush modifies scene (click)'
			moveCallback: @_handleMove
			selectCallback: -> console.log 'move-brush was selected'
			deselectCallback: -> console.log 'move-brush was deselected'
		}]

	_handleMove: (event) =>
		selectedNode = @bundle.ui.selection.selectedNode
		if not selectedNode?
			return
		@_createPluginData selectedNode
		pld = selectedNode.pluginData.objectMover

		posNew = @_getGridXY event.clientX, event.clientY
		if not pld.oldPosition?
			pld.oldPosition = posNew
			return
				
		delta = {
			x: posNew.x - pld.oldPosition.x
			y: posNew.y - pld.oldPosition.y
		}
		pld.oldPosition = posNew

		pld.realPosition.x += delta.x
		pld.realPosition.y += delta.y

		rasterPos = @_rasterizeVector pld.realPosition

		selectedNode.positionData.position.x = rasterPos.x
		selectedNode.positionData.position.y = rasterPos.y

		#console.log "Mouse moved in 3d: x:#{delta.x}, y:#{delta.y}"
		console.log "Set raster position to #{rasterPos.x}, #{rasterPos.y}"
		
	_createPluginData: (node) ->
		if not node.pluginData.objectMover?
			node.pluginData.objectMover = {
				realPosition: {
					x: node.positionData.position.x
					y: node.positionData.position.y
					z: node.positionData.position.z
				}
			}

	_getGridXY: (screenX, screenY) =>
		# calculates the position on the z=0 plane in 3d space
		# from given screen (mouse) coordinates
		# see http://stackoverflow.com/questions/13055214/
		camera = @bundle.renderer.getCamera()
		vector = new THREE.Vector3()
		relativeX = (screenX / window.innerWidth) * 2 - 1
		relativeY = -(screenY / window.innerHeight) * 2 + 1
		vector.set relativeX, relativeY, 0.5
		vector.unproject camera
		
		dir = vector.sub( camera.position ).normalize()
		distance = -camera.position.z / dir.z
		pos = camera.position.clone().add( dir.multiplyScalar( distance ) )

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

