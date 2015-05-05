module.exports = (chai, utils) ->
	expect = chai.expect
	utils.overwriteMethod(chai.Assertion.prototype, 'equal', (_super) ->
		return (other) ->
			obj = utils.flag(this, 'object')
			if obj instanceof ThreeBSP.Vertex and
			Array.isArray(other) and other.length == 3
				compareVertex expect, obj, other
			else if obj instanceof ThreeBSP.Polygon and
			Array.isArray other
				comparePolygon expect, obj, other
			else
				_super.apply this, arguments
	)

compareVertex = (expect, obj, coords) ->
	{x, y, z} = obj
	o = [x, y, z]
	expect(o).to.deep.equal(coords)

comparePolygon = (expect, obj, coordsarray) ->
	expect(obj.vertices).to.have.length(coordsarray.length)
	for v,i in obj.vertices
		expect(v).to.equal(coordsarray[i])
