module.exports.convertToSolidObject3D = (optimizedModel) ->
	object = new SolidObject3D()
	for i in optimizedModel.faceNormals by 1
		points = optimizedModel.indices[i * 3 .. i * 3 + 3]
		normal = optimizedModel.faceNormals[i]
		object.add_Polygon_for(points, normal)
	object
