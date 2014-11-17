class Ray
	constructor: (@origin, @direction) ->
		return

	@from_to: (origin, target) ->
		ray = new @(origin, origin)
		ray.target_at target

	target_at: (point) ->
		@direction = @origin .to(point) .normalize()
		@

	point_at: (t) ->
		@direction .multiple(t) .add @origin

	clone: () ->
		new Ray( @origin.clone(), @direction.clone() )


	distance_to_Point: (point) ->
		distance = @origin .to(point) .scalar(@direction)
		distance = @origin .distance_to point  unless distance >= 0

	closest_Point_to: (point) ->
		@direction.multiple( @.distance_to_Point point ).add( @orign )

	build_Debug_Support: () ->
		origin_point = new THREE.Mesh( new THREE.SphereGeometry( 0.25, 16, 8 ), new THREE.MeshBasicMaterial( { color: new THREE.Color( 0xFF00FF ) } ) )
		origin_point.position = @origin

		ray_geometry = new THREE.Geometry()
		ray_geometry.vertices.push THREE.get_Vector_for new Vector3D(0,0,0)
		ray_geometry.vertices.push THREE.get_Vector_for @direction.multiple(10000)
		ray_line = new THREE.Line( ray_geometry, new THREE.LineBasicMaterial( { color: new THREE.Color( 0xFF00FF ), linewidth: 1} ) )
		
		origin_point.add ray_line
		origin_point

	intersects_Triangle: (a,b,c) ->


		old_edge = a.to(b)
		edge = a.to(c)
		normal = old_edge.cross( edge )
		diff = a.to(@origin)

		# Solve Q + t*D = b1*E1 + b2*E2 (Q = kDiff, D = ray direction,
		# E1 = kEdge1, E2 = kEdge2, N = Cross(E1,E2)) by
		#   |Dot(D,N)|*b1 = sign(Dot(D,N))*Dot(D,Cross(Q,E2))
		#   |Dot(D,N)|*b2 = sign(Dot(D,N))*Dot(D,Cross(E1,Q))
		#   |Dot(D,N)|*t = -sign(Dot(D,N))*Dot(Q,N)
		DdN = @direction.scalar( normal )
		sign = null

		if DdN > 0
			sign = 1
		else if ( DdN < 0 )
			sign = -1
			DdN = -DdN
		else
			return null

		DdE1xQ = sign * @direction.scalar( old_edge.cross( diff ) )
		DdQxE2 = sign * @direction.scalar( edge.cross(diff) )

		# b2 < 0, no intersection
		if DdE1xQ < 0
			return null

		# b1 < 0, no intersection
		if DdQxE2 > 0
			return null

		# b1+b2 > 1, no intersection
		if DdE1xQ - DdQxE2 > DdN
			return null

		# Line intersects triangle, check if ray does.
		QdN = -sign * diff.dot( normal )

		# t < 0, no intersection
		if QdN < 0
			return null

		return @.point_at( QdN / DdN)


	intersects_Polygon: (polygon) ->
		fix_point = polygon.points.first()
		origin_distance = fix_point.to @origin

		old_point = polygon.points.second()
		old_edge = fix_point.to(old_point)

		orientaion = @direction.scalar polygon.plane.normal
		origin_to_normal = origin_distance.scalar( polygon.plane.normal )

		#Face direction check
		if orientaion > 0      #front facing
			sign = 1
		else if orientaion < 0 #back facing
			sign = -1
		else            #parallel
			sign = 0
			return null if origin_to_normal == 0 #coplanar
			return no

		#Ray direction check
		return no if origin_to_normal * -sign < 0 # wrong direction
			
		#QdN = QdN * sign
		old_bridge = sign * @direction.scalar( old_edge.cross origin_distance )

		for point in polygon.points[2..]

			edge = fix_point.to(point)
			bridge = sign * @direction.scalar( edge.cross origin_distance )

			normal = old_edge.cross edge
			DdN = sign * @direction.scalar normal

			if old_bridge >= 0 and bridge <= 0
				if old_bridge - bridge <= DdN
					QdN = -sign * origin_distance.scalar( normal )
					return ( QdN / DdN)
				else
					return no

			old_edge = edge
			old_bridge = bridge

		no

	intersects_with_cutted_Brick: (brickspace) ->
		intersection_count = 0
		for polygon in brickspace.pre_model.polygons
			distance = @intersects_Polygon polygon
			if distance
				intersection_count++
		intersection_count

	intersect_Object: (solidObject) ->
		intersections = []
		for polygon in solidObject.polygons
			distance = @intersects_Polygon polygon
			if distance
				intersections.push {polygon: polygon, distance: distance}
		intersections

module.exports = Ray
