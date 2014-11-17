class Edge
	constructor: (@from_point, @to_point) ->
		@inner_Polygon = null
		@outer_Polygon = null
		@hard_edge = yes
		@broken_edge = no

	clone: () -> new Edge()

	equals: (other_Edge) ->
		return yes if @vertex1.equals other_Edge.vertex1 and @vertex2.equals other_Edge.vertex2
		return yes if @vertex1.equals other_Edge.vertex2 and @vertex2.equals other_Edge.vertex1
		no

	get_Neighbor_of: (polygon) ->
		if @inner_Polygon == polygon
			@outer_Polygon
		else if @outer_Polygon == polygon
			@inner_Polygon

	is_inner: (from, to) ->
		if from == @from_point and to == @to_point
			yes
		else if to == @from_point and from == @to_point
			no

	set_Polygon: (polygon, from, to) ->
		if @is_inner from, to
			@inner_Polygon = polygon
		else
			@outer_Polygon = polygon

	check_Visibility: (treshhold) ->
		treshhold ?= Tolerances.soft_edge
		if !@inner_Polygon or !@outer_Polygon
			@broken_edge = yes
			@hard_edge = no
		else if treshhold >= @inner_Polygon.plane.normal.scalar @outer_Polygon.plane.normal
			@hard_edge = yes
			@broken_edge = no
		else
			@hard_edge = no
			@broken_edge = no


find_groups_of = (obj) ->
	ungrouped = obj.polygons.clone()
	groups = []

	while ungrouped.length > 0
		groups.push find_group ungrouped.pop(), ungrouped

	groups

find_group = (polygon, ungrouped) ->
	group = [polygon]
	check_polygons = [polygon]

	while check_polygons.length > 0
		p = check_polygons.pop()

		for edge in p.edges
			if !edge.hard_edge
				neighbor_polygon = edge.get_Neighbor_of p
				if ungrouped.includes neighbor_polygon
					ungrouped.remove neighbor_polygon

					group.add neighbor_polygon
					check_polygons.add neighbor_polygon

	group

find_objects = (obj) ->
	remain_polygons = obj.polygons.clone()
	check_polygons = [ remain_polygons.pop() ]

	while check_polygons.length > 0
		p = check_polygons.pop()

		for edge in p.edges
			neighbor_polygon = edge.get_Neighbor_of p
			if remain_polygons.includes neighbor_polygon
				remain_polygons.remove neighbor_polygon
				check_polygons.add neighbor_polygon

	remain_polygons


module.exports =  Edge