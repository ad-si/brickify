BoundaryBox = require './BoundaryBox'
Polygon = require './Polygon'
Edge = require './Edge'
Vector3D = require './Vector3D'
Point = require './Point'

module.exports.getBoundaryBox = (model) ->
	bb = model.boundingBox()
	new BoundaryBox(
		new Vector3D(bb.min.x, bb.min.y, bb.min.z),
		new Vector3D(bb.max.x, bb.max.y, bb.max.x))

module.exports.getPolygons = (model) ->
	polygons = []
	vertices = []
	for i in [0..model.positions.length - 1] by 3
		vertices.push new Point(model.positions[i],
			model.positions[i + 1], model.positions[i + 2])
	for j in [0..model.indices.length - 1] by 3
		points = []
		points.push vertices[model.indices[j]]
		points.push vertices[model.indices[j + 1]]
		points.push vertices[model.indices[j + 2]]
		edges = []
		edges.push new Edge points[2], points[0]
		edges.push new Edge points[0], points[1]
		edges.push new Edge points[1], points[2]
		normal = new Point(model.faceNormals[j],
			model.faceNormals[j + 1], model.faceNormals[j + 2])
		polygons.push new Polygon(points, normal, edges)
	polygons
