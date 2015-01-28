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
		bricks = brickLayouter.initializeBrickGraph(grid)
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
		bricks = brickLayouter.initializeBrickGraph(grid)
		brick = brickLayouter.chooseRandomBrick(bricks)
		expect(brick.position.x).to.equal(0)
		expect(brick.position.y).to.equal(0)
		expect(brick.position.z).to.equal(0)
		done()

	it 'should find mergeable neighbor brick', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid)

		brick = bricks[0][0]
		mergeableNeighbors = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbors[0]).to.be.undefined
		expect(mergeableNeighbors[1][0]).to.not.be.null
		expect(mergeableNeighbors[2]).to.be.undefined
		expect(mergeableNeighbors[3]).to.be.undefined

		brick = bricks[0][1]
		mergeableNeighbors = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbors[0][0]).to.not.be.null
		expect(mergeableNeighbors[1]).to.be.undefined
		expect(mergeableNeighbors[2]).to.be.undefined
		expect(mergeableNeighbors[3]).to.be.undefined
		done()


	it 'should find mergeable neighbor bricks', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 4
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		grid.setVoxel {x: 2, y: 0, z: 0}
		grid.setVoxel {x: 3, y: 0, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid)

		brick = bricks[0][0]
		mergeableNeighbors = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbors[0]).to.be.undefined
		#expect(mergeableNeighbors[1]).to.have.length(3)
		expect(mergeableNeighbors[2]).to.be.undefined
		expect(mergeableNeighbors[3]).to.be.undefined
		done()
