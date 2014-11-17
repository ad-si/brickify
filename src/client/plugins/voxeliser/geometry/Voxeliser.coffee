class Voxeliser
	constructor: () ->
		@hull_voxels = []
		@mightbe_hull_voxels = []
		@innervoxels = []
		@bricksystem = null
		#for z in [-70...70]
		#  @grid[z] = new Array(200)
		#  for y in [-25...25]
		#    @grid[z][y] = new Array(200)
		#    for x in [-25...25]
		#      @grid[z][y][x] = null


	voxelise: (object, @bricksystem) ->
		#@progress = ProgressBar.span()
		@hull_voxels = []
		@mightbe_hull_voxels = []
		@innervoxels = []
		@hull_list = {}
		@box = object.get_BoundaryBox()
		grid = new BrickSpaceGrid( object.get_BoundaryBox(), @bricksystem)
		window.grid = grid

		count = 0
		# shell bricks
		#@progress.set_total object.polygons.length

		for polygon in object.polygons
			count++
			cuts_list = []

			polygon.tag.set_Label('child_polygons', [])
			@.slicePolygon(polygon, cuts_list)
			#@progress.update_one()

			dx = 0
			dy = 0
			dz = 0

			if polygon.points[0].x % @bricksystem.width == 0 and -Tolerances.float <= polygon.plane.normal.y <= Tolerances.float and -Tolerances.float <= polygon.plane.normal.z <= Tolerances.float # x co-aligned
				if polygon.plane.normal.x > 0
					dx = -1

			if polygon.points[0].y % @bricksystem.depth == 0 and -Tolerances.float <= polygon.plane.normal.x <= Tolerances.float and -Tolerances.float <= polygon.plane.normal.z <= Tolerances.float # x co-aligned
				if polygon.plane.normal.y > 0
					dy = -1

			if polygon.points[0].z % @bricksystem.height == 0 and -Tolerances.float <= polygon.plane.normal.y <= Tolerances.float and -Tolerances.float <= polygon.plane.normal.x <= Tolerances.float # x co-aligned
				if polygon.plane.normal.z > 0
					dz = -1

			for cut in cuts_list
				x = cut.position[0] + dx
				y = cut.position[1] + dy
				z = cut.position[2] + dz
				brickspace = grid.get_BrickSpace_global_for x, y, z
				brickspace.inner = no
				cutted_polygon = brickspace.pre_model.add_Polygon_by cut.points, cut.polygon.plane
				cutted_polygon.tag.set_Label('original_polygon', polygon)
				polygon.tag.child_polygons.add {brickspace: brickspace, polygon: cutted_polygon}

		#inner Bricks

		for x in [0..grid.brick_extend.x]
			for y in [0..grid.brick_extend.y]
				column = grid.grid[x][y]
				range = column.range
				if range.minZ? and range.minZ != range.maxZ
					if range.maxZ - range.minZ + 1 > range.bricks.length # check posible hollow bricks
						r_x = (x + grid.brick_position.x - 0.61) * @bricksystem.width
						r_y = (y + grid.brick_position.y - 0.335) * @bricksystem.depth
						r_z = grid.extend.z + 100
						ray = new Ray( new Vector3D(r_x, r_y, r_z), new Vector3D(0,0,-1) )
						#m = ray.build_Debug_Support()
						#window.editor.workspace.canvas.scene.add m

						inside = no
						for z in [column.range.minZ .. column.range.maxZ]
							brick = grid.grid[x][y][z]
							#console.log brick
							if brick
								counts = ray.intersects_with_cutted_Brick brick
								#console.log counts
								if counts % 2 == 1
									inside = !inside
							else if inside
								#console.log 'hit'
								inner_brick = grid.get_BrickSpace_for(x,y,z)
								inner_brick.inner = yes

		grid.update_Inner_Relation()
		#window.editor.workspace.canvas.scene.add grid.get_SceneModel()
		#object.remove_SceneModel()
		#window.editor.workspace.canvas.update()

		grid



	slice_Object: (solidObject) ->
		cuts = []
		for polygon in solidObject.polygons
			cuts.push @.slicePolygon(polygon)
		cuts

	slicePolygon: (polygon, cuts_list) ->
		point_list = []

		for point in polygon.points
			point_list.push [point.x, point.y, point.z]

		@sliceX(point_list, polygon, cuts_list)
		#console.log list
		###for lx in list
			for ly in lx
				@.display_cuts ly
		###


	display_cuts: (list) ->

		for pa in list
			if pa.length > 0
				obj = new SolidObject3D()
				pot = []
				n = obj.get_Normal(0,0,1)
				for pi in pa
					pot.push obj.get_Point(pi[0],pi[1],pi[2])
				obj.add_Polygon_for(pot, n)
				editor.workspace.canvas.add_Object3D obj

	sliceX: (points, original_polygon, cuts_list) ->
		current_Slice = []
		next_Slice = []

		minX = points[0][0]
		maxX = points[0][0]
		for point in points
			minX = point[0] if point[0] < minX
			maxX = point[0] if point[0] > maxX

		minX = Math.floor(minX / @bricksystem.width) + 1
		maxX = Math.ceil(maxX / @bricksystem.width) + 1

		working = points
		x = minX

		while x <= maxX and working.length > 0
			threshold =  x * @bricksystem.width

			last = working[working.length - 1]
			behind_count = 0
			on_count = 0
			for point in working
				behind = last[0] < threshold # if previous point was behind
				if point[0] < threshold # self behind
					if !behind
						dy = last[1] - point[1]
						dz = last[2] - point[2]
						f = (threshold - point[0]) / (last[0] - point[0])
						pt = [threshold, dy * f + point[1], dz * f + point[2]]
						if last[0] != threshold
							next_Slice.push pt
						current_Slice.push pt
						
					current_Slice.push point
				else  # front
					if behind
						dy = point[1] - last[1]
						dz = point[2] - last[2]
						f = (threshold - last[0]) / (point[0] - last[0])
						pt = [ threshold, dy * f + last[1], dz * f + last[2]]
						if point[0] != threshold
							next_Slice.push pt
						current_Slice.push pt

					behind_count++
					if point[0] == threshold
						on_count++

					next_Slice.push point

				last = point

			#list.push current_Slice
			if current_Slice.length > 2
				@.sliceY(current_Slice, original_polygon, x, cuts_list)
			if next_Slice.length > 2 and behind_count > on_count
				working = next_Slice
			else
				working = []
			next_Slice = []

			current_Slice = []
			x++

	sliceY: (points, original_polygon, x, cuts_list) ->
		current_Slice = []
		next_Slice = []

		minY = maxY = points[0][1]
		for point in points
			minY = point[1] if point[1] < minY
			maxY = point[1] if point[1] > maxY

		minY = Math.floor(minY / @bricksystem.depth) + 1
		maxY = Math.ceil(maxY / @bricksystem.depth) + 1

		working = points
		y = minY


		while y <= maxY and working.length > 0
			threshold =  y * @bricksystem.depth

			last = working[working.length - 1]
			behind_count = 0
			on_count = 0
			for point in working
				behind = last[1] < threshold # if previous point was behind
				if point[1] < threshold # self behind
					if !behind
						dx = last[0] - point[0]
						dz = last[2] - point[2]
						f = (threshold - point[1]) / (last[1] - point[1])
						pt = [dx * f + point[0], threshold, dz * f + point[2]]
						if last[1] != threshold
							next_Slice.push pt
						current_Slice.push pt

					current_Slice.push point
				else  # front
					if behind
						dx = point[0] - last[0]
						dz = point[2] - last[2]
						f = (threshold - last[1]) / (point[1] - last[1])
						pt = [ dx * f + last[0], threshold, dz * f + last[2]]
						if point[1] != threshold
							next_Slice.push pt
						current_Slice.push pt

					behind_count++
					if point[1] == threshold
						on_count++

					next_Slice.push point

				last = point
			
			#list.push current_Slice
			if (current_Slice.length > 2)
				@.sliceZ(current_Slice, original_polygon, x, y, cuts_list)
			if next_Slice.length > 2 and behind_count > on_count
				working = next_Slice
			else
				working = []
			next_Slice = []

			current_Slice = []
			y++

	sliceZ: (points, original_polygon, x, y, cuts_list) ->
		current_Slice = []
		next_Slice = []

		minZ = maxZ = points[0][2]
		for point in points
			minZ = point[2] if point[2] < minZ
			maxZ = point[2] if point[2] > maxZ

		minZ = Math.floor(minZ / @bricksystem.height) + 1
		maxZ = Math.ceil(maxZ / @bricksystem.height) + 1

		working = points
		z = minZ

		while z <= maxZ and working.length > 0
			next_Slice = []
			threshold =  z * @bricksystem.height

			last = working[working.length - 1]
			behind_count = 0
			on_count = 0
			for point in working
				behind = last[2] < threshold # if previous point was behind
				if point[2] < threshold # self behind
					if !behind
						dx = last[0] - point[0]
						dy = last[1] - point[1]
						f = (threshold - point[2]) / (last[2] - point[2])
						pt = [dx * f + point[0], dy * f + point[1], threshold]
						if last[2] != threshold
							next_Slice.push pt
						current_Slice.push pt

					current_Slice.push point
				else  # front
					if behind
						dx = point[0] - last[0]
						dy = point[1] - last[1]
						f = (threshold - last[2]) / (point[2] - last[2])
						pt = [ dx * f + last[0], dy * f + last[1], threshold]
						if point[2] != threshold
							next_Slice.push pt
						current_Slice.push pt
					
					behind_count++
					if point[2] == threshold
						on_count++

					next_Slice.push point
				
				last = point

			if (current_Slice.length > 2)
				cuts_list.push {position: [x,y,z], points: current_Slice, polygon: original_polygon } if current_Slice.length > 0

			if next_Slice.length > 2 and behind_count > on_count
				working = next_Slice
			else
				working = []
			current_Slice = []
			z++

###
plane = new Plane(new Vector3D(0,-1,0), 0 );
polygon = new Polygon([new Vector3D(32,32,0),new Vector3D(0,0,0),new Vector3D(0,32,0)],plane);
v = new Voxeliser();
v.bricksystem = LegoPlate;
r = [];
v.slicePolygon(polygon, r);


		var code = "while(true){}";

		function makeWorker(script) {
				var URL = window.URL || window.webkitURL;
				var Blob = window.Blob;
				var Worker = window.Worker;
				
				if (!URL || !Blob || !Worker || !script) {
						return null;
				}
				
				var blob = new Blob([script]);
				var worker = new Worker(URL.createObjectURL(blob));
				return worker;
		}


		makeWorker(code);
###

module.exports = Voxeliser