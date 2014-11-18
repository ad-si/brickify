SolidObject3D = require './SolidObject3D'
Point = require './Point'

module.exports.convertToSolidObject3D = (optimizedModel) ->
	vertices = new Array
	for i in [0..optimizedModel.positions.length - 1] by 3
		vertices.push new Point(optimizedModel.positions[i],
			optimizedModel.positions[i + 1], optimizedModel.positions[i + 2])
	solidObject = new SolidObject3D()
	for j in [0..optimizedModel.faceNormals - 1] by 1
		points = new Array 
		points.push vertices[optimizedModel.indices[j]]
		points.push vertices[optimizedModel.indices[j + 1]]
		points.push vertices[optimizedModel.indices[j + 2]]
		normal = optimizedModel.faceNormals[j]
		solidObject.add_Polygon_for(points, normal)
	solidObject
