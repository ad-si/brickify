expect = require('chai').expect
Grid = require '../../src/plugins/newBrickator/Grid'
VoxelUnion = require '../../src/plugins/newBrickator/VoxelUnion'
THREE = require 'three'

describe 'VoxelUnion', ->
	grid = new Grid()
	grid.origin = {x: 0, y: 0, z: 0}

	it 'should create a single cube csg', () ->
		vg = new VoxelUnion(grid)
		bsp = vg.run [ {x: 0, y: 0, z: 0} ]
		geometry = bsp.toMesh(null).geometry

		expect(geometry.faces.length).to.equal(12)
		expect(geometry.vertices.length).to.equal(8)

	it 'should create a 2x2 plate csg', () ->
		vg = new VoxelUnion(grid)
		bsp = vg.run [
			{x: 0, y: 0, z: 0}
			{x: 1, y: 0, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 0, y: 1, z: 0}
		]
		geometry = bsp.toMesh(null).geometry

		expect(geometry.faces.length).to.equal(32)
		expect(geometry.vertices.length).to.equal(18)

	it 'should create a 2x2x2 cube csg with 26 vertices', () ->
		vg = new VoxelUnion(grid)
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

	it 'should create a 2x2x2 cube THREE.Geometry with 27 vertices', () ->
		# the algorithm creates a point in the middle of the cube,
		# which is then not used in the geometry

		vg = new VoxelUnion(grid)
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

	it 'should create a "+" with hole plate THREE.Geometry', () ->
		#  #
		# # #
		#  #

		vg = new VoxelUnion(grid)
		geometry = vg._createVoxelGeometry [
			{x: 1, y: 0, z: 0}
			{x: 0, y: 1, z: 0}
			{x: 2, y: 1, z: 0}
			{x: 1, y: 2, z: 0}
		]
		
		expect(geometry.vertices.length).to.equal(24)
		expect(geometry.faces.length).to.equal(8 + 32 + 8)

	it 'should create a 3x3 plate THREE.Geometry', () ->
		vg = new VoxelUnion(grid)
		geometry = vg._createVoxelGeometry [
			{x: 0, y: 0, z: 0}
			{x: 1, y: 0, z: 0}
			{x: 2, y: 0, z: 0}
			{x: 0, y: 1, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 2, y: 1, z: 0}
			{x: 0, y: 2, z: 0}
			{x: 1, y: 2, z: 0}
			{x: 2, y: 2, z: 0}
		]
		
		expect(geometry.vertices.length).to.equal(32)
		expect(geometry.faces.length).to.equal(18 + 24 + 18)

	it 'should create a filled "+" plate THREE.Geometry', () ->
		#  #
		# ###
		#  #

		vg = new VoxelUnion(grid)
		geometry = vg._createVoxelGeometry [
			{x: 1, y: 0, z: 0}
			{x: 0, y: 1, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 2, y: 1, z: 0}
			{x: 1, y: 2, z: 0}
		]
		
		expect(geometry.vertices.length).to.equal(24)
		expect(geometry.faces.length).to.equal(10 + 24 + 10)

	it 'should create a filled "+" plate datastructure', () ->
		#  #
		# ###
		#  #

		vg = new VoxelUnion(grid)
		data = vg._prepareData [
			{x: 1, y: 0, z: 0}
			{x: 0, y: 1, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 2, y: 1, z: 0}
			{x: 1, y: 2, z: 0}
		]
		
		expect(data.minX).to.equal(0)
		expect(data.minY).to.equal(0)
		expect(data.minZ).to.equal(0)
		expect(data.maxX).to.equal(2)
		expect(data.maxY).to.equal(2)
		expect(data.maxZ).to.equal(0)

		expect(data.zLayers[-1]).to.not.equal(undefined)
		expect(data.zLayers[0]).to.not.equal(undefined)
		expect(data.zLayers[1]).to.not.equal(undefined)

		for z in [-1..1] by 1
			for x in [-1..3] by 1
				expect(data.zLayers[z][x]).to.not.equal(undefined)

		expect(data.zLayers[0][0][0].voxel).to.equal(false)
		expect(data.zLayers[0][1][0].voxel).to.equal(true)
		expect(data.zLayers[0][2][0].voxel).to.equal(false)
		expect(data.zLayers[0][0][1].voxel).to.equal(true)
		expect(data.zLayers[0][1][1].voxel).to.equal(true)
		expect(data.zLayers[0][2][1].voxel).to.equal(true)
		expect(data.zLayers[0][0][2].voxel).to.equal(false)
		expect(data.zLayers[0][1][2].voxel).to.equal(true)
		expect(data.zLayers[0][2][2].voxel).to.equal(false)

		expect(data.zLayers[1][1][1].voxel).to.equal(false)
		expect(data.zLayers[-1][1][1].voxel).to.equal(false)

	it 'should create a filled "+" plate point list', () ->
		#  #
		# ###
		#  #

		vg = new VoxelUnion(grid)
		data = vg._prepareData [
			{x: 1, y: 0, z: 0}
			{x: 0, y: 1, z: 0}
			{x: 1, y: 1, z: 0}
			{x: 2, y: 1, z: 0}
			{x: 1, y: 2, z: 0}
		]

		geo = new THREE.Geometry()

		vg._createGeoPoints 1, 0, 0, data, geo
		vg._createGeoPoints 0, 1, 0, data, geo
		vg._createGeoPoints 1, 1, 0, data, geo
		vg._createGeoPoints 2, 1, 0, data, geo
		vg._createGeoPoints 1, 2, 0, data, geo

		expect(geo.vertices.length).to.equal(12)


