expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/pipeline/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'brickLayouter', ->
	it 'should initialize grid', ->
		brickLayouter = new BrickLayouter()
		expect(brickLayouter).not.to.be.null

		grid = new Grid()

		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}

		brickLayouter.initializeBrickGraph(grid)
		bricks = grid.getAllBricks()

		expect(bricks.size).to.equal(2)

	it 'should choose random brick', ->
		grid = new Grid()
		grid.setVoxel {x: 0, y: 0, z: 0}

		brickLayouter = new BrickLayouter()
		brickLayouter.initializeBrickGraph(grid)

		brick = brickLayouter._chooseRandomBrick(grid.getAllBricks())
		position = brick.getPosition()
		expect(position.x).to.equal(0)
		expect(position.y).to.equal(0)
		expect(position.z).to.equal(0)
