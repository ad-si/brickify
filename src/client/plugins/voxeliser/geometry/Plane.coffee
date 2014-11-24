# abs min max ?
# multi additons?
# euclidian check?
#CSG.Plane.EPSILON = 1e-5;

Polygon = require './Polygon'

class Plane
	constructor: (@normal, @lambda) ->
		return

	@construct: (a, b ,c) ->
		switch arguments.length
			# construct by a vector with its length
			when 1 and a instanceof Vector3D
					@by_Vector a
			# construct by normal and lambda
			when 2 and  (a instanceof Vector) and  (typeof b is 'number')
					new @ a, b
			# construct by normal and point on the plane
			when 2 and (a instanceof Vector) and (b instanceof Vector)
					@by_Origin a, b
				 # construct by 3 points on the plane
			when 3
					@by_Points a, b, c

	@by_Points: (point_A, point_B, point_C) ->
		normal = ( point_A.to point_B ).cross( point_A.to point_C ).normalize()
		lambda =  normal.scalar point_A
		new @ normal, lambda

	@by_Origin: (point, normal) ->
		lambda = normal.scalar point
		new @ normal, lambda

	@by_Vector: (vector) ->
		normal = vector.normal()
		lambda = vector.length()

	clone: () -> new Plane(@normal, @lambda)

	# postive
	equals: (plane) -> @lambda == plane.lambda and @normal.equals plane.normal

	similar: (plane) ->
		-Tolerances.float <= plane.lambda - @lambda <= Tolerances.float and
		@normal.similar plane.normal

	set_normal: (@normal) ->
		return
	set_lambda: (@lambda) ->
		return

	turn: () ->
		@normal.negate()
		@lambda = -@lambda

	distance_to: (point) ->
		@normal.scalar(point) - @lambda

	range_of: (object3d) ->
		first_point = object3d.points
		min = @.distance_to first_point
		max = @.distance_to first_point
		for point in object3d.points
			distance = @.distance_to point
			min = Math.min(min, distance)
			max = Math.min(min, distance)

		[min, max]

	move_by: (vector) ->
		onplane_point = @normal.clone().times(@lambda)
		onplane_point.add vector

		@lambda = @normal.scalar onplane_point

	calculate_cutting_point: (from_point, to_point, from_distance, to_distance) ->
		from_distance = @distance_to from_point unless from_distance
		to_distance = @distance_to to_point unless to_distance
		# sum of both (one distance is negative)
		distance = from_distance / (from_distance - to_distance)

		from_point.interpolatedTo to_point, distance


	classify_Polygon: (polygon, tolerance) ->
		tolerance ?= Tolerances.plane
		category = Plane.ONPLANE
		point_positons = []
		point_distances = []

		for point in polygon.points
			distance = @.distance_to point
			point_distances.add distance
			if distance > tolerance # before
				point_positon = Plane.BEFORE
			else if distance < -tolerance # behind
				point_positon = Plane.BEHIND
			else
				point_positon = Plane.ONPLANE

			point_positons.add point_positon
			category |= point_positon

		[category, point_positons, point_distances]


	arrange_Polygon:
		(polygon, onplane_list, before_list, behind_list, tolerance) ->
			[category, point_positons, point_distances] =
				@.classify_Polygon polygon, tolerance

			if category == Plane.ONPLANE
					onplane_list.add polygon
			else if category == Plane.BEFORE
					before_list.add polygon
			else if category == Plane.BEHIND
					behind_list.add polygon
			else if category == Plane.SPLIT
					[before_polygon, behind_polygon] =
						@split_Polygon polygon, point_positons, point_distances
					behind_list.add behind_polygon
					before_list.add before_polygon

			category


	split_Polygon: (polygon, point_positons, point_distances, tolerance) ->
		[category, point_positons, point_distances] =
		@.classify_Polygon polygon, tolerance unless point_positons and
			point_distances
		last_point = polygon.points.last()
		last_position = point_positons.last()
		last_distance = point_distances.last()

		before_points = []
		behind_points = []

		onplane_count = 0

		for point, index in polygon.points
			position = point_positons[index]
			distance = point_distances[index]
			if position == Plane.BEFORE

				if last_position == Plane.BEHIND
					onplane_point =
						@.calculate_cutting_point last_point, point, last_distance, distance
					before_points.add onplane_point
					behind_points.add onplane_point

				before_points.add point

			else if position == Plane.BEHIND

				if last_position == Plane.BEFORE
					onplane_point =
						@.calculate_cutting_point last_point, point, last_distance, distance
					before_points.add onplane_point
					behind_points.add onplane_point
				
				behind_points.add point

			else if position == Plane.ONPLANE
				onplane_count++
				before_points.add point
				behind_points.add point

			#else # should not happen
			last_point = point
			last_position = position
			last_distance = distance

		# Should not points > onplane_count should not occure at proper usage
		if before_points.length > onplane_count
			before_polygon = new Polygon(before_points, polygon.plane)
			before_polygon.tag = polygon.tag
		if before_points.length > onplane_count
			behind_polygon = new Polygon(behind_points, polygon.plane)
			behind_polygon.tag = polygon.tag

		[before_polygon, behind_polygon]


# used as Symbols and as binary bit mask for binary OR
Plane.ONPLANE = 0 # 00
Plane.BEFORE = 1  # 01
Plane.BEHIND = 2  # 10
Plane.SPLIT = 3   # 11

module.exports = Plane
