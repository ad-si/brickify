expect = require('chai').expect
BrickLayouter = require '../src/plugins/newBrickator/BrickLayouter'
Grid = require '../src/plugins/newBrickator/Grid'

describe 'brickLayouter', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}
	brickLayouter = null
	bricks = null

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
		expect(bricks[0].length).to.equal(2)
		done()

	it 'should choose random brick', (done) ->
		brick = brickLayouter.chooseRandomBrick(bricks)
		console.log brick.position
		expect(brick.position.y).to.equal(0)
		expect(brick.position.z).to.equal(0)
		done()

	it 'should find mergeable neighbor brick', (done) ->
		brick = brickLayouter.chooseRandomBrick(bricks)
		mergeableNeighbors = brickLayouter.findMergeableNeighbours brick, bricks
		expect(mergeableNeighbors).not.to.be.empty
		done()
