SolidObject3D = require './SolidObject3D'
Vector3D = require './Vector3D'
Point = require './Point'

module.exports.convertToSolidObject3D = (optimizedModel) ->
	object = new SolidObject3D()
	for i in [0..optimizedModel.indices.length - 1] by 3
		points = (createPointFromIndex(optimizedModel, index) for index in optimizedModel.indices.subarray i, i + 3)
		for point in points
			object.set_Point(point.x, point.y, point.z)
		normal = createNormalFromIndex(optimizedModel, i)

		object.add_Polygon_for(points, normal)
	object


createPointFromIndex = (optimizedModel, i) ->
	new Point(optimizedModel.positions[i],
		optimizedModel.positions[i + 1], optimizedModel.positions[i + 2])

createNormalFromIndex = (optimizedModel, i) ->
	new Point(optimizedModel.faceNormals[i],
		optimizedModel.faceNormals[i + 1], optimizedModel.faceNormals[i + 2])