expect = require('chai').expect
stlLoader = require '../src/plugins/stlImport/stlLoader'
fs = require 'fs'

OptimizedModel = require '../src/common/OptimizedModel'


describe 'OptimizedMesh', () ->
	before (done) ->
		done()

	describe 'Manifoldness', () ->
		it 'should be two-manifold', (done) ->
			m = loadOptimizedModel('test/models/unitCube.bin.stl')
			expect(m.isTwoManifold()).to.equal(true)
			done()
		it 'should not be two-manifold', (done) ->
			m = loadOptimizedModel('test/models/missingFace.stl')
			expect(m.isTwoManifold()).to.equal(false)
			done()
	after () ->
		return

loadOptimizedModel = (fileName) ->
	fileContent = fs.readFileSync fileName, {encoding: 'utf8'}
	optimized = stlLoader.parse fileContent
	return optimized
