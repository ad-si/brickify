###
# Generator for unique alphanumeric identifiers
#
# @module idGenerator
###

chars = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

pattern = (length) ->
	return new RegExp("^[#{chars}]{#{length}}$")

acceptAllFilter = -> true

###
# Generates a unique alphanumeric identifier
#
# @param {Function} filter a function that returns false for existent ids and
#   true for unique ones.
# @param {Number} length the number of characters in the id
# @return {String} id
#
# @memberOf idGenerator
###
module.exports.generate = (filter = acceptAllFilter, length = 8) ->
	generate = ->
		id = ''
		for i in [0...length] by 1
			index = Math.floor((Math.random() * chars.length))
			id += chars[index]
		return id

	maxNumberOfTries = Math.pow chars.length, length

	for i in [0..maxNumberOfTries] by 1
		return id if filter id = generate()

	return null #no id could be found that was accepted by the filter

###
# Checks an identifier for syntactical correctness
#
# @param {String} id the identifier
# @param {Number} length the required length of the identifier
# @return {Boolean} true/false depending on the correctness of the identifier
#
# @memberOf idGenerator
###
module.exports.check = (id, length = 8) ->
	return pattern(length).test id
