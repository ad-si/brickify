expect = require('chai').expect
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'Grid', ->
	it 'should set a voxel', ->
		grid = new Grid()
		grid.setVoxel {x: 0, y: 0, z: 0}
		expect(grid.hasVoxelAt 0, 0, 0).to.equal(true)

	it 'should correctly report whether it has a voxel at a position', ->
		grid = new Grid()

		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 0, y: 0, z: 1}
		grid.setVoxel {x: 0, y: 2, z: 0}
		grid.setVoxel {x: 3, y: 0, z: 0}

		expect(grid.hasVoxelAt(0, 0, 0)).to.equal(true)
		expect(grid.hasVoxelAt(0, 0, 1)).to.equal(true)
		expect(grid.hasVoxelAt(0, 2, 0)).to.equal(true)
		expect(grid.hasVoxelAt(3, 0, 0)).to.equal(true)

		expect(grid.hasVoxelAt(5, 0, 1)).to.equal(false)
		expect(grid.hasVoxelAt(0, 5, 0)).to.equal(false)
		expect(grid.hasVoxelAt(0, 1, 0)).to.equal(false)

	it 'should enumerate over all voxels', ->
		grid = new Grid()

		grid.setVoxel {x: 1, y: 0, z: 0}
		grid.setVoxel {x: 0, y: 1, z: 0}
		grid.setVoxel {x: 0, y: 0, z: 1}

		e1 = false
		e2 = false
		e3 = false
		numEnum = 0

		grid.forEachVoxel (voxel) ->
			numEnum++
			p = voxel.position

			e1 = true if p.x == 1 and p.y == 0 and p.z == 0
			e2 = true if p.x == 0 and p.y == 1 and p.z == 0
			e3 = true if p.x == 0 and p.y == 0 and p.z == 1

		expect(numEnum).to.equal(3)
		expect(e1).to.equal(true)
		expect(e2).to.equal(true)
		expect(e3).to.equal(true)

	it 'should return the right voxel', ->
		grid = new Grid()

		grid.setVoxel {x: 1, y: 2, z: 3}, 'v1'

		v = grid.getVoxel 0, 0, 0
		expect(v).to.equal(undefined)

		v = grid.getVoxel 1, 2, 3
		expect(v.dataEntrys[0]).to.equal('v1')
