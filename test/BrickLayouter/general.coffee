expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/Brick'
Grid = require '../../src/plugins/newBrickator/Grid'

describe 'brickLayouter', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}

	it 'should initialize grid', (done) ->
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
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 1
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).bricks
		brick = brickLayouter._chooseRandomBrick(bricks)
		expect(brick.position.x).to.equal(0)
		expect(brick.position.y).to.equal(0)
		expect(brick.position.z).to.equal(0)
		done()


