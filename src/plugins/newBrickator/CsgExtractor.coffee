ThreeCSG = require './threeCSG/ThreeCSG'

module.exports = class CsgExtractor
	extractGeometry: (grid, options) ->
		# extracts voxel that are not selected for
		# legofication (where enabled = false)
		# intersected with the original mesh
		# as a 3d geometry

		printVoxels = @_analyzeGrid(grid)

		if printVoxels.length == 0
			return null

		geo = @_createPrimitiveGeometry grid.spacing, options.knobSize
		voxelHull = @_createVoxelHull options.grid,	printVoxels, geo
		printGeometry = @_extractPrintGeometry options.transformedModel, voxelHull
		return printGeometry

	_analyzeGrid: (grid) ->
		# creates a list of voxels to be printed
		printVoxels = []

		grid.forEachVoxel (voxel, x, y, z) =>
			if not voxel.enabled
				#check if the voxel above is legofied. if yes, add a knob to current voxel
				knobOnTop = false
				if grid.zLayers[z + 1]?[x]?[y]? and grid.zLayers[z + 1][x][y].enabled
					knobOnTop = true

				# check if the voxel is the lowest voxel or has a lego brick below it
				# if yes, create space for knob below
				knobFromBelow = false
				if z == 0 or
				(grid.zLayers[z - 1]?[x]?[y]? and grid.zLayers[z - 1][x][y].enabled)
					knobFromBelow = true

				printVoxels.push {
					x: x
					y: y
					z: z
					knobOnTop: knobOnTop
					knobFromBelow: knobFromBelow
				}

		return printVoxels

	_createPrimitiveGeometry: (gridSpacing, knobSize) ->
		# creates Geometry needed for CSG operations

		voxelGeometry = new THREE.BoxGeometry(
			gridSpacing.x, gridSpacing.y, gridSpacing.z
		)

		knobRotation = new THREE.Matrix4().makeRotationX( 3.14159 / 2 )
		dzBottom = -(gridSpacing.z / 2) + (knobSize.height / 2)
		knobTranslationBottom = new THREE.Matrix4().makeTranslation(0,0,dzBottom)
		dzTop = (gridSpacing.z / 2) + (knobSize.height / 2)
		knobTranslationTop = new THREE.Matrix4().makeTranslation(0,0,dzTop)
		
		knobGeometryBottom = new THREE.CylinderGeometry(
			knobSize.radius, knobSize.radius, knobSize.height, 20
		)
		knobGeometryTop = new THREE.CylinderGeometry(
			knobSize.radius, knobSize.radius, knobSize.height, 20
		)

		knobGeometryBottom.applyMatrix(knobRotation)
		knobGeometryTop.applyMatrix(knobRotation)
		knobGeometryBottom.applyMatrix(knobTranslationBottom)
		knobGeometryTop.applyMatrix(knobTranslationTop)

		return {
			# The shape of a voxel
			voxelGeometry: voxelGeometry
			# The shape of a knob that is subtracted from the bottom of the voxel
			knobGeometryBottom: knobGeometryBottom
			# The shape of a knob that is added on top of a voxel
			knobGeometryTop: knobGeometryTop
		}

	_createVoxelHull: (grid, printVoxels, primitiveGeometry) ->
		# creates a hull out of the selected voxels with knobs on top and bottom
		# ToDo: merge voxels into one geometry, see issue #202

		for voxel in printVoxels
			mesh = new THREE.Mesh(primitiveGeometry.voxelGeometry, null)
			mesh.translateX( grid.origin.x + grid.spacing.x * voxel.x)
			mesh.translateY( grid.origin.y + grid.spacing.y * voxel.y)
			mesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z)
			meshBsp = new ThreeBSP(mesh)

			if unionBsp?
				unionBsp = unionBsp.union(meshBsp)
			else
				unionBsp = meshBsp

			# if this is the lowest voxel to be printed, subtract a knob
			# to make it fit to lego bricks
			if voxel.knobFromBelow
				knobMesh = new THREE.Mesh(primitiveGeometry.knobGeometryBottom, null)
				knobMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
				knobMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
				knobMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

				knobBsp = new ThreeBSP(knobMesh)
				unionBsp = unionBsp.subtract knobBsp

			# create a knob for lego above this voxel
			if voxel.knobOnTop
				knobMesh = new THREE.Mesh(primitiveGeometry.knobGeometryTop, null)
				knobMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
				knobMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
				knobMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

				knobBsp = new ThreeBSP(knobMesh)
				unionBsp = unionBsp.union knobBsp

		return unionBsp

	_extractPrintGeometry: (originalModel, voxelHull) ->
		# returns the volumetric intersection of the selected voxels and
		# the original model as a THREE.Mesh

		modelBsp = new ThreeBSP(originalModel)
		printBsp = modelBsp.intersect(voxelHull)
		return printBsp.toMesh(null)
