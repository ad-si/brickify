module.exports = {
	# everything that is lego
	legoMask: 0x01
	# every object that is visible
	visibleObjectMask: 0x01 << 1
	# every object that is hidden
	hiddenObjectMask: 0x01 << 2
	# every visible shadow
	visibleShadowMask: 0x01 << 3
}
