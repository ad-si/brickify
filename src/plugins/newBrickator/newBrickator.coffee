modelCache = require '../../client/modelCache'

module.exports = class NewBrickator
	constructor: () ->
		# smallest lego brick
		@baseBrick = {
			length: 8
			width: 8
			height: 3.2
		}

	init: (@bundle) => return
	init3d: (@threejsRootNode) => return

	getUiSchema: () =>
		voxelCallback = (selectedNode) =>
			modelCache.request(selectedNode.meshHash).then(
				(optimizedModel) => @voxelize optimizedModel, selectedNode
			)

		return {
		title: 'NewBrickator'
		type: 'object'
		actions:
			a1:
				title: 'Voxelize'
				callback: voxelCallback
		}

	voxelize: (optimizedModel, selectedNode) =>
		voxelGrid = {
			origin: {x: 0, y: 0, z: 0}
			spacing: {x: @baseBrick.length, y: @baseBrick.width, z: @baseBrick.height}
			numVoxelsX: 0
			numVoxelsY: 0
			numVoxelsZ: 0
			zLayers: []
		}

		bb = optimizedModel.boundingBox()
		voxelGrid.origin = bb.min
		voxelGrid.numVoxelsX = Math.ceil ((bb.max.x - bb.min.x) / voxelGrid.spacing.x)
		voxelGrid.numVoxelsY = Math.ceil ((bb.max.y - bb.min.y) / voxelGrid.spacing.y)
		voxelGrid.numVoxelsZ = Math.ceil ((bb.max.z - bb.min.z) / voxelGrid.spacing.z)

		console.log voxelGrid

		#for each voxel...
		for z in [0..voxelGrid.numVoxelsZ - 1] by 1
			layer = new Array()
			voxelGrid.zLayers.push layer

			for x in [0..voxelGrid.numVoxelsX - 1] by 1
				layer[x] = new Array()
				for y in [0..voxelGrid.numVoxelsY - 1] by 1
					#get the 8 edgepoints of this voxel cell
					edgepoints = @voxelEdgePoints voxelGrid, x, y, z
					voxelInsideModel = false
					for i in [0..7] by 1
						if optimizedModel.isInsideModel edgepoints[i]
							voxelInsideModel = true
							break
					layer[x][y] = voxelInsideModel

		console.log voxelGrid
		return voxelGrid

	voxelEdgePoints: (voxelGrid, voxelX, voxelY, voxelZ) ->
		# returns the 8 edge points in realWorld coordinates for the voxel with
		# given voxel coordinates
		points = []

		voxelOrigin = {
			x: voxelGrid.origin.x + voxelGrid.spacing.x * voxelX
			y: voxelGrid.origin.y + voxelGrid.spacing.y * voxelY
			z: voxelGrid.origin.z + voxelGrid.spacing.z * voxelZ
		}

		points.push voxelOrigin
		points.push {
			x: voxelOrigin.x + voxelGrid.spacing.x
			y: voxelOrigin.y #+ voxelGrid.spacing.y
			z: voxelOrigin.z #+ voxelGrid.spacing.z
		}
		points.push {
			x: voxelOrigin.x + voxelGrid.spacing.x
			y: voxelOrigin.y + voxelGrid.spacing.y
			z: voxelOrigin.z #+ voxelGrid.spacing.z
		}
		points.push {
			x: voxelOrigin.x + voxelGrid.spacing.x
			y: voxelOrigin.y + voxelGrid.spacing.y
			z: voxelOrigin.z + voxelGrid.spacing.z
		}
		points.push {
			x: voxelOrigin.x #+ voxelGrid.spacing.x
			y: voxelOrigin.y + voxelGrid.spacing.y
			z: voxelOrigin.z #+ voxelGrid.spacing.z
		}
		points.push {
			x: voxelOrigin.x #+ voxelGrid.spacing.x
			y: voxelOrigin.y + voxelGrid.spacing.y
			z: voxelOrigin.z + voxelGrid.spacing.z
		}
		points.push {
			x: voxelOrigin.x #+ voxelGrid.spacing.x
			y: voxelOrigin.y #+ voxelGrid.spacing.y
			z: voxelOrigin.z + voxelGrid.spacing.z
		}
		points.push {
			x: voxelOrigin.x + voxelGrid.spacing.x
			y: voxelOrigin.y #+ voxelGrid.spacing.y
			z: voxelOrigin.z + voxelGrid.spacing.z
		}
		return points





