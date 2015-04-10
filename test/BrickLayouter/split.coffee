expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/pipeline/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
BrickGraph = require '../../src/plugins/newBrickator/pipeline/BrickGraph'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'brickLayouter split', ->
	it 'should split one brick and relayout locally', ->
		brickLayouter = new BrickLayouter(true)
		grid = new Grid()
		grid.numVoxelsX = 3
		grid.numVoxelsY = 3
		grid.numVoxelsZ = 1

		v0 = grid.setVoxel { x: 0, y: 0, z: 0 }
		v1 = grid.setVoxel { x: 1, y: 0, z: 0 }
		v2 = grid.setVoxel { x: 0, y: 1, z: 0 }
		v3 = grid.setVoxel { x: 1, y: 1, z: 0 }
		v4 = grid.setVoxel { x: 1, y: 2, z: 0 }
		brickGraph = new BrickGraph(grid)

		# merge bricks to one single (invalid) brick
		v0.brick.mergeWith v1.brick
		v0.brick.mergeWith v2.brick
		v0.brick.mergeWith v3.brick
		v0.brick.mergeWith v4.brick

		#split it up and relayout
		brickLayouter.splitBricksAndRelayoutLocally [v0.brick], grid, brickGraph

		#expect to be more than 1 brick
		bricks = brickGraph.getAllBricks()
		expect(bricks.size > 1).to.equal(true)

