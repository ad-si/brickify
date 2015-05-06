clean = (geometry) ->
	geometry.mergeVertices()
	connectedComponents = getConnectedComponents geometry
	console.log connectedComponents

###
# calculates the volume of threeGeometry
# see http://stackoverflow.com/questions/1410525
# @param {THREE.Geometry} threeGeometry an instance of three geometry
# @return {Number} volume in cm^3
###
getVolume = (threeGeometry) ->
	volume = 0
	forAllFaces threeGeometry, (a, b, c) ->
		volume += (a.x * b.y * c.z) + (a.y * b.z * c.x) + (a.z * b.x * c.y) - \
				(a.x * b.z * c.y) - (a.y * b.x * c.z) - (a.z * b.y * c.x)
	return volume / 6 / 1000


getConnectedComponents = (geometry) ->
	equivalenceClasses = []
	forEachFace geometry, (a, b, c) ->
		connectedClasses = []
		
		for equivalenceClass in equivalenceClasses
			if equivalenceClass.has(a) or
			equivalenceClass.has(b) or
			equivalenceClass.has(c)
				equivalenceClass.push a
				equivalenceClass.push b
				equivalenceClass.push c
				connectedClasses.push equivalenceClass

		if connectedClasses.length is 0
			equivalenceClass = new Hashmap()
			equivalenceClass.push a
			equivalenceClass.push b
			equivalenceClass.push c
			equivalenceClasses.push equivalenceClass

		else if connectedClasses.length > 1
			combined = compactClasses connectedClasses
			equivalenceClasses.push combined
			equivalenceClasses = equivalenceClasses.filter (a) ->
				a.length > 0

	return equivalenceClasses

forEachFace = (geometry, visitor) ->
	for face in geometry.faces
		visitor face.a, face.b ,face.c

compactClasses = (equivalenceClasses) ->
	newClass =  new Hashmap()

	for eq in equivalenceClasses
		# add points and polygons to new class. The hashmap
		# automatically prevents inserting duplicate values
		eq.enumerate (point) ->
			newClass.push point

		# clear old class
		eq.clear()

	return newClass

module.exports.clean = clean

class Hashmap
	constructor: ->
		@length = 0
		@_enumarray = []
		@_hasarray = []
	push: (number) =>
		if not @_hasarray[number]
			@length++
			@_hasarray[number] = true
			@_enumarray.push number
	has: (number) =>
		if @_hasarray[number]?
			return true
		return false
	enumerate: (callback) =>
		for i in [0..@_enumarray.length - 1] by 1
			callback @_enumarray[i]
	clear: =>
		@length = 0
		@_enumarray = []
		@_hasarray = []