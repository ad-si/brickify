Object3D = require './Object3D'
Plane = require './Plane'
Polygon = require './Polygon'
Point = require './Point'
Mesh = require './Mesh'
Edge = require './Edge'
BoundaryBox = require './BoundaryBox'
Vector3D = require './Vector3D'
ColorPalette = require '../rendering/ColorPalette'
THREE = require 'three'


# Base class for all three-dimentional Objects.
class SolidObject3D extends Object3D
	constructor: () ->
		super()
		@boundaryBox = null
		@color = ColorPalette.default()
		@reverse_Scene_Model = null
		@edge_threshold = null
		@selection_group = []

#################################################
#                                               #
#                  SCENEMODEL                   #
#                                               #
#################################################

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

		material = new THREE.MeshPhongMaterial( { vertexColors: THREE.FaceColors, \
			color: @color.specular, ambient: @color.base, opacity: 1.0, \
			transparent: true} );

		
		phongShader = THREE.ShaderLib.phong
		uniforms = THREE.UniformsUtils.clone(phongShader.uniforms)
			
		 
		for point in @points
			geometry.vertices.push point
	
		for polygon in @polygons
			for face in polygon.get_RenderFaces()
				geometry.faces.push face
		
		@ed
		geometry.computeFaceNormals()

		mesh = new THREE.Mesh(geometry, material)

		
		if with_Edges
			edges = @.get_Edge_SceneModel()
			mesh.add edges

		
		mesh

	build_Edge_SceneModel: () ->
		edges = new THREE.Object3D()
		edge_geo = new THREE.Geometry()
		edge_material = new THREE.LineBasicMaterial(
			{ color: new THREE.Color( 0x000000 ), linewidth: 2, wireframe: true} )
		triangle_geo = new THREE.Geometry()
		triangle_material = new THREE.LineBasicMaterial(
			{ color: @color.error, linewidth: 0.5, wireframe: true} )
		broken_geo = new THREE.Geometry()
		broken_material = new THREE.LineBasicMaterial(
			{ color: @color.error, linewidth: 3, wireframe: true} )

		@.update_FaceGroups()

		for edge in @edges
			#edge.check_Visibility(@edge_threshold)
			#if edge.broken_edge
			#  broken_geo.vertices.push edge.from_point
			#  broken_geo.vertices.push edge.to_point
			if edge.hard_edge
				t = (edge.inner_Polygon.plane.normal).cross(
					edge.from_point.to(edge.to_point)).scalar(edge.inner_Polygon.plane.
					normal.plus(edge.outer_Polygon.plane.normal))
				h = new Vector3D(0,0,0)
				if (t > 0)
					h = edge.inner_Polygon.plane.normal.plus(
						edge.outer_Polygon.plane.normal)
					r = h.length_squared() * h.length_squared()
					if r < 0.8
						r = 0.8
					h.shrink(r).times(0.3)
					#h = new Vector3D(0,0,0)
				edge_geo.vertices.push (edge.from_point)
				edge_geo.vertices.push (edge.to_point)
				#edge_geo.vertices.push edge.from_point
				#edge_geo.vertices.push edge.to_point
			else
				triangle_geo.vertices.push edge.from_point
				triangle_geo.vertices.push edge.to_point

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
		material = new THREE.MeshPhongMaterial( { vertexColors: THREE.FaceColors, \
			color: @color.specular, ambient: @color.base, opacity: 0.3, \
			transparent: true} )

		for point in @points
			geometry.vertices.push point

		for polygon in @polygons
			for face in polygon.get_Reverse_RenderFaces()
				geometry.faces.push face

		geometry.computeFaceNormals()

		mesh = new THREE.Mesh(geometry, material)


		edge_geo = new THREE.Geometry()
		edge_material = new THREE.LineBasicMaterial(
			{ color: new THREE.Color( 0x707070 ), linewidth: 2, wireframe: true} )
		triangle_geo = new THREE.Geometry()
		triangle_material = new THREE.LineBasicMaterial(
			{ color: @color.error, linewidth: 0.5, wireframe: true} )
		broken_geo = new THREE.Geometry()
		broken_material = new THREE.LineBasicMaterial(
			{ color: @color.error, linewidth: 3, wireframe: true} )

		for edge in @edges
			edge.check_Visibility()
			if edge.broken_edge
				broken_geo.vertices.push edge.from_point
				broken_geo.vertices.push edge.to_point
			else if edge.hard_edge
				t = (edge.inner_Polygon.plane.normal).cross(edge.from_point.to(
					edge.to_point)).scalar(edge.inner_Polygon.plane.normal.plus(
					edge.outer_Polygon.plane.normal))
				h = new Vector3D(0,0,0)
				if (t > 0)
					h = edge.inner_Polygon.plane.normal.plus(
						edge.outer_Polygon.plane.normal)
					r = h.length_squared() * h.length_squared()
					if r < 0.8
						r = 0.8
					h.shrink(r).times(0.3)
					#h = new Vector3D(0,0,0)
				edge_geo.vertices.push (edge.from_point)
				edge_geo.vertices.push (edge.to_point)
				#edge_geo.vertices.push edge.from_point
				#edge_geo.vertices.push edge.to_point
			else
				triangle_geo.vertices.push edge.from_point
				triangle_geo.vertices.push edge.to_point

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
