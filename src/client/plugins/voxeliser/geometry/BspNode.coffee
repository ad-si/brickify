class BspNode
	constructor: () ->
		@hyperplane = null
		@polygons = []
		@before_Node = null
		@behind_Node = null

	build_Tree: (remaining_polygons) ->
		polygon = remaining_polygons.first()
		@polygons = [polygon]
		@hyperplane = polygon.plane

		@before_polygons = []
		@behind_polygons = []

		for polygon in remaining_polygons[1..] # otherwise points vs plane incorrect = endless loop
			@hyperplane.arrange_Polygon polygon, @polygons, @before_polygons, @behind_polygons, Tolerances.bspt_build

		if @before_polygons.is_not_empty()
			@before_Node = new BspNode()
			@before_Node.build_Tree(@before_polygons.clone())

		if @behind_polygons.is_not_empty()
			@behind_Node = new BspNode()
			@behind_Node.build_Tree(@behind_polygons.clone())

		@

	build_DebugModel: (model) ->
		color = new THREE.Color(0xFFFFFF * Math.random())
		new_poly = []
		for polygon in @polygons
			poly = model.copy_foreign_Polygon polygon
			poly.set_Color color
			new_poly.add poly
		@polygons = new_poly
		if @before_Node?
			@before_Node.build_DebugModel model
		if @behind_Node?
			@behind_Node.build_DebugModel model
		model

	build_DebugModel_Depth: (model, d) ->
		color = new THREE.Color(0xFFFFFF * Math.random())
		new_poly = []
		for polygon in @polygons
			poly = model.copy_foreign_Polygon polygon
			poly.set_Color color
			new_poly.add poly
		@polygons = new_poly
		if d > 0
			if @before_Node?
				@before_Node.build_DebugModel_Depth model, d - 1
			if @behind_Node?
				@behind_Node.build_DebugModel_Depth model, d - 1
		else
			if @before_Node?
				color = new THREE.Color(0xFFFFFF * Math.random())
				for polygon in @before_polygons
					poly = model.copy_foreign_Polygon polygon
					poly.set_Color color
			if @behind_Node?
				color = new THREE.Color(0xFFFFFF * Math.random())
				for polygon in @behind_polygons
					poly = model.copy_foreign_Polygon polygon
					poly.set_Color color
		model

	set_PolygonColor: () ->
		color = new THREE.Color(0xFFFFFF * Math.random())
		for polygon in @polygons
			polygon.set_Color color


	plot_Node: (depth) ->
		print_line = ''
		for count in [0...depth] by 1
			print_line += ' |'
		print_line += '-o'
		if !@behind_Node? and !@before_Node?
			print_line += ' leaf '
		else
			print_line += ' node '
		print_line += @polygons.length
		console.log print_line
		@before_Node.plot_Node depth + 1 if @before_Node
		@behind_Node.plot_Node depth + 1 if @behind_Node


	covers_Polygon: (polygon) ->
		[category, point_positons, point_distances] = @hyperplane.classify_Polygon polygon, Tolerances.bspt_cover
		if category == Plane.BEFORE
			if @before_Node?
				return @before_Node.covers_Polygon polygon
			else
				return [ [polygon], [], [], []]

		else if category == Plane.BEHIND
			if @behind_Node?
				return @behind_Node.covers_Polygon polygon
			else
				return [ [], [polygon], [], []]

		else if category == Plane.ONPLANE
			before_polygons = []
			coplanar_polygons = [polygon]
			behind_polygons = []
			if @before_Node?
				[coplanar_polygons, behind_polygons] = @before_Node.covers_Polygon polygon # no coplanar should exist
			if @behind_Node?
				collected_coplanar = []
				for co_polygon in coplanar_polygons
					[ temp_before_polygons, temp_coplanar_polygons] = @behind_Node.covers_Polygon co_polygon  # no coplanar should exist

					collected_coplanar = collected_coplanar.concat temp_coplanar_polygons
					before_polygons = before_polygons.concat temp_before_polygons

				coplanar_polygons = collected_coplanar

			#behind_polygons.concat coplanar_polygons
			front_facing_coplanar = []
			back_facing_coplanar = []

			for co_polygon in coplanar_polygons
				if 0 < @hyperplane.normal.scalar co_polygon.plane.normal
					front_facing_coplanar.add co_polygon
				else
					back_facing_coplanar.add co_polygon

			return [ before_polygons, behind_polygons, front_facing_coplanar, back_facing_coplanar ]

		else if category == Plane.SPLIT
			[before_polygon, behind_polygon] = @hyperplane.split_Polygon polygon, point_positons, point_distances

			outside_before = []
			outside_behind = []
			outside_front_coplanar = []
			outside_back_coplanar = []

			inside_before = []
			inside_behind = []
			inside_front_coplanar = []
			inside_back_coplanar = []


			if @before_Node?
				[outside_before, outside_behind, outside_front_coplanar, outside_back_coplanar ] = @before_Node.covers_Polygon before_polygon
			else
				outside_before.add before_polygon

			if @behind_Node?
				[inside_before, inside_behind, inside_front_coplanar, inside_back_coplanar ] = @behind_Node.covers_Polygon behind_polygon
			else
				inside_behind.add behind_polygon

			before_polygons = outside_before.concat inside_before
			behind_polygons = outside_behind.concat inside_behind
			front_facing_coplanar = outside_front_coplanar.concat inside_front_coplanar
			back_facing_coplanar = outside_back_coplanar.concat inside_back_coplanar

			return [ before_polygons, behind_polygons, front_facing_coplanar, back_facing_coplanar ]
		else
			debugger #else should never occur


module.exports = BspNode