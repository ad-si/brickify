class Mesh extends Object3D
	constructor: (triangles) ->
		#super()
		@geometry = []
		@triangles = []

		mesh = new @()
		mesh.geometry = new THREE.Geometry()
		
		for triangle in triangles
			indecies = []
			for point in triangle
				indecies.push mesh.get_Point point[0], point[1], point[2]

			@geometry.faces.push new THREE.Face3(indecies[0],indecies[1], indecies[2])

		@geometry.verticies = @points
	
module.exports = Mesh