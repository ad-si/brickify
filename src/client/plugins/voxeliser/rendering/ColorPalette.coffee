class ColorPalette
  constructor: (@hue, @saturation, @lightness) ->
    @base = new THREE.Color().setHSL @hue, @saturation, @lightness
    @specular = @variation 0.05, -0.1, 0.05
    @hard_edge = @variation 0, -0.2, -0.2
    @edge    = @variation 0, -0.2, -0.2
    @triangle  = @variation 0, -0.1, -0.05

    @customBrick = @variation 0.2, -0.1, 0.2
    @customBrick_specular = @variation 0.25, -0.2, 0.25

    @selected = @variation 0.52, -0.3, 0.2
    @selected_specular = @variation 0.52, -0.3, 0.2

    @error = @variation 0.0 - @hue, 1.0, 0.5 - @lightness

  clone: () -> new @( @hue, @saturation, @lightness ) 

  get_Variation: (factor) ->
    h = ( Math.random() * factor/2) - factor/4
    s = ( Math.random() * 2 * factor) - factor
    l = ( Math.random() * factor) - factor / 2
    new ColorPalette( @hue + h, @saturation + s, @lightness + l) 

  get_Variation_of_Base: (factor) ->
    h = ( Math.random() * factor/5) - factor/10
    s = ( Math.random() * 2 * factor) - factor
    l = ( Math.random() * 2 * factor) - factor
    new THREE.Color().setHSL( @hue + h, @saturation + s, @lightness + l) 

  get_Variation_of_Color: (color, factor) ->
    hsl = color.getHSL()
    h = ( Math.random() * factor/5) - factor/10
    s = ( Math.random() * 2 * factor) - factor
    l = ( Math.random() * 2 * factor) - factor
    new THREE.Color().setHSL( hsl.h + h, hsl.s + s, hsl.l + l) 


  variation: (delta_hue, delta_saturation, delta_lightness) ->
    changed_hue        =  ((@hue + delta_hue) % 1 + 1) % 1
    changed_saturation =  @saturation #Math.between @saturation + delta_saturation, 0, 1.0
    changed_lightness  =  @lightness #Math.between @lightness + delta_lightness, 0, 1.0

    new THREE.Color().setHSL changed_hue, changed_saturation, changed_lightness



  @default: () -> @.orange()

  @orange: () -> new @( 0.06, 0.8, 0.5)
  @yellow: () -> new @( 0.1, 0.9, 0.5)
  @grass_green: () -> new @( 0.2, 0.4, 0.5)
  @green: () -> new @( 0.3, 0.4, 0.35)
  @gray: () -> new @( 0.00, 0.0, 0.65)
  @cyan: () -> new @( 0.5, 0.8, 0.45)
  
  @blau: () -> new @( 0.55, 0.8, 0.3)

  @next: () ->
    @color_list ?= [
      @.orange(),
      @.yellow(), 
      @.grass_green(), 
      @.green(),
      @.orange(), 
      @.gray(),
      @.gray(),
    ]

    @index ?= 0
    color = @color_list[@index++ % @color_list.length]


module.exports = ColorPalette
