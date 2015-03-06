module.exports = (chai, utils) ->
	chai.Assertion.addMethod 'modified', (time, delta = 2000) ->
		# the property should always be there
		new chai.Assertion(@_obj).to.have.deep.property('lastModified.date')
		# the date should be between time-delta and time
		assertDate = new chai.Assertion @_obj.lastModified.date
		utils.transferFlags @, assertDate, false
		assertDate.within(time - delta, time)
		return @

	chai.Assertion.addMethod 'cause', (cause) ->
		# the property should always be there
		new chai.Assertion(@_obj).to.have.deep.property('lastModified.cause')
		# the cause should match
		assertCause = new chai.Assertion @_obj.lastModified.cause
		utils.transferFlags @, assertCause, false
		assertCause.equal(cause)
		return @
