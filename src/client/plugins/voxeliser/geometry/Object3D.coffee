# BoundaryBox = require './BoundaryBox'
# BspNode = require './BspNode'
# BspTree = require './BspTree'
Edge = require './Edge'
# Mesh = require './Mesh'
# Object3D = require './Object3D'
# Plane = require './Plane'
Point = require './Point'
Polygon = require './Polygon'
# Ray = require './Ray'
# Slicer = require './Slicer'
# SolidObject3D = require './SolidObject3D'
# Tag = require './Tag'
Vector3D = require './Vector3D'

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

class Object3D
	constructor: () ->
		@points = []
		@point_lookup = {}
		@edges = []
		@edges_lookup = {}
		@normal_lookup = {}
		@polygons = []
		@scene_model = null
		@scene_model_edges = null
		@ref_point = new Vector3D(0,0,0)


#  ########   #######  #### ##    ## ########     #######  ########  ######## ########     ###    ######## ####  #######  ##    ##  ######
#  ##     ## ##     ##  ##  ###   ##    ##       ##     ## ##     ## ##       ##     ##   ## ##      ##     ##  ##     ## ###   ## ##    ##
#  ##     ## ##     ##  ##  ####  ##    ##       ##     ## ##     ## ##       ##     ##  ##   ##     ##     ##  ##     ## ####  ## ##
#  ########  ##     ##  ##  ## ## ##    ##       ##     ## ########  ######   ########  ##     ##    ##     ##  ##     ## ## ## ##  ######
#  ##        ##     ##  ##  ##  ####    ##       ##     ## ##        ##       ##   ##   #########    ##     ##  ##     ## ##  ####       ##
#  ##        ##     ##  ##  ##   ###    ##       ##     ## ##        ##       ##    ##  ##     ##    ##     ##  ##     ## ##   ### ##    ##
#  ##         #######  #### ##    ##    ##        #######  ##        ######## ##     ## ##     ##    ##    ####  #######  ##    ##  ######


	# checks whether a point is contained in the object. If so the point is returned.
	# If not undefined.
	# @param x [float] the x coordinate
	# @param y [float] the y coordinate
	# @param z [float] the z coordinate
	# @return [Point] the requested point or undefined
	check_Point: (x, y, z) ->
		if @point_lookup[x] and @point_lookup[x][y]
			@point_lookup[x][y][z]
		else
			undefined

	# Gets the specified point from the Object. If the Object doesn't contain this point,
	# the point is added and returned
	# @param x [float] the x coordinate
	# @param y [float] the y coordinate
	# @param z [float] the z coordinate
	# @return [Point] the requested point
	get_Point: (x, y, z) ->
		if point = @check_Point x, y, z
			point
		else
			@set_Point x, y, z

	# Adds the specific point to the Object
	# @param x [float] the x coordinate
	# @param y [float] the y coordinate
	# @param z [float] the z coordinate
	# @return [Point] the requested point
	set_Point: (x, y, z) ->
		point = new Point x, y, z

		# since we add the point afterwards @points.length is also
		# the index of the point in @points
		point.set_Object @, @points.length
		@points.push point

		@point_lookup[x] ?= {}
		@point_lookup[x][y] ?= {}
		@point_lookup[x][y][z] = point


#  ######## ########   ######   ########     #######  ########  ######## ########     ###    ######## ####  #######  ##    ##  ######
#  ##       ##     ## ##    ##  ##          ##     ## ##     ## ##       ##     ##   ## ##      ##     ##  ##     ## ###   ## ##    ##
#  ##       ##     ## ##        ##          ##     ## ##     ## ##       ##     ##  ##   ##     ##     ##  ##     ## ####  ## ##
#  ######   ##     ## ##   #### ######      ##     ## ########  ######   ########  ##     ##    ##     ##  ##     ## ## ## ##  ######
#  ##       ##     ## ##    ##  ##          ##     ## ##        ##       ##   ##   #########    ##     ##  ##     ## ##  ####       ##
#  ##       ##     ## ##    ##  ##          ##     ## ##        ##       ##    ##  ##     ##    ##     ##  ##     ## ##   ### ##    ##
#  ######## ########   ######   ########     #######  ##        ######## ##     ## ##     ##    ##    ####  #######  ##    ##  ######

	check_Edge: (point1, point2) ->
		if @edges_lookup[point1.x] and @edges_lookup[point1.x][point1.y] and @edges_lookup[point1.x][point1.y][point1.z] and @edges_lookup[point1.x][point1.y][point1.z][point2.x] and @edges_lookup[point1.x][point1.y][point1.z][point2.x][point2.y]
			@edges_lookup[point1.x][point1.y][point1.z][point2.x][point2.y][point2.z]
		else
			undefined

	get_Edge: (point1, point2) ->
		if edge = @check_Edge point1, point2
			edge
		else
			@set_Edge point1, point2

	set_Edge: (point1, point2) ->
		edge = new Edge point1, point2
		@edges.push edge
		@edges_lookup[point1.x] ?= {}
		@edges_lookup[point1.x][point1.y] ?= {}
		@edges_lookup[point1.x][point1.y][point1.z] ?= {}
		@edges_lookup[point1.x][point1.y][point1.z][point2.x] ?= {}
		@edges_lookup[point1.x][point1.y][point1.z][point2.x][point2.y] ?= {}
		@edges_lookup[point2.x] ?= {}
		@edges_lookup[point2.x][point2.y] ?= {}
		@edges_lookup[point2.x][point2.y][point2.z] ?= {}
		@edges_lookup[point2.x][point2.y][point2.z][point1.x] ?= {}
		@edges_lookup[point2.x][point2.y][point2.z][point1.x][point1.y] ?= {}
		@edges_lookup[point1.x][point1.y][point1.z][point2.x][point2.y][point2.z] = @edges_lookup[point2.x][point2.y][point2.z][point1.x][point1.y][point1.z] = edge


#  ##    ##  #######  ########  ##     ##    ###    ##           #######  ########  ######## ########     ###    ######## ####  #######  ##    ##  ######
#  ###   ## ##     ## ##     ## ###   ###   ## ##   ##          ##     ## ##     ## ##       ##     ##   ## ##      ##     ##  ##     ## ###   ## ##    ##
#  ####  ## ##     ## ##     ## #### ####  ##   ##  ##          ##     ## ##     ## ##       ##     ##  ##   ##     ##     ##  ##     ## ####  ## ##
#  ## ## ## ##     ## ########  ## ### ## ##     ## ##          ##     ## ########  ######   ########  ##     ##    ##     ##  ##     ## ## ## ##  ######
#  ##  #### ##     ## ##   ##   ##     ## ######### ##          ##     ## ##        ##       ##   ##   #########    ##     ##  ##     ## ##  ####       ##
#  ##   ### ##     ## ##    ##  ##     ## ##     ## ##          ##     ## ##        ##       ##    ##  ##     ##    ##     ##  ##     ## ##   ### ##    ##
#  ##    ##  #######  ##     ## ##     ## ##     ## ########     #######  ##        ######## ##     ## ##     ##    ##    ####  #######  ##    ##  ######

	check_Normal: (x, y, z) ->
		if @normal_lookup[x] and @normal_lookup[x][y]
			@normal_lookup[x][y][z]
		else
			undefined

	get_Normal_for: (point_A, point_B, point_C) ->
		normal = ( point_A.to point_B ).cross( point_A.to point_C ).normalize().round_Tolerances()
		@get_Normal normal.x, normal.y, normal.z

	get_Normal: (x, y, z) ->
		if normal = @check_Normal x, y, z
			normal
		else
			@set_Normal x, y, z

	set_Normal: (x, y, z) ->
		normal = new Vector3D(x,y,z)

		@normal_lookup[x] ?= {}
		@normal_lookup[x][y] ?= {}
		@normal_lookup[x][y][z] = normal


#  ########   #######  ##       ##    ##  ######    #######  ##    ##
#  ##     ## ##     ## ##        ##  ##  ##    ##  ##     ## ###   ##
#  ##     ## ##     ## ##         ####   ##        ##     ## ####  ##
#  ########  ##     ## ##          ##    ##   #### ##     ## ## ## ##
#  ##        ##     ## ##          ##    ##    ##  ##     ## ##  ####
#  ##        ##     ## ##          ##    ##    ##  ##     ## ##   ###
#  ##         #######  ########    ##     ######    #######  ##    ##

	add_Polygon: (polygon) ->
		if !polygon.object
			polygon.set_Object @
			@polygons.push polygon
		else if polygon.object == @
			@polygons.add_unique polygon
		else
			polygon = @.copy_foreign_Polygon polygon
		polygon

	copy_foreign_Polygon: (polygon) ->
		normal = polygon.plane.normal
		normal = @.get_Normal normal.x, normal.y, normal.z

		plane = new Plane(normal, polygon.plane.lambda)

		points = []
		for point in polygon.points
			points.push @.get_Point point.x, point.y, point.z

		edges = []
		last = points.last()

		for point in points
			edges.push @.get_Edge(last, point)
			last = point

		new_polygon = new Polygon points, plane, edges
		@add_Polygon new_polygon

	add_Polygon_for: (points, normal, tag) ->
		edges = []
		plane = Plane.by_Origin points[0], normal if normal
		#plane ?= Plane.by_Points points[0], points[1], points[2]
		last = points[points.length - 1]

		for point in points
			edge = @.get_Edge(last, point)
			edges.push edge
			last = point

		polygon = new Polygon points, plane, edges
		if tag
			tag.parentPolygon = @
			polygon.tag.set_Labels_of tag
		@add_Polygon polygon

	add_Polygon_by: (pointlist, plane) ->
		edges = []
		last_point_entry = pointlist[pointlist.length - 1]
		last =  @.get_Point(last_point_entry[0],last_point_entry[1],last_point_entry[2])
		points = []

		for point_entry in pointlist
			point = @.get_Point(point_entry[0],point_entry[1],point_entry[2])
			edge = @get_Edge(last, point)
			points.push point
			edges.push edge
			last = point

		@add_Polygon new Polygon points, plane, edges

	set_Polygon_Ids: () ->
		for polygon, index in @polygons
			polygon.set_Id index

	get_Polygon_by_Index: (index) ->
		@polygons[index]

#   ######   ######  ######## ##    ## ######## ##     ##  #######  ########  ######## ##
#  ##    ## ##    ## ##       ###   ## ##       ###   ### ##     ## ##     ## ##       ##
#  ##       ##       ##       ####  ## ##       #### #### ##     ## ##     ## ##       ##
#   ######  ##       ######   ## ## ## ######   ## ### ## ##     ## ##     ## ######   ##
#        ## ##       ##       ##  #### ##       ##     ## ##     ## ##     ## ##       ##
#  ##    ## ##    ## ##       ##   ### ##       ##     ## ##     ## ##     ## ##       ##
#   ######   ######  ######## ##    ## ######## ##     ##  #######  ########  ######## ########

	update_SceneModel: () ->
		if @scene_model?
			parent = @scene_model.parent
			@.remove_SceneModel()
			parent.add @scene_model = @.build_SceneModel()

	get_SceneModel: () ->
		@scene_model ?= @.build_SceneModel()

	remove_SceneModel: () ->
		@scene_model.parent.remove @scene_model if @scene_model?

	delete_SceneModel: () ->
		@scene_model = null
		#toDo deallocate

	update_Edge_SceneModel: () ->
		if @scene_model?
			@scene_model.remove @scene_model_edges
			@scene_model_edges = @.build_Edge_SceneModel()
			@scene_model.add @scene_model_edges


	get_Edge_SceneModel: () ->
		@scene_model_edges ?= @.build_Edge_SceneModel()

	build_Edge_SceneModel: () ->
		edge_geometry = new THREE.Geometry()
		edge_material = new THREE.LineBasicMaterial( { color: new THREE.Color( 0x000000 ), linewidth: 2, wireframe: true} )

		for edge in @edges
			edge.check_Visibility()
			if edge.hard_edge
				edge_geometry.vertices.push edge.from_point
				edge_geometry.vertices.push edge.to_point

		lines = new THREE.Line(edge_geometry, edge_material)
		lines.type = THREE.LinePieces
		lines


	get_Volume: () ->
		vol = 0
		for polygon in @polygons
			vol += polygon.calculate_Volume()
		vol


module.exports = Object3D