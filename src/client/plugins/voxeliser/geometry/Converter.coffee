SolidObject3D = require './SolidObject3D'
Point = require './Point'

module.exports.convertToSolidObject3D = (optimizedModel) ->
	solidObject = new SolidObject3D()
	vertices = []
	for i in [0..optimizedModel.positions.length - 1] by 3
		vertices.push new Point(optimizedModel.positions[i],
			optimizedModel.positions[i + 1], optimizedModel.positions[i + 2])
	for point in vertices
		solidObject.set_Point(point.x, point.y, point.z)
	for j in [0..optimizedModel.indices.length - 1] by 3
		points = []
		points.push vertices[optimizedModel.indices[j]]
		points.push vertices[optimizedModel.indices[j + 1]]
		points.push vertices[optimizedModel.indices[j + 2]]
		normal = new Point(optimizedModel.faceNormals[j],
			optimizedModel.faceNormals[j + 1], optimizedModel.faceNormals[j + 2])
		solidObject.add_Polygon_for(points, normal)
	solidObject
