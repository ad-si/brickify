bottomStudTypes = {
	rectangular: 0
	smallCircle: 1
	largeCircle: 2
}

topStudTypes = {
	cylinder: 0
}

module.exports.addStuds = (
	boxGeometryBsp, options, voxelsToBeGeometrized, grid) ->
	return _addStuds boxGeometryBsp, options, voxelsToBeGeometrized, grid

###
# annotates voxel with information about which studs to use
#
###
layoutStuds = (voxelsToBeGeometrized) ->
	console.log voxelsToBeGeometrized

	return voxelsToBeGeometrized

###
# adds studs on top, subtracts studs from below
###
_addStuds = (boxGeometry, options, voxelsToBeGeometrized, grid) ->
	studGeometry = _createStudGeometry(
		grid.spacing, options.studSize, options.holeSize
	)
	unionBsp = boxGeometry

	for voxel in voxelsToBeGeometrized
		# if this is the lowest voxel to be printed, or
		# there is lego below this voxel, subtract a stud
		# to make it fit to lego bricks
		if voxel.studFromBelow
			studMesh = new THREE.Mesh(studGeometry.studGeometryBottom, null)
			studMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
			studMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
			studMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

			studBsp = new ThreeBSP(studMesh)
			unionBsp = unionBsp.subtract studBsp

		# create a stud for lego above this voxel
		if voxel.studOnTop
			studMesh = new THREE.Mesh(studGeometry.studGeometryTop, null)
			studMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
			studMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
			studMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

			studBsp = new ThreeBSP(studMesh)
			unionBsp = unionBsp.union studBsp

	return unionBsp

###
# creates Geometry needed for CSG operations
###
_createStudGeometry = (gridSpacing, studSize, holeSize) ->
	studRotation = new THREE.Matrix4().makeRotationX( 3.14159 / 2 )
	dzBottom = -(gridSpacing.z / 2) + (holeSize.height / 2)
	studTranslationBottom = new THREE.Matrix4().makeTranslation(0,0,dzBottom)
	dzTop = (gridSpacing.z / 2) + (studSize.height / 2)
	studTranslationTop = new THREE.Matrix4().makeTranslation(0,0,dzTop)

	studGeometryBottom = new THREE.CylinderGeometry(
		studSize.radius, studSize.radius, studSize.height, 20
	)
	studGeometryTop = new THREE.BoxGeometry(
		2 * holeSize.radius, holeSize.height, 2 * holeSize.radius
	)

	studGeometryBottom.applyMatrix(studRotation)
	studGeometryTop.applyMatrix(studRotation)
	studGeometryBottom.applyMatrix(studTranslationBottom)
	studGeometryTop.applyMatrix(studTranslationTop)

	return {
	# The shape of a stud that is subtracted from the bottom of the voxel
	studGeometryBottom: studGeometryBottom
	# The shape of a stud that is added on top of a voxel
	studGeometryTop: studGeometryTop
	}