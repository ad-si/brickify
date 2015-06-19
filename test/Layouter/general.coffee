expect = require('chai').expect
Common = require '../../src/plugins/newBrickator/pipeline/LayouterCommon'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'Layouter', ->
	it 'should choose random brick', ->
		grid = new Grid()
		grid.setVoxel {x: 0, y: 0, z: 0}

		grid.initializeBricks()

		brick = Common.chooseRandomBrick(grid.getAllBricks())
		position = brick.getPosition()
		expect(position.x).to.equal(0)
		expect(position.y).to.equal(0)
		expect(position.z).to.equal(0)
