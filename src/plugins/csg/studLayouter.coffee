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
	boxGeometryBsp, options, voxelsToBeGeometrized, grid) ->
	_layoutStuds voxelsToBeGeometrized
	unionBsp = _subtractStudsFromBelow(
		boxGeometryBsp, options, voxelsToBeGeometrized, grid)
	unionBsp = _addStudsOnTop(
		unionBsp, options, voxelsToBeGeometrized, grid)

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
		#if layer[x + 1][y + 1] or layer[x + 1]?[y - 1]
		#	studType.xp = topStudTypes.largeCircle
	if layer[x - 1]?[y]
		studType.xm = topStudTypes.smallCircle
		#if layer[x - 1]?[y + 1] or layer[x + 1]?[y - 1]
		#	studType.xm = topStudTypes.largeCircle
	if layer[x][y + 1]
		studType.yp = topStudTypes.smallCircle
		#if layer[x + 1]?[y + 1] or layer[x - 1]?[y + 1]
		#	studType.yp = topStudTypes.largeCircle
	if layer[x][y - 1]
		studType.ym = topStudTypes.smallCircle
		#if layer[x + 1]?[y - 1] or layer[x - 1]?[y - 1]
		#	studType.ym = topStudTypes.largeCircle

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
				if type is topStudTypes.smallCircle
					cutoutMesh = new THREE.Mesh studGeometry.rectangular, null
					_translateToPosition(
						cutoutMesh, grid.origin, grid.spacing, voxel, direction
					)
					cutoutBsp = new ThreeBSP cutoutMesh
					studBsp = studBsp.union cutoutBsp
					smallCircleMesh = new THREE.Mesh studGeometry.smallCircle, null
					_translateToPosition(
						smallCircleMesh, grid.origin, grid.spacing, voxel, direction
					)
					smallCircleBsp = new ThreeBSP smallCircleMesh
					studBsp = studBsp.subtract smallCircleBsp

				else if type is topStudTypes.largeCircle
					studMesh = new THREE.Mesh studGeometry.largeCircle, null
					_translateToPosition(
						studMesh, grid.origin, grid.spacing, voxel, direction
					)
					largeCircleBsp = new ThreeBSP studMesh
					studBsp = studBsp.union largeCircleBsp

			unionBsp = unionBsp.union studBsp

	return unionBsp

_translateToPosition = (mesh, gridOrigin, gridSpacing, voxel, direction) ->
	modifierX = 0
	modifierY = 0

	switch direction
		when 'xp' then modifierX = 0.5
		when 'xm' then modifierX = -0.5
		when 'yp' then modifierY = 0.5
		when 'ym' then modifierY = -0.5

	mesh.translateX gridOrigin.x + gridSpacing.x * voxel.x + gridSpacing.x * modifierX
	mesh.translateY gridOrigin.y + gridSpacing.y * voxel.y + gridSpacing.y * modifierY
	mesh.translateZ gridOrigin.z + gridSpacing.z * voxel.z

###
# creates Geometry needed for CSG operations
###
_createBottomStudGeometry = (gridSpacing, studSize) ->
	studRotation = new THREE.Matrix4().makeRotationX Math.PI / 2
	dzBottom =  -(gridSpacing.z / 2) + (studSize.height / 2)
	studTranslationBottom = new THREE.Matrix4().makeTranslation 0, 0, dzBottom

	studGeometryBottom = _getCylinderStudGeometry studSize.radius, studSize.height, 20

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

	smallCircleGeometry = _getSmallCircleStudGeometry(
		(gridSpacing.x - 2 * holeSize.radius) / 2, holeSize.height)
	rotation = new THREE.Matrix4().makeRotationX Math.PI / 2
	smallCircleGeometry.applyMatrix rotation
	smallCircleGeometry.applyMatrix studTranslationTop

	return {
		rectangular: rectGeometry
		smallCircle: smallCircleGeometry
		largeCircle: rectGeometry # TODO
	}

_getCylinderStudGeometry = (radius, height) ->
	new THREE.CylinderGeometry radius, radius, height, 16

_getRectangularStudGeometry = (radius, height) ->
	new THREE.BoxGeometry 2 * radius, 2 * radius, height

_getSmallCircleStudGeometry = (circleRadius, height) ->
	new THREE.CylinderGeometry circleRadius, circleRadius, height, 16
