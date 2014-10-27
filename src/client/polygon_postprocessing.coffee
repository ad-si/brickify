mergeUnmergedPolygons = (listOfPoly) ->
	# merge last unmerged polygons
	#listOfPoly = sorted(listOfPoly, key=lambda poly: poly.length, reverse=True)

	listOfPoly.sort(
		(a,b) ->
			return if a.length < b.length then 1 else -1
	)

	polygons_to_merge = {}
	throw_away_polygons = []


	for polygons_index_outer in [0...listOfPoly.length]
		continue if polygons_index_outer in throw_away_polygons

		poly_outer = listOfPoly[polygons_index_outer]
		poly_index_outer = 0
		points_merged = 0
		#is_outer_contour = isClockWise(poly_outer)

		for poly_index_outer in [0...poly_outer.length]

			p1 = poly_outer[poly_index_outer]
			poly_index_outer2 = if (poly_index_outer is (poly_outer.length-1))
			then 0 else poly_index_outer+1

			p2 = poly_outer[poly_index_outer2]
			polygons_index_inner = 0

			for polygons_index_inner in [polygons_index_outer+1...
				listOfPoly.length]
				continue if polygons_index_inner in throw_away_polygons

				poly_inner = listOfPoly[polygons_index_inner]
				poly_index_inner = 0

				# don't merge holes with contours
				#is_inner_hole = not isClockWise(poly_inner)
				#if is_inner_hole
				#	throw_away_polygons.push(polygons_index_inner)
				#	continue

				for poly_index_inner in [0...poly_inner.length]
					p3 = poly_inner[poly_index_inner]
					poly_index_inner2 =
						if (poly_index_inner is (poly_inner.length-1))
						then 0 else poly_index_inner+1
					p4 = poly_inner[poly_index_inner2]

					if arePointsOnSameLineSegment(p3, p4, p1, p2)
						# check direction if it is a hole
						if p3.distanceTo(p1) < p4.distanceTo(p1)
							p_first = poly_index_inner
							poly_range = [0...poly_inner.length]
						else
							p_first = poly_index_inner2
							poly_range = [0...poly_inner.length].reverse()

						throw_away_polygons.push(polygons_index_inner)
						key = [polygons_index_outer, poly_index_outer,
							poly_index_outer2].join()
						if not polygons_to_merge[key] != "undefined"
							polygons_to_merge[key] = {}

						polygons_to_merge[key][polygons_index_inner] =
							((if c+p_first < poly_inner.length
							then c+p_first
							else c+p_first-poly_inner.length
							) for c in poly_range)
						break

	# sort index concerning to insert position which is the index
	# of p2 -> begin with biggest index

	# polygons_to_merge = sorted(polygons_to_merge.items(),
	# key=lambda x: x[0].p2_idx, reverse=true)
	console.log polygons_to_merge
	console.log throw_away_polygons
	tuples = ([key, poly] for key, poly of polygons_to_merge)
	tuples.sort(
		(a, b) ->
			akeys = a[0].split(',')
			ap2_idx = parseInt(akeys[2])
			bkeys = b[0].split(',')
			bp2_idx = parseInt(bkeys[2])
			return if ap2_idx < bp2_idx then 1 else -1
	)
	polygons_to_merge = {}
	for i in [0...tuples.length]
		key = tuples[i][0]
		value = tuples[i][1]
		polygons_to_merge[key] = value

	for key, merge of polygons_to_merge
		keys = key.split(',')
		target_idx = parseInt(keys[0])
		p1_idx = parseInt(keys[1])
		p2_idx = parseInt(keys[2])
		target = listOfPoly[target_idx]
		target_p1 = target[p1_idx]
		target_key = p2_idx+c

		tuples = ([k, poly] for k, poly of merge)
		tuples.sort(
			(a, b) ->
				result = listOfPoly[a[0]][a[1][0]].distanceTo(target_p1) <
					listOfPoly[b[0]][b[1][0]].distanceTo(target_p1)
				return if result then 1 else -1
		)

		for item in tuples
			merge_poly = listOfPoly[item[0]]
			for merge_vertex_idx in item[1]
				listOfPoly[target_idx].splice(target_key, 0, merge_poly[merge_vertex_idx])

	listOfPoly = (poly for poly, idx in listOfPoly when idx not
		in throw_away_polygons and poly.length > 2)


arePointsOnSameLineSegment = (p1, p2, p3, p4) ->
	v = new THREE.Vector2( p4.x - p3.x, p4.y - p3.y)

	threshhold = Math.pow(10,-1)
	if p3.x != p4.x
	    t1 = (p1.x - p3.x) / v.x # 0.333333019
	    if t1 > 1.0+threshhold or t1 < 0.0-threshhold or not
	    isInRange( p1.y -  ( p3.y + t1*v.y ), threshhold ) # −0.000100007
	        return false
	    t2 = (p2.x - p3.x) / v.x # 0.666666981
	    if t2 > 1.0+threshhold or t2 < 0.0-threshhold or not
	    isInRange( p2.y - ( p3.y + t2*v.y ), threshhold ) #
	        return false
	else if p3.y != p4.y
	    t3 = (p1.y - p3.y) / v.y
	    if t3 > 1.0+threshhold or t3 < 0.0-threshhold or not
	    isInRange( p1.x - ( p3.x + t3*v.x ), threshhold )
	        return false
	    t4 = (p2.y - p3.y) / v.y
	    if t4 > 1.0+threshhold or t4 < 0.0-threshhold or not
	    isInRange( p2.x - ( p3.x + t4*v.x ), threshhold )
	        return false
	else
	    return false
	return true


arePointPairsEqual = (p1, p2, p3, p4) ->
	threshhold = Math.pow(10, -3)
	result = true

	result &&= isInRange(p1.x - p3.x, threshhold) or
		isInRange(p1.x - p4.x, threshhold)

	result &&= isInRange(p2.x - p3.x, threshhold) or
		isInRange(p2.x - p4.x, threshhold)

	result &&= isInRange(p1.y - p3.y, threshhold) or
		isInRange(p1.y - p4.y, threshhold)

	result &&= isInRange(p2.y - p3.y, threshhold) or
		isInRange(p2.y - p4.y, threshhold)

	return result


# vector3 poly
removeCollinearPoints = (listOfPoly) ->
	# throw away all vertices which lie on same line
	polygons_merged = []
	#for iii in range(0,3):
	for poly in listOfPoly
		throw_away_vertices = []
		i = 0
		while i < poly.length
			if i==poly.length-2
				i2 = i+1
				i3 = 0
			else if i==poly.length-1
				i2 = 0
				i3 = 1
			else
				i2 = i+1
				i3 = i+2

			sub_poly = [poly[i], poly[i2], poly[i3]]
			c = 0
			# also check small area sub polys?
			while pointsOnOneLine( sub_poly )
				#print(sub_poly)
				#print('throw away ' + str(poly[i2].x) + ', ' + str(poly[i2].y))
				throw_away_vertices.push(i2)
				i2 = if i2 == (poly.length-1) then 0 else i2+1
				sub_poly.push(poly[i2])
				c += 1
			if c != 0
				throw_away_vertices.pop()
			i = if c!=0 then i+c else i+1

		#throw_away_vertices.pop()
		new_poly = (p for p, idx in poly when idx not in throw_away_vertices)
		polygons_merged.push(new_poly)

	return polygons_merged

# for original poly
polygonAreaOverThreshhold = (poly, threshhold) ->
	sum = 0
	for i in [0...poly.getNumPoints()-1]
		x1 = poly.getX(i)
		y1 = poly.getY(i)
		x2 = poly.getX(i+1)
		y2 = poly.getY(i+1)

		sum += x1*y2 - y1*x2

	x1 = poly.getX(poly.getNumPoints()-1)
	y1 = poly.getY(poly.getNumPoints()-1)
	x2 = poly.getX(0)
	y2 = poly.getY(0)

	sum += x1*y2 - y1*x2
	return Math.abs(sum / 2.0) > threshhold

isInRange = (val, threshhold) ->
	return Math.abs(val) < threshhold

# for vector3 poly lists
pointsOnOneLine = (poly) ->
	threshhold = Math.pow(10,-2)

	x2 = poly[poly.length-1].x
	y2 = poly[poly.length-1].y
	x1 = poly[0].x
	y1 = poly[0].y

	if not isInRange( x2-x1 , threshhold)
		b = -1
		a = (y2 - y1)/(x2 - x1)
	else if not isInRange( y2 - y1, threshhold )
		a = -1
		b = (x2 - x1)/(y2 - y1)
	else
		return true
	c = -a * x1 - b * y1

	for i in [0...poly.length]
		x = poly[i].x
		y = poly[i].y
		if not isInRange( x*a + y*b + c, threshhold )
			return false

	return true

isClockWise = (poly) ->
	#(x2-x1)(y2+y1)
	sum = 0.0
	for i in [i...poly.length]
		p1 = p[i]
		p2 = if i == poly.length-1 then 0 else poly[i+1]
		sum += (p2.x-p1.x)*(p2.y+p1.y)
	return sum < 0

removeDuplicates = (listOfPoly) ->
	threshhold = Math.pow(10, -3)
	# throw away nearly equal vertices
	for poly in listOfPoly
		i = poly.length
		loop
			--i
			break if i < 0
			p1 = poly[i]
			p2 = if i == 0 then poly[poly.length-1] else poly[i-1]
			if isInRange(p1.distanceTo( p2 ), threshhold)
				poly.splice(i, 1)
				i += 2

		#polygons_merged.push(distinct_vertices) if distinct_vertices.length > 2

	return listOfPoly

exports =
	mergeUnmergedPolygons: mergeUnmergedPolygons
	arePointsOnSameLineSegment : arePointsOnSameLineSegment
	arePointPairsEqual: arePointPairsEqual
	removeCollinearPoints: removeCollinearPoints
	polygonAreaOverThreshhold: polygonAreaOverThreshhold
	isInRange: isInRange
	pointsOnOneLine: pointsOnOneLine
	isClockWise: isClockWise
	removeDuplicates: removeDuplicates
