expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/pipeline/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'brickLayouter', ->
	it 'should initialize grid', ->
		brickLayouter = new BrickLayouter()
		expect(brickLayouter).not.to.be.null

		grid = new Grid()
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1

		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.getAllBricks()
		expect(bricks.size).to.equal(2)

	it 'should choose random brick', ->
		grid = new Grid()
		grid.numVoxelsX = 1
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}

		brickLayouter = new BrickLayouter()
		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph

		brick = brickLayouter._chooseRandomBrick(brickGraph.getAllBricks())
		position = brick.getPosition()
		expect(position.x).to.equal(0)
		expect(position.y).to.equal(0)
		expect(position.z).to.equal(0)
