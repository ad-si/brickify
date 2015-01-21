OptimizedModel = require './OptimizedModel'
Octree = require './Octree'
Vec3 = require './Vector'


module.exports = (importedStl, options) ->

	options ?= {}

	cleanseStl = options.cleanseStl || true
	pointDistanceEpsilon = options.pointDistanceEpsilon || 0.0001

	if cleanseStl
		importedStl.cleanse()

	vertexnormals = []
	faceNormals = []
	index = [] #vert1 vert2 vert3

	octreeRoot = new Octree(pointDistanceEpsilon)
	biggestPointIndex = -1

	for poly in importedStl.polygons
		#add points if they don't exist, or get index of these points
		indices = [-1,-1,-1]
		for vertexIndex in [0..2]
			point = poly.points[vertexIndex]
			newPointIndex = octreeRoot.add point,
				new Vec3(poly.normal.x, poly.normal.y, poly.normal.z), biggestPointIndex
			indices[vertexIndex] = newPointIndex
			if newPointIndex > biggestPointIndex
				biggestPointIndex = newPointIndex

		index.push indices[0]
		index.push indices[1]
		index.push indices[2]
		faceNormals.push poly.normal.x
		faceNormals.push poly.normal.y
		faceNormals.push poly.normal.z

	#get a list out of the octree
	vertexPositions = new Array((biggestPointIndex + 1) * 3)
	octreeRoot.forEach (node) ->
		v = node.vec
		i = node.index * 3
		vertexPositions[i] = v.x
		vertexPositions[i + 1] = v.y
		vertexPositions[i + 2] = v.z

	#average all vertexnormals
	avgNormals = new Array((biggestPointIndex + 1) * 3)
	octreeRoot.forEach (node) ->
		normalList = node.normalList
		i = node.index * 3
		avg = new Vec3(0,0,0)
		for normal in normalList
			normal = normal.normalized()
			avg = avg.add normal
		avg = avg.normalized()
		avgNormals[i] = avg.x
		avgNormals[i + 1] = avg.y
		avgNormals[i + 2] = avg.z

	optimized = new OptimizedModel()
	optimized.positions = vertexPositions
	optimized.indices = index
	optimized.vertexNormals = avgNormals
	optimized.faceNormals = faceNormals

	return optimized
