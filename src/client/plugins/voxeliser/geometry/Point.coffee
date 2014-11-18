Vector3D = require './Vector3D'

class Point extends Vector3D

	# specifies in which object this point is contained
	# @param object [Object3D] the containing object
	# @param index [int] the index of this point in @object.points
	set_Object: (@object, @index) ->
		return

	move_by: (vector) ->
		@.add vector

	as_Vector: () ->
		new Vector3D(@x, @y, @z)

	smaller: (point) ->
		if @x == point.x
			if @y == point.y
				if @z == point.z
					return null
				else return @z < point.z
			else return @y < point.z
		else return @x < point.x

module.exports = Vector3D