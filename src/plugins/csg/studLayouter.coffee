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
	# TODO
	for voxel in voxelsToBeGeometrized
		if voxel.studFromBelow
			voxel.bottomStudType = bottomStudTypes.cylinder
		if voxel.studOnTop
			voxel.topStudType = topStudTypes.rectangular
	return voxelsToBeGeometrized

_subtractStudsFromBelow = (boxGeometry, options, voxelsToBeGeometrized, grid) ->
	studGeometry = _createBottomStudGeometry grid.spacing, options.holeSize
	unionBsp = boxGeometry

	for voxel in voxelsToBeGeometrized
		# if there is lego below this voxel, subtract a
		# stud to make it fit to lego bricks
		if voxel.studFromBelow
			if voxel.bottomStudType is bottomStudTypes.cylinder
				studMesh = new THREE.Mesh(studGeometry.cylinder, null)
			studMesh.translateX grid.origin.x + grid.spacing.x * voxel.x
			studMesh.translateY grid.origin.y + grid.spacing.y * voxel.y
			studMesh.translateZ grid.origin.z + grid.spacing.z * voxel.z

			studBsp = new ThreeBSP(studMesh)
			unionBsp = unionBsp.subtract studBsp

	return unionBsp

_addStudsOnTop = (boxGeometry, options, voxelsToBeGeometrized, grid) ->
	studGeometry = _createTopStudGeometry	grid.spacing, options.studSize
	unionBsp = boxGeometry

	for voxel in voxelsToBeGeometrized
		if voxel.studOnTop
			# create a stud for lego above this voxel
			if voxel.topStudType is topStudTypes.rectangular
				studMesh = new THREE.Mesh(studGeometry.rectangular, null)
			else if voxel.topStudType is topStudTypes.smallCircle
				studMesh = new THREE.Mesh(studGeometry.smallCircle, null)
			else # if voxel.topStudType is topStudTypes.largeCircle
				studMesh = new THREE.Mesh(studGeometry.largeCircle, null)
			studMesh.translateX grid.origin.x + grid.spacing.x * voxel.x
			studMesh.translateY grid.origin.y + grid.spacing.y * voxel.y
			studMesh.translateZ grid.origin.z + grid.spacing.z * voxel.z

			studBsp = new ThreeBSP(studMesh)
			unionBsp = unionBsp.union studBsp

	return unionBsp

###
# creates Geometry needed for CSG operations
###
_createBottomStudGeometry = (gridSpacing, studSize) ->
	studRotation = new THREE.Matrix4().makeRotationX( 3.14159 / 2 )
	dzBottom =  -(gridSpacing.z / 2) + (studSize.height / 2)
	studTranslationBottom = new THREE.Matrix4().makeTranslation(0, 0, dzBottom)

	studGeometryBottom = _getCylinderStudGeometry studSize.radius, studSize.height, 20

	studGeometryBottom.applyMatrix studRotation
	studGeometryBottom.applyMatrix studTranslationBottom

	return {
		cylinder: studGeometryBottom
	}

_createTopStudGeometry = (gridSpacing, holeSize) ->
	studRotation = new THREE.Matrix4().makeRotationX( 3.14159 / 2 )
	dzTop = (gridSpacing.z / 2) + (holeSize.height / 2)
	studTranslationTop = new THREE.Matrix4().makeTranslation(0, 0, dzTop)

	studGeometryTop = _getRectangularStudGeometry holeSize.radius, holeSize.height

	studGeometryTop.applyMatrix studRotation
	studGeometryTop.applyMatrix studTranslationTop

	return {
		rectangular: studGeometryTop
		smallCircle: studGeometryTop # TODO
		largeCircle: studGeometryTop # TODO
	}

_getCylinderStudGeometry = (radius, height) ->
	return new THREE.CylinderGeometry radius, radius, height, 20

_getRectangularStudGeometry = (radius, height) ->
	new THREE.BoxGeometry 2 * radius, height, 2 * radius
