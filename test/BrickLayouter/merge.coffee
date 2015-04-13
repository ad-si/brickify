expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/pipeline/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'brickLayouter merge', ->
	it 'should find mergeable neighbor brick xp and xm', ->
		grid = new Grid()
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 1, y: 0, z: 0}
		brickLayouter = new BrickLayouter()

		brickLayouter.initializeBrickGraph(grid)
		bricks = grid.getAllBricks()

		mergeableNeighbors = brickLayouter._findMergeableNeighbors v0.brick
		mergeableNeighborsXp = mergeableNeighbors[1]
		expect(mergeableNeighborsXp.has(v1.brick)).to.equal(true)

		mergeableNeighbors = brickLayouter._findMergeableNeighbors v1.brick
		mergeableNeighborsXm = mergeableNeighbors[0]
		expect(mergeableNeighborsXm.has(v0.brick)).to.equal(true)

	it 'should find mergeable neighbor brick yp and ym', ->
		grid = new Grid()
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 0, y: 1, z: 0}
		brickLayouter = new BrickLayouter()

		brickLayouter.initializeBrickGraph(grid)

		mergeableNeighbors = brickLayouter._findMergeableNeighbors v0.brick
		mergeableNeighborsYp = mergeableNeighbors[3]
		expect(mergeableNeighborsYp.has(v1.brick)).to.equal(true)

		mergeableNeighbors = brickLayouter._findMergeableNeighbors v1.brick
		mergeableNeighborsYm = mergeableNeighbors[2]
		expect(mergeableNeighborsYm.has(v0.brick)).to.equal(true)

	it 'should choose the better brick 10 out of 10 times', ->
		grid = new Grid()
		grid.numVoxelsX = 3
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 2
		grid.setVoxel {x: 0, y: 0, z: 0}
		v0 = grid.setVoxel {x: 1, y: 0, z: 0}
		v1 = grid.setVoxel {x: 2, y: 0, z: 0}
		grid.setVoxel {x: 2, y: 0, z: 1}

		brickLayouter = new BrickLayouter()
		brickLayouter.initializeBrickGraph(grid)
		brick = v0.brick

		for num in [1..10]
			mergeableNeighbors = brickLayouter._findMergeableNeighbors brick
			mergeDirection =
				brickLayouter._chooseNeighborsToMergeWith mergeableNeighbors

			expect(mergeableNeighbors[mergeDirection].has(v1.brick)).to.equal(true)

	it 'should not merge a single voxel', ->
		grid = new Grid()
		grid.numVoxelsX = 10
		grid.numVoxelsY = 10
		grid.numVoxelsZ = 1
		v0 = grid.setVoxel {x: 5, y: 5, z: 0}
		brickLayouter = new BrickLayouter()

		brickLayouter.initializeBrickGraph(grid)
		brickLayouter.layoutByGreedyMerge(grid)

		expect(v0.brick.getPosition()).to.eql({x: 5, y: 5, z: 0})
		expect(v0.brick.getSize()).to.eql({x: 1, y: 1, z: 1})

	it 'should merge two bricks 2x1', ->
		grid = new Grid()
		grid.numVoxelsX = 10
		grid.numVoxelsY = 10
		grid.numVoxelsZ = 1
		v0 = grid.setVoxel {x: 5, y: 5, z: 0}
		v1 = grid.setVoxel {x: 5, y: 6, z: 0}
		brickLayouter = new BrickLayouter()

		brickLayouter.initializeBrickGraph(grid)
		brickLayouter.layoutByGreedyMerge(grid)

		expect(grid.getAllBricks().size).to.equal(1)
		expect(v0.brick).to.equal(v1.brick)
		expect(v0.brick.getPosition()).to.eql({x: 5, y: 5, z: 0})
		expect(v0.brick.getSize()).to.eql({x: 1, y: 2, z: 1})

	it 'should merge four bricks', ->
		grid = new Grid()
		grid.numVoxelsX = 10
		grid.numVoxelsY = 10
		grid.numVoxelsZ = 1
		v0 = grid.setVoxel {x: 5, y: 5, z: 0}
		v1 = grid.setVoxel {x: 5, y: 6, z: 0}
		v2 = grid.setVoxel {x: 6, y: 5, z: 0}
		v3 = grid.setVoxel {x: 6, y: 6, z: 0}

		brickLayouter = new BrickLayouter()
		brickLayouter.initializeBrickGraph(grid)
		brickLayouter.layoutByGreedyMerge(grid)

		expect(grid.getAllBricks().size).to.equals(1)
		expect(v0.brick.getPosition()).to.eql({x: 5, y: 5, z: 0})
		expect(v0.brick.getSize()).to.eql({x: 2, y: 2, z: 1})
