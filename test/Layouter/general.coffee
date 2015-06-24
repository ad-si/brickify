expect = require('chai').expect
Layouter = require '../../src/plugins/newBrickator/pipeline/Layout/Layouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'Layouter', ->
	it 'should choose random brick', ->
		grid = new Grid()
		layouter = new Layouter()
		grid.setVoxel {x: 0, y: 0, z: 0}

		grid.initializeBricks()

		brick = layouter.chooseRandomBrick(grid.getAllBricks())
		position = brick.getPosition()
		expect(position.x).to.equal(0)
		expect(position.y).to.equal(0)
		expect(position.z).to.equal(0)
