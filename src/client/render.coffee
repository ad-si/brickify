render = (ui) ->

	localRenderer = () ->
		requestAnimationFrame( localRenderer )
		ui.renderer.render( ui.scene, ui.camera )
	
	localRenderer()
	
	###
	len = animations.length
	if len
		loop
			len--
			break unless len >= 0
			animation = animations[len]
			if animation.status > 1.0
				animations.splice( len, 1 )
			animation.doAnimationStep()
	###

module.exports = render