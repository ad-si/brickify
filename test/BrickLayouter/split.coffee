expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/Brick'
Grid = require '../../src/plugins/newBrickator/Grid'

describe 'brickLayouter split', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}

	###
	it 'should split bricks & establish new neighbours and connections', (done) ->
		# 89AB
		# 7777
		# 4556
		# 0123

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
		brick1.neigbours = [[brick0],[brick2],[],[]]
		brick1.upperSlots = [[brick5]]
		brick2.neigbours = [[brick1],[brick3],[],[]]
		brick2.upperSlots = [[brick5]]
		brick3.neigbours = [[brick2],[],[],[]]
		brick3.upperSlots = [[brick5]]

		brick4.neigbours = [[],[brick5],[],[]]
		brick4.upperSlots = [[brick7]]
		brick4.lowerSlots = [[brick0]]
		brick5.neigbours = [[brick4],[brick6],[],[]]
		brick5.upperSlots = [[brick7],[brick7]]
		brick5.lowerSlots = [[brick1],[brick2]]
		brick6.neigbours = [[brick5],[],[],[]]
		brick6.upperSlots = [[brick7]]
		brick6.lowerSlots = [[brick3]]

		brick7.neigbours = [[],[],[],[]]
		brick7.upperSlots = [[brick8],[brick9],[brickA],[brickB]]
		brick7.lowerSlots = [[brick4],[brick5],[brick5],[brick6]]

		brick8.neighbours = [[],[brick9],[],[]]
		brick8.lowerSlots = [[brick7]]
		brick9.neigbours = [[brick8],[brickA],[],[]]
		brick9.lowerSlots = [[brick7]]
		brickA.neigbours = [[brick9],[brickB],[],[]]
		brickA.lowerSlots = [[brick7]]
		brickB.neigbours = [[brickA],[],[],[]]
		brickB.lowerSlots = [[brick7]]

		layer0 = [brick0, brick1, brick2, brick3]
		layer1 = [brick4, brick5, brick6]
		layer2 = [brick7]
		layer3 = [brick8, brick9, brickA, brickB]
		bricks = [layer0, layer1, layer2, layer3]

		bricksToSplit = [brick5, brick7]

		newBricks = brickLayouter._splitBricks bricksToSplit bricks

		for newBrick in newBricks
			expect(newBrick.size).to.eql({x: 1, y: 1, z: 1})

		# check correct neighbours
		# check correct connections

		done()

	###
