expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/pipeline/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'brickLayouter merge', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}

	it 'should find mergeable neighbour brick xp and xm', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.bricks

		brick = bricks[0][0]
		mergeableNeighbours = brickLayouter._findMergeableNeighbours brick
		expect(mergeableNeighbours[1][0]).to.equal(bricks[0][1])

		brick = bricks[0][1]
		mergeableNeighbours = brickLayouter._findMergeableNeighbours brick
		expect(mergeableNeighbours[0][0]).to.equal(bricks[0][0])
		done()

	it 'should find mergeable neighbour brick yp and ym', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 2
		grid.numVoxelsY = 2
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 0, y: 1, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.bricks

		brick = bricks[0][0]
		mergeableNeighbours = brickLayouter._findMergeableNeighbours brick
		expect(mergeableNeighbours[3][0]).to.equal(bricks[0][1])

		brick = bricks[0][1]
		mergeableNeighbours = brickLayouter._findMergeableNeighbours brick
		expect(mergeableNeighbours[2][0]).to.equal(bricks[0][0])
		done()

	it 'should find mergeable neighbour bricks in all directions', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 3
		grid.numVoxelsY = 3
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 1, y: 1, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 2, z: 0}
		grid.setVoxel {x: 0, y: 1, z: 0}
		grid.setVoxel {x: 2, y: 1, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.bricks

		brick = bricks[0][2]
		mergeableNeighbours = brickLayouter._findMergeableNeighbours brick
		expect(mergeableNeighbours[0][0]).to.equal(bricks[0][0])
		expect(mergeableNeighbours[1][0]).to.equal(bricks[0][4])
		expect(mergeableNeighbours[2][0]).to.equal(bricks[0][1])
		expect(mergeableNeighbours[3][0]).to.equal(bricks[0][3])
		done()

	it 'should make the right brick connections', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 1
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 0, y: 0, z: 0}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.bricks
		connectedBricks = bricks[0][0].uniqueConnectedBricks()
		expect(connectedBricks).to.have.length(0)

		grid = new Grid(baseBrick)
		grid.numVoxelsX = 1
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 2
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 0, y: 0, z: 1}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.bricks
		connectedBricks = bricks[0][0].uniqueConnectedBricks()
		expect(connectedBricks).to.have.length(1)

		grid = new Grid(baseBrick)
		grid.numVoxelsX = 1
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 3
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 0, y: 0, z: 1}
		grid.setVoxel {x: 0, y: 0, z: 2}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.bricks
		connectedBricks = bricks[1][0].uniqueConnectedBricks()
		expect(connectedBricks).to.have.length(2)
		done()

	it 'should choose the better brick 10 out of 10 times', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 3
		grid.numVoxelsY = 1
		grid.numVoxelsZ = 2
		grid.setVoxel {x: 0, y: 0, z: 0}
		grid.setVoxel {x: 1, y: 0, z: 0}
		grid.setVoxel {x: 2, y: 0, z: 0}
		grid.setVoxel {x: 2, y: 0, z: 1}
		brickLayouter = new BrickLayouter()
		bricks = brickLayouter.initializeBrickGraph(grid).brickGraph.bricks

		brick = bricks[0][1]
		for num in [1..10]
			mergeableNeighbours = brickLayouter._findMergeableNeighbours brick
			mergeDirection =
				brickLayouter._chooseNeighboursToMergeWith mergeableNeighbours
			expect(mergeableNeighbours[mergeDirection][0]).to.equal(bricks[0][2])
		done()

	it 'should produce correct brick after merge', (done) ->
		brickLayouter = new BrickLayouter()
		brick1 = new Brick({x: 0, y: 0, z: 0},{x: 1, y: 1, z: 1})
		brick2 = new Brick({x: 1, y: 0, z: 0},{x: 1, y: 1, z: 1})
		brick3 = new Brick({x: 0, y: 1, z: 0},{x: 1, y: 1, z: 1})
		brick1.neighbours[0] = []
		brick1.neighbours[1] = [brick2]
		brick1.neighbours[2] = []
		brick1.neighbours[3] = [brick3]
		brick2.neighbours[0] = [brick1]
		brick2.neighbours[1] = []
		brick2.neighbours[2] = []
		brick2.neighbours[3] = []
		brick3.neighbours[0] = []
		brick3.neighbours[1] = []
		brick3.neighbours[2] = [brick1]
		brick3.neighbours[3] = []
		bricks = [[brick1, brick2, brick3]]

		newBrick = brickLayouter._mergeBricksAndUpdateGraphConnections(
			brick2
			[[brick1], [], [], []]
			0
			{bricks: bricks}
		)
		expect(newBrick.position).to.eql({x: 0, y: 0, z: 0})
		expect(newBrick.size).to.eql({x: 2, y: 1, z: 1})
		expect(bricks).to.eql([[brick3, newBrick]])
		expect(newBrick.neighbours[3]).to.eql([brick3])
		expect(brick3.neighbours[2]).to.eql([newBrick])

		brick1.neighbours[0] = []
		brick1.neighbours[1] = [brick2]
		brick1.neighbours[2] = []
		brick1.neighbours[3] = [brick3]
		brick2.neighbours[0] = [brick1]
		brick2.neighbours[1] = []
		brick2.neighbours[2] = []
		brick2.neighbours[3] = []
		brick3.neighbours[0] = []
		brick3.neighbours[1] = []
		brick3.neighbours[2] = [brick1]
		brick3.neighbours[3] = []
		bricks = [[brick1, brick2, brick3]]
		newBrick = brickLayouter._mergeBricksAndUpdateGraphConnections(
			brick1
			[[], [brick2], [], []]
			1
			{bricks: bricks}
		)
		expect(newBrick.position).to.eql({x: 0, y: 0, z: 0})
		expect(newBrick.size).to.eql({x: 2, y: 1, z: 1})
		expect(bricks).to.eql([[brick3, newBrick]])
		expect(newBrick.neighbours[3]).to.eql([brick3])
		expect(brick3.neighbours[2]).to.eql([newBrick])

		brick1.neighbours[0] = []
		brick1.neighbours[1] = [brick2]
		brick1.neighbours[2] = []
		brick1.neighbours[3] = [brick3]
		brick2.neighbours[0] = [brick1]
		brick2.neighbours[1] = []
		brick2.neighbours[2] = []
		brick2.neighbours[3] = []
		brick3.neighbours[0] = []
		brick3.neighbours[1] = []
		brick3.neighbours[2] = [brick1]
		brick3.neighbours[3] = []
		bricks = [[brick1, brick2, brick3]]
		newBrick = brickLayouter._mergeBricksAndUpdateGraphConnections(
			brick3
			[[], [], [brick1], []]
			2
			{bricks: bricks}
		)
		expect(newBrick.position).to.eql({x: 0, y: 0, z: 0})
		expect(newBrick.size).to.eql({x: 1, y: 2, z: 1})
		expect(bricks).to.eql([[brick2, newBrick]])
		expect(newBrick.neighbours[1]).to.eql([brick2])
		expect(brick2.neighbours[0]).to.eql([newBrick])

		brick1.neighbours[0] = []
		brick1.neighbours[1] = [brick2]
		brick1.neighbours[2] = []
		brick1.neighbours[3] = [brick3]
		brick2.neighbours[0] = [brick1]
		brick2.neighbours[1] = []
		brick2.neighbours[2] = []
		brick2.neighbours[3] = []
		brick3.neighbours[0] = []
		brick3.neighbours[1] = []
		brick3.neighbours[2] = [brick1]
		brick3.neighbours[3] = []
		bricks = [[brick1, brick2, brick3]]
		newBrick = brickLayouter._mergeBricksAndUpdateGraphConnections(
			brick1
			[[], [], [], [brick3]]
			3
			{bricks: bricks}
		)
		expect(newBrick.position).to.eql({x: 0, y: 0, z: 0})
		expect(newBrick.size).to.eql({x: 1, y: 2, z: 1})
		expect(bricks).to.eql([[brick2, newBrick]])
		expect(newBrick.neighbours[1]).to.eql([brick2])
		expect(brick2.neighbours[0]).to.eql([newBrick])

		done()

	it 'should not merge a single voxel', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 10
		grid.numVoxelsY = 10
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 5, y: 5, z: 0}
		brickLayouter = new BrickLayouter()

		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph
		brickLayouter.layoutByGreedyMerge(brickGraph)
	
		expect(brickGraph.bricks[0][0].position).to.eql({x: 5, y: 5, z: 0})
		expect(brickGraph.bricks[0][0].size).to.eql({x: 1, y: 1, z: 1})
		done()

	it 'should merge two bricks 2x1', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 10
		grid.numVoxelsY = 10
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 5, y: 5, z: 0}
		grid.setVoxel {x: 5, y: 6, z: 0}
		brickLayouter = new BrickLayouter()
		
		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph
		brickLayouter.layoutByGreedyMerge(brickGraph).brickGraph

		expect(brickGraph.bricks[0]).to.have.length(1)
		expect(brickGraph.bricks[0][0].position).to.eql({x: 5, y: 5, z: 0})
		expect(brickGraph.bricks[0][0].size).to.eql({x: 1, y: 2, z: 1})
		done()

	it 'should merge four bricks', (done) ->
		grid = new Grid(baseBrick)
		grid.numVoxelsX = 10
		grid.numVoxelsY = 10
		grid.numVoxelsZ = 1
		grid.setVoxel {x: 5, y: 5, z: 0}
		grid.setVoxel {x: 5, y: 6, z: 0}
		grid.setVoxel {x: 6, y: 5, z: 0}
		grid.setVoxel {x: 6, y: 6, z: 0}

		brickLayouter = new BrickLayouter()
		brickGraph = brickLayouter.initializeBrickGraph(grid).brickGraph
		brickLayouter.layoutByGreedyMerge(brickGraph)
		
		expect(brickGraph.bricks[0]).to.have.length(1)
		expect(brickGraph.bricks[0][0].position).to.eql({x: 5, y: 5, z: 0})
		expect(brickGraph.bricks[0][0].size).to.eql({x: 2, y: 2, z: 1})
		done()

	it 'should have correct upperSlots/lowerSlots after merge', (done) ->
		brickLayouter = new BrickLayouter()
		Brick.nextBrickIndex = 0
		brick1 = new Brick {x: 0, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick2 = new Brick {x: 0, y: 1, z: 1}, {x: 1, y: 1, z: 1}
		brick3 = new Brick {x: 0, y: 0, z: 2}, {x: 1, y: 2, z: 1}
		brick4 = new Brick {x: 0, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick5 = new Brick {x: 0, y: 1, z: 0}, {x: 1, y: 1, z: 1}

		brick1.neighbours[3].push brick2
		brick2.neighbours[2].push brick1

		brick4.neighbours[3].push brick5
		brick5.neighbours[2].push brick4

		brick4.upperSlots[0][0] = brick1
		brick1.lowerSlots[0][0] = brick4

		brick5.upperSlots[0][0] = brick2
		brick2.lowerSlots[0][0] = brick5

		brick1.upperSlots[0][0] = brick3
		brick2.upperSlots[0][0] = brick3
		brick3.lowerSlots[0][0] = brick1
		brick3.lowerSlots[0][1] = brick2

		bricks = [[brick4, brick5],[brick1, brick2],[brick3]]

		newBrick = brickLayouter._mergeBricksAndUpdateGraphConnections(
			brick1
			brick1.neighbours
			3
			{bricks: bricks}
		)

		expect(newBrick.position).to.eql({x: 0, y: 0, z: 1})
		expect(newBrick.size).to.eql({x: 1, y: 2, z: 1})
		expect(newBrick.id).to.equal(5)
		expect(newBrick.upperSlots[0][0].id).to.equal(brick3.id)
		expect(newBrick.upperSlots[0][1].id).to.equal(brick3.id)
		expect(newBrick.lowerSlots[0][0].id).to.equal(brick4.id)
		expect(newBrick.lowerSlots[0][1].id).to.equal(brick5.id)

		expect(brick5.upperSlots[0][0].id).to.equal(newBrick.id)
		expect(brick4.upperSlots[0][0].id).to.equal(newBrick.id)
		expect(brick3.lowerSlots[0][0].id).to.equal(newBrick.id)
		expect(brick3.lowerSlots[0][1].id).to.equal(newBrick.id)
		done()

	###
	it 'should not merge 1x4 & 1x2, even with duplicate neighbours', (done) ->

			#22
			#1111

		brickLayouter = new BrickLayouter()
		Brick.nextBrickIndex = 0
		brick1 = new Brick {x: 0, y: 0, z: 0}, {x: 4, y: 1, z: 1}
		brick2 = new Brick {x: 0, y: 1, z: 0}, {x: 2, y: 1, z: 1}
		brick1.neighbours[3] = [brick2, brick2] # duplicate neighbour here
		brick2.neighbours[2] = [brick1]
		bricks = [[brick1, brick2]]
		console.log bricks
		bricksObject = brickLayouter.layoutByGreedyMerge(bricks)
		console.log bricks
		expect(bricksObject.bricks[0]).to.have.length(2)
		expect(bricksObject.bricks[0][0].id).to.eql(0)
		expect(bricksObject.bricks[0][0].size).to.eql({x: 4, y: 1, z: 1})
		expect(bricksObject.bricks[0][1].id).to.eql(1)
		expect(bricksObject.bricks[0][1].size).to.eql({x: 2, y: 1, z: 1})


		done()

	###
