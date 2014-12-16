BoundaryBox = require './BoundaryBox'
Polygon = require './Polygon'
Edge = require './Edge'
Vector3D = require './Vector3D'
Point = require './Point'

module.exports.getBoundaryBox = (model) ->
	minX = maxX = model.positions[0]
	minY = maxY = model.positions[1]
	minZ = maxZ = model.positions[2]
	for i in [0..model.positions.length - 1] by 3
		minX = model.positions[i]     if model.positions[i] < minX
		minY = model.positions[i + 1] if model.positions[i + 1] < minY
		minZ = model.positions[i + 2] if model.positions[i + 2] < minZ
		maxX = model.positions[i]     if model.positions[i] > maxX
		maxY = model.positions[i + 1] if model.positions[i + 1] > maxY
		maxZ = model.positions[i + 2] if model.positions[i + 2] > maxZ

	new BoundaryBox(new Vector3D(minX, minY, minZ), new Vector3D(maxX, maxY, maxZ))

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
