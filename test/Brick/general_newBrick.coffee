expect = require('chai').expect
NewBrick = require '../../src/plugins/newBrickator/pipeline/newBrick'
Grid = require '../../src/plugins/newBrickator/pipeline/Grid'

describe 'newBrick', ->
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

		nb.forEachVoxel (voxel)	=>
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
			console.log voxel
			new NewBrick([voxel])

		b = vC.brick

		console.log b

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
