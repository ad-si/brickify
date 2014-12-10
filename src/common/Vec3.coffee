class Vec3
	constructor: (@x, @y, @z) ->
		return 0
	minus: (vec) ->
		return new Vec3(@x - vec.x, @y - vec.y, @z - vec.z)
	add: (vec) ->
		return new Vec3(@x + vec.x, @y + vec.y, @z + vec.z)
	crossProduct: (vec) ->
		return new Vec3(@y * vec.z - @z * vec.y,
			@z * vec.x - @x * vec.z,
			@x * vec.y - @y * vec.x)
	length: () ->
		return Math.sqrt(@x * @x + @y * @y + @z * @z)
	euclideanDistanceTo: (vec) ->
		return (@minus vec).length()
	multiplyScalar: (scalar) ->
		return new Vec3(@x * scalar, @y * scalar, @z * scalar)
	normalized: () ->
		return @multiplyScalar (1.0 / @length())

module.exports = Vec3
