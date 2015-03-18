###
# A reentrant-save spinner that can be invoked for a html target node.
# @module Spinner
###
Spin = require 'spin'
$ = require 'jquery'

spinners = new Map()
defaultTarget = document.createElement 'div'
defaultTarget.id = 'body-spinner'
document.body.appendChild defaultTarget

options =
	shadow: true
	hwaccel: true
	color: '#fff'

###
# Starts a spinner attached to the given target node.
# @param {DOMNode} [target=document.body] the target node
# @return {Number} the number of start invocations of this spinner
# @memberOf Spinner
###
start = (target) ->
	target ?= defaultTarget

	spinnerState = spinners.get target
	unless spinnerState?
		spin = new Spin(options).spin()
		target.appendChild spin.el
		spinnerState = spin: spin, count: 0
		spinners.set target, spinnerState

	return ++spinnerState.count
module.exports.start = start

###
# Starts a spinner located centered above the given target node.
# @param {DOMNode} [target=document.body] the target node
# @return {Number} the number of start invocations of this spinner
# @memberOf Spinner
###
startOverlay = (target) ->
	return start() unless target?

	spinnerState = spinners.get target
	unless spinnerState?
		spin = new Spin(options).spin()
		overlay = document.createElement 'div'
		overlay.className = 'overlay-spinner'
		overlay.appendChild spin.el
		$target = $(target)
		offset = $target.offset()
		top = offset.top + $target.height() / 2
		left = offset.left + $target.width() / 2
		overlay.style.cssText = "top: #{top}px; left: #{left}px;"
		document.body.appendChild overlay
		spinnerState = spin: spin, count: 0, overlay: overlay
		spinners.set target, spinnerState

	spinnerState.count++
module.exports.startOverlay = startOverlay

###
# Stops a spinner associated with the given target node.
# @param {DOMNode} [target=document.body] the target node
# @return {Number} the number of remaining start invocations of this spinner
# @memberOf Spinner
###
stop = (target) ->
	target ?= defaultTarget

	spinnerState = spinners.get target
	return unless spinnerState

	spinnerState.count--
	return spinnerState.count if spinnerState.count > 0

	spinnerState.spin.stop()

	if spinnerState.overlay?
		document.body.removeChild spinnerState.overlay

	spinners.delete target
	return 0
module.exports.stop = stop
