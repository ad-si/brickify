expect = require('chai').expect
PlateLayouter = require '../../src/plugins/newBrickator/pipeline/PlateLayouter'
Brick = require '../../src/plugins/newBrickator/pipeline/Brick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'brickLayouter merge', ->
	it 'should find mergeable neighbor brick xp and xm', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 1, y: 0, z: 0}

		plateLayouter = new PlateLayouter()
		grid.initializeBricks()
		bricks = grid.getAllBricks()

		mergeableNeighbors = plateLayouter._findMergeableNeighbors v0.brick
		mergeableNeighborsXp = mergeableNeighbors[3]
		expect(mergeableNeighborsXp.has(v1.brick)).to.equal(true)

		mergeableNeighbors = plateLayouter._findMergeableNeighbors v1.brick
		mergeableNeighborsXm = mergeableNeighbors[2]
		expect(mergeableNeighborsXm.has(v0.brick)).to.equal(true)

	it 'should find mergeable neighbor brick yp and ym', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 0, y: 1, z: 0}

		plateLayouter = new PlateLayouter()
		grid.initializeBricks()

		mergeableNeighbors = plateLayouter._findMergeableNeighbors v0.brick
		mergeableNeighborsYp = mergeableNeighbors[0]
		expect(mergeableNeighborsYp.has(v1.brick)).to.equal(true)

		mergeableNeighbors = plateLayouter._findMergeableNeighbors v1.brick
		mergeableNeighborsYm = mergeableNeighbors[1]
		expect(mergeableNeighborsYm.has(v0.brick)).to.equal(true)

	it 'should choose the better brick 10 out of 10 times', ->
		grid = new Grid()
		grid.setVoxel {x: 0, y: 0, z: 0}
		v0 = grid.setVoxel {x: 1, y: 0, z: 0}
		v1 = grid.setVoxel {x: 2, y: 0, z: 0}
		grid.setVoxel {x: 2, y: 0, z: 1}

		plateLayouter = new PlateLayouter()
		grid.initializeBricks()
		brick = v0.brick

		for num in [1..10]
			mergeableNeighbors = plateLayouter._findMergeableNeighbors brick
			mergeDirection =
				plateLayouter._chooseNeighborsToMergeWith mergeableNeighbors

			expect(mergeableNeighbors[mergeDirection].has(v1.brick)).to.equal(true)

	it 'should not merge a single voxel', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 5, y: 5, z: 0}
		plateLayouter = new PlateLayouter()

		grid.initializeBricks()
		plateLayouter.layout grid

		expect(v0.brick.getPosition()).to.eql({x: 5, y: 5, z: 0})
		expect(v0.brick.getSize()).to.eql({x: 1, y: 1, z: 1})

	it 'should merge two bricks 2x1', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 5, y: 5, z: 0}
		v1 = grid.setVoxel {x: 5, y: 6, z: 0}
		plateLayouter = new PlateLayouter()

		grid.initializeBricks()
		plateLayouter.layout grid

		expect(grid.getAllBricks().size).to.equal(1)
		expect(v0.brick).to.equal(v1.brick)
		expect(v0.brick.getPosition()).to.eql({x: 5, y: 5, z: 0})
		expect(v0.brick.getSize()).to.eql({x: 1, y: 2, z: 1})

	it 'should merge four bricks', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 5, y: 5, z: 0}
		v1 = grid.setVoxel {x: 5, y: 6, z: 0}
		v2 = grid.setVoxel {x: 6, y: 5, z: 0}
		v3 = grid.setVoxel {x: 6, y: 6, z: 0}

		plateLayouter = new PlateLayouter()
		grid.initializeBricks()
		plateLayouter.layout grid

		expect(grid.getAllBricks().size).to.equals(1)
		expect(v0.brick.getPosition()).to.eql({x: 5, y: 5, z: 0})
		expect(v0.brick.getSize()).to.eql({x: 2, y: 2, z: 1})
