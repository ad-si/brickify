expect = require('chai').expect
PlateLayouter =
	require '../../src/plugins/newBrickator/pipeline/Layout/PlateLayouter'
LayoutOptimizer =
	require '../../src/plugins/newBrickator/pipeline/Layout/LayoutOptimizer'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'brickLayouter split', ->
	it 'should split one brick and relayout locally', ->
		plateLayouter = new PlateLayouter(true)
		layoutOptimizer = new LayoutOptimizer(null, plateLayouter)
		grid = new Grid()

		v0 = grid.setVoxel { x: 0, y: 0, z: 0 }
		v1 = grid.setVoxel { x: 1, y: 0, z: 0 }
		v2 = grid.setVoxel { x: 0, y: 1, z: 0 }
		v3 = grid.setVoxel { x: 1, y: 1, z: 0 }
		v4 = grid.setVoxel { x: 1, y: 2, z: 0 }

		grid.initializeBricks()

		# merge bricks to one single (invalid) brick
		v0.brick.mergeWith v1.brick
		v0.brick.mergeWith v2.brick
		v0.brick.mergeWith v3.brick
		v0.brick.mergeWith v4.brick

		#split it up and relayout
		layoutOptimizer.splitBricksAndRelayoutLocally [v0.brick], grid, true, false

		#expect to be more than 1 brick
		bricks = grid.getAllBricks()
		expect(bricks.size > 1).to.equal(true)

