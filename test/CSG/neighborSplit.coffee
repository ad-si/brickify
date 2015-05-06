chai = require 'chai'
chai.use require './threeChaiHelper'
expect = require('chai').expect
THREE = require 'three'
require '../../src/plugins/csg/threeCsg/ThreeCSG'

baseTemplate = [
	[-1, -1, 0]
	[1, -1, 0]
	[1, 1, 0]
	[-1, 1, 0]
]

splitXZTemplate = [
	[-1, 0, -1]
	[1, 0, -1]
	[1, 0, 1]
	[-1, 0, 1]
]

splitYZTemplate = [
	[0, -1, -1]
	[0, 1, -1]
	[0, 1, 1]
	[0, -1, 1]
]

baseTemplate45 = [
	[-1, 0, 0]
	[0, -1, 0]
	[1, 0, 0]
	[0, 1, 0]
]

baseTemplate45NE = [
	[0, 1, 0]
	[1, 0, 0]
	[2, 1, 0]
	[1, 2, 0]
]

templateToPolygon = (template) ->
	vertices = []
	for v in template
		vertices.push new ThreeBSP.Vertex v[0], v[1], v[2]
	return new ThreeBSP.Polygon vertices

describe 'CSG neighbor splitting for two-manifoldness', ->
	describe 'first split tests', ->
		it 'should split correctly', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate

			front = []
			back = []
			split.splitPolygon base, [], [], front, back

			expect(front).to.have.length(1)
			expect(back).to.have.length(1)
			front = front[0]
			expect(front).to.equal([[-1, -1, 0], [1, -1, 0], [1, 0, 0], [-1, 0, 0]])
			back = back[0]
			expect(back).to.equal([[1, 0, 0], [1, 1, 0], [-1, 1, 0], [-1, 0, 0]])

		it 'should set correct neighborhood on first split', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate

			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			expect(front.neighborhood).to.have.length(1)
			neighborhood = front.neighborhood[0]
			expect(neighborhood.p1).to.equal(front)
			expect(neighborhood.p2).to.equal(back)
			expect(neighborhood.v1).to.equal([1, 0, 0])
			expect(neighborhood.v2).to.equal([-1, 0, 0])

			expect(back.neighborhood).to.have.length(1)
			expect(back.neighborhood[0]).to.equal(neighborhood)

	describe 'second split front tests', ->
		it 'should correctly split front twice', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate

			front = []
			split.splitPolygon base, [], [], front, []
			front = front[0]
			front2 = []
			back2 = []
			split2.splitPolygon front, [], [], front2, back2
			expect(front2).to.have.length(1)
			expect(back2).to.have.length(1)
			front2 = front2[0]
			expect(front2).to.equal([[0, -1, 0], [1, -1, 0], [1, 0, 0], [0, 0, 0]])
			back2 = back2[0]
			expect(back2).to.equal([[-1, -1, 0], [0, -1, 0], [0, 0, 0], [-1, 0, 0]])

		it 'should insert vertex in back neighbor on second split', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			split2.splitPolygon front, [], [], [], []
			expect(back).to.equal([[1, 0, 0], [1, 1, 0], [-1, 1, 0], [-1, 0, 0],
														 [0, 0, 0]])

		it 'should insert vertex in back neighbor on second split
 with reversed vertices', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			neighbor = front.neighborhood[0]
			v = neighbor.v1
			neighbor.v1 = neighbor.v2
			neighbor.v2 = v
			split2.splitPolygon front, [], [], [], []
			expect(back).to.equal([[1, 0, 0], [1, 1, 0], [-1, 1, 0], [-1, 0, 0],
														 [0, 0, 0]])

		it 'should set correct neighborhood on second split of front', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			front2 = []
			back2 = []
			split2.splitPolygon front, [], [], front2, back2
			front2 = front2[0]
			back2 = back2[0]
			expect(front2.neighborhood).to.have.length(2)
			neighbor = front2.neighborhood[1]
			expect(neighbor.p1).to.equal(front2)
			expect(neighbor.p2).to.equal(back2)
			expect(neighbor.v1).to.equal([0, -1, 0])
			expect(neighbor.v2).to.equal([0, 0, 0])

		it 'should remove the old neighborhood on second split of front', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			neighbor = front.neighborhood[0]
			split2.splitPolygon front, [], [], [], []
			expect(front.neighborhood).not.to.contain(neighbor)
			expect(back.neighborhood).not.to.contain(neighbor)

		it 'should connect old neighbor with new polygons on second split', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			front2 = []
			back2 = []
			split2.splitPolygon front, [], [], front2, back2
			front2 = front2[0]
			back2 = back2[0]
			expect(back.neighborhood).to.have.length(2)
			neighbor1 = back.neighborhood[0]
			expect(neighbor1.p1).to.equal(back)
			expect(neighbor1.p2).to.equal(front2)
			expect(neighbor1.v1).to.equal([1, 0, 0])
			expect(neighbor1.v2).to.equal([0, 0, 0])
			neighbor2 = back.neighborhood[1]
			expect(neighbor2.p1).to.equal(back)
			expect(neighbor2.p2).to.equal(back2)
			expect(neighbor2.v1).to.equal([-1, 0, 0])
			expect(neighbor2.v2).to.equal([0, 0, 0])

	describe 'second split back tests', ->
		it 'should correctly split back twice', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate

			back = []
			split.splitPolygon base, [], [], [], back
			back = back[0]
			front2 = []
			back2 = []
			split2.splitPolygon back, [], [], front2, back2
			expect(front2).to.have.length(1)
			expect(back2).to.have.length(1)
			front2 = front2[0]
			expect(front2).to.equal([[1, 0, 0], [1, 1, 0], [0, 1, 0], [0, 0, 0]])
			back2 = back2[0]
			expect(back2).to.equal([[0, 1, 0], [-1, 1, 0], [-1, 0, 0], [0, 0, 0]])

		it 'should insert vertex in front neighbor on second split', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			split2.splitPolygon back, [], [], [], []
			expect(front).to.equal([[-1, -1, 0], [1, -1, 0], [1, 0, 0], [0, 0, 0],
															[-1, 0, 0]])

		it 'should insert vertex in front neighbor on second split
 with reversed vertices', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			neighbor = back.neighborhood[0]
			v = neighbor.v1
			neighbor.v1 = neighbor.v2
			neighbor.v2 = v
			split2.splitPolygon back, [], [], [], []
			expect(front).to.equal([[-1, -1, 0], [1, -1, 0], [1, 0, 0], [0, 0, 0],
															[-1, 0, 0]])

		it 'should set correct neighborhood on second split of back', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			front2 = []
			back2 = []
			split2.splitPolygon back, [], [], front2, back2
			front2 = front2[0]
			back2 = back2[0]
			expect(front2.neighborhood).to.have.length(2)
			neighborhood = front2.neighborhood[1]
			expect(neighborhood.p1).to.equal(front2)
			expect(neighborhood.p2).to.equal(back2)
			expect(neighborhood.v1).to.equal([0, 1, 0])
			expect(neighborhood.v2).to.equal([0, 0, 0])

		it 'should remove the old neighborhood on second split of back', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			neighbor = front.neighborhood[0]
			split2.splitPolygon back, [], [], [], []
			expect(front.neighborhood).not.to.contain(neighbor)
			expect(back.neighborhood).not.to.contain(neighbor)

		it 'should connect old neighbor with new polygons on second split', ->
			base = templateToPolygon baseTemplate
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			front2 = []
			back2 = []
			split2.splitPolygon back, [], [], front2, back2
			front2 = front2[0]
			back2 = back2[0]
			expect(front.neighborhood).to.have.length(2)
			neighbor1 = front.neighborhood[0]
			expect(neighbor1.p1).to.equal(front)
			expect(neighbor1.p2).to.equal(back2)
			expect(neighbor1.v1).to.equal([-1, 0, 0])
			expect(neighbor1.v2).to.equal([0, 0, 0])
			neighbor2 = front.neighborhood[1]
			expect(neighbor2.p1).to.equal(front)
			expect(neighbor2.p2).to.equal(front2)
			expect(neighbor2.v1).to.equal([1, 0, 0])
			expect(neighbor2.v2).to.equal([0, 0, 0])

	describe 'coplanar vertex split tests', ->
		it 'should correctly split with coplanar vertex', ->
			base = templateToPolygon baseTemplate45
			split = templateToPolygon splitXZTemplate

			front = []
			back = []
			split.splitPolygon base, [], [], front, back

			expect(front).to.have.length(1)
			expect(back).to.have.length(1)
			front = front[0]
			expect(front).to.equal([[-1, 0, 0], [0, -1, 0], [1, 0, 0]])
			back = back[0]
			expect(back).to.equal([[-1, 0, 0], [1, 0, 0], [0, 1, 0]])

		it 'should set correct neighborhood on first split', ->
			base = templateToPolygon baseTemplate45
			split = templateToPolygon splitXZTemplate

			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			expect(front.neighborhood).to.have.length(1)
			neighborhood = front.neighborhood[0]
			expect(neighborhood.p1).to.equal(front)
			expect(neighborhood.p2).to.equal(back)
			expect(neighborhood.v1).to.equal([-1, 0, 0])
			expect(neighborhood.v2).to.equal([1, 0, 0])

			expect(back.neighborhood).to.have.length(1)
			expect(back.neighborhood[0]).to.equal(neighborhood)

		it 'should correctly split twice', ->
			base = templateToPolygon baseTemplate45
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate

			front = []
			split.splitPolygon base, [], [], front, []
			front = front[0]
			front2 = []
			back2 = []
			split2.splitPolygon front, [], [], front2, back2
			expect(front2).to.have.length(1)
			expect(back2).to.have.length(1)
			front2 = front2[0]
			expect(front2).to.equal([[0, -1, 0], [1, 0, 0], [0, 0, 0]])
			back2 = back2[0]
			expect(back2).to.equal([[-1, 0, 0], [0, -1, 0], [0, 0, 0]])

		it 'should insert vertex in back neighbor on second split', ->
			base = templateToPolygon baseTemplate45
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			split2.splitPolygon front, [], [], [], []
			expect(back).to.equal([[-1, 0, 0], [0, 0, 0], [1, 0, 0], [0, 1, 0]])

		it 'should set correct neighborhood on second split of front', ->
			base = templateToPolygon baseTemplate45
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			front2 = []
			back2 = []
			split2.splitPolygon front, [], [], front2, back2
			front2 = front2[0]
			back2 = back2[0]
			expect(front2.neighborhood).to.have.length(2)
			neighbor = front2.neighborhood[1]
			expect(neighbor.p1).to.equal(front2)
			expect(neighbor.p2).to.equal(back2)
			expect(neighbor.v1).to.equal([0, -1, 0])
			expect(neighbor.v2).to.equal([0, 0, 0])

		it 'should remove the old neighborhood on second split of front', ->
			base = templateToPolygon baseTemplate45
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			neighbor = front.neighborhood[0]
			split2.splitPolygon front, [], [], [], []
			expect(front.neighborhood).not.to.contain(neighbor)
			expect(back.neighborhood).not.to.contain(neighbor)

		it 'should connect old neighbor with new polygons on second split', ->
			base = templateToPolygon baseTemplate45
			split = templateToPolygon splitXZTemplate
			split2 = templateToPolygon splitYZTemplate
			front = []
			back = []
			split.splitPolygon base, [], [], front, back
			front = front[0]
			back = back[0]
			front2 = []
			back2 = []
			split2.splitPolygon front, [], [], front2, back2
			front2 = front2[0]
			back2 = back2[0]
			expect(back.neighborhood).to.have.length(2)
			neighbor1 = back.neighborhood[0]
			expect(neighbor1.p1).to.equal(back)
			expect(neighbor1.p2).to.equal(front2)
			expect(neighbor1.v1).to.equal([1, 0, 0])
			expect(neighbor1.v2).to.equal([0, 0, 0])
			neighbor2 = back.neighborhood[1]
			expect(neighbor2.p1).to.equal(back)
			expect(neighbor2.p2).to.equal(back2)
			expect(neighbor2.v1).to.equal([-1, 0, 0])
			expect(neighbor2.v2).to.equal([0, 0, 0])

		it 'should update neighbors on coplanar vertex split NE', ->
			base1 = templateToPolygon baseTemplate45
			base2 = templateToPolygon baseTemplate45NE
			split = templateToPolygon splitXZTemplate
			v1 = base1.vertices[2] # 1, 0, 0
			v2 = base1.vertices[3] # 0, 1, 0

			neighbor = new ThreeBSP.Neighborhood base1, base2, v1, v2
			base1.neighborhood.push neighbor
			base2.neighborhood.push neighbor

			front = []
			back = []
			split.splitPolygon base1, [], [], front, back
			front = front[0]
			back = back[0]
			expect(base1.neighborhood).to.be.empty
			expect(base2.neighborhood).to.have.length(1)
			b2n = base2.neighborhood[0]
			expect(b2n.p1).to.equal(base2)
			expect(b2n.p2).to.equal(back)
			expect(b2n.v1).to.equal([1, 0, 0])
			expect(b2n.v2).to.equal([0, 1, 0])
			expect(front.neighborhood).to.have.length(1)
			fn = front.neighborhood[0]
			expect(fn.p1).to.equal(front)
			expect(fn.p2).to.equal(back)
			expect(fn.v1).to.equal([-1, 0, 0])
			expect(fn.v2).to.equal([1, 0, 0])
			expect(back.neighborhood).to.have.length(2)
			expect(back.neighborhood[0]).to.equal(b2n)
			expect(back.neighborhood[1]).to.equal(fn)
