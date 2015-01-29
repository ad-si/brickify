expect = require('chai').expect
BrickLayouter = require '../src/plugins/newBrickator/BrickLayouter'
Grid = require '../src/plugins/newBrickator/Grid'

describe 'brickLayouter', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}

	it 'should initialize', (done) ->
		brickLayouter = new BrickLayouter()
		expect(brickLayouter).not.to.be.null

		grid = new Grid(baseBrick)
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		bricks = brickLayouter.initializeBrickGraph(grid).bricks
		expect(bricks[0]).to.have.length(2)
		done()

	it 'should choose random brick', (done) ->
		#this.timeout(10)
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 1
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).bricks
		brick = brickLayouter.chooseRandomBrick(bricks)
		expect(brick.position.x).to.equal(0)
		expect(brick.position.y).to.equal(0)
		expect(brick.position.z).to.equal(0)
		done()

	it 'should find mergeable neighbour brick xp and xm', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).bricks

		brick = bricks[0][0]
		mergeableNeighbours = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbours[1][0]).to.equal(bricks[0][1])

		brick = bricks[0][1]
		mergeableNeighbours = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbours[0][0]).to.equal(bricks[0][0])
		done()

	it 'should find mergeable neighbour brick yp and ym', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 0, y: 1, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).bricks

		brick = bricks[0][0]
		mergeableNeighbours = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbours[3][0]).to.equal(bricks[0][1])

		brick = bricks[0][1]
		mergeableNeighbours = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbours[2][0]).to.equal(bricks[0][0])
		done()


	it 'should find mergeable neighbour bricks in all directions', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 3
		grid.numVoxelsY = 3
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 1, y: 1, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 2, z: 0}
		grid.setVoxel {x: 0, y: 1, z: 0}
		grid.setVoxel {x: 2, y: 1, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).bricks

		brick = bricks[0][2]
		mergeableNeighbours = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbours[0][0]).to.equal(bricks[0][0])
		expect(mergeableNeighbours[1][0]).to.equal(bricks[0][4])
		expect(mergeableNeighbours[2][0]).to.equal(bricks[0][1])
		expect(mergeableNeighbours[3][0]).to.equal(bricks[0][3])
		done()

	it 'should choose the better brick 10 out of 10 times', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 3
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 2
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		grid.setVoxel {x: 2, y: 0, z: 0}
		grid.setVoxel {x: 2, y: 0, z: 1}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).bricks

		brick = bricks[0][1]
		for num in [1..10]
			mergeableNeighbours = brickLayouter.findMergeableNeighbours brick, bricks
			mergeDirection = brickLayouter.chooseNeighboursToMergeWith brick,
				mergeableNeighbours
			expect(mergeableNeighbours[mergeDirection][0]).to.equal(bricks[0][2])
		done()
