module.exports = {
	# Everything that is lego
	legoMask: 0x01
	# Every object that is visible
	visibleObjectMask: 0x01 << 1
	# Every object that is hidden
	hiddenObjectMask: 0x01 << 2
	# Every visible shadow
	visibleShadowMask: 0x01 << 3
}
