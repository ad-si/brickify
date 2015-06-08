module.exports.generateScad = (bricks) ->
	scad = _scadDisclaimer()

	bricks.forEach (brick) ->
		pos = "[#{brick.getPosition().x},
		#{brick.getPosition().y},#{brick.getPosition().z}]"
		size = "[#{brick.getSize().x},#{brick.getSize().y},#{brick.getSize().z}]"
		scad += "GridTranslate(#{pos}){ Brick(#{size}); }\n"

	scad += '\n\n'
	scad += _scadBase()

	return {
		fileName: 'bricks.scad'
		data: scad
	}

_scadDisclaimer = ->
	return '
		/*\n
		 * \n
		 * Brick layout for openSCAD\n
		 * Generated with http://brickify.it\n
		 *\n
		 */\n\n
	'

_scadBase = ->
	return '
		gridSpacing = [8, 8, 3.2];
		brickSpacing = [0.2, 0.2, 0.2];
		studRadius = 2.4;
		holeRadius = 2.6;
		studHeight = 1.8;

		module GridTranslate(position){
		    translate([
		        position[0] * gridSpacing[0] + brickSpacing[0]/2,
		        position[1] * gridSpacing[1] + brickSpacing[1]/2,
		        position[2] * gridSpacing[2]
		    ]){
		        children();
		    }
		}

		module Brick(size){
		    difference(){
		        union(){
		            cube([
		            size[0] * gridSpacing[0] - brickSpacing[0],
		            size[1] * gridSpacing[1] - brickSpacing[1],
		            size[2] * gridSpacing[2] - brickSpacing[2]], false);

		            for ( sx = [1 : size[0]]){
		                for ( sy = [1 : size[1]]){
		                    tx = sx * gridSpacing[0] - gridSpacing[0]/2
		                    - brickSpacing[0]/2;
		                    ty = sy * gridSpacing[1] - gridSpacing[1]/2
		                    - brickSpacing[1]/2;
		                    tz = size[2] * gridSpacing[2] - brickSpacing[2];
		                    translate([tx, ty, tz]){
		                        cylinder(r = studRadius, h = studHeight, $fs = 0.5);
		                    }
		                }
		            }
		        }
		        union(){
		            for ( sx = [1 : size[0]]){
		                for ( sy = [1 : size[1]]){
		                    tx = sx * gridSpacing[0] - gridSpacing[0]/2
		                    - brickSpacing[0]/2;
		                    ty = sy * gridSpacing[1] - gridSpacing[1]/2
		                    - brickSpacing[1]/2;
		                    tz = 0;
		                    translate([tx, ty, tz - brickSpacing.z]){
		                        cylinder(
		                        	r = holeRadius,
		                        	h = 2 + brickSpacing.z,
		                        	$fs = 0.5
		                        );
		                    }
		                }
		            }
		        }
		    }
		}
	'
