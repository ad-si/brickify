expect = require('chai').expect
idGenerator = require '../../src/server/sync/idGenerator'

describe 'id generator tests', ->
	it 'should only contain alphanumeric characters', ->
		id = idGenerator.generate()
		expect(id).to.match(/^[a-zA-z0-9]+$/)

	it 'should generate and validate according to the same pattern', ->
		id = idGenerator.generate()
		expect(idGenerator.check(id)).to.be.ok()

	it 'should generate ids of the correct length', ->
		acceptingFilter = -> true
		id = idGenerator.generate acceptingFilter, 5
		expect(id).to.have.length(5)

	it 'should abort if the filter does not accept any id', ->
		rejectingFilter = -> false
		id = idGenerator.generate rejectingFilter, 3
		expect(id).to.be.null
