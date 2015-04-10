expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/pipeline/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'BrickGraph', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}

	grid = new Grid(baseBrick)
	grid.numVoxelsX = 5
	grid.numVoxelsY = 5
	grid.numVoxelsZ = 5
	for x in [0...grid.numVoxelsX]
		for y in [0...grid.numVoxelsY]
			for z in [0...grid.numVoxelsZ]
				grid.setVoxel {x: x, y: y, z: z}

	it 'should initialize with correct number of bricks', ->
		brickLayouter = new BrickLayouter()
		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph

		bricks = brickGraph.getAllBricks()
		numVoxels = grid.numVoxelsX * grid.numVoxelsY * grid.numVoxelsZ
		expect(bricks.size).to.equal(numVoxels)

	it 'should return correct number of bricks for a 1x1x1 grid', ->
		testGrid = new Grid()
		testGrid.numVoxelsX = 1
		testGrid.numVoxelsY = 1
		testGrid.numVoxelsZ = 1
		testGrid.setVoxel {x: 0, y: 0, z: 0}

		brickLayouter = new BrickLayouter()
		brickGraph = brickLayouter.initializeBrickGraph(testGrid).brickGraph

		expect(brickGraph.getAllBricks().size).to.equal(1)

