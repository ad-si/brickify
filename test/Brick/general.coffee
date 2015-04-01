expect = require('chai').expect
BrickGraph = require '../../src/plugins/newBrickator/pipeline/BrickGraph'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'Brick', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}

	it 'should be completely removed', ->
		# create a brick layout
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 5
		grid.numVoxelsY = 5
		grid.numVoxelsZ = 5
		for x in [0...grid.numVoxelsX]
			for y in [0...grid.numVoxelsY]
				for z in [0...grid.numVoxelsZ]
					grid.setVoxel {x: x, y: y, z: z}

		brickGraph = new BrickGraph(grid)

		# chose a brick and delete it
		brickToBeDeleted = brickGraph.bricks[3][1]

		brickGraph.deleteBrick brickToBeDeleted

		# check that there are no references to this brick anymore
		refs = 0
		for layer in brickGraph.bricks
			for brick in layer
				if brick == brickToBeDeleted
					refs++

				connectedBricks = brick.uniqueConnectedBricks()
				if connectedBricks.indexOf(brickToBeDeleted) >= 0
					console.log 'brick is in connectedBricks'
					refs++

				for neighborList in brick.neighbors
					for neighbor in neighborList
						if neighbor == brickToBeDeleted
							refs++

		expect(refs).to.equal(0)


