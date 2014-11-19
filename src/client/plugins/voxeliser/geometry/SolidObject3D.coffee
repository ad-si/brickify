Object3D = require './Object3D'
Plane = require './Plane'
Polygon = require './Polygon'
Point = require './Point'
Mesh = require './Mesh'
Edge = require './Edge'
BoundaryBox = require './BoundaryBox'
Vector3D = require './Vector3D'
ColorPalette = require '../rendering/ColorPalette'

# Base class for all three-dimentional Objects.
class SolidObject3D extends Object3D
	constructor: () ->
		super()
		@model = null
		@hyperplanes = []
		@hyperplanes_lookup = {}
		@sides = {}
		@boundaryBox = null
		@color = ColorPalette.default()
		@reverse_Scene_Model = null
		@edge_threshold = null
		@selection_group = []

#  ##     ## ##    ## ########  ######## ########  ########  ##          ###    ##    ## ########
#  ##     ##  ##  ##  ##     ## ##       ##     ## ##     ## ##         ## ##   ###   ## ##
#  ##     ##   ####   ##     ## ##       ##     ## ##     ## ##        ##   ##  ####  ## ##
#  #########    ##    ########  ######   ########  ########  ##       ##     ## ## ## ## ######
#  ##     ##    ##    ##        ##       ##   ##   ##        ##       ######### ##  #### ##
#  ##     ##    ##    ##        ##       ##    ##  ##        ##       ##     ## ##   ### ##
#  ##     ##    ##    ##        ######## ##     ## ##        ######## ##     ## ##    ## ########

	check_Hyperplane: (x, y, z, w) ->
		if @hyperplanes_lookup[x] and @hyperplanes_lookup[x][y] and @hyperplanes_lookup[x][y][z]
			@hyperplanes_lookup[x][y][z][w]
		else
			undefined

	get_Hyperplane: (x, y, z, w) ->
		if plane = @check_Hyperplane x, y, z, w
			plane = @check_Hyperplane
		else
			@set_Hyperplane x, y, z, w

	set_Hyperplane: (x, y, z, w) ->
		normal = @get_Normal x, y, z

		@hyperplanes_lookup[normal] ?= {}
		@hyperplanes_lookup[normal][w] = new Plane(normal, w)

	check_Model: () ->
		for edge in @edges
			edge.check_Visibility()


#   ######   ######  ######## ##    ## ######## ##     ##  #######  ########  ######## ##
#  ##    ## ##    ## ##       ###   ## ##       ###   ### ##     ## ##     ## ##       ##
#  ##       ##       ##       ####  ## ##       #### #### ##     ## ##     ## ##       ##
#   ######  ##       ######   ## ## ## ######   ## ### ## ##     ## ##     ## ######   ##
#        ## ##       ##       ##  #### ##       ##     ## ##     ## ##     ## ##       ##
#  ##    ## ##    ## ##       ##   ### ##       ##     ## ##     ## ##     ## ##       ##
#   ######   ######  ######## ##    ## ######## ##     ##  #######  ########  ######## ########

	select_Polygons: (polygons) ->
		for polygon in polygons
			polygon.set_Color new THREE.Color(0xFF0000)
		@.update_Color()

	set_Defaut_Color_for: (polygons) ->
		for polygon in polygons
			polygon.reset_Color()
		@.update_Color()

	update_Color: () ->
		@scene_model.geometry.colorsNeedUpdate = yes if @scene_model


	get_BoundaryBox: () ->
		@boundaryBox ?= BoundaryBox.create_from @

	lift_Model_onPlattform: () ->
		@.move_by new Vector3D 0, 0, -(@.get_BoundaryBox().minPoint.z)
		@boundaryBox = null

	center_Model: () ->
		center = @.get_BoundaryBox().get_CenterPoint()
		@.move_by new Vector3D -center.x, -center.y, 0
		@boundaryBox = null

	move_by: (vector) ->
		for point in @points
			point.move_by vector

		for polygon in @polygons
			polygon.plane.move_by vector

		if @scene_model
			@scene_model.geometry.verticesNeedUpdate = yes
			for child in @scene_model.children
				child.geometry.verticesNeedUpdate = yes

	update_FaceGroups: () ->
		for edge in @edges
			edge.check_Visibility(@edge_threshold)

		ungrouped = @polygons.clone()
		groups = []
		while ungrouped.length > 0
			groups.push @.find_selectionGroup( ungrouped.pop(), ungrouped )

		for group in groups
			all_edges = []
			for polygon in group
				for edge in polygon.edges
					neighbor = edge.get_Neighbor_of polygon
					if group.includes neighbor
						edge.hard_edge = no

	find_selectionGroup: (polygon, ungrouped) ->
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

	set_Edge_Threshold: (@edge_threshold) ->
		@.update_Edge_SceneModel()


	build_SceneModel: (with_Edges = yes) ->

		geometry = new THREE.Geometry()

		# WebGL Render delete Butter
		# var deleteBuffers = function ( geometry ) {
		# var deallocateGeometry = function ( geometry ) {

		#material = new THREE.MeshPhongMaterial( { color: @color.specular, ambient: @color.base, opacity: 1.0, transparent: true} );
		material = new THREE.MeshPhongMaterial( { vertexColors: THREE.FaceColors, color: @color.specular, ambient: @color.base, opacity: 1.0, transparent: true} );

		#material2 = new THREE.MeshLambertMaterial( { vertexColors: THREE.VertexColors, color: @color.specular, ambient: @color.base, opacity: 1.0, transparent: true} );

		phongShader = THREE.ShaderLib.phong
		uniforms = THREE.UniformsUtils.clone(phongShader.uniforms);

		#material.uniforms = uniforms;
		#material.vertexShader = document.getElementById( 'vertexShader2' ).textContent;
		#material.fragmentShader = document.getElementById( 'fragmentShader2' ).textContent;


		#material = new THREE.ShaderMaterial( );


		###material = new THREE.ShaderMaterial({
			uniforms: uniforms,
			vertexShader: phongShader.vertexShader,
			fragmentShader: phongShader.fragmentShader,
			color: @color.specular,
			ambient: @color.base
		});
		###
		#material.setValues( {color: new THREE.Color( 0xffffff ), ambient: new THREE.Color( 0xffffff ), emissive: new THREE.Color( 0x000000 ), specular: new THREE.Color( 0x111111 ), shininess: 30, metal: false, perPixel: true, wrapAround: false, wrapRGB: new THREE.Vector3( 1, 1, 1 ), map: null, lightMap: null, bumpMap: null, bumpScale: 1, normalMap: null, normalScale: new THREE.Vector2( 1, 1 ), specularMap: null, envMap: null, combine: THREE.MultiplyOperation, reflectivity: 1, refractionRatio: 0.98, fog: true, shading: THREE.SmoothShading, wireframe: false, wireframeLinewidth: 1, wireframeLinecap: 'round', wireframeLinejoin: 'round', vertexColors: THREE.NoColors, skinning: false, morphTargets: false, morphNormals: false })
		#material.setValues( { uniforms: THREE.ShaderLib.phong.uniforms, vertexShader: document.getElementById( 'vertexShader2' ).textContent, fragmentShader: document.getElementById( 'fragmentShader2' ).textContent, color: @color.specular, ambient: @color.base, opacity: 1.0, transparent: true } )

		#sub_poly = (polygon for polygon in @csg.polygons when polygon.shared.tag isnt 5 and polygon.shared.tag isnt 3)
		for point in @points
			geometry.vertices.push THREE.get_Vector_for point

		for polygon in @polygons
			for face in polygon.get_RenderFaces()
				geometry.faces.push face

		@ed
		#geometry.mergeVertices()
		geometry.computeFaceNormals()
		#geometry.computeVertexNormals()

		mesh = new THREE.Mesh(geometry, material)

		if with_Edges
			edges = @.get_Edge_SceneModel()
			mesh.add edges


		mesh

	build_Edge_SceneModel: () ->
		edges = new THREE.Object3D()
		edge_geo = new THREE.Geometry()
		edge_material = new THREE.LineBasicMaterial( { color: new THREE.Color( 0x000000 ), linewidth: 2, wireframe: true} )
		triangle_geo = new THREE.Geometry()
		triangle_material = new THREE.LineBasicMaterial( { color: @color.error, linewidth: 0.5, wireframe: true} )
		broken_geo = new THREE.Geometry()
		broken_material = new THREE.LineBasicMaterial( { color: @color.error, linewidth: 3, wireframe: true} )

		@.update_FaceGroups()

		for edge in @edges
			#edge.check_Visibility(@edge_threshold)
			#if edge.broken_edge
			#  broken_geo.vertices.push THREE.get_Vector_for edge.from_point
			#  broken_geo.vertices.push THREE.get_Vector_for edge.to_point
			if edge.hard_edge
				t = (edge.inner_Polygon.plane.normal).cross(edge.from_point.to(edge.to_point)).scalar(edge.inner_Polygon.plane.normal.plus(edge.outer_Polygon.plane.normal))
				h = new Vector3D(0,0,0)
				if (t > 0)
					h = edge.inner_Polygon.plane.normal.plus(edge.outer_Polygon.plane.normal)
					r = h.length_squared() * h.length_squared()
					if r < 0.8
						r = 0.8
					h.shrink(r).times(0.3)
					#h = new Vector3D(0,0,0)
				edge_geo.vertices.push THREE.get_Vector_for (edge.from_point)
				edge_geo.vertices.push THREE.get_Vector_for (edge.to_point)
				#edge_geo.vertices.push THREE.get_Vector_for edge.from_point
				#edge_geo.vertices.push THREE.get_Vector_for edge.to_point
			else
				triangle_geo.vertices.push THREE.get_Vector_for edge.from_point
				triangle_geo.vertices.push THREE.get_Vector_for edge.to_point

		lines = new THREE.Line(edge_geo, edge_material)
		lines.type = THREE.LinePieces
		edges.add(lines)

		lines = new THREE.Line(triangle_geo, triangle_material)
		lines.type = THREE.LinePieces
		#mesh.add(lines)

		lines = new THREE.Line(broken_geo, broken_material)
		lines.type = THREE.LinePieces
		edges.add(lines)

		edges

	get_Reverse_SceneModel: () ->
		@reverse_Scene_Model ?= @build_Reverse_SceneModel()


	build_Reverse_SceneModel: () ->

		geometry = new THREE.Geometry()
		material = new THREE.MeshPhongMaterial( { vertexColors: THREE.FaceColors, color: @color.specular, ambient: @color.base, opacity: 0.3, transparent: true} )

		for point in @points
			geometry.vertices.push THREE.get_Vector_for point

		for polygon in @polygons
			for face in polygon.get_Reverse_RenderFaces()
				geometry.faces.push face

		geometry.computeFaceNormals()

		mesh = new THREE.Mesh(geometry, material)


		edge_geo = new THREE.Geometry()
		edge_material = new THREE.LineBasicMaterial( { color: new THREE.Color( 0x707070 ), linewidth: 2, wireframe: true} )
		triangle_geo = new THREE.Geometry()
		triangle_material = new THREE.LineBasicMaterial( { color: @color.error, linewidth: 0.5, wireframe: true} )
		broken_geo = new THREE.Geometry()
		broken_material = new THREE.LineBasicMaterial( { color: @color.error, linewidth: 3, wireframe: true} )

		for edge in @edges
			edge.check_Visibility()
			if edge.broken_edge
				broken_geo.vertices.push THREE.get_Vector_for edge.from_point
				broken_geo.vertices.push THREE.get_Vector_for edge.to_point
			else if edge.hard_edge
				t = (edge.inner_Polygon.plane.normal).cross(edge.from_point.to(edge.to_point)).scalar(edge.inner_Polygon.plane.normal.plus(edge.outer_Polygon.plane.normal))
				h = new Vector3D(0,0,0)
				if (t > 0)
					h = edge.inner_Polygon.plane.normal.plus(edge.outer_Polygon.plane.normal)
					r = h.length_squared() * h.length_squared()
					if r < 0.8
						r = 0.8
					h.shrink(r).times(0.3)
					#h = new Vector3D(0,0,0)
				edge_geo.vertices.push THREE.get_Vector_for (edge.from_point)
				edge_geo.vertices.push THREE.get_Vector_for (edge.to_point)
				#edge_geo.vertices.push THREE.get_Vector_for edge.from_point
				#edge_geo.vertices.push THREE.get_Vector_for edge.to_point
			else
				triangle_geo.vertices.push THREE.get_Vector_for edge.from_point
				triangle_geo.vertices.push THREE.get_Vector_for edge.to_point

		lines = new THREE.Line(edge_geo, edge_material)
		lines.type = THREE.LinePieces
		mesh.add(lines)

		lines = new THREE.Line(triangle_geo, triangle_material)
		lines.type = THREE.LinePieces
		#mesh.add(lines)

		lines = new THREE.Line(broken_geo, broken_material)
		lines.type = THREE.LinePieces
		#mesh.add(lines)

		mesh

module.exports = SolidObject3D
