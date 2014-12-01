Object3D = require './Object3D'

# require CSG lib !!
CSG = require './csg'

class BoundaryBox
	constructor: (@minPoint, @maxPoint) ->
		@centerPoint = null
		@extent = null

	@create_from: (object3D) ->
		points = object3D.points
		bb = new @( points[0].as_Vector(), points[0].as_Vector())

		for point in points
			bb.minPoint.x = point.x if point.x < bb.minPoint.x
			bb.minPoint.y = point.y if point.y < bb.minPoint.y
			bb.minPoint.z = point.z if point.z < bb.minPoint.z
			bb.maxPoint.x = point.x if point.x > bb.maxPoint.x
			bb.maxPoint.y = point.y if point.y > bb.maxPoint.y
			bb.maxPoint.z = point.z if point.z > bb.maxPoint.z

		bb

	clone: () ->
		clone = new BoundaryBox(@minPoint.clone(), @maxPoint.clone())

	get_CenterPoint: () ->
		@centerPoint ?= @.calculate_CenterPoint()

	calculate_CenterPoint: () ->
		@minPoint.plus(@maxPoint) .shrink(2)

	get_Extent: () ->
		@extent ?= @.calculate_Extent()

	calculate_Extent: () ->
		@maxPoint.minus @minPoint

	get_LegoDimension: () ->
		'x': (@maxX - @minX) / Lego.width,
		'y': (@maxY - @minY) / Lego.height,
		'z': (@maxZ - @minZ) / Lego.width

	align_to: (bricksystem) ->
		@minPoint.x =
			Math.floor(@minPoint.x / bricksystem.width ) * bricksystem.width
		@minPoint.y =
			Math.floor(@minPoint.y / bricksystem.depth ) * bricksystem.depth
		@minPoint.z =
			Math.floor(@minPoint.z / bricksystem.height ) * bricksystem.height

		@maxPoint.x =
			Math.ceil(@maxPoint.x / bricksystem.width ) * bricksystem.width
		@maxPoint.y =
			Math.ceil(@maxPoint.y / bricksystem.depth ) * bricksystem.depth
		@maxPoint.z =
			Math.ceil(@maxPoint.z / bricksystem.height ) * bricksystem.height
		@

module.exports = BoundaryBox
