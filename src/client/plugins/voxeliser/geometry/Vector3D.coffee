#<< app/Settings

#class point & normal
#class Matrix4x4

class Vector3D
	constructor: (@x, @y, @z) ->
		return

#  ########    ###     ######  ########  #######  ########  #### ########  ######
#  ##         ## ##   ##    ##    ##    ##     ## ##     ##  ##  ##       ##    ##
#  ##        ##   ##  ##          ##    ##     ## ##     ##  ##  ##       ##
#  ######   ##     ## ##          ##    ##     ## ########   ##  ######    ######
#  ##       ######### ##          ##    ##     ## ##   ##    ##  ##             ##
#  ##       ##     ## ##    ##    ##    ##     ## ##    ##   ##  ##       ##    ##
#  ##       ##     ##  ######     ##     #######  ##     ## #### ########  ######







#   ######  ######## ##       ########       ###    ########  #### ######## ##     ## ##     ## ######## ######## ####  ######
#  ##    ## ##       ##       ##            ## ##   ##     ##  ##     ##    ##     ## ###   ### ##          ##     ##  ##    ##
#  ##       ##       ##       ##           ##   ##  ##     ##  ##     ##    ##     ## #### #### ##          ##     ##  ##
#   ######  ######   ##       ######      ##     ## ########   ##     ##    ######### ## ### ## ######      ##     ##  ##
#        ## ##       ##       ##          ######### ##   ##    ##     ##    ##     ## ##     ## ##          ##     ##  ##
#  ##    ## ##       ##       ##          ##     ## ##    ##   ##     ##    ##     ## ##     ## ##          ##     ##  ##    ##
#   ######  ######## ######## ##          ##     ## ##     ## ####    ##    ##     ## ##     ## ########    ##    ####  ######

	negate: ->
			@x = -@x
			@y = -@y
			@z = -@z
			@

	add: (vector) ->
			@x += vector.x
			@y += vector.y
			@z += vector.z
			@

	remove: (vector) ->
			@x -= vector.x
			@y -= vector.y
			@z -= vector.z
			@

	times: (factor) ->
			@x *= factor
			@y *= factor
			@z *= factor
			@

	shrink: (factor) ->
			@x /= factor
			@y /= factor
			@z /= factor
			@

	normalize: -> @.shrink( @.length() )

	round: (digits ) ->
		factor = Math.pow(10,digits)
		@x = Math.round( @x * factor ) / factor
		@y = Math.round( @y * factor ) / factor
		@z = Math.round( @z * factor ) / factor
		@

	round_Tolerances: () ->
		@x = Math.round( @x / Tolerances.float ) * Tolerances.float
		@y = Math.round( @y / Tolerances.float ) * Tolerances.float
		@z = Math.round( @z / Tolerances.float ) * Tolerances.float
		@

#  ##    ## ######## ##      ##    #### ##    ##  ######  ########    ###    ##    ##  ######  ########
#  ###   ## ##       ##  ##  ##     ##  ###   ## ##    ##    ##      ## ##   ###   ## ##    ## ##
#  ####  ## ##       ##  ##  ##     ##  ####  ## ##          ##     ##   ##  ####  ## ##       ##
#  ## ## ## ######   ##  ##  ##     ##  ## ## ##  ######     ##    ##     ## ## ## ## ##       ######
#  ##  #### ##       ##  ##  ##     ##  ##  ####       ##    ##    ######### ##  #### ##       ##
#  ##   ### ##       ##  ##  ##     ##  ##   ### ##    ##    ##    ##     ## ##   ### ##    ## ##
#  ##    ## ########  ###  ###     #### ##    ##  ######     ##    ##     ## ##    ##  ######  ########

	clone: () -> new Vector3D( @.x, @.y, @.z )

	copy: (vector) ->
		@x = vector.x
		@y = vector.y
		@z = vector.z

#                           ###                                                       #
#   #    # ###### #    #     #  #    #  ####  #####   ##   #    #  ####  ######      # #   #####  # ##### #    # #    # ###### ##### #  ####
#   ##   # #      #    #     #  ##   # #        #    #  #  ##   # #    # #          #   #  #    # #   #   #    # ##  ## #        #   # #    #
#   # #  # #####  #    #     #  # #  #  ####    #   #    # # #  # #      #####     #     # #    # #   #   ###### # ## # #####    #   # #
#   #  # # #      # ## #     #  #  # #      #   #   ###### #  # # #      #         ####### #####  #   #   #    # #    # #        #   # #
#   #   ## #      ##  ##     #  #   ## #    #   #   #    # #   ## #    # #         #     # #   #  #   #   #    # #    # #        #   # #    #
#   #    # ###### #    #    ### #    #  ####    #   #    # #    #  ####  ######    #     # #    # #   #   #    # #    # ######   #   #  ####
#


	negative: -> @.clone() .negate()

	plus: (vector) -> @.clone() .add vector

	minus: (vector) -> @.clone() .remove vector
	to: (vector) -> vector.minus @

	multiple: (factor) -> @.clone() .times factor

	multiple_by: (vector) -> new Vector3D( @x * vector.x, @y * vector.y, @z * vector.z)

	divide: (by_factor) -> @.clone() .shrink factor

	divide_by: (vector) -> new Vector3D( @x / vector.x, @y / vector.y, @z / vector.z)

	normal: -> @.clone() .normalize()

	interpolatedTo: (vector, factor) -> ( @.to vector ).times(factor).plus(@)

	cross: (vector) -> new Vector3D(  @y * vector.z - @z * vector.y,
										@z * vector.x - @x * vector.z,
										@x * vector.y - @y * vector.x )



#  ########  ########   #######  ########  ######## ########  ######## #### ########  ######
#  ##     ## ##     ## ##     ## ##     ## ##       ##     ##    ##     ##  ##       ##    ##
#  ##     ## ##     ## ##     ## ##     ## ##       ##     ##    ##     ##  ##       ##
#  ########  ########  ##     ## ########  ######   ########     ##     ##  ######    ######
#  ##        ##   ##   ##     ## ##        ##       ##   ##      ##     ##  ##             ##
#  ##        ##    ##  ##     ## ##        ##       ##    ##     ##     ##  ##       ##    ##
#  ##        ##     ##  #######  ##        ######## ##     ##    ##    #### ########  ######

	length: -> Math.sqrt @scalar @

	length_squared: ->
		@scalar @
	#distanceToSquared: (vector) -> @.minus(vector).lengthSquared()

	scalar: (vector) ->
		@x * vector.x + @y * vector.y + @z * vector.z


	equals: (vector) ->
		@x == vector.x and @y == vector.y and @z == vector.z


	similar: (vector) ->
		@.similar_by vector, Tolerances.float

	similar_by: (vector, tolerance) ->
		-tolerance <= @x - vector.x <= tolerance and -tolerance <= @y - vector.y <= tolerance and -tolerance <= @z - vector.z <= tolerance


	parallel: (vector) ->
		0.0 == @.scalar vector

	orthogonal: (vector) ->
		1.0 == @.scalar vector

	distance_to: (vector) ->
		(@.to vector) .length()
	# length_of @ .to vector

	angle_to: (vector) ->
		theta = @.scalar vector / ( @.length * vector.length )
		Math.acos Math.between theta, -1, 1




	is_normalized: -> 1.0 == @length_squared()

	build_Debug_Support: () ->
		point = new THREE.Mesh( new THREE.SphereGeometry( 0.75, 16, 8 ), new THREE.MeshBasicMaterial( { color: new THREE.Color( 0xFF00FF ) } ) )
		point.position = @
		point



#  ######## ##     ## ########  ######## ########       ##  ######      ######   #######  ##     ## ########     ###    ########  #### ##       #### ######## ##    ##
#     ##    ##     ## ##     ## ##       ##             ## ##    ##    ##    ## ##     ## ###   ### ##     ##   ## ##   ##     ##  ##  ##        ##     ##     ##  ##
#     ##    ##     ## ##     ## ##       ##             ## ##          ##       ##     ## #### #### ##     ##  ##   ##  ##     ##  ##  ##        ##     ##      ####
#     ##    ######### ########  ######   ######         ##  ######     ##       ##     ## ## ### ## ########  ##     ## ########   ##  ##        ##     ##       ##
#     ##    ##     ## ##   ##   ##       ##       ##    ##       ##    ##       ##     ## ##     ## ##        ######### ##     ##  ##  ##        ##     ##       ##
#     ##    ##     ## ##    ##  ##       ##       ##    ## ##    ##    ##    ## ##     ## ##     ## ##        ##     ## ##     ##  ##  ##        ##     ##       ##
#     ##    ##     ## ##     ## ######## ########  ######   ######      ######   #######  ##     ## ##        ##     ## ########  #### ######## ####    ##       ##

	dot: (vector) ->
		@x * vector.x + @y * vector.y + @z * vector.z

	lengthSq: () ->
		@x * @x + @y * @y + @z * @z


	set: ( @x, @y, @z ) -> @
	setX: ( @x ) -> @
	setY: ( @y ) -> @
	setZ: ( @z ) -> @

	setComponent: ( index, value )  ->
		switch index
			when 0 then @x = value
			when 1 then @y = value
			when 2 then @z = value
			else throw new Error( 'index is out of range: ' + index )

	getComponent: ( index ) ->
		switch index
			when 0 then return @x
			when 1 then return @y
			when 2 then return @z
			else throw new Error( 'index is out of range: ' + index )

	addScalar: ( s ) ->
		@.x += s
		@.y += s
		@.z += s
		@


	addVectors: ( a, b ) ->
		@.x = a.x + b.x
		@.y = a.y + b.y
		@.z = a.z + b.z
		@

	sub: ( v ) ->
		@x -= v.x
		@y -= v.y
		@z -= v.z
		@

	subVectors: ( a, b ) ->
		@x = a.x - b.x
		@y = a.y - b.y
		@z = a.z - b.z
		@

	multiply: ( v, w ) ->
		@x *= v.x
		@y *= v.y
		@z *= v.z
		@

	multiplyScalar: ( scalar ) ->
		@x *= scalar
		@y *= scalar
		@z *= scalar
		@

	multiplyVectors: ( a, b ) ->
		@x = a.x * b.x
		@y = a.y * b.y
		@z = a.z * b.z
		@

	applyMatrix3: ( m ) ->
		x = @x
		y = @y
		z = @z
		e = m.elements

		@x = e[0] * x + e[3] * y + e[6] * z
		@y = e[1] * x + e[4] * y + e[7] * z
		@z = e[2] * x + e[5] * y + e[8] * z
		@


	applyMatrix4: ( m ) ->
		x = @x
		y = @y
		z = @z
		e = m.elements

		@x = e[0] * x + e[4] * y + e[8]  * z + e[12]
		@y = e[1] * x + e[5] * y + e[9]  * z + e[13]
		@z = e[2] * x + e[6] * y + e[10] * z + e[14]
		@


	applyProjection: ( m ) ->
		x = @x
		y = @y
		z = @z

		e = m.elements
		d = 1 / ( e[3] * x + e[7] * y + e[11] * z + e[15] )

		@x = ( e[0] * x + e[4] * y + e[8]  * z + e[12] ) * d
		@y = ( e[1] * x + e[5] * y + e[9]  * z + e[13] ) * d
		@z = ( e[2] * x + e[6] * y + e[10] * z + e[14] ) * d
		@

	applyQuaternion: ( q ) ->
		x = @x
		y = @y
		z = @z

		qx = q.x
		qy = q.y
		qz = q.z
		qw = q.w

		ix =  qw * x + qy * z - qz * y
		iy =  qw * y + qz * x - qx * z
		iz =  qw * z + qx * y - qy * x
		iw = -qx * x - qy * y - qz * z

		@x = ix * qw + iw * -qx + iy * -qz - iz * -qy
		@y = iy * qw + iw * -qy + iz * -qx - ix * -qz
		@z = iz * qw + iw * -qz + ix * -qy - iy * -qx
		@

	transformDirection: ( m ) ->
		x = @x
		y = @y
		z = @z
		e = m.elements

		@x = e[0] * x + e[4] * y + e[8]  * z
		@y = e[1] * x + e[5] * y + e[9]  * z
		@z = e[2] * x + e[6] * y + e[10] * z
		@.normalize()


	divideScalar: ( scalar ) ->

		if scalar != 0
			invScalar = 1 / scalar
			@x *= invScalar
			@y *= invScalar
			@z *= invScalar
		else
			@x = 0
			@y = 0
			@z = 0
		@

	min: ( v ) ->
		if @x > v.x
			@x = v.x

		if @y > v.y
			@y = v.y

		if @z > v.z
			@z = v.z
		@


	max: ( v ) ->
		if @x < v.x
			@x = v.x

		if @y < v.y
			@y = v.y

		if @z < v.z
			@z = v.z
		@


	clamp: ( min, max ) ->
		# This function assumes min < max, if this assumption isn't true it will not operate correctly
		if @x < min.x
			@x = min.x;
		else if @x > max.x
			@x = max.x

		if @y < min.y
			@y = min.y
		else if @y > max.y
			@y = max.y

		if @z < min.z
			@z = min.z
		else if @z > max.z
			@z = max.z

		@


	lengthManhattan: () ->
		Math.abs( @x ) + Math.abs( @y ) + Math.abs( @z )


	setLength: ( l ) ->
		oldLength = @.length()
		if oldLength != 0 && l != oldLength
			@.multiplyScalar( l / oldLength )
		@

	lerp: ( v, alpha ) ->
		@x += ( v.x - @x ) * alpha
		@y += ( v.y - @y ) * alpha
		@z += ( v.z - @z ) * alpha
		@

	crossVectors: ( a, b ) ->
		ax = a.x
		ay = a.y
		az = a.z

		bx = b.x
		by1 = b.y
		bz = b.z

		@x = ay * bz - az * by1
		@y = az * bx - ax * bz
		@z = ax * by1 - ay * bx
		@

	angleTo: ( v ) ->
		@.angle_to v


	distanceTo: (v) ->
		@.distance_to v


	distanceToSquared: ( v ) ->
		dx = @x - v.x
		dy = @y - v.y
		dz = @z - v.z

		dx * dx + dy * dy + dz * dz

	setFromMatrixPosition: ( m ) ->
		@x = m.elements[ 12 ]
		@y = m.elements[ 13 ]
		@z = m.elements[ 14 ]
		@

	setFromMatrixScale: ( m ) ->
		sx = @.set( m.elements[ 0 ], m.elements[ 1 ], m.elements[  2 ] ).length()
		sy = @.set( m.elements[ 4 ], m.elements[ 5 ], m.elements[  6 ] ).length()
		sz = @.set( m.elements[ 8 ], m.elements[ 9 ], m.elements[ 10 ] ).length()

		@x = sx
		@y = sy
		@z = sz
		@

	setFromMatrixColumn: ( index, matrix ) ->
		offset = index * 4
		me = matrix.elements

		@x = me[ offset ]
		@y = me[ offset + 1 ]
		@z = me[ offset + 2 ]
		@


	fromArray: ( array ) ->
		@x = array[ 0 ]
		@y = array[ 1 ]
		@z = array[ 2 ]
		@

	toArray: () ->
		[ @x, @y, @z ]

	applyEuler: ( euler ) ->
		quaternion = new THREE.Quaternion()
		if euler instanceof THREE.Euler == no
			console.error( 'ERROR: Vector3\'s .applyEuler() now expects a Euler rotation rather than a Vector3 and order.  Please update your code.' )
		@.applyQuaternion( quaternion.setFromEuler( euler ) )
		@

	applyAxisAngle: ( axis, angle ) ->
		quaternion = new THREE.Quaternion()
		@applyQuaternion( quaternion.setFromAxisAngle( axis, angle ) )
		@


	projectOnVector: ( vector ) ->
		v1 = new THREE.Vector3()
		v1.copy( vector ).normalize()
		d = @.dot( v1 )
		@.copy( v1 ).multiplyScalar( d )


	projectOnPlane: ( planeNormal ) ->
		v1 = new THREE.Vector3()
		v1.copy( this ).projectOnVector( planeNormal )
		@.sub( v1 )

	reflect: ( vector ) ->
		v1 = new THREE.Vector3()
		v1.copy( this ).projectOnVector( vector ).multiplyScalar( 2 )
		@subVectors( v1, this )

module.exports = Vector3D