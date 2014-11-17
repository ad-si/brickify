class Polygon
	constructor: (@points, @plane, @edges) ->
		@render_Faces = null
		@reverse_Render_Faces = null
		@render_Face_Points = null
		@tag = new Tag()
		@object = null
		@side_label = null
		@color = null
		@id = null
		@selection = null
		if @edges
			@.interlink_with_Edges()


	#clone: () ->
	#  polygon = new Polygon(@points, @plane, @edges)
	interlink_with_Edges: () ->
		last = @points.last()

		for point, index in @points
			@edges[index].set_Polygon @, last, point
			last = point

	set_Id: (@id) ->
		return

	clip: (plane) ->
		return

	set_Object: (@object) ->
		return

	#only of objectless polygons
	get_Points_of_RenderFace: () ->
		@render_Face_Points ?= @build_Points_of_RenderFace()

	build_Export_Faces: () ->
		faces = []
		for i in [0...@points.length - 2] by 1
			face = { normal: @plane.normal, vertices: [ @points[0], @points[i + 1], @points[i + 2] ]}
			faces.add face
		faces

	build_Points_of_RenderFace: () ->
		face_points = []
		for i in [0...@points.length - 2] by 1
			face_points.add [ @points[0], @points[i + 1], @points[i + 2] ]
		face_points

	get_RenderFaces: () ->
		@render_Faces ?= @build_RenderFaces()

	get_Reverse_RenderFaces: () ->
		@reverse_Render_Faces ?= @build_Reverse_RenderFaces()

	build_RenderFaces: () ->
		faces = []

		for i in [0...@points.length - 2] by 1
			face = new THREE.Face3(@points[0].index, @points[i + 1].index, @points[i + 2].index)
			face.parentPolygon = @

			c = new THREE.Color(Math.random() * 0xffffff)
			#face.vertexColors = [c,c,c]
			if @color
				face.color = @color
			faces.push face
		faces

	build_Reverse_RenderFaces: () ->
		faces = []

		for i in [0...@points.length - 2] by 1
			face = new THREE.Face3(@points[0].index, @points[i + 2].index, @points[i + 1].index)
			face.parentPolygon = @
			faces.push face
		faces

	reset_Color: () ->
		@color = new THREE.Color()
		if @render_Faces
			for face in @render_Faces
				face.color = @color


	set_Color: (@color) ->
		console.log @color
		if !@render_Faces?
			return null
		for face in @render_Faces
			face.color = @color
			#face.vertexColors = [@color, @color, @color]

	calculate_Volume: () ->
		vol = 0
		for i in [0...@points.length - 2] by 1
			p1 = @points[0]
			p2 = @points[i + 1]
			p3 = @points[i + 2]

			v1 = p1.to p2
			v2 = p1.to p3

			vol += (((v1.cross(v2)).dot(p3)) / 6)

		vol


	###
	method to calculate the area of the polygon
	###
	getArea: () ->
		p1 = new Vector3D(@points[0].x, @points[0].y, @points[0].z)
		p2 = new Vector3D(@points[1].x, @points[1].y, @points[1].z)
		p3 = new Vector3D(@points[2].x, @points[2].y, @points[2].z)

		m1 = p2.minus(p1)
		m2 = p3.minus(p1)
		area = m1.cross(m2).length() / 2

		area

module.exports = Polygon
