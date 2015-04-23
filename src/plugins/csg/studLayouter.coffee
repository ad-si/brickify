log = require 'loglevel'

###
# @module studLayouter
###

topStudTypes = {
	rectangular: 0
	smallCircle: 1
	largeCircle: 2
}

bottomStudTypes = {
	cylinder: 0
}

module.exports.addStuds = (
	boxGeometryBsp, options, voxelsToBeGeometrized, grid, profile) ->
	_layoutStuds voxelsToBeGeometrized
	d = new Date()
	unionBsp = _subtractStudsFromBelow(
		boxGeometryBsp, options, voxelsToBeGeometrized, grid)
	log.debug "Stud layouter: studs from below took #{new Date() - d}ms" if profile
	d2 = new Date()
	unionBsp = _addStudsOnTop(
		unionBsp, options, voxelsToBeGeometrized, grid)
	log.debug "Stud layouter: studs on top took #{new Date() - d2}ms" if profile
	log.debug "Stud layouter: stud geometry took #{new Date() - d}ms" if profile

	return unionBsp

###
# annotates voxels with information about which stud type to use
###
_layoutStuds = (voxelsToBeGeometrized) ->
	voxelsWithTopStuds = []
	for voxel in voxelsToBeGeometrized
		if voxel.studFromBelow
			voxel.bottomStudType = bottomStudTypes.cylinder
		if voxel.studOnTop
			voxelsWithTopStuds[voxel.z] ?= []
			voxelsWithTopStuds[voxel.z][voxel.x] ?= []
			voxelsWithTopStuds[voxel.z][voxel.x][voxel.y] = voxel

	for z, voxelLayer of voxelsWithTopStuds
		for x, voxelLine of voxelLayer
			for y, voxel of voxelLine
				voxel.topStudType = _getTopStudTypeForVoxel voxel, voxelLayer

	return voxelsToBeGeometrized

_getTopStudTypeForVoxel = (voxel, layer) ->
	x = voxel.x
	y = voxel.y

	studType = voxel.topStudType
	studType ?= {
		zp: topStudTypes.rectangular
		zm: topStudTypes.rectangular
		yp: topStudTypes.rectangular
		ym: topStudTypes.rectangular
	}

	if layer[x + 1]?[y]
		studType.xp = topStudTypes.smallCircle
		if (layer[x + 1][y + 1] and layer[x][y + 1]) or
		(layer[x + 1][y - 1] and layer[x][y - 1])
			studType.xp = topStudTypes.largeCircle
	if layer[x - 1]?[y]
		studType.xm = topStudTypes.smallCircle
		if (layer[x - 1][y + 1] and layer[x][y + 1]) or
		(layer[x - 1][y - 1] and layer[x][y - 1])
			studType.xm = topStudTypes.largeCircle
	if layer[x][y + 1]
		studType.yp = topStudTypes.smallCircle
		if (layer[x + 1]?[y + 1] and layer[x + 1]?[y]) or
		(layer[x - 1]?[y] and layer[x - 1]?[y + 1])
			studType.yp = topStudTypes.largeCircle
	if layer[x][y - 1]
		studType.ym = topStudTypes.smallCircle
		if (layer[x + 1]?[y - 1] and layer[x + 1]?[y]) or
		(layer[x - 1]?[y] and layer[x - 1]?[y - 1])
			studType.ym = topStudTypes.largeCircle

	return studType

_subtractStudsFromBelow = (boxGeometry, options, voxelsToBeGeometrized, grid) ->
	studGeometry = _createBottomStudGeometry grid.spacing, options.studSize
	unionBsp = boxGeometry

	for voxel in voxelsToBeGeometrized
		# if there is lego below this voxel, subtract a
		# stud to make it fit to lego bricks
		if voxel.studFromBelow
			if voxel.bottomStudType is bottomStudTypes.cylinder
				studMesh = new THREE.Mesh(studGeometry.cylinder, null)
			_translateToPosition studMesh, grid.origin, grid.spacing, voxel

			studBsp = new ThreeBSP(studMesh)
			unionBsp = unionBsp.subtract studBsp

	return unionBsp

_addStudsOnTop = (boxGeometry, options, voxelsToBeGeometrized, grid) ->
	studGeometry = _createTopStudGeometry	grid.spacing, options.holeSize
	unionBsp = boxGeometry

	for voxel in voxelsToBeGeometrized
		if voxel.studOnTop
			# create a stud for lego above this voxel
			studMesh = new THREE.Mesh studGeometry.rectangular, null
			_translateToPosition studMesh, grid.origin, grid.spacing, voxel
			studBsp = new ThreeBSP studMesh
			for direction, type of voxel.topStudType
				if type is topStudTypes.smallCircle or type is topStudTypes.largeCircle
					cutoutMesh = new THREE.Mesh studGeometry.rectangular, null
					_translateToPosition(
						cutoutMesh, grid.origin, grid.spacing, voxel, direction)
					cutoutBsp = new ThreeBSP cutoutMesh
					studBsp = studBsp.union cutoutBsp
				if type is topStudTypes.smallCircle
					smallCircleMesh = new THREE.Mesh studGeometry.smallCircle, null
					_translateToPosition(
						smallCircleMesh, grid.origin, grid.spacing, voxel, direction)
					smallCircleBsp = new ThreeBSP smallCircleMesh
					studBsp = studBsp.subtract smallCircleBsp

				else if type is topStudTypes.largeCircle
					largeCircleGeometry = _duplicateLargeCircle(
						studGeometry.largeCircle, grid.spacing, direction)
					largeCircleMesh = new THREE.Mesh largeCircleGeometry, null
					_translateToPosition(
						largeCircleMesh, grid.origin, grid.spacing, voxel, direction)
					largeCircleBsp = new ThreeBSP largeCircleMesh
					studBsp = studBsp.subtract largeCircleBsp

			unionBsp = unionBsp.union studBsp

	return unionBsp

_translateToPosition = (mesh, gridOrigin, gridSpacing, voxel, direction) ->
	modX = 0
	modY = 0

	switch direction
		when 'xp' then modX = 0.5
		when 'xm' then modX = -0.5
		when 'yp' then modY = 0.5
		when 'ym' then modY = -0.5

	mesh.translateX gridOrigin.x + gridSpacing.x * voxel.x + gridSpacing.x * modX
	mesh.translateY gridOrigin.y + gridSpacing.y * voxel.y + gridSpacing.y * modY
	mesh.translateZ gridOrigin.z + gridSpacing.z * voxel.z

_duplicateLargeCircle = (geometry, gridSpacing, direction) ->
	geo1 = geometry.clone()
	geo2 = geometry.clone()

	translationX1 = 0
	translationY1 = 0

	translationX2 = 0
	translationY2 = 0

	if direction is 'xp'
		translationX1 = 0
		translationY1 = 0.5
		translationX2 = 0
		translationY2 = -0.5
	else if direction is 'xm'
		translationX1 = 0
		translationY1 = 0.5
		translationX2 = 0
		translationY2 = -0.5
	else if direction is 'yp'
		translationX1 = 0.5
		translationY1 = 0
		translationX2 = -0.5
		translationY2 = 0
	else if direction is 'ym'
		translationX1 = 0.5
		translationY1 = 0
		translationX2 = -0.5
		translationY2 = 0

	translation1 = new THREE.Matrix4().makeTranslation(
		gridSpacing.x * translationX1, gridSpacing.y * translationY1, 0)
	translation2 = new THREE.Matrix4().makeTranslation(
		gridSpacing.x * translationX2, gridSpacing.y * translationY2, 0)

	geo1.applyMatrix translation1
	geo2.applyMatrix translation2

	geo1.merge geo2

	return geo1

###
# creates Geometry needed for CSG operations
###
_createBottomStudGeometry = (gridSpacing, studSize) ->
	studRotation = new THREE.Matrix4().makeRotationX Math.PI / 2
	dzBottom =  -(gridSpacing.z / 2) + (studSize.height / 2)
	studTranslationBottom = new THREE.Matrix4().makeTranslation 0, 0, dzBottom

	studGeometryBottom = _getCylinderStudGeometry studSize.radius, studSize.height

	studGeometryBottom.applyMatrix studRotation
	studGeometryBottom.applyMatrix studTranslationBottom

	return {
		cylinder: studGeometryBottom
	}

_createTopStudGeometry = (gridSpacing, holeSize) ->
	dzTop = (gridSpacing.z / 2) + (holeSize.height / 2)
	studTranslationTop = new THREE.Matrix4().makeTranslation 0, 0, dzTop

	rectGeometry = _getRectangularStudGeometry holeSize.radius, holeSize.height
	rectGeometry.applyMatrix studTranslationTop

	rotation = new THREE.Matrix4().makeRotationX Math.PI / 2

	smallCircleGeometry = _getSmallCircleStudGeometry(
		(gridSpacing.x - 2 * holeSize.radius) / 2, holeSize.height)
	smallCircleGeometry.applyMatrix rotation
	smallCircleGeometry.applyMatrix studTranslationTop

	largeCircleGeometry = _getLargeCircleStudGeometry(
		holeSize.radius, holeSize.height)
	largeCircleGeometry.applyMatrix rotation
	largeCircleGeometry.applyMatrix studTranslationTop

	return {
		rectangular: rectGeometry
		smallCircle: smallCircleGeometry
		largeCircle: largeCircleGeometry
	}

_getCylinderStudGeometry = (radius, height) ->
	new THREE.CylinderGeometry radius, radius, height, 14

_getRectangularStudGeometry = (radius, height) ->
	new THREE.BoxGeometry 2 * radius, 2 * radius, height

_getSmallCircleStudGeometry = (circleRadius, height) ->
	new THREE.CylinderGeometry circleRadius, circleRadius, height, 8

_getLargeCircleStudGeometry = (circleRadius, height) ->
	new THREE.CylinderGeometry circleRadius, circleRadius, height, 14
