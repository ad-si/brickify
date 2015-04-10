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
