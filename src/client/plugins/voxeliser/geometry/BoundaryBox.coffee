# BoundaryBox = require './BoundaryBox'
# BspNode = require './BspNode'
# BspTree = require './BspTree'
# Edge = require './Edge'
# Mesh = require './Mesh'
Object3D = require './Object3D'
# Plane = require './Plane'
# Point = require './Point'
# Polygon = require './Polygon'
# Ray = require './Ray'
# Slicer = require './Slicer'
# SolidObject3D = require './SolidObject3D'
# Tag = require './Tag'
# Vector3D = require './Vector3D'

# Brick = require '../Bricks/Brick'
# BrickGrid = require '../Bricks/BrickGrid'
# BrickGroup = require '../Bricks/BrickGroup'
# BrickInstruction = require '../Bricks/BrickInstruction'
# BrickLayout = require '../Bricks/BrickLayout'
# BrickLayouter = require '../Bricks/BrickLayouter'
# BrickSpace = require '../Bricks/BrickSpace'
# BrickSpaceGrid = require '../Bricks/BrickSpaceGrid'
# BrickSystem = require '../Bricks/BrickSystem'
# BrickSystems = require '../Bricks/BrickSystems'
# BrickType = require '../Bricks/BrickType'
# CustomBrick = require '../Bricks/CustomBrick'
# IterationInstruction = require '../Bricks/IterationInstruction'

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
		@minPoint.x = ( Math.floor(@minPoint.x / bricksystem.width ) * bricksystem.width )
		@minPoint.y = ( Math.floor(@minPoint.y / bricksystem.depth ) * bricksystem.depth )
		@minPoint.z = ( Math.floor(@minPoint.z / bricksystem.height ) * bricksystem.height )

		@maxPoint.x = ( Math.ceil(@maxPoint.x / bricksystem.width ) * bricksystem.width)
		@maxPoint.y = ( Math.ceil(@maxPoint.y / bricksystem.depth ) * bricksystem.depth )
		@maxPoint.z = ( Math.ceil(@maxPoint.z / bricksystem.height ) * bricksystem.height )
		@

	voxelize_to: () ->
		voxels = new Array()

		dim = @.get_LegoDimension()

		for y in [0...dim.y] by 1
			voxels[y] = new Array()
			for z in [0...dim.z] by 1
				voxels[y][z] = new Array()
				for x in [0...dim.x] by 1
					x_value = @minX + x * Lego.width
					y_value = @minY + y * Lego.height
					z_value = @minZ + z * Lego.width
					voxels[y][z][x] = new BoundaryBox(x_value, y_value, z_value, x_value + Lego.width, y_value + Lego.height, z_value + Lego.width )
		voxels

	build_Lego: (top = yes, bottom = yes, front, back, left, right) ->
		# building points
		points = [
					new CSG.Vector( @minX, @minY, @minZ ),
					new CSG.Vector( @maxX, @minY, @minZ ),
					new CSG.Vector( @maxX, @minY, @maxZ ),
					new CSG.Vector( @minX, @minY, @maxZ ),
					new CSG.Vector( @minX, @maxY, @minZ ),
					new CSG.Vector( @maxX, @maxY, @minZ ),
					new CSG.Vector( @maxX, @maxY, @maxZ ),
					new CSG.Vector( @minX, @maxY, @maxZ ) ]

		middle_point = { x: (@minX + @maxX) / 2, y: (@minY + @maxY) / 2, z: (@minZ + @maxZ) / 2 }

		circle_steps = 30

		circle_top = []
		for angle in [0..360] by circle_steps
			circle_top.push new CSG.Vector( middle_point.x + Math.sin(angle * Math.PI / 180.0) * Lego.knob_radius , @maxY, middle_point.z + Math.cos(angle * Math.PI / 180.0) * Lego.knob_radius)

		circle_cap = []
		for angle in [0..360] by circle_steps
			circle_cap.push new CSG.Vector( middle_point.x + Math.sin(angle * Math.PI / 180.0) * Lego.knob_radius , @maxY + Lego.knob_height, middle_point.z + Math.cos(angle * Math.PI / 180.0) * Lego.knob_radius)

		circle_bottom = []
		for angle in [360..0] by -circle_steps
			circle_bottom.push new CSG.Vector( middle_point.x + Math.sin(angle * Math.PI / 180.0) * Lego.knob_radius , @minY, middle_point.z + Math.cos(angle * Math.PI / 180.0) * Lego.knob_radius)

		circle_inlet = []
		for angle in [360..0] by -circle_steps
			circle_inlet.push new CSG.Vector( middle_point.x + Math.sin(angle * Math.PI / 180.0) * Lego.knob_radius , @minY + Lego.knob_height, middle_point.z + Math.cos(angle * Math.PI / 180.0) * Lego.knob_radius)

		#build faces
		#faces = []

		faces  = [ [ [ points[0], points[4], points[5], points[1] ], new CSG.Vector( 0, 0,-1), {origin: ['lego'], side: '-z'} ],
							 [ [ points[3], points[2], points[6], points[7] ], new CSG.Vector( 0, 0, 1), {origin: ['lego'], side: '+z'} ],
							 [ [ points[0], points[3], points[7], points[4] ], new CSG.Vector(-1, 0, 0), {origin: ['lego'], side: '-x'} ],
							 [ [ points[2], points[1], points[5], points[6] ], new CSG.Vector( 1, 0, 0), {origin: ['lego'], side: '+x'} ] ]

		point_per_segement = 360 / circle_steps / 4

		top_points = [points[6],points[5],points[4],points[7] ]

		bottom_points = [points[3],points[0],points[1],points[2] ]

		# knob faces

		top_faces = []
		cap_faces = []

		bottom_faces = []
		inlet_faces = []

		old_top_edge = points[7]
		old_bottom_edge = points[2]


		for side in [0...4]
			edge_top_point = top_points[side]
			edge_bottom_point = bottom_points[side]

			old_top_point = circle_top[ side * point_per_segement ]
			old_cap_point = circle_cap[ side * point_per_segement ]

			old_bottom_point = circle_bottom[ side * point_per_segement ]
			old_inlet_point = circle_inlet[ side * point_per_segement ]

			top_faces.push [ [ old_top_edge, edge_top_point , old_top_point ], new CSG.Vector( 0,1, 0), {origin: ['lego'], side: '+y'} ]
			bottom_faces.push [ [ old_bottom_edge, edge_bottom_point , old_bottom_point ], new CSG.Vector( 0,-1, 0), {origin: ['lego'], side: '-y'} ]

			for point in [side * point_per_segement + 1 .. (side + 1) * point_per_segement]
				current_top_point = circle_top[point]
				current_cap_point = circle_cap[point]
				current_bottom_point = circle_bottom[point]
				current_inlet_point = circle_inlet[point]

				top_faces.push [ [ current_top_point, old_top_point, edge_top_point ], new CSG.Vector( 0, 1, 0), {origin: ['lego'], side: '+y'} ]
				cap_faces.push [ [ current_top_point, current_cap_point, old_cap_point, old_top_point ], null, {origin: ['lego'], side: '+y'} ]

				bottom_faces.push [ [ current_bottom_point, old_bottom_point, edge_bottom_point ], new CSG.Vector( 0, -1, 0), {origin: ['lego'], side: '-y'} ]
				inlet_faces.push [ [ current_bottom_point, current_inlet_point, old_inlet_point, old_bottom_point ], null, {origin: ['lego'], side: '-y'} ]


				old_top_point = circle_top[point]
				old_cap_point = circle_cap[point]
				old_bottom_point = circle_bottom[point]
				old_inlet_point = circle_inlet[point]

			old_top_edge = edge_top_point
			old_bottom_edge = edge_bottom_point

		###if top
			something
		else
			faces.push [ [ points[2], points[1], points[5], points[6] ], new CSG.Vector( 1, 0, 0), {origin: ['cut'], axis: 'x', vec: 1 } ]

		if bottom
			something
		else
			faces.push [ [ points[0], points[3], points[7], points[4] ], new CSG.Vector(-1, 0, 0), {origin: ['cut'], axis: 'x', vec: -1} ]
		###

		faces.push [ circle_cap[0...circle_cap.length - 1], new CSG.Vector( 0,1, 0), {origin: ['lego'], side: '+y'} ]
		faces.merge bottom_faces
		faces.push [ circle_inlet[0...circle_inlet.length - 1], new CSG.Vector( 0,1, 0), {origin: ['lego'], side: '-y'} ]
		faces.merge top_faces

		faces.merge cap_faces
		faces.merge inlet_faces

		# Build Polygons

		cal_normal = (a, b, c) ->
			b.minus(a).cross( c.minus(a) ).unit()

		polys = []
		for face in faces
			normal = face[1]
			normal ?= cal_normal( face[0][0], face[0][1], face[0][2])
			#vex = []
			#for vec in face[0]
			#  vex.push( new CSG.Vertex( vec, normal) )
			vex = ( new CSG.Vertex( vec, normal) for vec in face[0] )
			polys.push( new CSG.Polygon(vex, face[2]) )

		obj = new Object3D( CSG.fromPolygons(polys) )
		obj.box = @
		obj

	build_Box: () ->
		points = [
					new CSG.Vector( @minX, @minY, @minZ ),
					new CSG.Vector( @maxX, @minY, @minZ ),
					new CSG.Vector( @maxX, @minY, @maxZ ),
					new CSG.Vector( @minX, @minY, @maxZ ),
					new CSG.Vector( @minX, @maxY, @minZ ),
					new CSG.Vector( @maxX, @maxY, @minZ ),
					new CSG.Vector( @maxX, @maxY, @maxZ ),
					new CSG.Vector( @minX, @maxY, @maxZ ) ]

		faces  = [ [ [ points[0], points[1], points[2], points[3] ], new CSG.Vector( 0,-1, 0), {origin: ['cut'], axis: 'x', vec: -1} ],
							 [ [ points[7], points[6], points[5], points[4] ], new CSG.Vector( 0, 1, 0), {origin: ['cut'], axis: 'x', vec: 1} ],
							 [ [ points[0], points[4], points[5], points[1] ], new CSG.Vector( 0, 0,-1), {origin: ['cut'], axis: 'z', vec: -1} ],
							 [ [ points[3], points[2], points[6], points[7] ], new CSG.Vector( 0, 0, 1), {origin: ['cut'], axis: 'z', vec: 1} ],
							 [ [ points[0], points[3], points[7], points[4] ], new CSG.Vector(-1, 0, 0), {origin: ['cut'], axis: 'x', vec: -1} ],
							 [ [ points[2], points[1], points[5], points[6] ], new CSG.Vector( 1, 0, 0), {origin: ['cut'], axis: 'x', vec: 1 } ] ]

		polys = []
		for face in faces
			vex = []
			for vec in face[0]
				vex.push( new CSG.Vertex( vec, face[1] ) )
			polys.push( new CSG.Polygon(vex, face[2]) )

		new Object3D( CSG.fromPolygons(polys) )

###
+ --->x
| 0-1
| 3-2
y
###

module.exports = BoundaryBox
