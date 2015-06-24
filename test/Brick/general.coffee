expect = require('chai').expect
NewBrick = require '../../src/plugins/newBrickator/pipeline/Brick'
BrickLayouter =
	require '../../src/plugins/newBrickator/pipeline/Layout/BrickLayouter'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'Brick', ->
	it 'should take ownership of voxels', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 1, y: 0, z: 0}

		nb = new NewBrick([v0, v1])

		expect(nb.voxels.size).to.equal(2)
		expect(v0.brick).to.equal(nb)
		expect(v1.brick).to.equal(nb)

	it 'should iterate over all voxels exactly once', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 1, y: 0, z: 0}

		nb = new NewBrick([v0, v1])

		v0c = false
		v1c = false
		numIter = 0

		nb.forEachVoxel (voxel)	->
			numIter++
			v0c = true if voxel == v0
			v1c = true if voxel == v1

		expect(numIter).to.equal(2)
		expect(v0c).to.equal(true)
		expect(v1c).to.equal(true)

	it 'should return the right neighbors', ->
		grid = new Grid()
		vC = grid.setVoxel {x: 1, y: 1, z: 1}
		vXp = grid.setVoxel {x: 2, y: 1, z: 1}
		vXm = grid.setVoxel {x: 0, y: 1, z: 1}
		vYp = grid.setVoxel {x: 1, y: 2, z: 1}
		vYm = grid.setVoxel {x: 1, y: 0, z: 1}
		vZp = grid.setVoxel {x: 1, y: 1, z: 2}
		vZm = grid.setVoxel {x: 1, y: 1, z: 0}

		grid.forEachVoxel (voxel) ->
			new NewBrick([voxel])

		b = vC.brick

		nXp = b.getNeighbors(NewBrick.direction.Xp)
		expect(nXp.size).to.equal(1)
		expect(nXp.has(vXp.brick)).to.equal(true)

		nYp = b.getNeighbors(NewBrick.direction.Yp)
		expect(nYp.size).to.equal(1)
		expect(nYp.has(vYp.brick)).to.equal(true)

		nXm = b.getNeighbors(NewBrick.direction.Xm)
		expect(nXm.size).to.equal(1)
		expect(nXm.has(vXm.brick)).to.equal(true)

		nYm = b.getNeighbors(NewBrick.direction.Ym)
		expect(nYm.size).to.equal(1)
		expect(nYm.has(vYm.brick)).to.equal(true)

		nZm = b.getNeighbors(NewBrick.direction.Zm)
		expect(nZm.size).to.equal(1)
		expect(nZm.has(vZm.brick)).to.equal(true)

		nZp = b.getNeighbors(NewBrick.direction.Zp)
		expect(nZp.size).to.equal(1)
		expect(nZp.has(vZp.brick)).to.equal(true)

	it 'should return the right connectedBricks', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}

		grid.initializeBricks()

		connectedBricks = v0.brick.connectedBricks()
		expect(connectedBricks.size).to.equal(0)

		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 0, y: 0, z: 1}

		grid.initializeBricks()

		connectedBricks = v0.brick.connectedBricks()
		expect(connectedBricks.size).to.equal(1)

		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 0, y: 0, z: 1}
		v2 = grid.setVoxel {x: 0, y: 0, z: 2}

		grid.initializeBricks()

		connectedBricks = v1.brick.connectedBricks()
		expect(connectedBricks.size).to.equal(2)

	it 'should split up', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 1, y: 0, z: 0}

		b = new NewBrick([v0, v1])
		newBricks = b.splitUp()

		expect(newBricks.size).to.equal(2)
		expect(v0.brick).to.not.equal(b)
		expect(v0.brick).to.not.equal(false)
		expect(v1.brick).to.not.equal(b)
		expect(v1.brick).to.not.equal(false)
		expect(v1.brick).to.not.equal(v0.brick)

	it 'should clear itself', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		b = new NewBrick([v0])
		b.clear()
		expect(v0.brick).to.equal(false)
		expect(b.voxels.size).to.equal(0)

	it 'should correctly merge', ->
		grid = new Grid()
		v0 = grid.setVoxel {x: 0, y: 0, z: 0}
		v1 = grid.setVoxel {x: 1, y: 0, z: 0}
		v2 = grid.setVoxel {x: 0, y: 1, z: 0}
		v3 = grid.setVoxel {x: 1, y: 2, z: 0}

		b0 = new NewBrick([v0, v1])
		b1 = new NewBrick([v2, v3])

		b0.mergeWith b1

		expect(v2.brick).to.equal(b0)
		expect(v3.brick).to.equal(b0)

		expect(b0.voxels.size).to.equal(4)
		expect(b1.voxels.size).to.equal(0)

	it 'should report correct size', ->
		grid = new Grid()
		voxels = []

		for x in [0...4] by 1
			for y in [0...3] by 1
				for z in [0...2] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		size = b.getSize()

		expect(size.x).to.equal(4)
		expect(size.y).to.equal(3)
		expect(size.z).to.equal(2)

		grid = new Grid()
		voxels = []

		for x in [1...4] by 1
			for y in [1...3] by 1
				for z in [1...2] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		size = b.getSize()

		expect(size.x).to.equal(3)
		expect(size.y).to.equal(2)
		expect(size.z).to.equal(1)

		grid = new Grid()
		voxels = []

		for x in [0...2] by 1
			for y in [0...4] by 1
				for z in [0...3] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		size = b.getSize()

		expect(size.x).to.equal(2)
		expect(size.y).to.equal(4)
		expect(size.z).to.equal(3)

	it 'should report correct position', ->
		grid = new Grid()
		voxels = []

		for x in [0...4] by 1
			for y in [1...3] by 1
				for z in [2...3] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		position = b.getPosition()

		expect(position.x).to.equal(0)
		expect(position.y).to.equal(1)
		expect(position.z).to.equal(2)

	it 'should report whether it has a valid size', ->
		# [2, 4, 3] is a valid lego brick
		grid = new Grid()
		voxels = []

		for x in [0...2] by 1
			for y in [0...4] by 1
				for z in [0...3] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		expect(b.hasValidSize()).to.equal(true)

		#[1, 4, 4] is not a valid lego brick
		grid = new Grid()
		voxels = []

		for x in [0...1] by 1
			for y in [0...4] by 1
				for z in [0...4] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		expect(b.hasValidSize()).to.equal(false)

	it 'should report whether it is valid', ->
		# [2, 4, 3] is a valid lego brick
		grid = new Grid()
		voxels = []

		for x in [0...2] by 1
			for y in [0...4] by 1
				for z in [0...3] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		expect(b.isValid()).to.equal(true)

		# [2, 4, 3] is a valid lego brick
		# but give this one a hole
		grid = new Grid()
		voxels = []

		for x in [0...2] by 1
			for y in [0...4] by 1
				for z in [0...3] by 1
					if not (x == 0 and y == 0 and z == 0)
						voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		expect(b.isValid()).to.equal(false)

		#[1, 4, 4] is not a valid lego brick
		grid = new Grid()
		voxels = []

		for x in [0...1] by 1
			for y in [0...4] by 1
				for z in [0...4] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		expect(b.isValid()).to.equal(false)

	it 'should report whether it is hole free', ->
		grid = new Grid()
		voxels = []

		for x in [0...2] by 1
			for y in [0...4] by 1
				for z in [0...3] by 1
					voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		expect(b.isHoleFree()).to.equal(true)

		# give this one a hole
		grid = new Grid()
		voxels = []

		for x in [0...2] by 1
			for y in [0...4] by 1
				for z in [0...3] by 1
					if not (x == 0 and y == 0 and z == 0)
						voxels.push grid.setVoxel {x: x, y: y, z: z}

		b = new NewBrick(voxels)
		expect(b.isHoleFree()).to.equal(false)
