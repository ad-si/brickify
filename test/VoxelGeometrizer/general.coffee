expect = require('chai').expect

Grid = require '../../src/plugins/newBrickator/Grid'
VoxelGeometrizer = require '../../src/plugins/newBrickator/VoxelGeometrizer'

describe 'VoxelGeometrizer', ->
	grid = new Grid()
	grid.origin = {x: 0, y: 0, z: 0}

	it 'should create a single cube csg', (done) ->
		vg = new VoxelGeometrizer(grid)
		bsp = vg.run [ {x: 0, y: 0, z: 0} ]
		geometry = bsp.toMesh(null).geometry

		expect(geometry.faces.length).to.equal(12)
		expect(geometry.vertices.length).to.equal(8)

		done()

	it 'should create a 2x2 plate csg', (done) ->
		vg = new VoxelGeometrizer(grid)
		bsp = vg.run [
			{x: 0, y: 0, z: 0}
			{x: 1, y: 0, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 0, y: 1, z: 0}
		]
		geometry = bsp.toMesh(null).geometry

		expect(geometry.faces.length).to.equal(32)
		expect(geometry.vertices.length).to.equal(18)

		done()

	it 'should create a 2x2x2 cube csg with 26 vertices', (done) ->
		vg = new VoxelGeometrizer(grid)
		bsp = vg.run [
			{x: 0, y: 0, z: 0}
			{x: 1, y: 0, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 0, y: 1, z: 0}
			{x: 0, y: 0, z: 1}
			{x: 1, y: 0, z: 1}
			{x: 1, y: 1, z: 1}
			{x: 0, y: 1, z: 1}
		]
		geometry = bsp.toMesh(null).geometry

		expect(geometry.faces.length).to.equal(48)
		expect(geometry.vertices.length).to.equal(26)

		done()

	it 'should create a 2x2x2 cube THREE.Geometry with 27 vertices', (done) ->
		# the algorithm creates a point in the middle of the cube,
		# which is then not used in the geometry
		
		vg = new VoxelGeometrizer(grid)
		geometry = vg._createVoxelGeometry [
			{x: 0, y: 0, z: 0}
			{x: 1, y: 0, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 0, y: 1, z: 0}
			{x: 0, y: 0, z: 1}
			{x: 1, y: 0, z: 1}
			{x: 1, y: 1, z: 1}
			{x: 0, y: 1, z: 1}
		]

		expect(geometry.faces.length).to.equal(48)
		expect(geometry.vertices.length).to.equal(27)

		done()

