expect = require('chai').expect
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'
BrickLayouter = require '../../src/plugins/newBrickator/pipeline/BrickLayouter'

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

		grid.setVoxel {x: 1, y: 2, z: 3}

		v = grid.getVoxel 0, 0, 0
		expect(v).to.equal(undefined)

		v = grid.getVoxel 1, 2, 3
		expect(v).not.to.be.null

	it 'should link voxels correctly', ->
		grid = new Grid()

		c = grid.setVoxel {x: 1, y: 1, z: 1}
		xp = grid.setVoxel {x: 2, y: 1, z: 1}
		xm = grid.setVoxel {x: 0, y: 1, z: 1}
		yp = grid.setVoxel {x: 1, y: 2, z: 1}
		ym = grid.setVoxel {x: 1, y: 0, z: 1}
		zp = grid.setVoxel {x: 1, y: 1, z: 2}
		zm = grid.setVoxel {x: 1, y: 1, z: 0}

		expect(c.neighbors.Xp).to.equal(xp)
		expect(c.neighbors.Xm).to.equal(xm)
		expect(c.neighbors.Yp).to.equal(yp)
		expect(c.neighbors.Ym).to.equal(ym)
		expect(c.neighbors.Zp).to.equal(zp)
		expect(c.neighbors.Zm).to.equal(zm)

		expect(xp.neighbors.Xm).to.equal(c)
		expect(xm.neighbors.Xp).to.equal(c)
		expect(yp.neighbors.Ym).to.equal(c)
		expect(ym.neighbors.Yp).to.equal(c)
		expect(zp.neighbors.Zm).to.equal(c)
		expect(zm.neighbors.Zp).to.equal(c)

	it 'should initialize correct number of bricks', ->
		grid = new Grid()
		numVoxelsX = 5
		numVoxelsY = 4
		numVoxelsZ = 6

		for x in [0...numVoxelsX]
			for y in [0...numVoxelsY]
				for z in [0...numVoxelsZ]
					grid.setVoxel { x: x, y: y, z: z }

		brickLayouter = new BrickLayouter()
		brickLayouter.initializeBrickGraph(grid)

		bricks = grid.getAllBricks()
		numVoxels = numVoxelsX * numVoxelsY * numVoxelsZ
		expect(bricks.size).to.equal(numVoxels)

	it 'should return correct number of bricks for a 1x1x1 configuration', ->
		testGrid = new Grid()
		testGrid.setVoxel {x: 0, y: 0, z: 0}

		brickLayouter = new BrickLayouter()
		brickLayouter.initializeBrickGraph(testGrid)

		expect(testGrid.getAllBricks().size).to.equal(1)
