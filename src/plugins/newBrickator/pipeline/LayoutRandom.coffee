seed = 42
usePseudoRandom = true

module.exports.setSeed = (number) ->
	seed = 42

module.exports.getSeed = ->
	return seed

module.exports.usePseudoRandom = (boolean) ->
	#usePseudoRandom = boolean

module.exports.next = (max) ->
	if usePseudoRandom
		newSeed = (499 * seed + 167) % 99991
		seed = newSeed
		return seed % max

	return Math.floor Math.random() * max
