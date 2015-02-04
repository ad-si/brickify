expect = require('chai').expect
BrickLayouter = require '../../src/plugins/newBrickator/BrickLayouter'
Brick = require '../../src/plugins/newBrickator/Brick'
Grid = require '../../src/plugins/newBrickator/Grid'

describe 'brickLayouter optimize', ->
	baseBrick = {
		length: 8
		width: 8
		height: 3.2
	}

	it 'should find one biconnected component', (done) ->

		# 44
		# 23
		# 11

		brickLayouter = new BrickLayouter()
		brick1 = new Brick {x: 0, y: 0, z: 0}, {x: 1, y: 2, z: 1}
		brick2 = new Brick {x: 0, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick3 = new Brick {x: 0, y: 1, z: 1}, {x: 1, y: 1, z: 1}
		brick4 = new Brick {x: 0, y: 0, z: 2}, {x: 1, y: 2, z: 1}
		brick1.upperSlots = [[brick2], [brick3]]
		brick2.lowerSlots = [[brick1]]
		brick2.upperSlots = [[brick4]]
		brick3.lowerSlots = [[brick1]]
		brick3.upperSlots = [[brick4]]
		brick4.lowerSlots = [[brick2], [brick3]]
		bricks = [[brick1, brick2, brick3, brick4]]
		connectedComponents = brickLayouter._getBiconnectedComponents(bricks)
		expect(connectedComponents).to.have.length(1)
		done()

	it 'should find two biconnected components', (done) ->
		# 4488
		# 2367
		# 1155

		brickLayouter = new BrickLayouter()
		brick1 = new Brick {x: 0, y: 0, z: 0}, {x: 1, y: 2, z: 1}
		brick2 = new Brick {x: 0, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick3 = new Brick {x: 0, y: 1, z: 1}, {x: 1, y: 1, z: 1}
		brick4 = new Brick {x: 0, y: 0, z: 2}, {x: 1, y: 2, z: 1}
		brick1.upperSlots = [[brick2], [brick3]]
		brick2.lowerSlots = [[brick1]]
		brick2.upperSlots = [[brick4]]
		brick3.lowerSlots = [[brick1]]
		brick3.upperSlots = [[brick4]]
		brick4.lowerSlots = [[brick2], [brick3]]
		brick5 = new Brick {x: 1, y: 0, z: 0}, {x: 1, y: 2, z: 1}
		brick6 = new Brick {x: 1, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick7 = new Brick {x: 1, y: 1, z: 1}, {x: 1, y: 1, z: 1}
		brick8 = new Brick {x: 1, y: 0, z: 2}, {x: 1, y: 2, z: 1}
		brick5.upperSlots = [[brick6], [brick7]]
		brick6.lowerSlots = [[brick5]]
		brick6.upperSlots = [[brick8]]
		brick7.lowerSlots = [[brick5]]
		brick7.upperSlots = [[brick8]]
		brick8.lowerSlots = [[brick6], [brick7]]
		bricks = [[brick1, brick2, brick3, brick4, brick5, brick6, brick7, brick8]]
		connectedComponents = brickLayouter._getBiconnectedComponents(bricks)
		expect(connectedComponents).to.have.length(2)
		done()

	it 'should find one biconnected component', (done) ->
		# 45
		# 22
		# 13

		brickLayouter = new BrickLayouter()
		brick1 = new Brick {x: 0, y: 0, z: 0}, {x: 1, y: 1, z: 1}
		brick2 = new Brick {x: 0, y: 1, z: 1}, {x: 1, y: 2, z: 1}
		brick3 = new Brick {x: 0, y: 0, z: 1}, {x: 1, y: 1, z: 1}
		brick4 = new Brick {x: 0, y: 0, z: 2}, {x: 1, y: 1, z: 1}
		brick5 = new Brick {x: 0, y: 1, z: 0}, {x: 1, y: 1, z: 1}
		brick1.upperSlots = [[brick2]]
		brick2.lowerSlots = [[brick1], [brick3]]
		brick2.upperSlots = [[brick4], [brick5]]
		brick3.upperSlots = [[brick2]]
		brick4.lowerSlots = [[brick2]]
		brick5.lowerSlots = [[brick2]]
		bricks = [[brick1, brick2, brick3, brick4, brick5]]
		connectedComponents = brickLayouter._getBiconnectedComponents(bricks)
		expect(connectedComponents).to.have.length(1)
		done()
