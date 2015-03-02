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

	it 'should initialize with correct number of bricks', () ->
		brickLayouter = new BrickLayouter()
		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph

		bricks = brickGraph.bricks
		expect(bricks.length).to.equal(grid.numVoxelsZ)
		for zLayer in bricks
			expect(zLayer.length).to.equal(grid.numVoxelsX * grid.numVoxelsY)

	it 'should initialize correct number of neighbours', () ->
		brickLayouter = new BrickLayouter()
		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph

		bricks = brickGraph.bricks
		
		for zLayer in bricks
			for brick in zLayer
				expectedNeighbours = 0
				if brick.position.x > 0
					expectedNeighbours++
				if brick.position.x < grid.numVoxelsX - 1
					expectedNeighbours++
				if brick.position.y > 0
					expectedNeighbours++
				if brick.position.y < grid.numVoxelsY - 1
					expectedNeighbours++

				actualNeighbours = brick.uniqueNeighbours().length
				expect(actualNeighbours).to.equal(expectedNeighbours)

	it 'should initialize correct references to neighbours', () ->
		brickLayouter = new BrickLayouter()
		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph

		bricks = brickGraph.bricks
		
		for zLayer in bricks
			for brick in zLayer

				if brick.position.x > 0
					n = brick.neighbours[Brick.direction.Xm][0]
					expect(n.position.x).to.equal(brick.position.x - 1)
					expect(n.position.y).to.equal(brick.position.y)
					expect(n.position.z).to.equal(brick.position.z)
				if brick.position.x < grid.numVoxelsX - 1
					n = brick.neighbours[Brick.direction.Xp][0]
					expect(n.position.x).to.equal(brick.position.x + 1)
					expect(n.position.y).to.equal(brick.position.y)
					expect(n.position.z).to.equal(brick.position.z)
				if brick.position.y > 0
					n = brick.neighbours[Brick.direction.Ym][0]
					expect(n.position.x).to.equal(brick.position.x)
					expect(n.position.y).to.equal(brick.position.y - 1)
					expect(n.position.z).to.equal(brick.position.z)
				if brick.position.y < grid.numVoxelsY - 1
					n = brick.neighbours[Brick.direction.Yp][0]
					expect(n.position.x).to.equal(brick.position.x)
					expect(n.position.y).to.equal(brick.position.y + 1)
					expect(n.position.z).to.equal(brick.position.z)





