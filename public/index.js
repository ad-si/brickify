(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
module.exports={"mm":1,"fov":40,"cameraNearPlane":0.1,"cameraFarPlane":1000,"animationStepSize":0.02,"animations":[],"axisLength":100,"axisXColor":16711680,"axisYColor":65280,"axisZColor":255,"axisLineWidth":2,"defaultObjectColor":13412915,"meshes":[],"gridColorNormal":13421772,"gridColor5":10066329,"gridColor10":6710886,"gridLineWidthNormal":1,"gridLineWidth5":1,"gridLineWidth10":1,"gridSize":200,"gridStepSize":10}
},{}],2:[function(require,module,exports){
(function() {
  var globalConfig, path, renderer, ui;

  globalConfig = require('./globals.json');

  path = require('path');


  /* TODO: move somewhere where it is needed
   * geometry functions
  degToRad = ( deg ) -> deg * ( Math.PI / 180.0 )
  radToDeg = ( rad ) -> deg * ( 180.0 / Math.PI )
  
  normalFormToParamterForm = ( n, p, u, v) ->
  	u.set( 0, -n.z, n.y ).normalize()
  	v.set( n.y, -n.x, 0 ).normalize()
  
   * utility
  String::contains = (str) -> -1 isnt this.indexOf str
   */

  ui = require("./ui")(globalConfig);

  ui.init();

  renderer = require("./render");

  renderer(ui);

}).call(this);

},{"./globals.json":1,"./render":4,"./ui":5,"path":6}],3:[function(require,module,exports){
(function() {
  var arePointPairsEqual, arePointsOnSameLineSegment, exports, isClockWise, isInRange, mergeUnmergedPolygons, pointsOnOneLine, polygonAreaOverThreshhold, removeCollinearPoints, removeDuplicates,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  mergeUnmergedPolygons = function(listOfPoly) {
    var c, i, idx, item, k, key, keys, merge, merge_poly, merge_vertex_idx, p1, p1_idx, p2, p2_idx, p3, p4, p_first, points_merged, poly, poly_index_inner, poly_index_inner2, poly_index_outer, poly_index_outer2, poly_inner, poly_outer, poly_range, polygons_index_inner, polygons_index_outer, polygons_to_merge, target, target_idx, target_key, target_p1, throw_away_polygons, tuples, value, _i, _j, _k, _l, _len, _len1, _m, _n, _o, _p, _q, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _results, _results1;
    listOfPoly.sort(function(a, b) {
      if (a.length < b.length) {
        return 1;
      } else {
        return -1;
      }
    });
    polygons_to_merge = {};
    throw_away_polygons = [];
    for (polygons_index_outer = _i = 0, _ref = listOfPoly.length; 0 <= _ref ? _i < _ref : _i > _ref; polygons_index_outer = 0 <= _ref ? ++_i : --_i) {
      if (__indexOf.call(throw_away_polygons, polygons_index_outer) >= 0) {
        continue;
      }
      poly_outer = listOfPoly[polygons_index_outer];
      poly_index_outer = 0;
      points_merged = 0;
      for (poly_index_outer = _j = 0, _ref1 = poly_outer.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; poly_index_outer = 0 <= _ref1 ? ++_j : --_j) {
        p1 = poly_outer[poly_index_outer];
        poly_index_outer2 = poly_index_outer === (poly_outer.length - 1) ? 0 : poly_index_outer + 1;
        p2 = poly_outer[poly_index_outer2];
        polygons_index_inner = 0;
        for (polygons_index_inner = _k = _ref2 = polygons_index_outer + 1, _ref3 = listOfPoly.length; _ref2 <= _ref3 ? _k < _ref3 : _k > _ref3; polygons_index_inner = _ref2 <= _ref3 ? ++_k : --_k) {
          if (__indexOf.call(throw_away_polygons, polygons_index_inner) >= 0) {
            continue;
          }
          poly_inner = listOfPoly[polygons_index_inner];
          poly_index_inner = 0;
          for (poly_index_inner = _l = 0, _ref4 = poly_inner.length; 0 <= _ref4 ? _l < _ref4 : _l > _ref4; poly_index_inner = 0 <= _ref4 ? ++_l : --_l) {
            p3 = poly_inner[poly_index_inner];
            poly_index_inner2 = poly_index_inner === (poly_inner.length - 1) ? 0 : poly_index_inner + 1;
            p4 = poly_inner[poly_index_inner2];
            if (arePointsOnSameLineSegment(p3, p4, p1, p2)) {
              if (p3.distanceTo(p1) < p4.distanceTo(p1)) {
                p_first = poly_index_inner;
                poly_range = (function() {
                  _results = [];
                  for (var _m = 0, _ref5 = poly_inner.length; 0 <= _ref5 ? _m < _ref5 : _m > _ref5; 0 <= _ref5 ? _m++ : _m--){ _results.push(_m); }
                  return _results;
                }).apply(this);
              } else {
                p_first = poly_index_inner2;
                poly_range = (function() {
                  _results1 = [];
                  for (var _n = 0, _ref6 = poly_inner.length; 0 <= _ref6 ? _n < _ref6 : _n > _ref6; 0 <= _ref6 ? _n++ : _n--){ _results1.push(_n); }
                  return _results1;
                }).apply(this).reverse();
              }
              throw_away_polygons.push(polygons_index_inner);
              key = "" + polygons_index_outer + "," + poly_index_outer + "," + poly_index_outer2;
              if (!polygons_to_merge[key] !== "undefined") {
                polygons_to_merge[key] = {};
              }
              polygons_to_merge[key][polygons_index_inner] = (function() {
                var _len, _o, _results2;
                _results2 = [];
                for (_o = 0, _len = poly_range.length; _o < _len; _o++) {
                  c = poly_range[_o];
                  _results2.push(c + p_first < poly_inner.length ? c + p_first : c + p_first - poly_inner.length);
                }
                return _results2;
              })();
              break;
            }
          }
        }
      }
    }
    console.log(polygons_to_merge);
    console.log(throw_away_polygons);
    tuples = (function() {
      var _results2;
      _results2 = [];
      for (key in polygons_to_merge) {
        poly = polygons_to_merge[key];
        _results2.push([key, poly]);
      }
      return _results2;
    })();
    tuples.sort(function(a, b) {
      var akeys, ap2_idx, bkeys, bp2_idx;
      akeys = a[0].split(',');
      ap2_idx = parseInt(akeys[2]);
      bkeys = b[0].split(',');
      bp2_idx = parseInt(bkeys[2]);
      if (ap2_idx < bp2_idx) {
        return 1;
      } else {
        return -1;
      }
    });
    polygons_to_merge = {};
    for (i = _o = 0, _ref7 = tuples.length; 0 <= _ref7 ? _o < _ref7 : _o > _ref7; i = 0 <= _ref7 ? ++_o : --_o) {
      key = tuples[i][0];
      value = tuples[i][1];
      polygons_to_merge[key] = value;
    }
    for (key in polygons_to_merge) {
      merge = polygons_to_merge[key];
      keys = key.split(',');
      target_idx = parseInt(keys[0]);
      p1_idx = parseInt(keys[1]);
      p2_idx = parseInt(keys[2]);
      target = listOfPoly[target_idx];
      target_p1 = target[p1_idx];
      target_key = p2_idx + c;
      tuples = (function() {
        var _results2;
        _results2 = [];
        for (k in merge) {
          poly = merge[k];
          _results2.push([k, poly]);
        }
        return _results2;
      })();
      tuples.sort(function(a, b) {
        var result;
        result = listOfPoly[a[0]][a[1][0]].distanceTo(target_p1) < listOfPoly[b[0]][b[1][0]].distanceTo(target_p1);
        if (result) {
          return 1;
        } else {
          return -1;
        }
      });
      for (_p = 0, _len = tuples.length; _p < _len; _p++) {
        item = tuples[_p];
        merge_poly = listOfPoly[item[0]];
        _ref8 = item[1];
        for (_q = 0, _len1 = _ref8.length; _q < _len1; _q++) {
          merge_vertex_idx = _ref8[_q];
          listOfPoly[target_idx].splice(target_key, 0, merge_poly[merge_vertex_idx]);
        }
      }
    }
    return listOfPoly = (function() {
      var _len2, _r, _results2;
      _results2 = [];
      for (idx = _r = 0, _len2 = listOfPoly.length; _r < _len2; idx = ++_r) {
        poly = listOfPoly[idx];
        if (__indexOf.call(throw_away_polygons, idx) < 0 && poly.length > 2) {
          _results2.push(poly);
        }
      }
      return _results2;
    })();
  };

  arePointsOnSameLineSegment = function(p1, p2, p3, p4) {
    var t1, t2, t3, t4, threshhold, v;
    v = new THREE.Vector2(p4.x - p3.x, p4.y - p3.y);
    threshhold = Math.pow(10, -1);
    if (p3.x !== p4.x) {
      t1 = (p1.x - p3.x) / v.x;
      if (t1 > 1.0 + threshhold || t1 < 0.0 - threshhold || !isInRange(p1.y - (p3.y + t1 * v.y), threshhold)) {
        return false;
      }
      t2 = (p2.x - p3.x) / v.x;
      if (t2 > 1.0 + threshhold || t2 < 0.0 - threshhold || !isInRange(p2.y - (p3.y + t2 * v.y), threshhold)) {
        return false;
      }
    } else if (p3.y !== p4.y) {
      t3 = (p1.y - p3.y) / v.y;
      if (t3 > 1.0 + threshhold || t3 < 0.0 - threshhold || !isInRange(p1.x - (p3.x + t3 * v.x), threshhold)) {
        return false;
      }
      t4 = (p2.y - p3.y) / v.y;
      if (t4 > 1.0 + threshhold || t4 < 0.0 - threshhold || !isInRange(p2.x - (p3.x + t4 * v.x), threshhold)) {
        return false;
      }
    } else {
      return false;
    }
    return true;
  };

  arePointPairsEqual = function(p1, p2, p3, p4) {
    var result, threshhold;
    threshhold = Math.pow(10, -3);
    result = true;
    result && (result = isInRange(p1.x - p3.x, threshhold) || isInRange(p1.x - p4.x, threshhold));
    result && (result = isInRange(p2.x - p3.x, threshhold) || isInRange(p2.x - p4.x, threshhold));
    result && (result = isInRange(p1.y - p3.y, threshhold) || isInRange(p1.y - p4.y, threshhold));
    result && (result = isInRange(p2.y - p3.y, threshhold) || isInRange(p2.y - p4.y, threshhold));
    return result;
  };

  removeCollinearPoints = function(listOfPoly) {
    var c, i, i2, i3, idx, new_poly, p, poly, polygons_merged, sub_poly, throw_away_vertices, _i, _len;
    polygons_merged = [];
    for (_i = 0, _len = listOfPoly.length; _i < _len; _i++) {
      poly = listOfPoly[_i];
      throw_away_vertices = [];
      i = 0;
      while (i < poly.length) {
        if (i === poly.length - 2) {
          i2 = i + 1;
          i3 = 0;
        } else if (i === poly.length - 1) {
          i2 = 0;
          i3 = 1;
        } else {
          i2 = i + 1;
          i3 = i + 2;
        }
        sub_poly = [poly[i], poly[i2], poly[i3]];
        c = 0;
        while (pointsOnOneLine(sub_poly)) {
          throw_away_vertices.push(i2);
          i2 = i2 === (poly.length - 1) ? 0 : i2 + 1;
          sub_poly.push(poly[i2]);
          c += 1;
        }
        if (c !== 0) {
          throw_away_vertices.pop();
        }
        i = c !== 0 ? i + c : i + 1;
      }
      new_poly = (function() {
        var _j, _len1, _results;
        _results = [];
        for (idx = _j = 0, _len1 = poly.length; _j < _len1; idx = ++_j) {
          p = poly[idx];
          if (__indexOf.call(throw_away_vertices, idx) < 0) {
            _results.push(p);
          }
        }
        return _results;
      })();
      polygons_merged.push(new_poly);
    }
    return polygons_merged;
  };

  polygonAreaOverThreshhold = function(poly, threshhold) {
    var i, sum, x1, x2, y1, y2, _i, _ref;
    sum = 0;
    for (i = _i = 0, _ref = poly.getNumPoints() - 1; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      x1 = poly.getX(i);
      y1 = poly.getY(i);
      x2 = poly.getX(i + 1);
      y2 = poly.getY(i + 1);
      sum += x1 * y2 - y1 * x2;
    }
    x1 = poly.getX(poly.getNumPoints() - 1);
    y1 = poly.getY(poly.getNumPoints() - 1);
    x2 = poly.getX(0);
    y2 = poly.getY(0);
    sum += x1 * y2 - y1 * x2;
    return Math.abs(sum / 2.0) > threshhold;
  };

  isInRange = function(val, threshhold) {
    return Math.abs(val) < threshhold;
  };

  pointsOnOneLine = function(poly) {
    var a, b, c, i, threshhold, x, x1, x2, y, y1, y2, _i, _ref;
    threshhold = Math.pow(10, -2);
    x2 = poly[poly.length - 1].x;
    y2 = poly[poly.length - 1].y;
    x1 = poly[0].x;
    y1 = poly[0].y;
    if (!isInRange(x2 - x1, threshhold)) {
      b = -1;
      a = (y2 - y1) / (x2 - x1);
    } else if (!isInRange(y2 - y1, threshhold)) {
      a = -1;
      b = (x2 - x1) / (y2 - y1);
    } else {
      return true;
    }
    c = -a * x1 - b * y1;
    for (i = _i = 0, _ref = poly.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      x = poly[i].x;
      y = poly[i].y;
      if (!isInRange(x * a + y * b + c, threshhold)) {
        return false;
      }
    }
    return true;
  };

  isClockWise = function(poly) {
    var i, p1, p2, sum, _i, _ref;
    sum = 0.0;
    for (i = _i = i, _ref = poly.length; i <= _ref ? _i < _ref : _i > _ref; i = i <= _ref ? ++_i : --_i) {
      p1 = p[i];
      p2 = i === poly.length - 1 ? 0 : poly[i + 1];
      sum += (p2.x - p1.x) * (p2.y + p1.y);
    }
    return sum < 0;
  };

  removeDuplicates = function(listOfPoly) {
    var i, p1, p2, poly, threshhold, _i, _len;
    threshhold = Math.pow(10, -3);
    for (_i = 0, _len = listOfPoly.length; _i < _len; _i++) {
      poly = listOfPoly[_i];
      i = poly.length;
      while (true) {
        --i;
        if (i < 0) {
          break;
        }
        p1 = poly[i];
        p2 = i === 0 ? poly[poly.length - 1] : poly[i - 1];
        if (isInRange(p1.distanceTo(p2), threshhold)) {
          poly.splice(i, 1);
          i += 2;
        }
      }
    }
    return listOfPoly;
  };

  exports = {
    mergeUnmergedPolygons: mergeUnmergedPolygons,
    arePointPairsEqual: arePointPairsEqual,
    arePointsOnSameLineSegment: arePointsOnSameLineSegment,
    arePointPairsEqual: arePointPairsEqual,
    removeCollinearPoints: removeCollinearPoints,
    polygonAreaOverThreshhold: polygonAreaOverThreshhold,
    isInRange: isInRange,
    pointsOnOneLine: pointsOnOneLine,
    isClockWise: isClockWise,
    removeDuplicates: removeDuplicates
  };

}).call(this);

},{}],4:[function(require,module,exports){
(function() {
  var render;

  render = function(ui) {
    var localRenderer;
    localRenderer = function() {
      requestAnimationFrame(localRenderer);
      return ui.renderer.render(ui.scene, ui.camera);
    };
    return localRenderer();

    /*
    	len = animations.length
    	if len
    		loop
    			len--
    			break unless len >= 0
    			animation = animations[len]
    			if animation.status > 1.0
    				animations.splice( len, 1 )
    			animation.doAnimationStep()
     */
  };

  module.exports = render;

}).call(this);

},{}],5:[function(require,module,exports){
(function() {
  module.exports = function(globalConfig) {
    return {
      scene: new THREE.Scene(),
      camera: new THREE.PerspectiveCamera(globalConfig.fov, window.innerWidth / window.innerHeight, globalConfig.cameraNearPlane, globalConfig.cameraFarPlane),
      renderer: new THREE.WebGLRenderer({
        alpha: true,
        antialiasing: true,
        preserveDrawingBuffer: true
      }),
      controls: null,
      stlLoader: new THREE.STLLoader(),
      fileReader: new FileReader(),
      keyUpHandler: function(event) {
        var mesh, _i, _len, _ref;
        if (event.keyCode === 67) {
          _ref = globalConfig.meshes;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            mesh = _ref[_i];
            this.scene.remove(mesh);
          }
          return globalConfig.meshes = [];
        }
      },
      loadHandler: function(event) {
        var geometry;
        geometry = this.stlLoader.parse(event.target.result);
        return $(this).trigger('geometry-loaded', geometry);

        /*
        			objectMaterial = new THREE.MeshLambertMaterial(
        				{
        					color: globalConfig.defaultObjectColor
        					ambient: globalConfig.defaultObjectColor
        				}
        			)
        			object = new THREE.Mesh( geometry, objectMaterial )
        			@scene.add( object )
        			globalConfig.meshes.push( object )
         */
      },
      dropHandler: function(event) {
        var file, files, _i, _len, _ref, _results;
        event.stopPropagation();
        event.preventDefault();
        files = (_ref = event.target.files) != null ? _ref : event.dataTransfer.files;
        _results = [];
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          file = files[_i];
          if (file.name.contains('.stl')) {
            _results.push(this.fileReader.readAsBinaryString(file));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      },
      dragOverHandler: function(event) {
        event.stopPropagation();
        event.preventDefault();
        return event.dataTransfer.dropEffect = 'copy';
      },
      windowResizeHandler: function(event) {
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        return this.renderer.render(this.scene, this.camera);
      },
      init: function() {
        var ambientLight, directionalLight, geometryXAxis, geometryYAxis, geometryZAxis, gridLineGeometryXNegative, gridLineGeometryXPositive, gridLineGeometryYNegative, gridLineGeometryYPositive, gridLineXNegative, gridLineXPositive, gridLineYNegative, gridLineYPositive, i, material, materialGrid10, materialGrid5, materialGridNormal, materialXAxis, materialYAxis, materialZAxis, num, sceneRotation, xAxis, yAxis, zAxis, _i, _ref;
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setClearColor(0xf6f6f6, 1);
        document.body.appendChild(this.renderer.domElement);
        sceneRotation = new THREE.Matrix4();
        sceneRotation.makeRotationAxis(new THREE.Vector3(1, 0, 0), -Math.PI / 2);
        this.scene.applyMatrix(sceneRotation);
        this.camera.position.set(globalConfig.axisLength, globalConfig.axisLength + 10, globalConfig.axisLength / 2);
        this.camera.up.set(0, 1, 0);
        this.camera.lookAt(new THREE.Vector3(0, 0, 0));
        this.controls = new THREE.OrbitControls(this.camera);
        this.controls.target.set(0, 0, 0);
        materialXAxis = new THREE.LineBasicMaterial({
          color: globalConfig.axisXColor,
          linewidth: globalConfig.axisLineWidth
        });
        materialYAxis = new THREE.LineBasicMaterial({
          color: globalConfig.axisYColor,
          linewidth: globalConfig.axisLineWidth
        });
        materialZAxis = new THREE.LineBasicMaterial({
          color: globalConfig.axisZColor,
          linewidth: globalConfig.axisLineWidth
        });
        geometryXAxis = new THREE.Geometry();
        geometryYAxis = new THREE.Geometry();
        geometryZAxis = new THREE.Geometry();
        geometryXAxis.vertices.push(new THREE.Vector3(0, 0, 0));
        geometryXAxis.vertices.push(new THREE.Vector3(globalConfig.axisLength, 0, 0));
        geometryYAxis.vertices.push(new THREE.Vector3(0, 0, 0));
        geometryYAxis.vertices.push(new THREE.Vector3(0, globalConfig.axisLength, 0));
        geometryZAxis.vertices.push(new THREE.Vector3(0, 0, 0));
        geometryZAxis.vertices.push(new THREE.Vector3(0, 0, globalConfig.axisLength));
        xAxis = new THREE.Line(geometryXAxis, materialXAxis);
        yAxis = new THREE.Line(geometryYAxis, materialYAxis);
        zAxis = new THREE.Line(geometryZAxis, materialZAxis);
        this.scene.add(xAxis);
        this.scene.add(yAxis);
        this.scene.add(zAxis);
        materialGridNormal = new THREE.LineBasicMaterial({
          color: globalConfig.gridColorNormal,
          linewidth: globalConfig.gridLineWidthNormal
        });
        materialGrid5 = new THREE.LineBasicMaterial({
          color: globalConfig.gridColor5,
          linewidth: globalConfig.gridLineWidth5
        });
        materialGrid10 = new THREE.LineBasicMaterial({
          color: globalConfig.gridColor10,
          linewidth: globalConfig.gridLineWidth10
        });
        for (i = _i = 0, _ref = globalConfig.gridSize / globalConfig.gridStepSize; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          num = i * globalConfig.gridStepSize;
          if (i % 10 * globalConfig.gridStepSize === 0) {
            material = materialGrid10;
          } else if (i % 5 * globalConfig.gridStepSize === 0) {
            material = materialGrid5;
          } else {
            material = materialGridNormal;
          }
          gridLineGeometryXPositive = new THREE.Geometry();
          gridLineGeometryYPositive = new THREE.Geometry();
          gridLineGeometryXNegative = new THREE.Geometry();
          gridLineGeometryYNegative = new THREE.Geometry();
          gridLineGeometryXPositive.vertices.push(new THREE.Vector3(-globalConfig.gridSize, num, 0));
          gridLineGeometryXPositive.vertices.push(new THREE.Vector3(globalConfig.gridSize, num, 0));
          gridLineGeometryYPositive.vertices.push(new THREE.Vector3(num, -globalConfig.gridSize, 0));
          gridLineGeometryYPositive.vertices.push(new THREE.Vector3(num, globalConfig.gridSize, 0));
          gridLineGeometryXNegative.vertices.push(new THREE.Vector3(-globalConfig.gridSize, -num, 0));
          gridLineGeometryXNegative.vertices.push(new THREE.Vector3(globalConfig.gridSize, -num, 0));
          gridLineGeometryYNegative.vertices.push(new THREE.Vector3(-num, -globalConfig.gridSize, 0));
          gridLineGeometryYNegative.vertices.push(new THREE.Vector3(-num, globalConfig.gridSize, 0));
          gridLineXPositive = new THREE.Line(gridLineGeometryXPositive, material);
          gridLineYPositive = new THREE.Line(gridLineGeometryYPositive, material);
          gridLineXNegative = new THREE.Line(gridLineGeometryXNegative, material);
          gridLineYNegative = new THREE.Line(gridLineGeometryYNegative, material);
          this.scene.add(gridLineXPositive);
          this.scene.add(gridLineYPositive);
          this.scene.add(gridLineXNegative);
          this.scene.add(gridLineYNegative);
        }
        this.renderer.domElement.addEventListener('dragover', this.dragOverHandler.bind(this), false);
        this.renderer.domElement.addEventListener('drop', this.dropHandler.bind(this), false);
        this.fileReader.addEventListener('loadend', this.loadHandler.bind(this), false);
        document.addEventListener('keyup', this.keyUpHandler.bind(this));
        window.addEventListener('resize', this.windowResizeHandler.bind(this), false);
        ambientLight = new THREE.AmbientLight(0x404040);
        this.scene.add(ambientLight);
        directionalLight = new THREE.DirectionalLight(0xffffff);
        directionalLight.position.set(0, 20, 30);
        this.scene.add(directionalLight);
        directionalLight = new THREE.DirectionalLight(0x808080);
        directionalLight.position.set(20, 0, 30);
        return this.scene.add(directionalLight);
      }
    };
  };

}).call(this);

},{}],6:[function(require,module,exports){
(function (process){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// resolves . and .. elements in a path array with directory names there
// must be no slashes, empty elements, or device names (c:\) in the array
// (so also no leading and trailing slashes - it does not distinguish
// relative and absolute paths)
function normalizeArray(parts, allowAboveRoot) {
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = parts.length - 1; i >= 0; i--) {
    var last = parts[i];
    if (last === '.') {
      parts.splice(i, 1);
    } else if (last === '..') {
      parts.splice(i, 1);
      up++;
    } else if (up) {
      parts.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (allowAboveRoot) {
    for (; up--; up) {
      parts.unshift('..');
    }
  }

  return parts;
}

// Split a filename into [root, dir, basename, ext], unix version
// 'root' is just a slash, or nothing.
var splitPathRe =
    /^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/;
var splitPath = function(filename) {
  return splitPathRe.exec(filename).slice(1);
};

// path.resolve([from ...], to)
// posix version
exports.resolve = function() {
  var resolvedPath = '',
      resolvedAbsolute = false;

  for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
    var path = (i >= 0) ? arguments[i] : process.cwd();

    // Skip empty and invalid entries
    if (typeof path !== 'string') {
      throw new TypeError('Arguments to path.resolve must be strings');
    } else if (!path) {
      continue;
    }

    resolvedPath = path + '/' + resolvedPath;
    resolvedAbsolute = path.charAt(0) === '/';
  }

  // At this point the path should be resolved to a full absolute path, but
  // handle relative paths to be safe (might happen when process.cwd() fails)

  // Normalize the path
  resolvedPath = normalizeArray(filter(resolvedPath.split('/'), function(p) {
    return !!p;
  }), !resolvedAbsolute).join('/');

  return ((resolvedAbsolute ? '/' : '') + resolvedPath) || '.';
};

// path.normalize(path)
// posix version
exports.normalize = function(path) {
  var isAbsolute = exports.isAbsolute(path),
      trailingSlash = substr(path, -1) === '/';

  // Normalize the path
  path = normalizeArray(filter(path.split('/'), function(p) {
    return !!p;
  }), !isAbsolute).join('/');

  if (!path && !isAbsolute) {
    path = '.';
  }
  if (path && trailingSlash) {
    path += '/';
  }

  return (isAbsolute ? '/' : '') + path;
};

// posix version
exports.isAbsolute = function(path) {
  return path.charAt(0) === '/';
};

// posix version
exports.join = function() {
  var paths = Array.prototype.slice.call(arguments, 0);
  return exports.normalize(filter(paths, function(p, index) {
    if (typeof p !== 'string') {
      throw new TypeError('Arguments to path.join must be strings');
    }
    return p;
  }).join('/'));
};


// path.relative(from, to)
// posix version
exports.relative = function(from, to) {
  from = exports.resolve(from).substr(1);
  to = exports.resolve(to).substr(1);

  function trim(arr) {
    var start = 0;
    for (; start < arr.length; start++) {
      if (arr[start] !== '') break;
    }

    var end = arr.length - 1;
    for (; end >= 0; end--) {
      if (arr[end] !== '') break;
    }

    if (start > end) return [];
    return arr.slice(start, end - start + 1);
  }

  var fromParts = trim(from.split('/'));
  var toParts = trim(to.split('/'));

  var length = Math.min(fromParts.length, toParts.length);
  var samePartsLength = length;
  for (var i = 0; i < length; i++) {
    if (fromParts[i] !== toParts[i]) {
      samePartsLength = i;
      break;
    }
  }

  var outputParts = [];
  for (var i = samePartsLength; i < fromParts.length; i++) {
    outputParts.push('..');
  }

  outputParts = outputParts.concat(toParts.slice(samePartsLength));

  return outputParts.join('/');
};

exports.sep = '/';
exports.delimiter = ':';

exports.dirname = function(path) {
  var result = splitPath(path),
      root = result[0],
      dir = result[1];

  if (!root && !dir) {
    // No dirname whatsoever
    return '.';
  }

  if (dir) {
    // It has a dirname, strip trailing slash
    dir = dir.substr(0, dir.length - 1);
  }

  return root + dir;
};


exports.basename = function(path, ext) {
  var f = splitPath(path)[2];
  // TODO: make this comparison case-insensitive on windows?
  if (ext && f.substr(-1 * ext.length) === ext) {
    f = f.substr(0, f.length - ext.length);
  }
  return f;
};


exports.extname = function(path) {
  return splitPath(path)[3];
};

function filter (xs, f) {
    if (xs.filter) return xs.filter(f);
    var res = [];
    for (var i = 0; i < xs.length; i++) {
        if (f(xs[i], i, xs)) res.push(xs[i]);
    }
    return res;
}

// String.prototype.substr - negative index don't work in IE8
var substr = 'ab'.substr(-1) === 'b'
    ? function (str, start, len) { return str.substr(start, len) }
    : function (str, start, len) {
        if (start < 0) start = str.length + start;
        return str.substr(start, len);
    }
;

}).call(this,require('_process'))
},{"_process":7}],7:[function(require,module,exports){
// shim for using process in browser

var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
    && window.setImmediate;
    var canMutationObserver = typeof window !== 'undefined'
    && window.MutationObserver;
    var canPost = typeof window !== 'undefined'
    && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return function (f) { return window.setImmediate(f) };
    }

    var queue = [];

    if (canMutationObserver) {
        var hiddenDiv = document.createElement("div");
        var observer = new MutationObserver(function () {
            var queueList = queue.slice();
            queue.length = 0;
            queueList.forEach(function (fn) {
                fn();
            });
        });

        observer.observe(hiddenDiv, { attributes: true });

        return function nextTick(fn) {
            if (!queue.length) {
                hiddenDiv.setAttribute('yes', 'no');
            }
            queue.push(fn);
        };
    }

    if (canPost) {
        window.addEventListener('message', function (ev) {
            var source = ev.source;
            if ((source === window || source === null) && ev.data === 'process-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);

        return function nextTick(fn) {
            queue.push(fn);
            window.postMessage('process-tick', '*');
        };
    }

    return function nextTick(fn) {
        setTimeout(fn, 0);
    };
})();

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};

},{}]},{},[2,3,4,5])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlc1xcYnJvd3NlcmlmeVxcbm9kZV9tb2R1bGVzXFxicm93c2VyLXBhY2tcXF9wcmVsdWRlLmpzIiwiYnVpbGRcXGNsaWVudFxcZ2xvYmFscy5qc29uIiwiYnVpbGRcXGNsaWVudFxcbWFpbi5qcyIsImJ1aWxkXFxjbGllbnRcXHBvbHlnb25fcG9zdHByb2Nlc3NpbmcuanMiLCJidWlsZFxcY2xpZW50XFxyZW5kZXIuanMiLCJidWlsZFxcY2xpZW50XFx1aS5qcyIsIm5vZGVfbW9kdWxlc1xcYnJvd3NlcmlmeVxcbm9kZV9tb2R1bGVzXFxwYXRoLWJyb3dzZXJpZnlcXGluZGV4LmpzIiwibm9kZV9tb2R1bGVzXFxicm93c2VyaWZ5XFxub2RlX21vZHVsZXNcXHByb2Nlc3NcXGJyb3dzZXIuanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7QUNBQTs7QUNBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM5QkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM5VUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDM0JBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ3hLQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2xPQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIihmdW5jdGlvbiBlKHQsbixyKXtmdW5jdGlvbiBzKG8sdSl7aWYoIW5bb10pe2lmKCF0W29dKXt2YXIgYT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2lmKCF1JiZhKXJldHVybiBhKG8sITApO2lmKGkpcmV0dXJuIGkobywhMCk7dmFyIGY9bmV3IEVycm9yKFwiQ2Fubm90IGZpbmQgbW9kdWxlICdcIitvK1wiJ1wiKTt0aHJvdyBmLmNvZGU9XCJNT0RVTEVfTk9UX0ZPVU5EXCIsZn12YXIgbD1uW29dPXtleHBvcnRzOnt9fTt0W29dWzBdLmNhbGwobC5leHBvcnRzLGZ1bmN0aW9uKGUpe3ZhciBuPXRbb11bMV1bZV07cmV0dXJuIHMobj9uOmUpfSxsLGwuZXhwb3J0cyxlLHQsbixyKX1yZXR1cm4gbltvXS5leHBvcnRzfXZhciBpPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7Zm9yKHZhciBvPTA7bzxyLmxlbmd0aDtvKyspcyhyW29dKTtyZXR1cm4gc30pIiwibW9kdWxlLmV4cG9ydHM9e1wibW1cIjoxLFwiZm92XCI6NDAsXCJjYW1lcmFOZWFyUGxhbmVcIjowLjEsXCJjYW1lcmFGYXJQbGFuZVwiOjEwMDAsXCJhbmltYXRpb25TdGVwU2l6ZVwiOjAuMDIsXCJhbmltYXRpb25zXCI6W10sXCJheGlzTGVuZ3RoXCI6MTAwLFwiYXhpc1hDb2xvclwiOjE2NzExNjgwLFwiYXhpc1lDb2xvclwiOjY1MjgwLFwiYXhpc1pDb2xvclwiOjI1NSxcImF4aXNMaW5lV2lkdGhcIjoyLFwiZGVmYXVsdE9iamVjdENvbG9yXCI6MTM0MTI5MTUsXCJtZXNoZXNcIjpbXSxcImdyaWRDb2xvck5vcm1hbFwiOjEzNDIxNzcyLFwiZ3JpZENvbG9yNVwiOjEwMDY2MzI5LFwiZ3JpZENvbG9yMTBcIjo2NzEwODg2LFwiZ3JpZExpbmVXaWR0aE5vcm1hbFwiOjEsXCJncmlkTGluZVdpZHRoNVwiOjEsXCJncmlkTGluZVdpZHRoMTBcIjoxLFwiZ3JpZFNpemVcIjoyMDAsXCJncmlkU3RlcFNpemVcIjoxMH0iLCIoZnVuY3Rpb24oKSB7XG4gIHZhciBnbG9iYWxDb25maWcsIHBhdGgsIHJlbmRlcmVyLCB1aTtcblxuICBnbG9iYWxDb25maWcgPSByZXF1aXJlKCcuL2dsb2JhbHMuanNvbicpO1xuXG4gIHBhdGggPSByZXF1aXJlKCdwYXRoJyk7XG5cblxuICAvKiBUT0RPOiBtb3ZlIHNvbWV3aGVyZSB3aGVyZSBpdCBpcyBuZWVkZWRcbiAgICogZ2VvbWV0cnkgZnVuY3Rpb25zXG4gIGRlZ1RvUmFkID0gKCBkZWcgKSAtPiBkZWcgKiAoIE1hdGguUEkgLyAxODAuMCApXG4gIHJhZFRvRGVnID0gKCByYWQgKSAtPiBkZWcgKiAoIDE4MC4wIC8gTWF0aC5QSSApXG4gIFxuICBub3JtYWxGb3JtVG9QYXJhbXRlckZvcm0gPSAoIG4sIHAsIHUsIHYpIC0+XG4gIFx0dS5zZXQoIDAsIC1uLnosIG4ueSApLm5vcm1hbGl6ZSgpXG4gIFx0di5zZXQoIG4ueSwgLW4ueCwgMCApLm5vcm1hbGl6ZSgpXG4gIFxuICAgKiB1dGlsaXR5XG4gIFN0cmluZzo6Y29udGFpbnMgPSAoc3RyKSAtPiAtMSBpc250IHRoaXMuaW5kZXhPZiBzdHJcbiAgICovXG5cbiAgdWkgPSByZXF1aXJlKFwiLi91aVwiKShnbG9iYWxDb25maWcpO1xuXG4gIHVpLmluaXQoKTtcblxuICByZW5kZXJlciA9IHJlcXVpcmUoXCIuL3JlbmRlclwiKTtcblxuICByZW5kZXJlcih1aSk7XG5cbn0pLmNhbGwodGhpcyk7XG4iLCIoZnVuY3Rpb24oKSB7XG4gIHZhciBhcmVQb2ludFBhaXJzRXF1YWwsIGFyZVBvaW50c09uU2FtZUxpbmVTZWdtZW50LCBleHBvcnRzLCBpc0Nsb2NrV2lzZSwgaXNJblJhbmdlLCBtZXJnZVVubWVyZ2VkUG9seWdvbnMsIHBvaW50c09uT25lTGluZSwgcG9seWdvbkFyZWFPdmVyVGhyZXNoaG9sZCwgcmVtb3ZlQ29sbGluZWFyUG9pbnRzLCByZW1vdmVEdXBsaWNhdGVzLFxuICAgIF9faW5kZXhPZiA9IFtdLmluZGV4T2YgfHwgZnVuY3Rpb24oaXRlbSkgeyBmb3IgKHZhciBpID0gMCwgbCA9IHRoaXMubGVuZ3RoOyBpIDwgbDsgaSsrKSB7IGlmIChpIGluIHRoaXMgJiYgdGhpc1tpXSA9PT0gaXRlbSkgcmV0dXJuIGk7IH0gcmV0dXJuIC0xOyB9O1xuXG4gIG1lcmdlVW5tZXJnZWRQb2x5Z29ucyA9IGZ1bmN0aW9uKGxpc3RPZlBvbHkpIHtcbiAgICB2YXIgYywgaSwgaWR4LCBpdGVtLCBrLCBrZXksIGtleXMsIG1lcmdlLCBtZXJnZV9wb2x5LCBtZXJnZV92ZXJ0ZXhfaWR4LCBwMSwgcDFfaWR4LCBwMiwgcDJfaWR4LCBwMywgcDQsIHBfZmlyc3QsIHBvaW50c19tZXJnZWQsIHBvbHksIHBvbHlfaW5kZXhfaW5uZXIsIHBvbHlfaW5kZXhfaW5uZXIyLCBwb2x5X2luZGV4X291dGVyLCBwb2x5X2luZGV4X291dGVyMiwgcG9seV9pbm5lciwgcG9seV9vdXRlciwgcG9seV9yYW5nZSwgcG9seWdvbnNfaW5kZXhfaW5uZXIsIHBvbHlnb25zX2luZGV4X291dGVyLCBwb2x5Z29uc190b19tZXJnZSwgdGFyZ2V0LCB0YXJnZXRfaWR4LCB0YXJnZXRfa2V5LCB0YXJnZXRfcDEsIHRocm93X2F3YXlfcG9seWdvbnMsIHR1cGxlcywgdmFsdWUsIF9pLCBfaiwgX2ssIF9sLCBfbGVuLCBfbGVuMSwgX20sIF9uLCBfbywgX3AsIF9xLCBfcmVmLCBfcmVmMSwgX3JlZjIsIF9yZWYzLCBfcmVmNCwgX3JlZjUsIF9yZWY2LCBfcmVmNywgX3JlZjgsIF9yZXN1bHRzLCBfcmVzdWx0czE7XG4gICAgbGlzdE9mUG9seS5zb3J0KGZ1bmN0aW9uKGEsIGIpIHtcbiAgICAgIGlmIChhLmxlbmd0aCA8IGIubGVuZ3RoKSB7XG4gICAgICAgIHJldHVybiAxO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgcmV0dXJuIC0xO1xuICAgICAgfVxuICAgIH0pO1xuICAgIHBvbHlnb25zX3RvX21lcmdlID0ge307XG4gICAgdGhyb3dfYXdheV9wb2x5Z29ucyA9IFtdO1xuICAgIGZvciAocG9seWdvbnNfaW5kZXhfb3V0ZXIgPSBfaSA9IDAsIF9yZWYgPSBsaXN0T2ZQb2x5Lmxlbmd0aDsgMCA8PSBfcmVmID8gX2kgPCBfcmVmIDogX2kgPiBfcmVmOyBwb2x5Z29uc19pbmRleF9vdXRlciA9IDAgPD0gX3JlZiA/ICsrX2kgOiAtLV9pKSB7XG4gICAgICBpZiAoX19pbmRleE9mLmNhbGwodGhyb3dfYXdheV9wb2x5Z29ucywgcG9seWdvbnNfaW5kZXhfb3V0ZXIpID49IDApIHtcbiAgICAgICAgY29udGludWU7XG4gICAgICB9XG4gICAgICBwb2x5X291dGVyID0gbGlzdE9mUG9seVtwb2x5Z29uc19pbmRleF9vdXRlcl07XG4gICAgICBwb2x5X2luZGV4X291dGVyID0gMDtcbiAgICAgIHBvaW50c19tZXJnZWQgPSAwO1xuICAgICAgZm9yIChwb2x5X2luZGV4X291dGVyID0gX2ogPSAwLCBfcmVmMSA9IHBvbHlfb3V0ZXIubGVuZ3RoOyAwIDw9IF9yZWYxID8gX2ogPCBfcmVmMSA6IF9qID4gX3JlZjE7IHBvbHlfaW5kZXhfb3V0ZXIgPSAwIDw9IF9yZWYxID8gKytfaiA6IC0tX2opIHtcbiAgICAgICAgcDEgPSBwb2x5X291dGVyW3BvbHlfaW5kZXhfb3V0ZXJdO1xuICAgICAgICBwb2x5X2luZGV4X291dGVyMiA9IHBvbHlfaW5kZXhfb3V0ZXIgPT09IChwb2x5X291dGVyLmxlbmd0aCAtIDEpID8gMCA6IHBvbHlfaW5kZXhfb3V0ZXIgKyAxO1xuICAgICAgICBwMiA9IHBvbHlfb3V0ZXJbcG9seV9pbmRleF9vdXRlcjJdO1xuICAgICAgICBwb2x5Z29uc19pbmRleF9pbm5lciA9IDA7XG4gICAgICAgIGZvciAocG9seWdvbnNfaW5kZXhfaW5uZXIgPSBfayA9IF9yZWYyID0gcG9seWdvbnNfaW5kZXhfb3V0ZXIgKyAxLCBfcmVmMyA9IGxpc3RPZlBvbHkubGVuZ3RoOyBfcmVmMiA8PSBfcmVmMyA/IF9rIDwgX3JlZjMgOiBfayA+IF9yZWYzOyBwb2x5Z29uc19pbmRleF9pbm5lciA9IF9yZWYyIDw9IF9yZWYzID8gKytfayA6IC0tX2spIHtcbiAgICAgICAgICBpZiAoX19pbmRleE9mLmNhbGwodGhyb3dfYXdheV9wb2x5Z29ucywgcG9seWdvbnNfaW5kZXhfaW5uZXIpID49IDApIHtcbiAgICAgICAgICAgIGNvbnRpbnVlO1xuICAgICAgICAgIH1cbiAgICAgICAgICBwb2x5X2lubmVyID0gbGlzdE9mUG9seVtwb2x5Z29uc19pbmRleF9pbm5lcl07XG4gICAgICAgICAgcG9seV9pbmRleF9pbm5lciA9IDA7XG4gICAgICAgICAgZm9yIChwb2x5X2luZGV4X2lubmVyID0gX2wgPSAwLCBfcmVmNCA9IHBvbHlfaW5uZXIubGVuZ3RoOyAwIDw9IF9yZWY0ID8gX2wgPCBfcmVmNCA6IF9sID4gX3JlZjQ7IHBvbHlfaW5kZXhfaW5uZXIgPSAwIDw9IF9yZWY0ID8gKytfbCA6IC0tX2wpIHtcbiAgICAgICAgICAgIHAzID0gcG9seV9pbm5lcltwb2x5X2luZGV4X2lubmVyXTtcbiAgICAgICAgICAgIHBvbHlfaW5kZXhfaW5uZXIyID0gcG9seV9pbmRleF9pbm5lciA9PT0gKHBvbHlfaW5uZXIubGVuZ3RoIC0gMSkgPyAwIDogcG9seV9pbmRleF9pbm5lciArIDE7XG4gICAgICAgICAgICBwNCA9IHBvbHlfaW5uZXJbcG9seV9pbmRleF9pbm5lcjJdO1xuICAgICAgICAgICAgaWYgKGFyZVBvaW50c09uU2FtZUxpbmVTZWdtZW50KHAzLCBwNCwgcDEsIHAyKSkge1xuICAgICAgICAgICAgICBpZiAocDMuZGlzdGFuY2VUbyhwMSkgPCBwNC5kaXN0YW5jZVRvKHAxKSkge1xuICAgICAgICAgICAgICAgIHBfZmlyc3QgPSBwb2x5X2luZGV4X2lubmVyO1xuICAgICAgICAgICAgICAgIHBvbHlfcmFuZ2UgPSAoZnVuY3Rpb24oKSB7XG4gICAgICAgICAgICAgICAgICBfcmVzdWx0cyA9IFtdO1xuICAgICAgICAgICAgICAgICAgZm9yICh2YXIgX20gPSAwLCBfcmVmNSA9IHBvbHlfaW5uZXIubGVuZ3RoOyAwIDw9IF9yZWY1ID8gX20gPCBfcmVmNSA6IF9tID4gX3JlZjU7IDAgPD0gX3JlZjUgPyBfbSsrIDogX20tLSl7IF9yZXN1bHRzLnB1c2goX20pOyB9XG4gICAgICAgICAgICAgICAgICByZXR1cm4gX3Jlc3VsdHM7XG4gICAgICAgICAgICAgICAgfSkuYXBwbHkodGhpcyk7XG4gICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgcF9maXJzdCA9IHBvbHlfaW5kZXhfaW5uZXIyO1xuICAgICAgICAgICAgICAgIHBvbHlfcmFuZ2UgPSAoZnVuY3Rpb24oKSB7XG4gICAgICAgICAgICAgICAgICBfcmVzdWx0czEgPSBbXTtcbiAgICAgICAgICAgICAgICAgIGZvciAodmFyIF9uID0gMCwgX3JlZjYgPSBwb2x5X2lubmVyLmxlbmd0aDsgMCA8PSBfcmVmNiA/IF9uIDwgX3JlZjYgOiBfbiA+IF9yZWY2OyAwIDw9IF9yZWY2ID8gX24rKyA6IF9uLS0peyBfcmVzdWx0czEucHVzaChfbik7IH1cbiAgICAgICAgICAgICAgICAgIHJldHVybiBfcmVzdWx0czE7XG4gICAgICAgICAgICAgICAgfSkuYXBwbHkodGhpcykucmV2ZXJzZSgpO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgIHRocm93X2F3YXlfcG9seWdvbnMucHVzaChwb2x5Z29uc19pbmRleF9pbm5lcik7XG4gICAgICAgICAgICAgIGtleSA9IFwiXCIgKyBwb2x5Z29uc19pbmRleF9vdXRlciArIFwiLFwiICsgcG9seV9pbmRleF9vdXRlciArIFwiLFwiICsgcG9seV9pbmRleF9vdXRlcjI7XG4gICAgICAgICAgICAgIGlmICghcG9seWdvbnNfdG9fbWVyZ2Vba2V5XSAhPT0gXCJ1bmRlZmluZWRcIikge1xuICAgICAgICAgICAgICAgIHBvbHlnb25zX3RvX21lcmdlW2tleV0gPSB7fTtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICBwb2x5Z29uc190b19tZXJnZVtrZXldW3BvbHlnb25zX2luZGV4X2lubmVyXSA9IChmdW5jdGlvbigpIHtcbiAgICAgICAgICAgICAgICB2YXIgX2xlbiwgX28sIF9yZXN1bHRzMjtcbiAgICAgICAgICAgICAgICBfcmVzdWx0czIgPSBbXTtcbiAgICAgICAgICAgICAgICBmb3IgKF9vID0gMCwgX2xlbiA9IHBvbHlfcmFuZ2UubGVuZ3RoOyBfbyA8IF9sZW47IF9vKyspIHtcbiAgICAgICAgICAgICAgICAgIGMgPSBwb2x5X3JhbmdlW19vXTtcbiAgICAgICAgICAgICAgICAgIF9yZXN1bHRzMi5wdXNoKGMgKyBwX2ZpcnN0IDwgcG9seV9pbm5lci5sZW5ndGggPyBjICsgcF9maXJzdCA6IGMgKyBwX2ZpcnN0IC0gcG9seV9pbm5lci5sZW5ndGgpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICByZXR1cm4gX3Jlc3VsdHMyO1xuICAgICAgICAgICAgICB9KSgpO1xuICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgY29uc29sZS5sb2cocG9seWdvbnNfdG9fbWVyZ2UpO1xuICAgIGNvbnNvbGUubG9nKHRocm93X2F3YXlfcG9seWdvbnMpO1xuICAgIHR1cGxlcyA9IChmdW5jdGlvbigpIHtcbiAgICAgIHZhciBfcmVzdWx0czI7XG4gICAgICBfcmVzdWx0czIgPSBbXTtcbiAgICAgIGZvciAoa2V5IGluIHBvbHlnb25zX3RvX21lcmdlKSB7XG4gICAgICAgIHBvbHkgPSBwb2x5Z29uc190b19tZXJnZVtrZXldO1xuICAgICAgICBfcmVzdWx0czIucHVzaChba2V5LCBwb2x5XSk7XG4gICAgICB9XG4gICAgICByZXR1cm4gX3Jlc3VsdHMyO1xuICAgIH0pKCk7XG4gICAgdHVwbGVzLnNvcnQoZnVuY3Rpb24oYSwgYikge1xuICAgICAgdmFyIGFrZXlzLCBhcDJfaWR4LCBia2V5cywgYnAyX2lkeDtcbiAgICAgIGFrZXlzID0gYVswXS5zcGxpdCgnLCcpO1xuICAgICAgYXAyX2lkeCA9IHBhcnNlSW50KGFrZXlzWzJdKTtcbiAgICAgIGJrZXlzID0gYlswXS5zcGxpdCgnLCcpO1xuICAgICAgYnAyX2lkeCA9IHBhcnNlSW50KGJrZXlzWzJdKTtcbiAgICAgIGlmIChhcDJfaWR4IDwgYnAyX2lkeCkge1xuICAgICAgICByZXR1cm4gMTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHJldHVybiAtMTtcbiAgICAgIH1cbiAgICB9KTtcbiAgICBwb2x5Z29uc190b19tZXJnZSA9IHt9O1xuICAgIGZvciAoaSA9IF9vID0gMCwgX3JlZjcgPSB0dXBsZXMubGVuZ3RoOyAwIDw9IF9yZWY3ID8gX28gPCBfcmVmNyA6IF9vID4gX3JlZjc7IGkgPSAwIDw9IF9yZWY3ID8gKytfbyA6IC0tX28pIHtcbiAgICAgIGtleSA9IHR1cGxlc1tpXVswXTtcbiAgICAgIHZhbHVlID0gdHVwbGVzW2ldWzFdO1xuICAgICAgcG9seWdvbnNfdG9fbWVyZ2Vba2V5XSA9IHZhbHVlO1xuICAgIH1cbiAgICBmb3IgKGtleSBpbiBwb2x5Z29uc190b19tZXJnZSkge1xuICAgICAgbWVyZ2UgPSBwb2x5Z29uc190b19tZXJnZVtrZXldO1xuICAgICAga2V5cyA9IGtleS5zcGxpdCgnLCcpO1xuICAgICAgdGFyZ2V0X2lkeCA9IHBhcnNlSW50KGtleXNbMF0pO1xuICAgICAgcDFfaWR4ID0gcGFyc2VJbnQoa2V5c1sxXSk7XG4gICAgICBwMl9pZHggPSBwYXJzZUludChrZXlzWzJdKTtcbiAgICAgIHRhcmdldCA9IGxpc3RPZlBvbHlbdGFyZ2V0X2lkeF07XG4gICAgICB0YXJnZXRfcDEgPSB0YXJnZXRbcDFfaWR4XTtcbiAgICAgIHRhcmdldF9rZXkgPSBwMl9pZHggKyBjO1xuICAgICAgdHVwbGVzID0gKGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgX3Jlc3VsdHMyO1xuICAgICAgICBfcmVzdWx0czIgPSBbXTtcbiAgICAgICAgZm9yIChrIGluIG1lcmdlKSB7XG4gICAgICAgICAgcG9seSA9IG1lcmdlW2tdO1xuICAgICAgICAgIF9yZXN1bHRzMi5wdXNoKFtrLCBwb2x5XSk7XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIF9yZXN1bHRzMjtcbiAgICAgIH0pKCk7XG4gICAgICB0dXBsZXMuc29ydChmdW5jdGlvbihhLCBiKSB7XG4gICAgICAgIHZhciByZXN1bHQ7XG4gICAgICAgIHJlc3VsdCA9IGxpc3RPZlBvbHlbYVswXV1bYVsxXVswXV0uZGlzdGFuY2VUbyh0YXJnZXRfcDEpIDwgbGlzdE9mUG9seVtiWzBdXVtiWzFdWzBdXS5kaXN0YW5jZVRvKHRhcmdldF9wMSk7XG4gICAgICAgIGlmIChyZXN1bHQpIHtcbiAgICAgICAgICByZXR1cm4gMTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICByZXR1cm4gLTE7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgICAgZm9yIChfcCA9IDAsIF9sZW4gPSB0dXBsZXMubGVuZ3RoOyBfcCA8IF9sZW47IF9wKyspIHtcbiAgICAgICAgaXRlbSA9IHR1cGxlc1tfcF07XG4gICAgICAgIG1lcmdlX3BvbHkgPSBsaXN0T2ZQb2x5W2l0ZW1bMF1dO1xuICAgICAgICBfcmVmOCA9IGl0ZW1bMV07XG4gICAgICAgIGZvciAoX3EgPSAwLCBfbGVuMSA9IF9yZWY4Lmxlbmd0aDsgX3EgPCBfbGVuMTsgX3ErKykge1xuICAgICAgICAgIG1lcmdlX3ZlcnRleF9pZHggPSBfcmVmOFtfcV07XG4gICAgICAgICAgbGlzdE9mUG9seVt0YXJnZXRfaWR4XS5zcGxpY2UodGFyZ2V0X2tleSwgMCwgbWVyZ2VfcG9seVttZXJnZV92ZXJ0ZXhfaWR4XSk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIGxpc3RPZlBvbHkgPSAoZnVuY3Rpb24oKSB7XG4gICAgICB2YXIgX2xlbjIsIF9yLCBfcmVzdWx0czI7XG4gICAgICBfcmVzdWx0czIgPSBbXTtcbiAgICAgIGZvciAoaWR4ID0gX3IgPSAwLCBfbGVuMiA9IGxpc3RPZlBvbHkubGVuZ3RoOyBfciA8IF9sZW4yOyBpZHggPSArK19yKSB7XG4gICAgICAgIHBvbHkgPSBsaXN0T2ZQb2x5W2lkeF07XG4gICAgICAgIGlmIChfX2luZGV4T2YuY2FsbCh0aHJvd19hd2F5X3BvbHlnb25zLCBpZHgpIDwgMCAmJiBwb2x5Lmxlbmd0aCA+IDIpIHtcbiAgICAgICAgICBfcmVzdWx0czIucHVzaChwb2x5KTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgICAgcmV0dXJuIF9yZXN1bHRzMjtcbiAgICB9KSgpO1xuICB9O1xuXG4gIGFyZVBvaW50c09uU2FtZUxpbmVTZWdtZW50ID0gZnVuY3Rpb24ocDEsIHAyLCBwMywgcDQpIHtcbiAgICB2YXIgdDEsIHQyLCB0MywgdDQsIHRocmVzaGhvbGQsIHY7XG4gICAgdiA9IG5ldyBUSFJFRS5WZWN0b3IyKHA0LnggLSBwMy54LCBwNC55IC0gcDMueSk7XG4gICAgdGhyZXNoaG9sZCA9IE1hdGgucG93KDEwLCAtMSk7XG4gICAgaWYgKHAzLnggIT09IHA0LngpIHtcbiAgICAgIHQxID0gKHAxLnggLSBwMy54KSAvIHYueDtcbiAgICAgIGlmICh0MSA+IDEuMCArIHRocmVzaGhvbGQgfHwgdDEgPCAwLjAgLSB0aHJlc2hob2xkIHx8ICFpc0luUmFuZ2UocDEueSAtIChwMy55ICsgdDEgKiB2LnkpLCB0aHJlc2hob2xkKSkge1xuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9XG4gICAgICB0MiA9IChwMi54IC0gcDMueCkgLyB2Lng7XG4gICAgICBpZiAodDIgPiAxLjAgKyB0aHJlc2hob2xkIHx8IHQyIDwgMC4wIC0gdGhyZXNoaG9sZCB8fCAhaXNJblJhbmdlKHAyLnkgLSAocDMueSArIHQyICogdi55KSwgdGhyZXNoaG9sZCkpIHtcbiAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgfVxuICAgIH0gZWxzZSBpZiAocDMueSAhPT0gcDQueSkge1xuICAgICAgdDMgPSAocDEueSAtIHAzLnkpIC8gdi55O1xuICAgICAgaWYgKHQzID4gMS4wICsgdGhyZXNoaG9sZCB8fCB0MyA8IDAuMCAtIHRocmVzaGhvbGQgfHwgIWlzSW5SYW5nZShwMS54IC0gKHAzLnggKyB0MyAqIHYueCksIHRocmVzaGhvbGQpKSB7XG4gICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgIH1cbiAgICAgIHQ0ID0gKHAyLnkgLSBwMy55KSAvIHYueTtcbiAgICAgIGlmICh0NCA+IDEuMCArIHRocmVzaGhvbGQgfHwgdDQgPCAwLjAgLSB0aHJlc2hob2xkIHx8ICFpc0luUmFuZ2UocDIueCAtIChwMy54ICsgdDQgKiB2LngpLCB0aHJlc2hob2xkKSkge1xuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9XG4gICAgcmV0dXJuIHRydWU7XG4gIH07XG5cbiAgYXJlUG9pbnRQYWlyc0VxdWFsID0gZnVuY3Rpb24ocDEsIHAyLCBwMywgcDQpIHtcbiAgICB2YXIgcmVzdWx0LCB0aHJlc2hob2xkO1xuICAgIHRocmVzaGhvbGQgPSBNYXRoLnBvdygxMCwgLTMpO1xuICAgIHJlc3VsdCA9IHRydWU7XG4gICAgcmVzdWx0ICYmIChyZXN1bHQgPSBpc0luUmFuZ2UocDEueCAtIHAzLngsIHRocmVzaGhvbGQpIHx8IGlzSW5SYW5nZShwMS54IC0gcDQueCwgdGhyZXNoaG9sZCkpO1xuICAgIHJlc3VsdCAmJiAocmVzdWx0ID0gaXNJblJhbmdlKHAyLnggLSBwMy54LCB0aHJlc2hob2xkKSB8fCBpc0luUmFuZ2UocDIueCAtIHA0LngsIHRocmVzaGhvbGQpKTtcbiAgICByZXN1bHQgJiYgKHJlc3VsdCA9IGlzSW5SYW5nZShwMS55IC0gcDMueSwgdGhyZXNoaG9sZCkgfHwgaXNJblJhbmdlKHAxLnkgLSBwNC55LCB0aHJlc2hob2xkKSk7XG4gICAgcmVzdWx0ICYmIChyZXN1bHQgPSBpc0luUmFuZ2UocDIueSAtIHAzLnksIHRocmVzaGhvbGQpIHx8IGlzSW5SYW5nZShwMi55IC0gcDQueSwgdGhyZXNoaG9sZCkpO1xuICAgIHJldHVybiByZXN1bHQ7XG4gIH07XG5cbiAgcmVtb3ZlQ29sbGluZWFyUG9pbnRzID0gZnVuY3Rpb24obGlzdE9mUG9seSkge1xuICAgIHZhciBjLCBpLCBpMiwgaTMsIGlkeCwgbmV3X3BvbHksIHAsIHBvbHksIHBvbHlnb25zX21lcmdlZCwgc3ViX3BvbHksIHRocm93X2F3YXlfdmVydGljZXMsIF9pLCBfbGVuO1xuICAgIHBvbHlnb25zX21lcmdlZCA9IFtdO1xuICAgIGZvciAoX2kgPSAwLCBfbGVuID0gbGlzdE9mUG9seS5sZW5ndGg7IF9pIDwgX2xlbjsgX2krKykge1xuICAgICAgcG9seSA9IGxpc3RPZlBvbHlbX2ldO1xuICAgICAgdGhyb3dfYXdheV92ZXJ0aWNlcyA9IFtdO1xuICAgICAgaSA9IDA7XG4gICAgICB3aGlsZSAoaSA8IHBvbHkubGVuZ3RoKSB7XG4gICAgICAgIGlmIChpID09PSBwb2x5Lmxlbmd0aCAtIDIpIHtcbiAgICAgICAgICBpMiA9IGkgKyAxO1xuICAgICAgICAgIGkzID0gMDtcbiAgICAgICAgfSBlbHNlIGlmIChpID09PSBwb2x5Lmxlbmd0aCAtIDEpIHtcbiAgICAgICAgICBpMiA9IDA7XG4gICAgICAgICAgaTMgPSAxO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIGkyID0gaSArIDE7XG4gICAgICAgICAgaTMgPSBpICsgMjtcbiAgICAgICAgfVxuICAgICAgICBzdWJfcG9seSA9IFtwb2x5W2ldLCBwb2x5W2kyXSwgcG9seVtpM11dO1xuICAgICAgICBjID0gMDtcbiAgICAgICAgd2hpbGUgKHBvaW50c09uT25lTGluZShzdWJfcG9seSkpIHtcbiAgICAgICAgICB0aHJvd19hd2F5X3ZlcnRpY2VzLnB1c2goaTIpO1xuICAgICAgICAgIGkyID0gaTIgPT09IChwb2x5Lmxlbmd0aCAtIDEpID8gMCA6IGkyICsgMTtcbiAgICAgICAgICBzdWJfcG9seS5wdXNoKHBvbHlbaTJdKTtcbiAgICAgICAgICBjICs9IDE7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKGMgIT09IDApIHtcbiAgICAgICAgICB0aHJvd19hd2F5X3ZlcnRpY2VzLnBvcCgpO1xuICAgICAgICB9XG4gICAgICAgIGkgPSBjICE9PSAwID8gaSArIGMgOiBpICsgMTtcbiAgICAgIH1cbiAgICAgIG5ld19wb2x5ID0gKGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgX2osIF9sZW4xLCBfcmVzdWx0cztcbiAgICAgICAgX3Jlc3VsdHMgPSBbXTtcbiAgICAgICAgZm9yIChpZHggPSBfaiA9IDAsIF9sZW4xID0gcG9seS5sZW5ndGg7IF9qIDwgX2xlbjE7IGlkeCA9ICsrX2opIHtcbiAgICAgICAgICBwID0gcG9seVtpZHhdO1xuICAgICAgICAgIGlmIChfX2luZGV4T2YuY2FsbCh0aHJvd19hd2F5X3ZlcnRpY2VzLCBpZHgpIDwgMCkge1xuICAgICAgICAgICAgX3Jlc3VsdHMucHVzaChwKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIF9yZXN1bHRzO1xuICAgICAgfSkoKTtcbiAgICAgIHBvbHlnb25zX21lcmdlZC5wdXNoKG5ld19wb2x5KTtcbiAgICB9XG4gICAgcmV0dXJuIHBvbHlnb25zX21lcmdlZDtcbiAgfTtcblxuICBwb2x5Z29uQXJlYU92ZXJUaHJlc2hob2xkID0gZnVuY3Rpb24ocG9seSwgdGhyZXNoaG9sZCkge1xuICAgIHZhciBpLCBzdW0sIHgxLCB4MiwgeTEsIHkyLCBfaSwgX3JlZjtcbiAgICBzdW0gPSAwO1xuICAgIGZvciAoaSA9IF9pID0gMCwgX3JlZiA9IHBvbHkuZ2V0TnVtUG9pbnRzKCkgLSAxOyAwIDw9IF9yZWYgPyBfaSA8IF9yZWYgOiBfaSA+IF9yZWY7IGkgPSAwIDw9IF9yZWYgPyArK19pIDogLS1faSkge1xuICAgICAgeDEgPSBwb2x5LmdldFgoaSk7XG4gICAgICB5MSA9IHBvbHkuZ2V0WShpKTtcbiAgICAgIHgyID0gcG9seS5nZXRYKGkgKyAxKTtcbiAgICAgIHkyID0gcG9seS5nZXRZKGkgKyAxKTtcbiAgICAgIHN1bSArPSB4MSAqIHkyIC0geTEgKiB4MjtcbiAgICB9XG4gICAgeDEgPSBwb2x5LmdldFgocG9seS5nZXROdW1Qb2ludHMoKSAtIDEpO1xuICAgIHkxID0gcG9seS5nZXRZKHBvbHkuZ2V0TnVtUG9pbnRzKCkgLSAxKTtcbiAgICB4MiA9IHBvbHkuZ2V0WCgwKTtcbiAgICB5MiA9IHBvbHkuZ2V0WSgwKTtcbiAgICBzdW0gKz0geDEgKiB5MiAtIHkxICogeDI7XG4gICAgcmV0dXJuIE1hdGguYWJzKHN1bSAvIDIuMCkgPiB0aHJlc2hob2xkO1xuICB9O1xuXG4gIGlzSW5SYW5nZSA9IGZ1bmN0aW9uKHZhbCwgdGhyZXNoaG9sZCkge1xuICAgIHJldHVybiBNYXRoLmFicyh2YWwpIDwgdGhyZXNoaG9sZDtcbiAgfTtcblxuICBwb2ludHNPbk9uZUxpbmUgPSBmdW5jdGlvbihwb2x5KSB7XG4gICAgdmFyIGEsIGIsIGMsIGksIHRocmVzaGhvbGQsIHgsIHgxLCB4MiwgeSwgeTEsIHkyLCBfaSwgX3JlZjtcbiAgICB0aHJlc2hob2xkID0gTWF0aC5wb3coMTAsIC0yKTtcbiAgICB4MiA9IHBvbHlbcG9seS5sZW5ndGggLSAxXS54O1xuICAgIHkyID0gcG9seVtwb2x5Lmxlbmd0aCAtIDFdLnk7XG4gICAgeDEgPSBwb2x5WzBdLng7XG4gICAgeTEgPSBwb2x5WzBdLnk7XG4gICAgaWYgKCFpc0luUmFuZ2UoeDIgLSB4MSwgdGhyZXNoaG9sZCkpIHtcbiAgICAgIGIgPSAtMTtcbiAgICAgIGEgPSAoeTIgLSB5MSkgLyAoeDIgLSB4MSk7XG4gICAgfSBlbHNlIGlmICghaXNJblJhbmdlKHkyIC0geTEsIHRocmVzaGhvbGQpKSB7XG4gICAgICBhID0gLTE7XG4gICAgICBiID0gKHgyIC0geDEpIC8gKHkyIC0geTEpO1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gdHJ1ZTtcbiAgICB9XG4gICAgYyA9IC1hICogeDEgLSBiICogeTE7XG4gICAgZm9yIChpID0gX2kgPSAwLCBfcmVmID0gcG9seS5sZW5ndGg7IDAgPD0gX3JlZiA/IF9pIDwgX3JlZiA6IF9pID4gX3JlZjsgaSA9IDAgPD0gX3JlZiA/ICsrX2kgOiAtLV9pKSB7XG4gICAgICB4ID0gcG9seVtpXS54O1xuICAgICAgeSA9IHBvbHlbaV0ueTtcbiAgICAgIGlmICghaXNJblJhbmdlKHggKiBhICsgeSAqIGIgKyBjLCB0aHJlc2hob2xkKSkge1xuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiB0cnVlO1xuICB9O1xuXG4gIGlzQ2xvY2tXaXNlID0gZnVuY3Rpb24ocG9seSkge1xuICAgIHZhciBpLCBwMSwgcDIsIHN1bSwgX2ksIF9yZWY7XG4gICAgc3VtID0gMC4wO1xuICAgIGZvciAoaSA9IF9pID0gaSwgX3JlZiA9IHBvbHkubGVuZ3RoOyBpIDw9IF9yZWYgPyBfaSA8IF9yZWYgOiBfaSA+IF9yZWY7IGkgPSBpIDw9IF9yZWYgPyArK19pIDogLS1faSkge1xuICAgICAgcDEgPSBwW2ldO1xuICAgICAgcDIgPSBpID09PSBwb2x5Lmxlbmd0aCAtIDEgPyAwIDogcG9seVtpICsgMV07XG4gICAgICBzdW0gKz0gKHAyLnggLSBwMS54KSAqIChwMi55ICsgcDEueSk7XG4gICAgfVxuICAgIHJldHVybiBzdW0gPCAwO1xuICB9O1xuXG4gIHJlbW92ZUR1cGxpY2F0ZXMgPSBmdW5jdGlvbihsaXN0T2ZQb2x5KSB7XG4gICAgdmFyIGksIHAxLCBwMiwgcG9seSwgdGhyZXNoaG9sZCwgX2ksIF9sZW47XG4gICAgdGhyZXNoaG9sZCA9IE1hdGgucG93KDEwLCAtMyk7XG4gICAgZm9yIChfaSA9IDAsIF9sZW4gPSBsaXN0T2ZQb2x5Lmxlbmd0aDsgX2kgPCBfbGVuOyBfaSsrKSB7XG4gICAgICBwb2x5ID0gbGlzdE9mUG9seVtfaV07XG4gICAgICBpID0gcG9seS5sZW5ndGg7XG4gICAgICB3aGlsZSAodHJ1ZSkge1xuICAgICAgICAtLWk7XG4gICAgICAgIGlmIChpIDwgMCkge1xuICAgICAgICAgIGJyZWFrO1xuICAgICAgICB9XG4gICAgICAgIHAxID0gcG9seVtpXTtcbiAgICAgICAgcDIgPSBpID09PSAwID8gcG9seVtwb2x5Lmxlbmd0aCAtIDFdIDogcG9seVtpIC0gMV07XG4gICAgICAgIGlmIChpc0luUmFuZ2UocDEuZGlzdGFuY2VUbyhwMiksIHRocmVzaGhvbGQpKSB7XG4gICAgICAgICAgcG9seS5zcGxpY2UoaSwgMSk7XG4gICAgICAgICAgaSArPSAyO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiBsaXN0T2ZQb2x5O1xuICB9O1xuXG4gIGV4cG9ydHMgPSB7XG4gICAgbWVyZ2VVbm1lcmdlZFBvbHlnb25zOiBtZXJnZVVubWVyZ2VkUG9seWdvbnMsXG4gICAgYXJlUG9pbnRQYWlyc0VxdWFsOiBhcmVQb2ludFBhaXJzRXF1YWwsXG4gICAgYXJlUG9pbnRzT25TYW1lTGluZVNlZ21lbnQ6IGFyZVBvaW50c09uU2FtZUxpbmVTZWdtZW50LFxuICAgIGFyZVBvaW50UGFpcnNFcXVhbDogYXJlUG9pbnRQYWlyc0VxdWFsLFxuICAgIHJlbW92ZUNvbGxpbmVhclBvaW50czogcmVtb3ZlQ29sbGluZWFyUG9pbnRzLFxuICAgIHBvbHlnb25BcmVhT3ZlclRocmVzaGhvbGQ6IHBvbHlnb25BcmVhT3ZlclRocmVzaGhvbGQsXG4gICAgaXNJblJhbmdlOiBpc0luUmFuZ2UsXG4gICAgcG9pbnRzT25PbmVMaW5lOiBwb2ludHNPbk9uZUxpbmUsXG4gICAgaXNDbG9ja1dpc2U6IGlzQ2xvY2tXaXNlLFxuICAgIHJlbW92ZUR1cGxpY2F0ZXM6IHJlbW92ZUR1cGxpY2F0ZXNcbiAgfTtcblxufSkuY2FsbCh0aGlzKTtcbiIsIihmdW5jdGlvbigpIHtcbiAgdmFyIHJlbmRlcjtcblxuICByZW5kZXIgPSBmdW5jdGlvbih1aSkge1xuICAgIHZhciBsb2NhbFJlbmRlcmVyO1xuICAgIGxvY2FsUmVuZGVyZXIgPSBmdW5jdGlvbigpIHtcbiAgICAgIHJlcXVlc3RBbmltYXRpb25GcmFtZShsb2NhbFJlbmRlcmVyKTtcbiAgICAgIHJldHVybiB1aS5yZW5kZXJlci5yZW5kZXIodWkuc2NlbmUsIHVpLmNhbWVyYSk7XG4gICAgfTtcbiAgICByZXR1cm4gbG9jYWxSZW5kZXJlcigpO1xuXG4gICAgLypcbiAgICBcdGxlbiA9IGFuaW1hdGlvbnMubGVuZ3RoXG4gICAgXHRpZiBsZW5cbiAgICBcdFx0bG9vcFxuICAgIFx0XHRcdGxlbi0tXG4gICAgXHRcdFx0YnJlYWsgdW5sZXNzIGxlbiA+PSAwXG4gICAgXHRcdFx0YW5pbWF0aW9uID0gYW5pbWF0aW9uc1tsZW5dXG4gICAgXHRcdFx0aWYgYW5pbWF0aW9uLnN0YXR1cyA+IDEuMFxuICAgIFx0XHRcdFx0YW5pbWF0aW9ucy5zcGxpY2UoIGxlbiwgMSApXG4gICAgXHRcdFx0YW5pbWF0aW9uLmRvQW5pbWF0aW9uU3RlcCgpXG4gICAgICovXG4gIH07XG5cbiAgbW9kdWxlLmV4cG9ydHMgPSByZW5kZXI7XG5cbn0pLmNhbGwodGhpcyk7XG4iLCIoZnVuY3Rpb24oKSB7XG4gIG1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24oZ2xvYmFsQ29uZmlnKSB7XG4gICAgcmV0dXJuIHtcbiAgICAgIHNjZW5lOiBuZXcgVEhSRUUuU2NlbmUoKSxcbiAgICAgIGNhbWVyYTogbmV3IFRIUkVFLlBlcnNwZWN0aXZlQ2FtZXJhKGdsb2JhbENvbmZpZy5mb3YsIHdpbmRvdy5pbm5lcldpZHRoIC8gd2luZG93LmlubmVySGVpZ2h0LCBnbG9iYWxDb25maWcuY2FtZXJhTmVhclBsYW5lLCBnbG9iYWxDb25maWcuY2FtZXJhRmFyUGxhbmUpLFxuICAgICAgcmVuZGVyZXI6IG5ldyBUSFJFRS5XZWJHTFJlbmRlcmVyKHtcbiAgICAgICAgYWxwaGE6IHRydWUsXG4gICAgICAgIGFudGlhbGlhc2luZzogdHJ1ZSxcbiAgICAgICAgcHJlc2VydmVEcmF3aW5nQnVmZmVyOiB0cnVlXG4gICAgICB9KSxcbiAgICAgIGNvbnRyb2xzOiBudWxsLFxuICAgICAgc3RsTG9hZGVyOiBuZXcgVEhSRUUuU1RMTG9hZGVyKCksXG4gICAgICBmaWxlUmVhZGVyOiBuZXcgRmlsZVJlYWRlcigpLFxuICAgICAga2V5VXBIYW5kbGVyOiBmdW5jdGlvbihldmVudCkge1xuICAgICAgICB2YXIgbWVzaCwgX2ksIF9sZW4sIF9yZWY7XG4gICAgICAgIGlmIChldmVudC5rZXlDb2RlID09PSA2Nykge1xuICAgICAgICAgIF9yZWYgPSBnbG9iYWxDb25maWcubWVzaGVzO1xuICAgICAgICAgIGZvciAoX2kgPSAwLCBfbGVuID0gX3JlZi5sZW5ndGg7IF9pIDwgX2xlbjsgX2krKykge1xuICAgICAgICAgICAgbWVzaCA9IF9yZWZbX2ldO1xuICAgICAgICAgICAgdGhpcy5zY2VuZS5yZW1vdmUobWVzaCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIHJldHVybiBnbG9iYWxDb25maWcubWVzaGVzID0gW107XG4gICAgICAgIH1cbiAgICAgIH0sXG4gICAgICBsb2FkSGFuZGxlcjogZnVuY3Rpb24oZXZlbnQpIHtcbiAgICAgICAgdmFyIGdlb21ldHJ5O1xuICAgICAgICBnZW9tZXRyeSA9IHRoaXMuc3RsTG9hZGVyLnBhcnNlKGV2ZW50LnRhcmdldC5yZXN1bHQpO1xuICAgICAgICByZXR1cm4gJCh0aGlzKS50cmlnZ2VyKCdnZW9tZXRyeS1sb2FkZWQnLCBnZW9tZXRyeSk7XG5cbiAgICAgICAgLypcbiAgICAgICAgXHRcdFx0b2JqZWN0TWF0ZXJpYWwgPSBuZXcgVEhSRUUuTWVzaExhbWJlcnRNYXRlcmlhbChcbiAgICAgICAgXHRcdFx0XHR7XG4gICAgICAgIFx0XHRcdFx0XHRjb2xvcjogZ2xvYmFsQ29uZmlnLmRlZmF1bHRPYmplY3RDb2xvclxuICAgICAgICBcdFx0XHRcdFx0YW1iaWVudDogZ2xvYmFsQ29uZmlnLmRlZmF1bHRPYmplY3RDb2xvclxuICAgICAgICBcdFx0XHRcdH1cbiAgICAgICAgXHRcdFx0KVxuICAgICAgICBcdFx0XHRvYmplY3QgPSBuZXcgVEhSRUUuTWVzaCggZ2VvbWV0cnksIG9iamVjdE1hdGVyaWFsIClcbiAgICAgICAgXHRcdFx0QHNjZW5lLmFkZCggb2JqZWN0IClcbiAgICAgICAgXHRcdFx0Z2xvYmFsQ29uZmlnLm1lc2hlcy5wdXNoKCBvYmplY3QgKVxuICAgICAgICAgKi9cbiAgICAgIH0sXG4gICAgICBkcm9wSGFuZGxlcjogZnVuY3Rpb24oZXZlbnQpIHtcbiAgICAgICAgdmFyIGZpbGUsIGZpbGVzLCBfaSwgX2xlbiwgX3JlZiwgX3Jlc3VsdHM7XG4gICAgICAgIGV2ZW50LnN0b3BQcm9wYWdhdGlvbigpO1xuICAgICAgICBldmVudC5wcmV2ZW50RGVmYXVsdCgpO1xuICAgICAgICBmaWxlcyA9IChfcmVmID0gZXZlbnQudGFyZ2V0LmZpbGVzKSAhPSBudWxsID8gX3JlZiA6IGV2ZW50LmRhdGFUcmFuc2Zlci5maWxlcztcbiAgICAgICAgX3Jlc3VsdHMgPSBbXTtcbiAgICAgICAgZm9yIChfaSA9IDAsIF9sZW4gPSBmaWxlcy5sZW5ndGg7IF9pIDwgX2xlbjsgX2krKykge1xuICAgICAgICAgIGZpbGUgPSBmaWxlc1tfaV07XG4gICAgICAgICAgaWYgKGZpbGUubmFtZS5jb250YWlucygnLnN0bCcpKSB7XG4gICAgICAgICAgICBfcmVzdWx0cy5wdXNoKHRoaXMuZmlsZVJlYWRlci5yZWFkQXNCaW5hcnlTdHJpbmcoZmlsZSkpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBfcmVzdWx0cy5wdXNoKHZvaWQgMCk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIHJldHVybiBfcmVzdWx0cztcbiAgICAgIH0sXG4gICAgICBkcmFnT3ZlckhhbmRsZXI6IGZ1bmN0aW9uKGV2ZW50KSB7XG4gICAgICAgIGV2ZW50LnN0b3BQcm9wYWdhdGlvbigpO1xuICAgICAgICBldmVudC5wcmV2ZW50RGVmYXVsdCgpO1xuICAgICAgICByZXR1cm4gZXZlbnQuZGF0YVRyYW5zZmVyLmRyb3BFZmZlY3QgPSAnY29weSc7XG4gICAgICB9LFxuICAgICAgd2luZG93UmVzaXplSGFuZGxlcjogZnVuY3Rpb24oZXZlbnQpIHtcbiAgICAgICAgdGhpcy5jYW1lcmEuYXNwZWN0ID0gd2luZG93LmlubmVyV2lkdGggLyB3aW5kb3cuaW5uZXJIZWlnaHQ7XG4gICAgICAgIHRoaXMuY2FtZXJhLnVwZGF0ZVByb2plY3Rpb25NYXRyaXgoKTtcbiAgICAgICAgdGhpcy5yZW5kZXJlci5zZXRTaXplKHdpbmRvdy5pbm5lcldpZHRoLCB3aW5kb3cuaW5uZXJIZWlnaHQpO1xuICAgICAgICByZXR1cm4gdGhpcy5yZW5kZXJlci5yZW5kZXIodGhpcy5zY2VuZSwgdGhpcy5jYW1lcmEpO1xuICAgICAgfSxcbiAgICAgIGluaXQ6IGZ1bmN0aW9uKCkge1xuICAgICAgICB2YXIgYW1iaWVudExpZ2h0LCBkaXJlY3Rpb25hbExpZ2h0LCBnZW9tZXRyeVhBeGlzLCBnZW9tZXRyeVlBeGlzLCBnZW9tZXRyeVpBeGlzLCBncmlkTGluZUdlb21ldHJ5WE5lZ2F0aXZlLCBncmlkTGluZUdlb21ldHJ5WFBvc2l0aXZlLCBncmlkTGluZUdlb21ldHJ5WU5lZ2F0aXZlLCBncmlkTGluZUdlb21ldHJ5WVBvc2l0aXZlLCBncmlkTGluZVhOZWdhdGl2ZSwgZ3JpZExpbmVYUG9zaXRpdmUsIGdyaWRMaW5lWU5lZ2F0aXZlLCBncmlkTGluZVlQb3NpdGl2ZSwgaSwgbWF0ZXJpYWwsIG1hdGVyaWFsR3JpZDEwLCBtYXRlcmlhbEdyaWQ1LCBtYXRlcmlhbEdyaWROb3JtYWwsIG1hdGVyaWFsWEF4aXMsIG1hdGVyaWFsWUF4aXMsIG1hdGVyaWFsWkF4aXMsIG51bSwgc2NlbmVSb3RhdGlvbiwgeEF4aXMsIHlBeGlzLCB6QXhpcywgX2ksIF9yZWY7XG4gICAgICAgIHRoaXMucmVuZGVyZXIuc2V0U2l6ZSh3aW5kb3cuaW5uZXJXaWR0aCwgd2luZG93LmlubmVySGVpZ2h0KTtcbiAgICAgICAgdGhpcy5yZW5kZXJlci5zZXRDbGVhckNvbG9yKDB4ZjZmNmY2LCAxKTtcbiAgICAgICAgZG9jdW1lbnQuYm9keS5hcHBlbmRDaGlsZCh0aGlzLnJlbmRlcmVyLmRvbUVsZW1lbnQpO1xuICAgICAgICBzY2VuZVJvdGF0aW9uID0gbmV3IFRIUkVFLk1hdHJpeDQoKTtcbiAgICAgICAgc2NlbmVSb3RhdGlvbi5tYWtlUm90YXRpb25BeGlzKG5ldyBUSFJFRS5WZWN0b3IzKDEsIDAsIDApLCAtTWF0aC5QSSAvIDIpO1xuICAgICAgICB0aGlzLnNjZW5lLmFwcGx5TWF0cml4KHNjZW5lUm90YXRpb24pO1xuICAgICAgICB0aGlzLmNhbWVyYS5wb3NpdGlvbi5zZXQoZ2xvYmFsQ29uZmlnLmF4aXNMZW5ndGgsIGdsb2JhbENvbmZpZy5heGlzTGVuZ3RoICsgMTAsIGdsb2JhbENvbmZpZy5heGlzTGVuZ3RoIC8gMik7XG4gICAgICAgIHRoaXMuY2FtZXJhLnVwLnNldCgwLCAxLCAwKTtcbiAgICAgICAgdGhpcy5jYW1lcmEubG9va0F0KG5ldyBUSFJFRS5WZWN0b3IzKDAsIDAsIDApKTtcbiAgICAgICAgdGhpcy5jb250cm9scyA9IG5ldyBUSFJFRS5PcmJpdENvbnRyb2xzKHRoaXMuY2FtZXJhKTtcbiAgICAgICAgdGhpcy5jb250cm9scy50YXJnZXQuc2V0KDAsIDAsIDApO1xuICAgICAgICBtYXRlcmlhbFhBeGlzID0gbmV3IFRIUkVFLkxpbmVCYXNpY01hdGVyaWFsKHtcbiAgICAgICAgICBjb2xvcjogZ2xvYmFsQ29uZmlnLmF4aXNYQ29sb3IsXG4gICAgICAgICAgbGluZXdpZHRoOiBnbG9iYWxDb25maWcuYXhpc0xpbmVXaWR0aFxuICAgICAgICB9KTtcbiAgICAgICAgbWF0ZXJpYWxZQXhpcyA9IG5ldyBUSFJFRS5MaW5lQmFzaWNNYXRlcmlhbCh7XG4gICAgICAgICAgY29sb3I6IGdsb2JhbENvbmZpZy5heGlzWUNvbG9yLFxuICAgICAgICAgIGxpbmV3aWR0aDogZ2xvYmFsQ29uZmlnLmF4aXNMaW5lV2lkdGhcbiAgICAgICAgfSk7XG4gICAgICAgIG1hdGVyaWFsWkF4aXMgPSBuZXcgVEhSRUUuTGluZUJhc2ljTWF0ZXJpYWwoe1xuICAgICAgICAgIGNvbG9yOiBnbG9iYWxDb25maWcuYXhpc1pDb2xvcixcbiAgICAgICAgICBsaW5ld2lkdGg6IGdsb2JhbENvbmZpZy5heGlzTGluZVdpZHRoXG4gICAgICAgIH0pO1xuICAgICAgICBnZW9tZXRyeVhBeGlzID0gbmV3IFRIUkVFLkdlb21ldHJ5KCk7XG4gICAgICAgIGdlb21ldHJ5WUF4aXMgPSBuZXcgVEhSRUUuR2VvbWV0cnkoKTtcbiAgICAgICAgZ2VvbWV0cnlaQXhpcyA9IG5ldyBUSFJFRS5HZW9tZXRyeSgpO1xuICAgICAgICBnZW9tZXRyeVhBeGlzLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoMCwgMCwgMCkpO1xuICAgICAgICBnZW9tZXRyeVhBeGlzLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoZ2xvYmFsQ29uZmlnLmF4aXNMZW5ndGgsIDAsIDApKTtcbiAgICAgICAgZ2VvbWV0cnlZQXhpcy52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKDAsIDAsIDApKTtcbiAgICAgICAgZ2VvbWV0cnlZQXhpcy52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKDAsIGdsb2JhbENvbmZpZy5heGlzTGVuZ3RoLCAwKSk7XG4gICAgICAgIGdlb21ldHJ5WkF4aXMudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMygwLCAwLCAwKSk7XG4gICAgICAgIGdlb21ldHJ5WkF4aXMudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMygwLCAwLCBnbG9iYWxDb25maWcuYXhpc0xlbmd0aCkpO1xuICAgICAgICB4QXhpcyA9IG5ldyBUSFJFRS5MaW5lKGdlb21ldHJ5WEF4aXMsIG1hdGVyaWFsWEF4aXMpO1xuICAgICAgICB5QXhpcyA9IG5ldyBUSFJFRS5MaW5lKGdlb21ldHJ5WUF4aXMsIG1hdGVyaWFsWUF4aXMpO1xuICAgICAgICB6QXhpcyA9IG5ldyBUSFJFRS5MaW5lKGdlb21ldHJ5WkF4aXMsIG1hdGVyaWFsWkF4aXMpO1xuICAgICAgICB0aGlzLnNjZW5lLmFkZCh4QXhpcyk7XG4gICAgICAgIHRoaXMuc2NlbmUuYWRkKHlBeGlzKTtcbiAgICAgICAgdGhpcy5zY2VuZS5hZGQoekF4aXMpO1xuICAgICAgICBtYXRlcmlhbEdyaWROb3JtYWwgPSBuZXcgVEhSRUUuTGluZUJhc2ljTWF0ZXJpYWwoe1xuICAgICAgICAgIGNvbG9yOiBnbG9iYWxDb25maWcuZ3JpZENvbG9yTm9ybWFsLFxuICAgICAgICAgIGxpbmV3aWR0aDogZ2xvYmFsQ29uZmlnLmdyaWRMaW5lV2lkdGhOb3JtYWxcbiAgICAgICAgfSk7XG4gICAgICAgIG1hdGVyaWFsR3JpZDUgPSBuZXcgVEhSRUUuTGluZUJhc2ljTWF0ZXJpYWwoe1xuICAgICAgICAgIGNvbG9yOiBnbG9iYWxDb25maWcuZ3JpZENvbG9yNSxcbiAgICAgICAgICBsaW5ld2lkdGg6IGdsb2JhbENvbmZpZy5ncmlkTGluZVdpZHRoNVxuICAgICAgICB9KTtcbiAgICAgICAgbWF0ZXJpYWxHcmlkMTAgPSBuZXcgVEhSRUUuTGluZUJhc2ljTWF0ZXJpYWwoe1xuICAgICAgICAgIGNvbG9yOiBnbG9iYWxDb25maWcuZ3JpZENvbG9yMTAsXG4gICAgICAgICAgbGluZXdpZHRoOiBnbG9iYWxDb25maWcuZ3JpZExpbmVXaWR0aDEwXG4gICAgICAgIH0pO1xuICAgICAgICBmb3IgKGkgPSBfaSA9IDAsIF9yZWYgPSBnbG9iYWxDb25maWcuZ3JpZFNpemUgLyBnbG9iYWxDb25maWcuZ3JpZFN0ZXBTaXplOyAwIDw9IF9yZWYgPyBfaSA8PSBfcmVmIDogX2kgPj0gX3JlZjsgaSA9IDAgPD0gX3JlZiA/ICsrX2kgOiAtLV9pKSB7XG4gICAgICAgICAgbnVtID0gaSAqIGdsb2JhbENvbmZpZy5ncmlkU3RlcFNpemU7XG4gICAgICAgICAgaWYgKGkgJSAxMCAqIGdsb2JhbENvbmZpZy5ncmlkU3RlcFNpemUgPT09IDApIHtcbiAgICAgICAgICAgIG1hdGVyaWFsID0gbWF0ZXJpYWxHcmlkMTA7XG4gICAgICAgICAgfSBlbHNlIGlmIChpICUgNSAqIGdsb2JhbENvbmZpZy5ncmlkU3RlcFNpemUgPT09IDApIHtcbiAgICAgICAgICAgIG1hdGVyaWFsID0gbWF0ZXJpYWxHcmlkNTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgbWF0ZXJpYWwgPSBtYXRlcmlhbEdyaWROb3JtYWw7XG4gICAgICAgICAgfVxuICAgICAgICAgIGdyaWRMaW5lR2VvbWV0cnlYUG9zaXRpdmUgPSBuZXcgVEhSRUUuR2VvbWV0cnkoKTtcbiAgICAgICAgICBncmlkTGluZUdlb21ldHJ5WVBvc2l0aXZlID0gbmV3IFRIUkVFLkdlb21ldHJ5KCk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVhOZWdhdGl2ZSA9IG5ldyBUSFJFRS5HZW9tZXRyeSgpO1xuICAgICAgICAgIGdyaWRMaW5lR2VvbWV0cnlZTmVnYXRpdmUgPSBuZXcgVEhSRUUuR2VvbWV0cnkoKTtcbiAgICAgICAgICBncmlkTGluZUdlb21ldHJ5WFBvc2l0aXZlLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoLWdsb2JhbENvbmZpZy5ncmlkU2l6ZSwgbnVtLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVhQb3NpdGl2ZS52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKGdsb2JhbENvbmZpZy5ncmlkU2l6ZSwgbnVtLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVlQb3NpdGl2ZS52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKG51bSwgLWdsb2JhbENvbmZpZy5ncmlkU2l6ZSwgMCkpO1xuICAgICAgICAgIGdyaWRMaW5lR2VvbWV0cnlZUG9zaXRpdmUudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMyhudW0sIGdsb2JhbENvbmZpZy5ncmlkU2l6ZSwgMCkpO1xuICAgICAgICAgIGdyaWRMaW5lR2VvbWV0cnlYTmVnYXRpdmUudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMygtZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCAtbnVtLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVhOZWdhdGl2ZS52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKGdsb2JhbENvbmZpZy5ncmlkU2l6ZSwgLW51bSwgMCkpO1xuICAgICAgICAgIGdyaWRMaW5lR2VvbWV0cnlZTmVnYXRpdmUudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMygtbnVtLCAtZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVlOZWdhdGl2ZS52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKC1udW0sIGdsb2JhbENvbmZpZy5ncmlkU2l6ZSwgMCkpO1xuICAgICAgICAgIGdyaWRMaW5lWFBvc2l0aXZlID0gbmV3IFRIUkVFLkxpbmUoZ3JpZExpbmVHZW9tZXRyeVhQb3NpdGl2ZSwgbWF0ZXJpYWwpO1xuICAgICAgICAgIGdyaWRMaW5lWVBvc2l0aXZlID0gbmV3IFRIUkVFLkxpbmUoZ3JpZExpbmVHZW9tZXRyeVlQb3NpdGl2ZSwgbWF0ZXJpYWwpO1xuICAgICAgICAgIGdyaWRMaW5lWE5lZ2F0aXZlID0gbmV3IFRIUkVFLkxpbmUoZ3JpZExpbmVHZW9tZXRyeVhOZWdhdGl2ZSwgbWF0ZXJpYWwpO1xuICAgICAgICAgIGdyaWRMaW5lWU5lZ2F0aXZlID0gbmV3IFRIUkVFLkxpbmUoZ3JpZExpbmVHZW9tZXRyeVlOZWdhdGl2ZSwgbWF0ZXJpYWwpO1xuICAgICAgICAgIHRoaXMuc2NlbmUuYWRkKGdyaWRMaW5lWFBvc2l0aXZlKTtcbiAgICAgICAgICB0aGlzLnNjZW5lLmFkZChncmlkTGluZVlQb3NpdGl2ZSk7XG4gICAgICAgICAgdGhpcy5zY2VuZS5hZGQoZ3JpZExpbmVYTmVnYXRpdmUpO1xuICAgICAgICAgIHRoaXMuc2NlbmUuYWRkKGdyaWRMaW5lWU5lZ2F0aXZlKTtcbiAgICAgICAgfVxuICAgICAgICB0aGlzLnJlbmRlcmVyLmRvbUVsZW1lbnQuYWRkRXZlbnRMaXN0ZW5lcignZHJhZ292ZXInLCB0aGlzLmRyYWdPdmVySGFuZGxlci5iaW5kKHRoaXMpLCBmYWxzZSk7XG4gICAgICAgIHRoaXMucmVuZGVyZXIuZG9tRWxlbWVudC5hZGRFdmVudExpc3RlbmVyKCdkcm9wJywgdGhpcy5kcm9wSGFuZGxlci5iaW5kKHRoaXMpLCBmYWxzZSk7XG4gICAgICAgIHRoaXMuZmlsZVJlYWRlci5hZGRFdmVudExpc3RlbmVyKCdsb2FkZW5kJywgdGhpcy5sb2FkSGFuZGxlci5iaW5kKHRoaXMpLCBmYWxzZSk7XG4gICAgICAgIGRvY3VtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ2tleXVwJywgdGhpcy5rZXlVcEhhbmRsZXIuYmluZCh0aGlzKSk7XG4gICAgICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKCdyZXNpemUnLCB0aGlzLndpbmRvd1Jlc2l6ZUhhbmRsZXIuYmluZCh0aGlzKSwgZmFsc2UpO1xuICAgICAgICBhbWJpZW50TGlnaHQgPSBuZXcgVEhSRUUuQW1iaWVudExpZ2h0KDB4NDA0MDQwKTtcbiAgICAgICAgdGhpcy5zY2VuZS5hZGQoYW1iaWVudExpZ2h0KTtcbiAgICAgICAgZGlyZWN0aW9uYWxMaWdodCA9IG5ldyBUSFJFRS5EaXJlY3Rpb25hbExpZ2h0KDB4ZmZmZmZmKTtcbiAgICAgICAgZGlyZWN0aW9uYWxMaWdodC5wb3NpdGlvbi5zZXQoMCwgMjAsIDMwKTtcbiAgICAgICAgdGhpcy5zY2VuZS5hZGQoZGlyZWN0aW9uYWxMaWdodCk7XG4gICAgICAgIGRpcmVjdGlvbmFsTGlnaHQgPSBuZXcgVEhSRUUuRGlyZWN0aW9uYWxMaWdodCgweDgwODA4MCk7XG4gICAgICAgIGRpcmVjdGlvbmFsTGlnaHQucG9zaXRpb24uc2V0KDIwLCAwLCAzMCk7XG4gICAgICAgIHJldHVybiB0aGlzLnNjZW5lLmFkZChkaXJlY3Rpb25hbExpZ2h0KTtcbiAgICAgIH1cbiAgICB9O1xuICB9O1xuXG59KS5jYWxsKHRoaXMpO1xuIiwiKGZ1bmN0aW9uIChwcm9jZXNzKXtcbi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG4vLyByZXNvbHZlcyAuIGFuZCAuLiBlbGVtZW50cyBpbiBhIHBhdGggYXJyYXkgd2l0aCBkaXJlY3RvcnkgbmFtZXMgdGhlcmVcbi8vIG11c3QgYmUgbm8gc2xhc2hlcywgZW1wdHkgZWxlbWVudHMsIG9yIGRldmljZSBuYW1lcyAoYzpcXCkgaW4gdGhlIGFycmF5XG4vLyAoc28gYWxzbyBubyBsZWFkaW5nIGFuZCB0cmFpbGluZyBzbGFzaGVzIC0gaXQgZG9lcyBub3QgZGlzdGluZ3Vpc2hcbi8vIHJlbGF0aXZlIGFuZCBhYnNvbHV0ZSBwYXRocylcbmZ1bmN0aW9uIG5vcm1hbGl6ZUFycmF5KHBhcnRzLCBhbGxvd0Fib3ZlUm9vdCkge1xuICAvLyBpZiB0aGUgcGF0aCB0cmllcyB0byBnbyBhYm92ZSB0aGUgcm9vdCwgYHVwYCBlbmRzIHVwID4gMFxuICB2YXIgdXAgPSAwO1xuICBmb3IgKHZhciBpID0gcGFydHMubGVuZ3RoIC0gMTsgaSA+PSAwOyBpLS0pIHtcbiAgICB2YXIgbGFzdCA9IHBhcnRzW2ldO1xuICAgIGlmIChsYXN0ID09PSAnLicpIHtcbiAgICAgIHBhcnRzLnNwbGljZShpLCAxKTtcbiAgICB9IGVsc2UgaWYgKGxhc3QgPT09ICcuLicpIHtcbiAgICAgIHBhcnRzLnNwbGljZShpLCAxKTtcbiAgICAgIHVwKys7XG4gICAgfSBlbHNlIGlmICh1cCkge1xuICAgICAgcGFydHMuc3BsaWNlKGksIDEpO1xuICAgICAgdXAtLTtcbiAgICB9XG4gIH1cblxuICAvLyBpZiB0aGUgcGF0aCBpcyBhbGxvd2VkIHRvIGdvIGFib3ZlIHRoZSByb290LCByZXN0b3JlIGxlYWRpbmcgLi5zXG4gIGlmIChhbGxvd0Fib3ZlUm9vdCkge1xuICAgIGZvciAoOyB1cC0tOyB1cCkge1xuICAgICAgcGFydHMudW5zaGlmdCgnLi4nKTtcbiAgICB9XG4gIH1cblxuICByZXR1cm4gcGFydHM7XG59XG5cbi8vIFNwbGl0IGEgZmlsZW5hbWUgaW50byBbcm9vdCwgZGlyLCBiYXNlbmFtZSwgZXh0XSwgdW5peCB2ZXJzaW9uXG4vLyAncm9vdCcgaXMganVzdCBhIHNsYXNoLCBvciBub3RoaW5nLlxudmFyIHNwbGl0UGF0aFJlID1cbiAgICAvXihcXC8/fCkoW1xcc1xcU10qPykoKD86XFwuezEsMn18W15cXC9dKz98KShcXC5bXi5cXC9dKnwpKSg/OltcXC9dKikkLztcbnZhciBzcGxpdFBhdGggPSBmdW5jdGlvbihmaWxlbmFtZSkge1xuICByZXR1cm4gc3BsaXRQYXRoUmUuZXhlYyhmaWxlbmFtZSkuc2xpY2UoMSk7XG59O1xuXG4vLyBwYXRoLnJlc29sdmUoW2Zyb20gLi4uXSwgdG8pXG4vLyBwb3NpeCB2ZXJzaW9uXG5leHBvcnRzLnJlc29sdmUgPSBmdW5jdGlvbigpIHtcbiAgdmFyIHJlc29sdmVkUGF0aCA9ICcnLFxuICAgICAgcmVzb2x2ZWRBYnNvbHV0ZSA9IGZhbHNlO1xuXG4gIGZvciAodmFyIGkgPSBhcmd1bWVudHMubGVuZ3RoIC0gMTsgaSA+PSAtMSAmJiAhcmVzb2x2ZWRBYnNvbHV0ZTsgaS0tKSB7XG4gICAgdmFyIHBhdGggPSAoaSA+PSAwKSA/IGFyZ3VtZW50c1tpXSA6IHByb2Nlc3MuY3dkKCk7XG5cbiAgICAvLyBTa2lwIGVtcHR5IGFuZCBpbnZhbGlkIGVudHJpZXNcbiAgICBpZiAodHlwZW9mIHBhdGggIT09ICdzdHJpbmcnKSB7XG4gICAgICB0aHJvdyBuZXcgVHlwZUVycm9yKCdBcmd1bWVudHMgdG8gcGF0aC5yZXNvbHZlIG11c3QgYmUgc3RyaW5ncycpO1xuICAgIH0gZWxzZSBpZiAoIXBhdGgpIHtcbiAgICAgIGNvbnRpbnVlO1xuICAgIH1cblxuICAgIHJlc29sdmVkUGF0aCA9IHBhdGggKyAnLycgKyByZXNvbHZlZFBhdGg7XG4gICAgcmVzb2x2ZWRBYnNvbHV0ZSA9IHBhdGguY2hhckF0KDApID09PSAnLyc7XG4gIH1cblxuICAvLyBBdCB0aGlzIHBvaW50IHRoZSBwYXRoIHNob3VsZCBiZSByZXNvbHZlZCB0byBhIGZ1bGwgYWJzb2x1dGUgcGF0aCwgYnV0XG4gIC8vIGhhbmRsZSByZWxhdGl2ZSBwYXRocyB0byBiZSBzYWZlIChtaWdodCBoYXBwZW4gd2hlbiBwcm9jZXNzLmN3ZCgpIGZhaWxzKVxuXG4gIC8vIE5vcm1hbGl6ZSB0aGUgcGF0aFxuICByZXNvbHZlZFBhdGggPSBub3JtYWxpemVBcnJheShmaWx0ZXIocmVzb2x2ZWRQYXRoLnNwbGl0KCcvJyksIGZ1bmN0aW9uKHApIHtcbiAgICByZXR1cm4gISFwO1xuICB9KSwgIXJlc29sdmVkQWJzb2x1dGUpLmpvaW4oJy8nKTtcblxuICByZXR1cm4gKChyZXNvbHZlZEFic29sdXRlID8gJy8nIDogJycpICsgcmVzb2x2ZWRQYXRoKSB8fCAnLic7XG59O1xuXG4vLyBwYXRoLm5vcm1hbGl6ZShwYXRoKVxuLy8gcG9zaXggdmVyc2lvblxuZXhwb3J0cy5ub3JtYWxpemUgPSBmdW5jdGlvbihwYXRoKSB7XG4gIHZhciBpc0Fic29sdXRlID0gZXhwb3J0cy5pc0Fic29sdXRlKHBhdGgpLFxuICAgICAgdHJhaWxpbmdTbGFzaCA9IHN1YnN0cihwYXRoLCAtMSkgPT09ICcvJztcblxuICAvLyBOb3JtYWxpemUgdGhlIHBhdGhcbiAgcGF0aCA9IG5vcm1hbGl6ZUFycmF5KGZpbHRlcihwYXRoLnNwbGl0KCcvJyksIGZ1bmN0aW9uKHApIHtcbiAgICByZXR1cm4gISFwO1xuICB9KSwgIWlzQWJzb2x1dGUpLmpvaW4oJy8nKTtcblxuICBpZiAoIXBhdGggJiYgIWlzQWJzb2x1dGUpIHtcbiAgICBwYXRoID0gJy4nO1xuICB9XG4gIGlmIChwYXRoICYmIHRyYWlsaW5nU2xhc2gpIHtcbiAgICBwYXRoICs9ICcvJztcbiAgfVxuXG4gIHJldHVybiAoaXNBYnNvbHV0ZSA/ICcvJyA6ICcnKSArIHBhdGg7XG59O1xuXG4vLyBwb3NpeCB2ZXJzaW9uXG5leHBvcnRzLmlzQWJzb2x1dGUgPSBmdW5jdGlvbihwYXRoKSB7XG4gIHJldHVybiBwYXRoLmNoYXJBdCgwKSA9PT0gJy8nO1xufTtcblxuLy8gcG9zaXggdmVyc2lvblxuZXhwb3J0cy5qb2luID0gZnVuY3Rpb24oKSB7XG4gIHZhciBwYXRocyA9IEFycmF5LnByb3RvdHlwZS5zbGljZS5jYWxsKGFyZ3VtZW50cywgMCk7XG4gIHJldHVybiBleHBvcnRzLm5vcm1hbGl6ZShmaWx0ZXIocGF0aHMsIGZ1bmN0aW9uKHAsIGluZGV4KSB7XG4gICAgaWYgKHR5cGVvZiBwICE9PSAnc3RyaW5nJykge1xuICAgICAgdGhyb3cgbmV3IFR5cGVFcnJvcignQXJndW1lbnRzIHRvIHBhdGguam9pbiBtdXN0IGJlIHN0cmluZ3MnKTtcbiAgICB9XG4gICAgcmV0dXJuIHA7XG4gIH0pLmpvaW4oJy8nKSk7XG59O1xuXG5cbi8vIHBhdGgucmVsYXRpdmUoZnJvbSwgdG8pXG4vLyBwb3NpeCB2ZXJzaW9uXG5leHBvcnRzLnJlbGF0aXZlID0gZnVuY3Rpb24oZnJvbSwgdG8pIHtcbiAgZnJvbSA9IGV4cG9ydHMucmVzb2x2ZShmcm9tKS5zdWJzdHIoMSk7XG4gIHRvID0gZXhwb3J0cy5yZXNvbHZlKHRvKS5zdWJzdHIoMSk7XG5cbiAgZnVuY3Rpb24gdHJpbShhcnIpIHtcbiAgICB2YXIgc3RhcnQgPSAwO1xuICAgIGZvciAoOyBzdGFydCA8IGFyci5sZW5ndGg7IHN0YXJ0KyspIHtcbiAgICAgIGlmIChhcnJbc3RhcnRdICE9PSAnJykgYnJlYWs7XG4gICAgfVxuXG4gICAgdmFyIGVuZCA9IGFyci5sZW5ndGggLSAxO1xuICAgIGZvciAoOyBlbmQgPj0gMDsgZW5kLS0pIHtcbiAgICAgIGlmIChhcnJbZW5kXSAhPT0gJycpIGJyZWFrO1xuICAgIH1cblxuICAgIGlmIChzdGFydCA+IGVuZCkgcmV0dXJuIFtdO1xuICAgIHJldHVybiBhcnIuc2xpY2Uoc3RhcnQsIGVuZCAtIHN0YXJ0ICsgMSk7XG4gIH1cblxuICB2YXIgZnJvbVBhcnRzID0gdHJpbShmcm9tLnNwbGl0KCcvJykpO1xuICB2YXIgdG9QYXJ0cyA9IHRyaW0odG8uc3BsaXQoJy8nKSk7XG5cbiAgdmFyIGxlbmd0aCA9IE1hdGgubWluKGZyb21QYXJ0cy5sZW5ndGgsIHRvUGFydHMubGVuZ3RoKTtcbiAgdmFyIHNhbWVQYXJ0c0xlbmd0aCA9IGxlbmd0aDtcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBsZW5ndGg7IGkrKykge1xuICAgIGlmIChmcm9tUGFydHNbaV0gIT09IHRvUGFydHNbaV0pIHtcbiAgICAgIHNhbWVQYXJ0c0xlbmd0aCA9IGk7XG4gICAgICBicmVhaztcbiAgICB9XG4gIH1cblxuICB2YXIgb3V0cHV0UGFydHMgPSBbXTtcbiAgZm9yICh2YXIgaSA9IHNhbWVQYXJ0c0xlbmd0aDsgaSA8IGZyb21QYXJ0cy5sZW5ndGg7IGkrKykge1xuICAgIG91dHB1dFBhcnRzLnB1c2goJy4uJyk7XG4gIH1cblxuICBvdXRwdXRQYXJ0cyA9IG91dHB1dFBhcnRzLmNvbmNhdCh0b1BhcnRzLnNsaWNlKHNhbWVQYXJ0c0xlbmd0aCkpO1xuXG4gIHJldHVybiBvdXRwdXRQYXJ0cy5qb2luKCcvJyk7XG59O1xuXG5leHBvcnRzLnNlcCA9ICcvJztcbmV4cG9ydHMuZGVsaW1pdGVyID0gJzonO1xuXG5leHBvcnRzLmRpcm5hbWUgPSBmdW5jdGlvbihwYXRoKSB7XG4gIHZhciByZXN1bHQgPSBzcGxpdFBhdGgocGF0aCksXG4gICAgICByb290ID0gcmVzdWx0WzBdLFxuICAgICAgZGlyID0gcmVzdWx0WzFdO1xuXG4gIGlmICghcm9vdCAmJiAhZGlyKSB7XG4gICAgLy8gTm8gZGlybmFtZSB3aGF0c29ldmVyXG4gICAgcmV0dXJuICcuJztcbiAgfVxuXG4gIGlmIChkaXIpIHtcbiAgICAvLyBJdCBoYXMgYSBkaXJuYW1lLCBzdHJpcCB0cmFpbGluZyBzbGFzaFxuICAgIGRpciA9IGRpci5zdWJzdHIoMCwgZGlyLmxlbmd0aCAtIDEpO1xuICB9XG5cbiAgcmV0dXJuIHJvb3QgKyBkaXI7XG59O1xuXG5cbmV4cG9ydHMuYmFzZW5hbWUgPSBmdW5jdGlvbihwYXRoLCBleHQpIHtcbiAgdmFyIGYgPSBzcGxpdFBhdGgocGF0aClbMl07XG4gIC8vIFRPRE86IG1ha2UgdGhpcyBjb21wYXJpc29uIGNhc2UtaW5zZW5zaXRpdmUgb24gd2luZG93cz9cbiAgaWYgKGV4dCAmJiBmLnN1YnN0cigtMSAqIGV4dC5sZW5ndGgpID09PSBleHQpIHtcbiAgICBmID0gZi5zdWJzdHIoMCwgZi5sZW5ndGggLSBleHQubGVuZ3RoKTtcbiAgfVxuICByZXR1cm4gZjtcbn07XG5cblxuZXhwb3J0cy5leHRuYW1lID0gZnVuY3Rpb24ocGF0aCkge1xuICByZXR1cm4gc3BsaXRQYXRoKHBhdGgpWzNdO1xufTtcblxuZnVuY3Rpb24gZmlsdGVyICh4cywgZikge1xuICAgIGlmICh4cy5maWx0ZXIpIHJldHVybiB4cy5maWx0ZXIoZik7XG4gICAgdmFyIHJlcyA9IFtdO1xuICAgIGZvciAodmFyIGkgPSAwOyBpIDwgeHMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgaWYgKGYoeHNbaV0sIGksIHhzKSkgcmVzLnB1c2goeHNbaV0pO1xuICAgIH1cbiAgICByZXR1cm4gcmVzO1xufVxuXG4vLyBTdHJpbmcucHJvdG90eXBlLnN1YnN0ciAtIG5lZ2F0aXZlIGluZGV4IGRvbid0IHdvcmsgaW4gSUU4XG52YXIgc3Vic3RyID0gJ2FiJy5zdWJzdHIoLTEpID09PSAnYidcbiAgICA/IGZ1bmN0aW9uIChzdHIsIHN0YXJ0LCBsZW4pIHsgcmV0dXJuIHN0ci5zdWJzdHIoc3RhcnQsIGxlbikgfVxuICAgIDogZnVuY3Rpb24gKHN0ciwgc3RhcnQsIGxlbikge1xuICAgICAgICBpZiAoc3RhcnQgPCAwKSBzdGFydCA9IHN0ci5sZW5ndGggKyBzdGFydDtcbiAgICAgICAgcmV0dXJuIHN0ci5zdWJzdHIoc3RhcnQsIGxlbik7XG4gICAgfVxuO1xuXG59KS5jYWxsKHRoaXMscmVxdWlyZSgnX3Byb2Nlc3MnKSkiLCIvLyBzaGltIGZvciB1c2luZyBwcm9jZXNzIGluIGJyb3dzZXJcblxudmFyIHByb2Nlc3MgPSBtb2R1bGUuZXhwb3J0cyA9IHt9O1xuXG5wcm9jZXNzLm5leHRUaWNrID0gKGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgY2FuU2V0SW1tZWRpYXRlID0gdHlwZW9mIHdpbmRvdyAhPT0gJ3VuZGVmaW5lZCdcbiAgICAmJiB3aW5kb3cuc2V0SW1tZWRpYXRlO1xuICAgIHZhciBjYW5NdXRhdGlvbk9ic2VydmVyID0gdHlwZW9mIHdpbmRvdyAhPT0gJ3VuZGVmaW5lZCdcbiAgICAmJiB3aW5kb3cuTXV0YXRpb25PYnNlcnZlcjtcbiAgICB2YXIgY2FuUG9zdCA9IHR5cGVvZiB3aW5kb3cgIT09ICd1bmRlZmluZWQnXG4gICAgJiYgd2luZG93LnBvc3RNZXNzYWdlICYmIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyXG4gICAgO1xuXG4gICAgaWYgKGNhblNldEltbWVkaWF0ZSkge1xuICAgICAgICByZXR1cm4gZnVuY3Rpb24gKGYpIHsgcmV0dXJuIHdpbmRvdy5zZXRJbW1lZGlhdGUoZikgfTtcbiAgICB9XG5cbiAgICB2YXIgcXVldWUgPSBbXTtcblxuICAgIGlmIChjYW5NdXRhdGlvbk9ic2VydmVyKSB7XG4gICAgICAgIHZhciBoaWRkZW5EaXYgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KFwiZGl2XCIpO1xuICAgICAgICB2YXIgb2JzZXJ2ZXIgPSBuZXcgTXV0YXRpb25PYnNlcnZlcihmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICB2YXIgcXVldWVMaXN0ID0gcXVldWUuc2xpY2UoKTtcbiAgICAgICAgICAgIHF1ZXVlLmxlbmd0aCA9IDA7XG4gICAgICAgICAgICBxdWV1ZUxpc3QuZm9yRWFjaChmdW5jdGlvbiAoZm4pIHtcbiAgICAgICAgICAgICAgICBmbigpO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH0pO1xuXG4gICAgICAgIG9ic2VydmVyLm9ic2VydmUoaGlkZGVuRGl2LCB7IGF0dHJpYnV0ZXM6IHRydWUgfSk7XG5cbiAgICAgICAgcmV0dXJuIGZ1bmN0aW9uIG5leHRUaWNrKGZuKSB7XG4gICAgICAgICAgICBpZiAoIXF1ZXVlLmxlbmd0aCkge1xuICAgICAgICAgICAgICAgIGhpZGRlbkRpdi5zZXRBdHRyaWJ1dGUoJ3llcycsICdubycpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcXVldWUucHVzaChmbik7XG4gICAgICAgIH07XG4gICAgfVxuXG4gICAgaWYgKGNhblBvc3QpIHtcbiAgICAgICAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoJ21lc3NhZ2UnLCBmdW5jdGlvbiAoZXYpIHtcbiAgICAgICAgICAgIHZhciBzb3VyY2UgPSBldi5zb3VyY2U7XG4gICAgICAgICAgICBpZiAoKHNvdXJjZSA9PT0gd2luZG93IHx8IHNvdXJjZSA9PT0gbnVsbCkgJiYgZXYuZGF0YSA9PT0gJ3Byb2Nlc3MtdGljaycpIHtcbiAgICAgICAgICAgICAgICBldi5zdG9wUHJvcGFnYXRpb24oKTtcbiAgICAgICAgICAgICAgICBpZiAocXVldWUubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgICAgICAgICB2YXIgZm4gPSBxdWV1ZS5zaGlmdCgpO1xuICAgICAgICAgICAgICAgICAgICBmbigpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgfSwgdHJ1ZSk7XG5cbiAgICAgICAgcmV0dXJuIGZ1bmN0aW9uIG5leHRUaWNrKGZuKSB7XG4gICAgICAgICAgICBxdWV1ZS5wdXNoKGZuKTtcbiAgICAgICAgICAgIHdpbmRvdy5wb3N0TWVzc2FnZSgncHJvY2Vzcy10aWNrJywgJyonKTtcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICByZXR1cm4gZnVuY3Rpb24gbmV4dFRpY2soZm4pIHtcbiAgICAgICAgc2V0VGltZW91dChmbiwgMCk7XG4gICAgfTtcbn0pKCk7XG5cbnByb2Nlc3MudGl0bGUgPSAnYnJvd3Nlcic7XG5wcm9jZXNzLmJyb3dzZXIgPSB0cnVlO1xucHJvY2Vzcy5lbnYgPSB7fTtcbnByb2Nlc3MuYXJndiA9IFtdO1xuXG5mdW5jdGlvbiBub29wKCkge31cblxucHJvY2Vzcy5vbiA9IG5vb3A7XG5wcm9jZXNzLmFkZExpc3RlbmVyID0gbm9vcDtcbnByb2Nlc3Mub25jZSA9IG5vb3A7XG5wcm9jZXNzLm9mZiA9IG5vb3A7XG5wcm9jZXNzLnJlbW92ZUxpc3RlbmVyID0gbm9vcDtcbnByb2Nlc3MucmVtb3ZlQWxsTGlzdGVuZXJzID0gbm9vcDtcbnByb2Nlc3MuZW1pdCA9IG5vb3A7XG5cbnByb2Nlc3MuYmluZGluZyA9IGZ1bmN0aW9uIChuYW1lKSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKCdwcm9jZXNzLmJpbmRpbmcgaXMgbm90IHN1cHBvcnRlZCcpO1xufTtcblxuLy8gVE9ETyhzaHR5bG1hbilcbnByb2Nlc3MuY3dkID0gZnVuY3Rpb24gKCkgeyByZXR1cm4gJy8nIH07XG5wcm9jZXNzLmNoZGlyID0gZnVuY3Rpb24gKGRpcikge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5jaGRpciBpcyBub3Qgc3VwcG9ydGVkJyk7XG59O1xuIl19
