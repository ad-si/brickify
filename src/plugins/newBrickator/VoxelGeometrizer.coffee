THREE = require 'three'
ThreeCSG = require './threeCSG/ThreeCSG'

# creates a CSG geometry for all voxels to be 3d printed
module.exports = class VoxelGeometrizer
	constructor: (@grid) ->
		return

	run: (voxelsToBeGeometrized, options) =>
		d = new Date()
		boxGeometry = @_createVoxelGeometry(voxelsToBeGeometrized)
		boxGeometryBsp = new ThreeBSP(boxGeometry)
		console.log "Geometrizer: voxel geometry took #{new Date() - d}ms"

		d = new Date()
		bspWithKnobs = @_addKnobs(
			boxGeometryBsp, options, voxelsToBeGeometrized, @grid)
		console.log "Geometrizer: knob geometry took #{new Date() - d}ms"

		return bspWithKnobs

	_createVoxelGeometry: (voxelsToBeGeometrized) ->
		# create the rectangular geometry for the voxels
		s = @_prepareData(voxelsToBeGeometrized)

		geo = new THREE.Geometry()

		for z in [s.minZ..s.maxZ] by 1
			for x in [s.minX..s.maxX] by 1
				for y in [s.minY..s.maxY] by 1
					# if this is a voxel...
					if s.zLayers[z][x][y].voxel
						v = s.zLayers[z][x][y]

						# create bottom plate if there is no voxel below us
						if not s.zLayers[z - 1][x][y].voxel
							if not v.points
								@_createGeoPoints x, y, z, s, geo

							# add faces clockwise, because the baseplate "looks down"
							# (we look at it from inside the model)
							geo.faces.push new THREE.Face3(v.points[0], v.points[1], v.points[3])
							geo.faces.push new THREE.Face3(v.points[3], v.points[1], v.points[2])

						# check if we are fully inside the model (voxel neighbours to all 4 sides)
						if s.zLayers[z][x + 1][y].voxel and s.zLayers[z][x - 1][y].voxel and
						s.zLayers[z][x][y + 1].voxel and s.zLayers[z][x][y - 1].voxel
							skipSidewalls = true

						if not skipSidewalls
							#create points for the voxel baseplate above this voxel
							upperIndices = @_createGeoPoints x, y, z + 1, s, geo
							
							# create a sideplate if there is no voxel at this side
							# +x direction
							if not s.zLayers[z][x + 1][y].voxel
								geo.faces.push new THREE.Face3(
									upperIndices[3], upperIndices[0], v.points[0])
								geo.faces.push new THREE.Face3(
									v.points[0], v.points[3], upperIndices[3])

							# -x direction
							if not s.zLayers[z][x - 1][y].voxel
								geo.faces.push new THREE.Face3(
									upperIndices[1], upperIndices[2], v.points[2])
								geo.faces.push new THREE.Face3(
									v.points[2], v.points[1], upperIndices[1])

							# +y direction
							if not s.zLayers[z][x][y + 1].voxel
								geo.faces.push new THREE.Face3(
									upperIndices[2], upperIndices[3], v.points[3])
								geo.faces.push new THREE.Face3(
									v.points[3], v.points[2], upperIndices[2])

							# -y direction
							if not s.zLayers[z][x][y - 1].voxel
								geo.faces.push new THREE.Face3(
									upperIndices[0], upperIndices[1], v.points[0])
								geo.faces.push new THREE.Face3(
									v.points[1], v.points[0], upperIndices[1])

						# is there a voxel above? if not, create a plate on top
						# facing upwards to close geometry
						if not s.zLayers[z + 1][x][y].voxel
							upperIndices = @_createGeoPoints x, y, z + 1, s, geo
							geo.faces.push new THREE.Face3(
								upperIndices[1], upperIndices[3], upperIndices[2])
							geo.faces.push new THREE.Face3(
								upperIndices[0], upperIndices[3], upperIndices[1])
		return geo

	_prepareData: (voxels) ->
		s = {
			zLayers: []
		}

		for v in voxels
			# min max values
			s.minX ?= v.x
			s.minX = Math.min(v.x, s.minX)
			s.minY ?= v.y
			s.minY = Math.min(v.y, s.minY)
			s.minZ ?= v.z
			s.minZ = Math.min(v.z, s.minZ)

			s.maxX ?= v.x
			s.maxX = Math.max(v.x, s.maxX)
			s.maxY ?= v.y
			s.maxY = Math.max(v.y, s.maxY)
			s.maxZ ?= v.z
			s.maxZ = Math.max(v.z, s.maxZ)

			# initialize structure
			s.zLayers[v.z] ?= []
			s.zLayers[v.z][v.x] ?= []
			s.zLayers[v.z][v.x][v.y] = {
				# these are points for the baseplate of this voxel
				# 0---1 (as seen from above (z-Layer), x goes right, y goes downwards)
				# |   |
				# 3---2
				points: null
				voxel: true
			}

		# go through everything and initialize empty cells with voxel=false
		# (reduces []? in algorithm)
		for z in [s.minZ - 1..s.maxZ + 1] by 1
			for x in [s.minX - 1..s.maxX + 1] by 1
				for y in [s.minY - 1..s.maxY + 1] by 1
					if not s.zLayers[z]?[x]?[y]?
						s.zLayers[z] ?= []
						s.zLayers[z][x] ?= []
						if not s.zLayers[z][x][y]?
							s.zLayers[z][x][y] = {
								points: null
								voxel: false
							}
		return s

	_createGeoPoints: (x, y, z, structure, geometry) ->
		# creates baseplate points in transformed world coordinates
		# and adds them to geometry (if they dont exist yet)
		# returns indices

		voxelCenter = @grid.mapVoxelToWorld {x: x, y: y, z: z}

		pz = voxelCenter.z - (@grid.spacing.z / 2)
		dx = (@grid.spacing.x / 2)
		dy = (@grid.spacing.y / 2)

		# check if this point already exists in a neighbour voxel
		# (a point can be used by up to 4 voxels in a layer, so check
		# if it already has been generated to prevent duplicates)

		# x----x----x----x  <---x---
		# |0  1|0  1|0  1|  |
		# |3  2|3  2|3  2|  y
		# x----§----x----x  |  point § of selected voxel can already exist as
		# |0  1|sel.|0  1|  v  point 1, 2 or 3 of neighbour voxels
		# |3  2|vox |3  2|
		# x----x----x----x
		# |0  1|0  1|0  1|
		# |3  2|3  2|3  2|
		# x----x----x----x

		# return points if they already exist
		if structure.zLayers[z][x][y].points?
			return structure.zLayers[z][x][y].points

		#p0
		if structure.zLayers[z][x + 1][y].points?
			p0i = structure.zLayers[z][x + 1][y].points[1]
		else if structure.zLayers[z][x + 1][y - 1].points?
			p0i = structure.zLayers[z][x + 1][y - 1].points[2]
		else if structure.zLayers[z][x][y - 1].points?
			p0i = structure.zLayers[z][x][y - 1].points[3]
		else
			# this point did not exist, therefore create it
			p0 = {
				x: voxelCenter.x + dx
				y: voxelCenter.y - dy
				z: pz
			}
			geometry.vertices.push(new THREE.Vector3(p0.x, p0.y, p0.z))
			p0i = geometry.vertices.length - 1

	    #p1
		if structure.zLayers[z][x][y - 1].points?
			p1i = structure.zLayers[z][x][y - 1].points[2]
		else if structure.zLayers[z][x - 1][y - 1].points?
			p1i = structure.zLayers[z][x - 1][y - 1].points[3]
		else if structure.zLayers[z][x - 1][y].points?
			p1i = structure.zLayers[z][x - 1][y].points[0]
		else
			p1 = {
				x: voxelCenter.x - dx
				y: voxelCenter.y - dy
				z: pz
			}
			geometry.vertices.push(new THREE.Vector3(p1.x, p1.y, p1.z))
			p1i = geometry.vertices.length - 1

		#p2
		if structure.zLayers[z][x - 1][y].points?
			p2i = structure.zLayers[z][x - 1][y].points[3]
		else if structure.zLayers[z][x - 1][y + 1].points?
			p2i = structure.zLayers[z][x - 1][y + 1].points[0]
		else if structure.zLayers[z][x][y + 1].points?
			p2i = structure.zLayers[z][x][y + 1].points[1]
		else
			p2 = {
				x: voxelCenter.x - dx
				y: voxelCenter.y + dy
				z: pz
			}
			geometry.vertices.push(new THREE.Vector3(p2.x, p2.y, p2.z))
			p2i = geometry.vertices.length - 1

		#p3
		if structure.zLayers[z][x][y + 1].points?
			p3i = structure.zLayers[z][x][y + 1].points[0]
		else if structure.zLayers[z][x + 1][y + 1].points?
			p3i = structure.zLayers[z][x + 1][y + 1].points[1]
		else if structure.zLayers[z][x + 1][y].points?
			p3i = structure.zLayers[z][x + 1][y].points[2]
		else
			p3 = {
				x: voxelCenter.x + dx
				y: voxelCenter.y + dy
				z: pz
			}
			geometry.vertices.push(new THREE.Vector3(p3.x, p3.y, p3.z))
			p3i = geometry.vertices.length - 1

		# set points
		structure.zLayers[z][x][y].points = [p0i, p1i, p2i, p3i]
		return structure.zLayers[z][x][y].points

	_addKnobs: (boxGeometry, options, voxelsToBeGeometrized, grid) ->
		knobGeometry = @_createKnobGeometry @grid.spacing, options.knobSize

		unionBsp = boxGeometry

		for voxel in voxelsToBeGeometrized
			# if this is the lowest voxel to be printed, subtract a knob
			# to make it fit to lego bricks
			if voxel.knobFromBelow
				knobMesh = new THREE.Mesh(knobGeometry.knobGeometryBottom, null)
				knobMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
				knobMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
				knobMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

				knobBsp = new ThreeBSP(knobMesh)
				unionBsp = unionBsp.subtract knobBsp

			# create a knob for lego above this voxel
			if voxel.knobOnTop
				knobMesh = new THREE.Mesh(knobGeometry.knobGeometryTop, null)
				knobMesh.translateX( grid.origin.x + grid.spacing.x * voxel.x )
				knobMesh.translateY( grid.origin.y + grid.spacing.y * voxel.y )
				knobMesh.translateZ( grid.origin.z + grid.spacing.z * voxel.z )

				knobBsp = new ThreeBSP(knobMesh)
				unionBsp = unionBsp.union knobBsp

		return unionBsp

	_createKnobGeometry: (gridSpacing, knobSize) ->
		# creates Geometry needed for CSG operations
		knobRotation = new THREE.Matrix4().makeRotationX( 3.14159 / 2 )
		dzBottom = -(gridSpacing.z / 2) + (knobSize.height / 2)
		knobTranslationBottom = new THREE.Matrix4().makeTranslation(0,0,dzBottom)
		dzTop = (gridSpacing.z / 2) + (knobSize.height / 2)
		knobTranslationTop = new THREE.Matrix4().makeTranslation(0,0,dzTop)
		
		knobGeometryBottom = new THREE.CylinderGeometry(
			knobSize.radius, knobSize.radius, knobSize.height, 8
		)
		knobGeometryTop = new THREE.CylinderGeometry(
			knobSize.radius, knobSize.radius, knobSize.height, 8
		)

		knobGeometryBottom.applyMatrix(knobRotation)
		knobGeometryTop.applyMatrix(knobRotation)
		knobGeometryBottom.applyMatrix(knobTranslationBottom)
		knobGeometryTop.applyMatrix(knobTranslationTop)

		return {
			# The shape of a knob that is subtracted from the bottom of the voxel
			knobGeometryBottom: knobGeometryBottom
			# The shape of a knob that is added on top of a voxel
			knobGeometryTop: knobGeometryTop
		}
