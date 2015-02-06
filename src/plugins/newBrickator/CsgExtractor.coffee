ThreeCSG = require './threeCSG/ThreeCSG'

module.exports = class CsgExtractor
	extractGeometry: (grid, options) ->
		analyzeResult = @_analyzeGrid(grid)

		if analyzeResult.printVoxels.length == 0
			return null

		geo = @_createPrimitiveGeometry grid.spacing, options.knobSize
		voxelHull = @_createVoxelHull options.grid,
			analyzeResult.printVoxels, analyzeResult.zRange, geo
		printGeometry = @_extractPrintGeometry options.transformedModel, voxelHull
		return printGeometry

	_analyzeGrid: (grid) ->
		# creates a list of voxels to be printed
		# and analyze their z-Range

		printVoxels = []
		zRange = {}

		grid.forEachVoxel (voxel, x, y, z) =>
			if not voxel.enabled
				printVoxels.push {x: x, y: y, z: z}

				range = zRange[@_genKey(x,y)]

				if not range?
					range = {
						lowest: z
						highest: z
					}
				if range.lowest > z
					range.lowest = z
				if range.highest < z
					range.highest = z

				zRange[@_genKey(x,y)] = range

		return {
			printVoxels: printVoxels
			zRange: zRange
		}

	_genKey: (x, y) ->
		return "#{x}-#{y}"

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
			voxelGeometry: voxelGeometry
			knobGeometryBottom: knobGeometryBottom
			knobGeometryTop: knobGeometryTop
		}

	_createVoxelHull: (grid, printVoxels, zRange, primitiveGeometry) ->
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

			# if this is the lowes voxel to be printed, subtract a knob
			# to make it fit to lego bricks
			range = zRange[@_genKey(voxel.x,voxel.y)]
			if voxel.z == range.lowest
				knobMesh = new THREE.Mesh(primitiveGeometry.knobGeometryBottom, null)
				knobMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
				knobMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
				knobMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

				knobBsp = new ThreeBSP(knobMesh)
				unionBsp = unionBsp.subtract knobBsp

			# if this is the highest voxel to be printed,
			# add knobs (for connecting with lego above this geometry)
			# but only if this voxel would have lego above it
			if grid.zLayers[voxel.z]?[voxel.x]?[voxel.y]?
				legoAbove = true

			if voxel.z == range.highest and legoAbove
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
