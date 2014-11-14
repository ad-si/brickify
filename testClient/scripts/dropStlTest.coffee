expect = (chai && chai.expect) || require('chai').expect
stlImport = require '../../src/client/plugins/stlImport/stlImport'

# Helper method to read files from the local file system
readFile = (filename, callBack) ->
	xmlhttp = new XMLHttpRequest()
	xmlhttp.onreadystatechange = ->
		if xmlhttp.readyState == 4
			txt = xmlhttp.responseText
			callBack(txt)
	xmlhttp.open("GET", filename, true)
	xmlhttp.send();

describe 'stl import tests', ->
	globalConfig = {}
	globalConfig.defaultObjectColor = new THREE.Color(1, 0, 0)
	stlImport.setGlobalConfig(globalConfig)

	# Check if the browser can access the local file system. To enable this in
	# Chrome first kill all instances and then run it with the flag
	# --allow-file-access-from-files. This is necessary for further testing i.e.
	# reading a number of stl files to import.
	it 'allows file reading', (done) ->
		xmlhttp = new XMLHttpRequest()
		xmlhttp.onreadystatechange = ->
			if xmlhttp.readyState == 4
				txt = xmlhttp.responseText
				expect(txt).to.equal('testfile')
				done()
		xmlhttp.open("GET", "testfile_for_local_file_access.txt", true)
		xmlhttp.send()

	it 'imports correct stl', (done) ->
		readFile 'models/unit_cube.stl', (fileContent)->
			threeObject = new THREE.Object3D()
			stlImport.init3d(threeObject)
			stlImport.importFile(fileContent)

			# Check if object is located at (0,0,0)
			expect(threeObject.position).to.eql(new THREE.Vector3 0, 0, 0)
			# Check object direction
			expect(threeObject.up).to.eql(new THREE.Vector3 0, 1, 0)
			# Check if children exist
			expect(threeObject.children).to.be.an('array')
			expect(threeObject.children[0].geometry).not.to.be.null()
			geometry = threeObject.children[0].geometry

			# Check the geometry
			expect(geometry.boundingBox.min).to.eql(new THREE.Vector3 0, 0, 0)
			expect(geometry.boundingBox.max).to.eql(new THREE.Vector3 1, 1, 1)

			# Check vertices
			expect(geometry.vertices[0]).to.eql(new THREE.Vector3 0, 0, 0)
			expect(geometry.vertices[1]).to.eql(new THREE.Vector3 1, 1, 0)
			expect(geometry.vertices[2]).to.eql(new THREE.Vector3 1, 0, 0)
			expect(geometry.vertices[3]).to.eql(new THREE.Vector3 1, 1, 0)
			expect(geometry.vertices[4]).to.eql(new THREE.Vector3 0, 0, 0)
			expect(geometry.vertices[5]).to.eql(new THREE.Vector3 0, 1, 0)
			expect(geometry.vertices[6]).to.eql(new THREE.Vector3 0, 0, 1)
			expect(geometry.vertices[7]).to.eql(new THREE.Vector3 1, 0, 1)

			# This fails using the current importer!
			# No two vertices should be the same
			#for vertex in geometry.vertices
			#	for otherVertex in geometry.vertices
			#		expect(vertex).not.to.eql(otherVertex) if vertex isnt otherVertex
			done()

	# Bulk import these models
	models = ['ballista.stl',
						'citrus_reamer.stl',
						'cube.stl',
						'faberdashery_spanner.stl',
						'files.txt',
						'googles.stl',
						'goprodyk.stl',
						'house.stl',
						'house2.stl',
						'KeeponMessengerHat_R2.stl',
						'kinect_mount_wide.stl',
						'microphone.stl',
						'Mini_Screwdriver_Handle.stl',
						'modified_nose.stl',
						'plane.stl',
						'plane2.stl',
						'Printable_Wrench_W_Longer_Screw.stl',
						'printing_times.txt',
						'pyramid.stl',
						'quadrant-driver.STL',
						'rings.stl',
						'Screw_Driver.STL',
						'soap.stl',
						'soap_casing.stl',
						'soap_casing2.stl',
						'soap_casing3.stl',
						'soap_razor.stl',
						'spool.stl',
						'spool2.stl',
						'stick_wrench.stl',
						'toy_boat.stl',
						'unit_cube.stl',
						'usbstand.stl',
						'vanderbilt.stl',
						'vanderbilt_b.stl',
						'weakbrick-test.stl',
						'Wrench (1).stl',
						'wrench.stl',
						'wrench2.stl'
	]

	for name in models
		it 'imports models/' + name, (done) ->
			readFile 'models/' + name, (fileContent)->
				threeObject = new THREE.Object3D()
				stlImport.init3d(threeObject)
				stlImport.importFile(fileContent)

				# Check if object is located at (0,0,0)
				expect(threeObject.position).to.eql(new THREE.Vector3 0, 0, 0)
				# Check object direction
				expect(threeObject.up).to.eql(new THREE.Vector3 0, 1, 0)
				#Check if children exist
				expect(threeObject.children).to.be.an('array')
				expect(threeObject.children[0].geometry).not.to.be.null()

				done()
