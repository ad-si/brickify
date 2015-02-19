expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/Brick'
Grid = require '../../src/plugins/newBrickator/Grid'

describe 'brickLayouter split', ->
	it 'should split 1x1 brick & establish new neighbours and connections', ->
		# y = 1
		# x4x
		# 123
		# x0x

		# y = 0
		# xxx
		# x5x
		# xxx

		# y = 2
		# xxx
		# x6x
		# xxx

		brickLayouter = new BrickLayouter()
		brick0 = new Brick {x: 1, y: 1, z: 0}, {x: 1, y: 1, z: 1}
		brick1 = new Brick {x: 0, y: 1, z: 1}, {x: 1, y: 1, z: 1}
		brick2 = new Brick {x: 1, y: 1, z: 1}, {x: 1, y: 1, z: 1}
		brick3 = new Brick {x: 2, y: 1, z: 1}, {x: 1, y: 1, z: 1}
		brick4 = new Brick {x: 1, y: 1, z: 2}, {x: 1, y: 1, z: 1}
		brick5 = new Brick {x: 1, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick6 = new Brick {x: 1, y: 2, z: 1}, {x: 1, y: 1, z: 1}

		brick0.upperSlots = [[brick2]]
		brick2.upperSlots = [[brick4]]
		brick2.lowerSlots = [[brick0]]
		brick4.lowerSlots = [[brick2]]

		brick1.neighbours = [[], [brick2], [], []]
		brick2.neighbours = [[brick1], [brick3], [brick5], [brick6]]
		brick3.neighbours = [[brick2], [], [], []]
		brick5.neighbours = [[], [], [], [brick2]]
		brick6.neighbours = [[], [], [brick2], []]

		newBricks = brick2.split()
		newBrick = newBricks[0]
		expect(newBrick).to.not.equal(brick2)
		expect(newBrick.neighbours).to.eql([[brick1], [brick3], [brick5], [brick6]])
		expect(newBrick.upperSlots).to.eql([[brick4]])
		expect(newBrick.lowerSlots).to.eql([[brick0]])

	it 'should split bricks & establish new neighbours and connections', ->
		# 89AB    xxxx
		# 7777    2345
		# 4556    x01x
		# 0123    xxxx

		Brick.nextBrickIndex = 0

		brickLayouter = new BrickLayouter()
		brick0 = new Brick {x: 0, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick1 = new Brick {x: 1, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick2 = new Brick {x: 2, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick3 = new Brick {x: 3, y: 0, z: 0}, {x: 1, y: 1, z: 1}

		brick4 = new Brick {x: 0, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick5 = new Brick {x: 1, y: 0, z: 1}, {x: 2, y: 1, z: 1}
		brick6 = new Brick {x: 3, y: 0, z: 1}, {x: 1, y: 1, z: 1}

		brick7 = new Brick {x: 0, y: 0, z: 2}, {x: 4, y: 1, z: 1}

		brick8 = new Brick {x: 0, y: 0, z: 3}, {x: 1, y: 1, z: 1}
		brick9 = new Brick {x: 1, y: 0, z: 3}, {x: 1, y: 1, z: 1}
		brickA = new Brick {x: 2, y: 0, z: 3}, {x: 1, y: 1, z: 1}
		brickB = new Brick {x: 3, y: 0, z: 3}, {x: 1, y: 1, z: 1}

		brick0.neighbours = [[],[brick1],[],[]]
		brick0.upperSlots = [[brick4]]
		brick1.neighbours = [[brick0],[brick2],[],[]]
		brick1.upperSlots = [[brick5]]
		brick2.neighbours = [[brick1],[brick3],[],[]]
		brick2.upperSlots = [[brick5]]
		brick3.neighbours = [[brick2],[],[],[]]
		brick3.upperSlots = [[brick5]]

		brick4.neighbours = [[],[brick5],[],[]]
		brick4.upperSlots = [[brick7]]
		brick4.lowerSlots = [[brick0]]
		brick5.neighbours = [[brick4],[brick6],[],[]]
		brick5.upperSlots = [[brick7],[brick7]]
		brick5.lowerSlots = [[brick1],[brick2]]
		brick6.neighbours = [[brick5],[],[],[]]
		brick6.upperSlots = [[brick7]]
		brick6.lowerSlots = [[brick3]]

		brick7.neighbours = [[],[],[],[]]
		brick7.upperSlots = [[brick8],[brick9],[brickA],[brickB]]
		brick7.lowerSlots = [[brick4],[brick5],[brick5],[brick6]]

		brick8.neighbours = [[],[brick9],[],[]]
		brick8.lowerSlots = [[brick7]]
		brick9.neighbours = [[brick8],[brickA],[],[]]
		brick9.lowerSlots = [[brick7]]
		brickA.neighbours = [[brick9],[brickB],[],[]]
		brickA.lowerSlots = [[brick7]]
		brickB.neighbours = [[brickA],[],[],[]]
		brickB.lowerSlots = [[brick7]]

		layer0 = [brick0, brick1, brick2, brick3]
		layer1 = [brick4, brick5, brick6]
		layer2 = [brick7]
		layer3 = [brick8, brick9, brickA, brickB]
		bricks = [layer0, layer1, layer2, layer3]

		bricksToSplit = [brick5, brick7]

		newBricks = brickLayouter._splitBricks bricksToSplit, bricks

		expect(newBricks.length).to.equal(6)

		for newBrick in newBricks
			expect(newBrick.size).to.eql({x: 1, y: 1, z: 1})

		expect(newBricks[0].position).to.eql({x: 1, y: 0, z: 1})
		expect(newBricks[0].lowerSlots).to.eql([[brick1]])
		expect(brick1.upperSlots[0][0]).to.eql(newBricks[0])
		expect(newBricks[0].upperSlots[0][0]).to.eql(newBricks[3])

		expect(newBricks[1].position).to.eql({x: 2, y: 0, z: 1})
		expect(newBricks[1].lowerSlots).to.eql([[brick2]])
		expect(brick2.upperSlots[0][0]).to.eql(newBricks[1])
		expect(newBricks[1].upperSlots[0][0]).to.eql(newBricks[4])
		expect(newBricks[4].lowerSlots[0][0]).to.eql(newBricks[1])

		expect(newBricks[2].position).to.eql({x: 0, y: 0, z: 2})
		expect(newBricks[2].lowerSlots).to.eql([[brick4]])
		expect(brick4.upperSlots[0][0]).to.eql(newBricks[2])
		expect(newBricks[2].upperSlots[0][0]).to.eql(brick8)
		expect(brick8.lowerSlots[0][0]).to.eql(newBricks[2])

		console.log 'done checking connections, now checking neighbours'
		expect(newBricks[0].neighbours[0]).to.not.equal([])
		expect(newBricks[0].neighbours).to.eql([[brick4],[newBricks[1]],[],[]])
		expect(newBricks[1].neighbours).to.eql([[newBricks[0]],[brick6],[],[]])
		expect(newBricks[4].neighbours).to.
			eql([[newBricks[3]],[newBricks[5]],[],[]])

	it 'should split one brick and its neighbours', ->
		# 011122
		brickLayouter = new BrickLayouter()
		brick0 = new Brick  {x: 0, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick1 = new Brick  {x: 1, y: 0, z: 0}, {x: 3, y: 1, z: 1}
		brick2 = new Brick  {x: 2, y: 0, z: 0}, {x: 2, y: 1, z: 1}
		brick0.neighbours = [[], [brick1], [], []]
		brick1.neighbours = [[brick0], [brick2], [], []]
		brick2.neighbours = [[brick1], [], [], []]
		bricks = [[brick0, brick1, brick2]]
		bricksToSplit = brick1.uniqueNeighbours()
		bricksToSplit.push brick1
		newBricks = brickLayouter._splitBricks bricksToSplit, bricks
		expect(bricks[0]).to.eql(newBricks)
		console.log bricks[0]

	it 'should split one brick and relayout locally', () ->
		# 01222
		brickLayouter = new BrickLayouter()
		brick0 = new Brick  {x: 0, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick1 = new Brick  {x: 1, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick2 = new Brick  {x: 2, y: 0, z: 0}, {x: 3, y: 1, z: 1}
		bricks = [[brick0, brick1, brick2]]

		brick0.neighbours = [[], [brick1], [], []]
		brick1.neighbours = [[brick0], [brick2], [], []]
		brick2.neighbours = [[brick1], [], [], []]
		brickLayouter._splitBrickAndRelayoutLocally brick0, bricks
		console.log '----------------------------------------------------'
		console.log bricks[0]
