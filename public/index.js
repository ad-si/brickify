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
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJidWlsZC9jbGllbnQvZ2xvYmFscy5qc29uIiwiYnVpbGQvY2xpZW50L21haW4uanMiLCJidWlsZC9jbGllbnQvcG9seWdvbl9wb3N0cHJvY2Vzc2luZy5qcyIsImJ1aWxkL2NsaWVudC9yZW5kZXIuanMiLCJidWlsZC9jbGllbnQvdWkuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvcGF0aC1icm93c2VyaWZ5L2luZGV4LmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL3Byb2Nlc3MvYnJvd3Nlci5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFBQTtBQ0FBOztBQ0FBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzlCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzlVQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUMzQkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDeEtBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDbE9BO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQSIsImZpbGUiOiJnZW5lcmF0ZWQuanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlc0NvbnRlbnQiOlsiKGZ1bmN0aW9uIGUodCxuLHIpe2Z1bmN0aW9uIHMobyx1KXtpZighbltvXSl7aWYoIXRbb10pe3ZhciBhPXR5cGVvZiByZXF1aXJlPT1cImZ1bmN0aW9uXCImJnJlcXVpcmU7aWYoIXUmJmEpcmV0dXJuIGEobywhMCk7aWYoaSlyZXR1cm4gaShvLCEwKTt2YXIgZj1uZXcgRXJyb3IoXCJDYW5ub3QgZmluZCBtb2R1bGUgJ1wiK28rXCInXCIpO3Rocm93IGYuY29kZT1cIk1PRFVMRV9OT1RfRk9VTkRcIixmfXZhciBsPW5bb109e2V4cG9ydHM6e319O3Rbb11bMF0uY2FsbChsLmV4cG9ydHMsZnVuY3Rpb24oZSl7dmFyIG49dFtvXVsxXVtlXTtyZXR1cm4gcyhuP246ZSl9LGwsbC5leHBvcnRzLGUsdCxuLHIpfXJldHVybiBuW29dLmV4cG9ydHN9dmFyIGk9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtmb3IodmFyIG89MDtvPHIubGVuZ3RoO28rKylzKHJbb10pO3JldHVybiBzfSkiLCJtb2R1bGUuZXhwb3J0cz17XCJtbVwiOjEsXCJmb3ZcIjo0MCxcImNhbWVyYU5lYXJQbGFuZVwiOjAuMSxcImNhbWVyYUZhclBsYW5lXCI6MTAwMCxcImFuaW1hdGlvblN0ZXBTaXplXCI6MC4wMixcImFuaW1hdGlvbnNcIjpbXSxcImF4aXNMZW5ndGhcIjoxMDAsXCJheGlzWENvbG9yXCI6MTY3MTE2ODAsXCJheGlzWUNvbG9yXCI6NjUyODAsXCJheGlzWkNvbG9yXCI6MjU1LFwiYXhpc0xpbmVXaWR0aFwiOjIsXCJkZWZhdWx0T2JqZWN0Q29sb3JcIjoxMzQxMjkxNSxcIm1lc2hlc1wiOltdLFwiZ3JpZENvbG9yTm9ybWFsXCI6MTM0MjE3NzIsXCJncmlkQ29sb3I1XCI6MTAwNjYzMjksXCJncmlkQ29sb3IxMFwiOjY3MTA4ODYsXCJncmlkTGluZVdpZHRoTm9ybWFsXCI6MSxcImdyaWRMaW5lV2lkdGg1XCI6MSxcImdyaWRMaW5lV2lkdGgxMFwiOjEsXCJncmlkU2l6ZVwiOjIwMCxcImdyaWRTdGVwU2l6ZVwiOjEwfSIsIihmdW5jdGlvbigpIHtcbiAgdmFyIGdsb2JhbENvbmZpZywgcGF0aCwgcmVuZGVyZXIsIHVpO1xuXG4gIGdsb2JhbENvbmZpZyA9IHJlcXVpcmUoJy4vZ2xvYmFscy5qc29uJyk7XG5cbiAgcGF0aCA9IHJlcXVpcmUoJ3BhdGgnKTtcblxuXG4gIC8qIFRPRE86IG1vdmUgc29tZXdoZXJlIHdoZXJlIGl0IGlzIG5lZWRlZFxuICAgKiBnZW9tZXRyeSBmdW5jdGlvbnNcbiAgZGVnVG9SYWQgPSAoIGRlZyApIC0+IGRlZyAqICggTWF0aC5QSSAvIDE4MC4wIClcbiAgcmFkVG9EZWcgPSAoIHJhZCApIC0+IGRlZyAqICggMTgwLjAgLyBNYXRoLlBJIClcbiAgXG4gIG5vcm1hbEZvcm1Ub1BhcmFtdGVyRm9ybSA9ICggbiwgcCwgdSwgdikgLT5cbiAgXHR1LnNldCggMCwgLW4ueiwgbi55ICkubm9ybWFsaXplKClcbiAgXHR2LnNldCggbi55LCAtbi54LCAwICkubm9ybWFsaXplKClcbiAgXG4gICAqIHV0aWxpdHlcbiAgU3RyaW5nOjpjb250YWlucyA9IChzdHIpIC0+IC0xIGlzbnQgdGhpcy5pbmRleE9mIHN0clxuICAgKi9cblxuICB1aSA9IHJlcXVpcmUoXCIuL3VpXCIpKGdsb2JhbENvbmZpZyk7XG5cbiAgdWkuaW5pdCgpO1xuXG4gIHJlbmRlcmVyID0gcmVxdWlyZShcIi4vcmVuZGVyXCIpO1xuXG4gIHJlbmRlcmVyKHVpKTtcblxufSkuY2FsbCh0aGlzKTtcbiIsIihmdW5jdGlvbigpIHtcbiAgdmFyIGFyZVBvaW50UGFpcnNFcXVhbCwgYXJlUG9pbnRzT25TYW1lTGluZVNlZ21lbnQsIGV4cG9ydHMsIGlzQ2xvY2tXaXNlLCBpc0luUmFuZ2UsIG1lcmdlVW5tZXJnZWRQb2x5Z29ucywgcG9pbnRzT25PbmVMaW5lLCBwb2x5Z29uQXJlYU92ZXJUaHJlc2hob2xkLCByZW1vdmVDb2xsaW5lYXJQb2ludHMsIHJlbW92ZUR1cGxpY2F0ZXMsXG4gICAgX19pbmRleE9mID0gW10uaW5kZXhPZiB8fCBmdW5jdGlvbihpdGVtKSB7IGZvciAodmFyIGkgPSAwLCBsID0gdGhpcy5sZW5ndGg7IGkgPCBsOyBpKyspIHsgaWYgKGkgaW4gdGhpcyAmJiB0aGlzW2ldID09PSBpdGVtKSByZXR1cm4gaTsgfSByZXR1cm4gLTE7IH07XG5cbiAgbWVyZ2VVbm1lcmdlZFBvbHlnb25zID0gZnVuY3Rpb24obGlzdE9mUG9seSkge1xuICAgIHZhciBjLCBpLCBpZHgsIGl0ZW0sIGssIGtleSwga2V5cywgbWVyZ2UsIG1lcmdlX3BvbHksIG1lcmdlX3ZlcnRleF9pZHgsIHAxLCBwMV9pZHgsIHAyLCBwMl9pZHgsIHAzLCBwNCwgcF9maXJzdCwgcG9pbnRzX21lcmdlZCwgcG9seSwgcG9seV9pbmRleF9pbm5lciwgcG9seV9pbmRleF9pbm5lcjIsIHBvbHlfaW5kZXhfb3V0ZXIsIHBvbHlfaW5kZXhfb3V0ZXIyLCBwb2x5X2lubmVyLCBwb2x5X291dGVyLCBwb2x5X3JhbmdlLCBwb2x5Z29uc19pbmRleF9pbm5lciwgcG9seWdvbnNfaW5kZXhfb3V0ZXIsIHBvbHlnb25zX3RvX21lcmdlLCB0YXJnZXQsIHRhcmdldF9pZHgsIHRhcmdldF9rZXksIHRhcmdldF9wMSwgdGhyb3dfYXdheV9wb2x5Z29ucywgdHVwbGVzLCB2YWx1ZSwgX2ksIF9qLCBfaywgX2wsIF9sZW4sIF9sZW4xLCBfbSwgX24sIF9vLCBfcCwgX3EsIF9yZWYsIF9yZWYxLCBfcmVmMiwgX3JlZjMsIF9yZWY0LCBfcmVmNSwgX3JlZjYsIF9yZWY3LCBfcmVmOCwgX3Jlc3VsdHMsIF9yZXN1bHRzMTtcbiAgICBsaXN0T2ZQb2x5LnNvcnQoZnVuY3Rpb24oYSwgYikge1xuICAgICAgaWYgKGEubGVuZ3RoIDwgYi5sZW5ndGgpIHtcbiAgICAgICAgcmV0dXJuIDE7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICByZXR1cm4gLTE7XG4gICAgICB9XG4gICAgfSk7XG4gICAgcG9seWdvbnNfdG9fbWVyZ2UgPSB7fTtcbiAgICB0aHJvd19hd2F5X3BvbHlnb25zID0gW107XG4gICAgZm9yIChwb2x5Z29uc19pbmRleF9vdXRlciA9IF9pID0gMCwgX3JlZiA9IGxpc3RPZlBvbHkubGVuZ3RoOyAwIDw9IF9yZWYgPyBfaSA8IF9yZWYgOiBfaSA+IF9yZWY7IHBvbHlnb25zX2luZGV4X291dGVyID0gMCA8PSBfcmVmID8gKytfaSA6IC0tX2kpIHtcbiAgICAgIGlmIChfX2luZGV4T2YuY2FsbCh0aHJvd19hd2F5X3BvbHlnb25zLCBwb2x5Z29uc19pbmRleF9vdXRlcikgPj0gMCkge1xuICAgICAgICBjb250aW51ZTtcbiAgICAgIH1cbiAgICAgIHBvbHlfb3V0ZXIgPSBsaXN0T2ZQb2x5W3BvbHlnb25zX2luZGV4X291dGVyXTtcbiAgICAgIHBvbHlfaW5kZXhfb3V0ZXIgPSAwO1xuICAgICAgcG9pbnRzX21lcmdlZCA9IDA7XG4gICAgICBmb3IgKHBvbHlfaW5kZXhfb3V0ZXIgPSBfaiA9IDAsIF9yZWYxID0gcG9seV9vdXRlci5sZW5ndGg7IDAgPD0gX3JlZjEgPyBfaiA8IF9yZWYxIDogX2ogPiBfcmVmMTsgcG9seV9pbmRleF9vdXRlciA9IDAgPD0gX3JlZjEgPyArK19qIDogLS1faikge1xuICAgICAgICBwMSA9IHBvbHlfb3V0ZXJbcG9seV9pbmRleF9vdXRlcl07XG4gICAgICAgIHBvbHlfaW5kZXhfb3V0ZXIyID0gcG9seV9pbmRleF9vdXRlciA9PT0gKHBvbHlfb3V0ZXIubGVuZ3RoIC0gMSkgPyAwIDogcG9seV9pbmRleF9vdXRlciArIDE7XG4gICAgICAgIHAyID0gcG9seV9vdXRlcltwb2x5X2luZGV4X291dGVyMl07XG4gICAgICAgIHBvbHlnb25zX2luZGV4X2lubmVyID0gMDtcbiAgICAgICAgZm9yIChwb2x5Z29uc19pbmRleF9pbm5lciA9IF9rID0gX3JlZjIgPSBwb2x5Z29uc19pbmRleF9vdXRlciArIDEsIF9yZWYzID0gbGlzdE9mUG9seS5sZW5ndGg7IF9yZWYyIDw9IF9yZWYzID8gX2sgPCBfcmVmMyA6IF9rID4gX3JlZjM7IHBvbHlnb25zX2luZGV4X2lubmVyID0gX3JlZjIgPD0gX3JlZjMgPyArK19rIDogLS1faykge1xuICAgICAgICAgIGlmIChfX2luZGV4T2YuY2FsbCh0aHJvd19hd2F5X3BvbHlnb25zLCBwb2x5Z29uc19pbmRleF9pbm5lcikgPj0gMCkge1xuICAgICAgICAgICAgY29udGludWU7XG4gICAgICAgICAgfVxuICAgICAgICAgIHBvbHlfaW5uZXIgPSBsaXN0T2ZQb2x5W3BvbHlnb25zX2luZGV4X2lubmVyXTtcbiAgICAgICAgICBwb2x5X2luZGV4X2lubmVyID0gMDtcbiAgICAgICAgICBmb3IgKHBvbHlfaW5kZXhfaW5uZXIgPSBfbCA9IDAsIF9yZWY0ID0gcG9seV9pbm5lci5sZW5ndGg7IDAgPD0gX3JlZjQgPyBfbCA8IF9yZWY0IDogX2wgPiBfcmVmNDsgcG9seV9pbmRleF9pbm5lciA9IDAgPD0gX3JlZjQgPyArK19sIDogLS1fbCkge1xuICAgICAgICAgICAgcDMgPSBwb2x5X2lubmVyW3BvbHlfaW5kZXhfaW5uZXJdO1xuICAgICAgICAgICAgcG9seV9pbmRleF9pbm5lcjIgPSBwb2x5X2luZGV4X2lubmVyID09PSAocG9seV9pbm5lci5sZW5ndGggLSAxKSA/IDAgOiBwb2x5X2luZGV4X2lubmVyICsgMTtcbiAgICAgICAgICAgIHA0ID0gcG9seV9pbm5lcltwb2x5X2luZGV4X2lubmVyMl07XG4gICAgICAgICAgICBpZiAoYXJlUG9pbnRzT25TYW1lTGluZVNlZ21lbnQocDMsIHA0LCBwMSwgcDIpKSB7XG4gICAgICAgICAgICAgIGlmIChwMy5kaXN0YW5jZVRvKHAxKSA8IHA0LmRpc3RhbmNlVG8ocDEpKSB7XG4gICAgICAgICAgICAgICAgcF9maXJzdCA9IHBvbHlfaW5kZXhfaW5uZXI7XG4gICAgICAgICAgICAgICAgcG9seV9yYW5nZSA9IChmdW5jdGlvbigpIHtcbiAgICAgICAgICAgICAgICAgIF9yZXN1bHRzID0gW107XG4gICAgICAgICAgICAgICAgICBmb3IgKHZhciBfbSA9IDAsIF9yZWY1ID0gcG9seV9pbm5lci5sZW5ndGg7IDAgPD0gX3JlZjUgPyBfbSA8IF9yZWY1IDogX20gPiBfcmVmNTsgMCA8PSBfcmVmNSA/IF9tKysgOiBfbS0tKXsgX3Jlc3VsdHMucHVzaChfbSk7IH1cbiAgICAgICAgICAgICAgICAgIHJldHVybiBfcmVzdWx0cztcbiAgICAgICAgICAgICAgICB9KS5hcHBseSh0aGlzKTtcbiAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICBwX2ZpcnN0ID0gcG9seV9pbmRleF9pbm5lcjI7XG4gICAgICAgICAgICAgICAgcG9seV9yYW5nZSA9IChmdW5jdGlvbigpIHtcbiAgICAgICAgICAgICAgICAgIF9yZXN1bHRzMSA9IFtdO1xuICAgICAgICAgICAgICAgICAgZm9yICh2YXIgX24gPSAwLCBfcmVmNiA9IHBvbHlfaW5uZXIubGVuZ3RoOyAwIDw9IF9yZWY2ID8gX24gPCBfcmVmNiA6IF9uID4gX3JlZjY7IDAgPD0gX3JlZjYgPyBfbisrIDogX24tLSl7IF9yZXN1bHRzMS5wdXNoKF9uKTsgfVxuICAgICAgICAgICAgICAgICAgcmV0dXJuIF9yZXN1bHRzMTtcbiAgICAgICAgICAgICAgICB9KS5hcHBseSh0aGlzKS5yZXZlcnNlKCk7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgdGhyb3dfYXdheV9wb2x5Z29ucy5wdXNoKHBvbHlnb25zX2luZGV4X2lubmVyKTtcbiAgICAgICAgICAgICAga2V5ID0gXCJcIiArIHBvbHlnb25zX2luZGV4X291dGVyICsgXCIsXCIgKyBwb2x5X2luZGV4X291dGVyICsgXCIsXCIgKyBwb2x5X2luZGV4X291dGVyMjtcbiAgICAgICAgICAgICAgaWYgKCFwb2x5Z29uc190b19tZXJnZVtrZXldICE9PSBcInVuZGVmaW5lZFwiKSB7XG4gICAgICAgICAgICAgICAgcG9seWdvbnNfdG9fbWVyZ2Vba2V5XSA9IHt9O1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgIHBvbHlnb25zX3RvX21lcmdlW2tleV1bcG9seWdvbnNfaW5kZXhfaW5uZXJdID0gKGZ1bmN0aW9uKCkge1xuICAgICAgICAgICAgICAgIHZhciBfbGVuLCBfbywgX3Jlc3VsdHMyO1xuICAgICAgICAgICAgICAgIF9yZXN1bHRzMiA9IFtdO1xuICAgICAgICAgICAgICAgIGZvciAoX28gPSAwLCBfbGVuID0gcG9seV9yYW5nZS5sZW5ndGg7IF9vIDwgX2xlbjsgX28rKykge1xuICAgICAgICAgICAgICAgICAgYyA9IHBvbHlfcmFuZ2VbX29dO1xuICAgICAgICAgICAgICAgICAgX3Jlc3VsdHMyLnB1c2goYyArIHBfZmlyc3QgPCBwb2x5X2lubmVyLmxlbmd0aCA/IGMgKyBwX2ZpcnN0IDogYyArIHBfZmlyc3QgLSBwb2x5X2lubmVyLmxlbmd0aCk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIHJldHVybiBfcmVzdWx0czI7XG4gICAgICAgICAgICAgIH0pKCk7XG4gICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgICBjb25zb2xlLmxvZyhwb2x5Z29uc190b19tZXJnZSk7XG4gICAgY29uc29sZS5sb2codGhyb3dfYXdheV9wb2x5Z29ucyk7XG4gICAgdHVwbGVzID0gKGZ1bmN0aW9uKCkge1xuICAgICAgdmFyIF9yZXN1bHRzMjtcbiAgICAgIF9yZXN1bHRzMiA9IFtdO1xuICAgICAgZm9yIChrZXkgaW4gcG9seWdvbnNfdG9fbWVyZ2UpIHtcbiAgICAgICAgcG9seSA9IHBvbHlnb25zX3RvX21lcmdlW2tleV07XG4gICAgICAgIF9yZXN1bHRzMi5wdXNoKFtrZXksIHBvbHldKTtcbiAgICAgIH1cbiAgICAgIHJldHVybiBfcmVzdWx0czI7XG4gICAgfSkoKTtcbiAgICB0dXBsZXMuc29ydChmdW5jdGlvbihhLCBiKSB7XG4gICAgICB2YXIgYWtleXMsIGFwMl9pZHgsIGJrZXlzLCBicDJfaWR4O1xuICAgICAgYWtleXMgPSBhWzBdLnNwbGl0KCcsJyk7XG4gICAgICBhcDJfaWR4ID0gcGFyc2VJbnQoYWtleXNbMl0pO1xuICAgICAgYmtleXMgPSBiWzBdLnNwbGl0KCcsJyk7XG4gICAgICBicDJfaWR4ID0gcGFyc2VJbnQoYmtleXNbMl0pO1xuICAgICAgaWYgKGFwMl9pZHggPCBicDJfaWR4KSB7XG4gICAgICAgIHJldHVybiAxO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgcmV0dXJuIC0xO1xuICAgICAgfVxuICAgIH0pO1xuICAgIHBvbHlnb25zX3RvX21lcmdlID0ge307XG4gICAgZm9yIChpID0gX28gPSAwLCBfcmVmNyA9IHR1cGxlcy5sZW5ndGg7IDAgPD0gX3JlZjcgPyBfbyA8IF9yZWY3IDogX28gPiBfcmVmNzsgaSA9IDAgPD0gX3JlZjcgPyArK19vIDogLS1fbykge1xuICAgICAga2V5ID0gdHVwbGVzW2ldWzBdO1xuICAgICAgdmFsdWUgPSB0dXBsZXNbaV1bMV07XG4gICAgICBwb2x5Z29uc190b19tZXJnZVtrZXldID0gdmFsdWU7XG4gICAgfVxuICAgIGZvciAoa2V5IGluIHBvbHlnb25zX3RvX21lcmdlKSB7XG4gICAgICBtZXJnZSA9IHBvbHlnb25zX3RvX21lcmdlW2tleV07XG4gICAgICBrZXlzID0ga2V5LnNwbGl0KCcsJyk7XG4gICAgICB0YXJnZXRfaWR4ID0gcGFyc2VJbnQoa2V5c1swXSk7XG4gICAgICBwMV9pZHggPSBwYXJzZUludChrZXlzWzFdKTtcbiAgICAgIHAyX2lkeCA9IHBhcnNlSW50KGtleXNbMl0pO1xuICAgICAgdGFyZ2V0ID0gbGlzdE9mUG9seVt0YXJnZXRfaWR4XTtcbiAgICAgIHRhcmdldF9wMSA9IHRhcmdldFtwMV9pZHhdO1xuICAgICAgdGFyZ2V0X2tleSA9IHAyX2lkeCArIGM7XG4gICAgICB0dXBsZXMgPSAoZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBfcmVzdWx0czI7XG4gICAgICAgIF9yZXN1bHRzMiA9IFtdO1xuICAgICAgICBmb3IgKGsgaW4gbWVyZ2UpIHtcbiAgICAgICAgICBwb2x5ID0gbWVyZ2Vba107XG4gICAgICAgICAgX3Jlc3VsdHMyLnB1c2goW2ssIHBvbHldKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gX3Jlc3VsdHMyO1xuICAgICAgfSkoKTtcbiAgICAgIHR1cGxlcy5zb3J0KGZ1bmN0aW9uKGEsIGIpIHtcbiAgICAgICAgdmFyIHJlc3VsdDtcbiAgICAgICAgcmVzdWx0ID0gbGlzdE9mUG9seVthWzBdXVthWzFdWzBdXS5kaXN0YW5jZVRvKHRhcmdldF9wMSkgPCBsaXN0T2ZQb2x5W2JbMF1dW2JbMV1bMF1dLmRpc3RhbmNlVG8odGFyZ2V0X3AxKTtcbiAgICAgICAgaWYgKHJlc3VsdCkge1xuICAgICAgICAgIHJldHVybiAxO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIHJldHVybiAtMTtcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgICBmb3IgKF9wID0gMCwgX2xlbiA9IHR1cGxlcy5sZW5ndGg7IF9wIDwgX2xlbjsgX3ArKykge1xuICAgICAgICBpdGVtID0gdHVwbGVzW19wXTtcbiAgICAgICAgbWVyZ2VfcG9seSA9IGxpc3RPZlBvbHlbaXRlbVswXV07XG4gICAgICAgIF9yZWY4ID0gaXRlbVsxXTtcbiAgICAgICAgZm9yIChfcSA9IDAsIF9sZW4xID0gX3JlZjgubGVuZ3RoOyBfcSA8IF9sZW4xOyBfcSsrKSB7XG4gICAgICAgICAgbWVyZ2VfdmVydGV4X2lkeCA9IF9yZWY4W19xXTtcbiAgICAgICAgICBsaXN0T2ZQb2x5W3RhcmdldF9pZHhdLnNwbGljZSh0YXJnZXRfa2V5LCAwLCBtZXJnZV9wb2x5W21lcmdlX3ZlcnRleF9pZHhdKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgICByZXR1cm4gbGlzdE9mUG9seSA9IChmdW5jdGlvbigpIHtcbiAgICAgIHZhciBfbGVuMiwgX3IsIF9yZXN1bHRzMjtcbiAgICAgIF9yZXN1bHRzMiA9IFtdO1xuICAgICAgZm9yIChpZHggPSBfciA9IDAsIF9sZW4yID0gbGlzdE9mUG9seS5sZW5ndGg7IF9yIDwgX2xlbjI7IGlkeCA9ICsrX3IpIHtcbiAgICAgICAgcG9seSA9IGxpc3RPZlBvbHlbaWR4XTtcbiAgICAgICAgaWYgKF9faW5kZXhPZi5jYWxsKHRocm93X2F3YXlfcG9seWdvbnMsIGlkeCkgPCAwICYmIHBvbHkubGVuZ3RoID4gMikge1xuICAgICAgICAgIF9yZXN1bHRzMi5wdXNoKHBvbHkpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgICByZXR1cm4gX3Jlc3VsdHMyO1xuICAgIH0pKCk7XG4gIH07XG5cbiAgYXJlUG9pbnRzT25TYW1lTGluZVNlZ21lbnQgPSBmdW5jdGlvbihwMSwgcDIsIHAzLCBwNCkge1xuICAgIHZhciB0MSwgdDIsIHQzLCB0NCwgdGhyZXNoaG9sZCwgdjtcbiAgICB2ID0gbmV3IFRIUkVFLlZlY3RvcjIocDQueCAtIHAzLngsIHA0LnkgLSBwMy55KTtcbiAgICB0aHJlc2hob2xkID0gTWF0aC5wb3coMTAsIC0xKTtcbiAgICBpZiAocDMueCAhPT0gcDQueCkge1xuICAgICAgdDEgPSAocDEueCAtIHAzLngpIC8gdi54O1xuICAgICAgaWYgKHQxID4gMS4wICsgdGhyZXNoaG9sZCB8fCB0MSA8IDAuMCAtIHRocmVzaGhvbGQgfHwgIWlzSW5SYW5nZShwMS55IC0gKHAzLnkgKyB0MSAqIHYueSksIHRocmVzaGhvbGQpKSB7XG4gICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgIH1cbiAgICAgIHQyID0gKHAyLnggLSBwMy54KSAvIHYueDtcbiAgICAgIGlmICh0MiA+IDEuMCArIHRocmVzaGhvbGQgfHwgdDIgPCAwLjAgLSB0aHJlc2hob2xkIHx8ICFpc0luUmFuZ2UocDIueSAtIChwMy55ICsgdDIgKiB2LnkpLCB0aHJlc2hob2xkKSkge1xuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9XG4gICAgfSBlbHNlIGlmIChwMy55ICE9PSBwNC55KSB7XG4gICAgICB0MyA9IChwMS55IC0gcDMueSkgLyB2Lnk7XG4gICAgICBpZiAodDMgPiAxLjAgKyB0aHJlc2hob2xkIHx8IHQzIDwgMC4wIC0gdGhyZXNoaG9sZCB8fCAhaXNJblJhbmdlKHAxLnggLSAocDMueCArIHQzICogdi54KSwgdGhyZXNoaG9sZCkpIHtcbiAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgfVxuICAgICAgdDQgPSAocDIueSAtIHAzLnkpIC8gdi55O1xuICAgICAgaWYgKHQ0ID4gMS4wICsgdGhyZXNoaG9sZCB8fCB0NCA8IDAuMCAtIHRocmVzaGhvbGQgfHwgIWlzSW5SYW5nZShwMi54IC0gKHAzLnggKyB0NCAqIHYueCksIHRocmVzaGhvbGQpKSB7XG4gICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgIH1cbiAgICB9IGVsc2Uge1xuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cbiAgICByZXR1cm4gdHJ1ZTtcbiAgfTtcblxuICBhcmVQb2ludFBhaXJzRXF1YWwgPSBmdW5jdGlvbihwMSwgcDIsIHAzLCBwNCkge1xuICAgIHZhciByZXN1bHQsIHRocmVzaGhvbGQ7XG4gICAgdGhyZXNoaG9sZCA9IE1hdGgucG93KDEwLCAtMyk7XG4gICAgcmVzdWx0ID0gdHJ1ZTtcbiAgICByZXN1bHQgJiYgKHJlc3VsdCA9IGlzSW5SYW5nZShwMS54IC0gcDMueCwgdGhyZXNoaG9sZCkgfHwgaXNJblJhbmdlKHAxLnggLSBwNC54LCB0aHJlc2hob2xkKSk7XG4gICAgcmVzdWx0ICYmIChyZXN1bHQgPSBpc0luUmFuZ2UocDIueCAtIHAzLngsIHRocmVzaGhvbGQpIHx8IGlzSW5SYW5nZShwMi54IC0gcDQueCwgdGhyZXNoaG9sZCkpO1xuICAgIHJlc3VsdCAmJiAocmVzdWx0ID0gaXNJblJhbmdlKHAxLnkgLSBwMy55LCB0aHJlc2hob2xkKSB8fCBpc0luUmFuZ2UocDEueSAtIHA0LnksIHRocmVzaGhvbGQpKTtcbiAgICByZXN1bHQgJiYgKHJlc3VsdCA9IGlzSW5SYW5nZShwMi55IC0gcDMueSwgdGhyZXNoaG9sZCkgfHwgaXNJblJhbmdlKHAyLnkgLSBwNC55LCB0aHJlc2hob2xkKSk7XG4gICAgcmV0dXJuIHJlc3VsdDtcbiAgfTtcblxuICByZW1vdmVDb2xsaW5lYXJQb2ludHMgPSBmdW5jdGlvbihsaXN0T2ZQb2x5KSB7XG4gICAgdmFyIGMsIGksIGkyLCBpMywgaWR4LCBuZXdfcG9seSwgcCwgcG9seSwgcG9seWdvbnNfbWVyZ2VkLCBzdWJfcG9seSwgdGhyb3dfYXdheV92ZXJ0aWNlcywgX2ksIF9sZW47XG4gICAgcG9seWdvbnNfbWVyZ2VkID0gW107XG4gICAgZm9yIChfaSA9IDAsIF9sZW4gPSBsaXN0T2ZQb2x5Lmxlbmd0aDsgX2kgPCBfbGVuOyBfaSsrKSB7XG4gICAgICBwb2x5ID0gbGlzdE9mUG9seVtfaV07XG4gICAgICB0aHJvd19hd2F5X3ZlcnRpY2VzID0gW107XG4gICAgICBpID0gMDtcbiAgICAgIHdoaWxlIChpIDwgcG9seS5sZW5ndGgpIHtcbiAgICAgICAgaWYgKGkgPT09IHBvbHkubGVuZ3RoIC0gMikge1xuICAgICAgICAgIGkyID0gaSArIDE7XG4gICAgICAgICAgaTMgPSAwO1xuICAgICAgICB9IGVsc2UgaWYgKGkgPT09IHBvbHkubGVuZ3RoIC0gMSkge1xuICAgICAgICAgIGkyID0gMDtcbiAgICAgICAgICBpMyA9IDE7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgaTIgPSBpICsgMTtcbiAgICAgICAgICBpMyA9IGkgKyAyO1xuICAgICAgICB9XG4gICAgICAgIHN1Yl9wb2x5ID0gW3BvbHlbaV0sIHBvbHlbaTJdLCBwb2x5W2kzXV07XG4gICAgICAgIGMgPSAwO1xuICAgICAgICB3aGlsZSAocG9pbnRzT25PbmVMaW5lKHN1Yl9wb2x5KSkge1xuICAgICAgICAgIHRocm93X2F3YXlfdmVydGljZXMucHVzaChpMik7XG4gICAgICAgICAgaTIgPSBpMiA9PT0gKHBvbHkubGVuZ3RoIC0gMSkgPyAwIDogaTIgKyAxO1xuICAgICAgICAgIHN1Yl9wb2x5LnB1c2gocG9seVtpMl0pO1xuICAgICAgICAgIGMgKz0gMTtcbiAgICAgICAgfVxuICAgICAgICBpZiAoYyAhPT0gMCkge1xuICAgICAgICAgIHRocm93X2F3YXlfdmVydGljZXMucG9wKCk7XG4gICAgICAgIH1cbiAgICAgICAgaSA9IGMgIT09IDAgPyBpICsgYyA6IGkgKyAxO1xuICAgICAgfVxuICAgICAgbmV3X3BvbHkgPSAoZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBfaiwgX2xlbjEsIF9yZXN1bHRzO1xuICAgICAgICBfcmVzdWx0cyA9IFtdO1xuICAgICAgICBmb3IgKGlkeCA9IF9qID0gMCwgX2xlbjEgPSBwb2x5Lmxlbmd0aDsgX2ogPCBfbGVuMTsgaWR4ID0gKytfaikge1xuICAgICAgICAgIHAgPSBwb2x5W2lkeF07XG4gICAgICAgICAgaWYgKF9faW5kZXhPZi5jYWxsKHRocm93X2F3YXlfdmVydGljZXMsIGlkeCkgPCAwKSB7XG4gICAgICAgICAgICBfcmVzdWx0cy5wdXNoKHApO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gX3Jlc3VsdHM7XG4gICAgICB9KSgpO1xuICAgICAgcG9seWdvbnNfbWVyZ2VkLnB1c2gobmV3X3BvbHkpO1xuICAgIH1cbiAgICByZXR1cm4gcG9seWdvbnNfbWVyZ2VkO1xuICB9O1xuXG4gIHBvbHlnb25BcmVhT3ZlclRocmVzaGhvbGQgPSBmdW5jdGlvbihwb2x5LCB0aHJlc2hob2xkKSB7XG4gICAgdmFyIGksIHN1bSwgeDEsIHgyLCB5MSwgeTIsIF9pLCBfcmVmO1xuICAgIHN1bSA9IDA7XG4gICAgZm9yIChpID0gX2kgPSAwLCBfcmVmID0gcG9seS5nZXROdW1Qb2ludHMoKSAtIDE7IDAgPD0gX3JlZiA/IF9pIDwgX3JlZiA6IF9pID4gX3JlZjsgaSA9IDAgPD0gX3JlZiA/ICsrX2kgOiAtLV9pKSB7XG4gICAgICB4MSA9IHBvbHkuZ2V0WChpKTtcbiAgICAgIHkxID0gcG9seS5nZXRZKGkpO1xuICAgICAgeDIgPSBwb2x5LmdldFgoaSArIDEpO1xuICAgICAgeTIgPSBwb2x5LmdldFkoaSArIDEpO1xuICAgICAgc3VtICs9IHgxICogeTIgLSB5MSAqIHgyO1xuICAgIH1cbiAgICB4MSA9IHBvbHkuZ2V0WChwb2x5LmdldE51bVBvaW50cygpIC0gMSk7XG4gICAgeTEgPSBwb2x5LmdldFkocG9seS5nZXROdW1Qb2ludHMoKSAtIDEpO1xuICAgIHgyID0gcG9seS5nZXRYKDApO1xuICAgIHkyID0gcG9seS5nZXRZKDApO1xuICAgIHN1bSArPSB4MSAqIHkyIC0geTEgKiB4MjtcbiAgICByZXR1cm4gTWF0aC5hYnMoc3VtIC8gMi4wKSA+IHRocmVzaGhvbGQ7XG4gIH07XG5cbiAgaXNJblJhbmdlID0gZnVuY3Rpb24odmFsLCB0aHJlc2hob2xkKSB7XG4gICAgcmV0dXJuIE1hdGguYWJzKHZhbCkgPCB0aHJlc2hob2xkO1xuICB9O1xuXG4gIHBvaW50c09uT25lTGluZSA9IGZ1bmN0aW9uKHBvbHkpIHtcbiAgICB2YXIgYSwgYiwgYywgaSwgdGhyZXNoaG9sZCwgeCwgeDEsIHgyLCB5LCB5MSwgeTIsIF9pLCBfcmVmO1xuICAgIHRocmVzaGhvbGQgPSBNYXRoLnBvdygxMCwgLTIpO1xuICAgIHgyID0gcG9seVtwb2x5Lmxlbmd0aCAtIDFdLng7XG4gICAgeTIgPSBwb2x5W3BvbHkubGVuZ3RoIC0gMV0ueTtcbiAgICB4MSA9IHBvbHlbMF0ueDtcbiAgICB5MSA9IHBvbHlbMF0ueTtcbiAgICBpZiAoIWlzSW5SYW5nZSh4MiAtIHgxLCB0aHJlc2hob2xkKSkge1xuICAgICAgYiA9IC0xO1xuICAgICAgYSA9ICh5MiAtIHkxKSAvICh4MiAtIHgxKTtcbiAgICB9IGVsc2UgaWYgKCFpc0luUmFuZ2UoeTIgLSB5MSwgdGhyZXNoaG9sZCkpIHtcbiAgICAgIGEgPSAtMTtcbiAgICAgIGIgPSAoeDIgLSB4MSkgLyAoeTIgLSB5MSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiB0cnVlO1xuICAgIH1cbiAgICBjID0gLWEgKiB4MSAtIGIgKiB5MTtcbiAgICBmb3IgKGkgPSBfaSA9IDAsIF9yZWYgPSBwb2x5Lmxlbmd0aDsgMCA8PSBfcmVmID8gX2kgPCBfcmVmIDogX2kgPiBfcmVmOyBpID0gMCA8PSBfcmVmID8gKytfaSA6IC0tX2kpIHtcbiAgICAgIHggPSBwb2x5W2ldLng7XG4gICAgICB5ID0gcG9seVtpXS55O1xuICAgICAgaWYgKCFpc0luUmFuZ2UoeCAqIGEgKyB5ICogYiArIGMsIHRocmVzaGhvbGQpKSB7XG4gICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIHRydWU7XG4gIH07XG5cbiAgaXNDbG9ja1dpc2UgPSBmdW5jdGlvbihwb2x5KSB7XG4gICAgdmFyIGksIHAxLCBwMiwgc3VtLCBfaSwgX3JlZjtcbiAgICBzdW0gPSAwLjA7XG4gICAgZm9yIChpID0gX2kgPSBpLCBfcmVmID0gcG9seS5sZW5ndGg7IGkgPD0gX3JlZiA/IF9pIDwgX3JlZiA6IF9pID4gX3JlZjsgaSA9IGkgPD0gX3JlZiA/ICsrX2kgOiAtLV9pKSB7XG4gICAgICBwMSA9IHBbaV07XG4gICAgICBwMiA9IGkgPT09IHBvbHkubGVuZ3RoIC0gMSA/IDAgOiBwb2x5W2kgKyAxXTtcbiAgICAgIHN1bSArPSAocDIueCAtIHAxLngpICogKHAyLnkgKyBwMS55KTtcbiAgICB9XG4gICAgcmV0dXJuIHN1bSA8IDA7XG4gIH07XG5cbiAgcmVtb3ZlRHVwbGljYXRlcyA9IGZ1bmN0aW9uKGxpc3RPZlBvbHkpIHtcbiAgICB2YXIgaSwgcDEsIHAyLCBwb2x5LCB0aHJlc2hob2xkLCBfaSwgX2xlbjtcbiAgICB0aHJlc2hob2xkID0gTWF0aC5wb3coMTAsIC0zKTtcbiAgICBmb3IgKF9pID0gMCwgX2xlbiA9IGxpc3RPZlBvbHkubGVuZ3RoOyBfaSA8IF9sZW47IF9pKyspIHtcbiAgICAgIHBvbHkgPSBsaXN0T2ZQb2x5W19pXTtcbiAgICAgIGkgPSBwb2x5Lmxlbmd0aDtcbiAgICAgIHdoaWxlICh0cnVlKSB7XG4gICAgICAgIC0taTtcbiAgICAgICAgaWYgKGkgPCAwKSB7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIH1cbiAgICAgICAgcDEgPSBwb2x5W2ldO1xuICAgICAgICBwMiA9IGkgPT09IDAgPyBwb2x5W3BvbHkubGVuZ3RoIC0gMV0gOiBwb2x5W2kgLSAxXTtcbiAgICAgICAgaWYgKGlzSW5SYW5nZShwMS5kaXN0YW5jZVRvKHAyKSwgdGhyZXNoaG9sZCkpIHtcbiAgICAgICAgICBwb2x5LnNwbGljZShpLCAxKTtcbiAgICAgICAgICBpICs9IDI7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIGxpc3RPZlBvbHk7XG4gIH07XG5cbiAgZXhwb3J0cyA9IHtcbiAgICBtZXJnZVVubWVyZ2VkUG9seWdvbnM6IG1lcmdlVW5tZXJnZWRQb2x5Z29ucyxcbiAgICBhcmVQb2ludFBhaXJzRXF1YWw6IGFyZVBvaW50UGFpcnNFcXVhbCxcbiAgICBhcmVQb2ludHNPblNhbWVMaW5lU2VnbWVudDogYXJlUG9pbnRzT25TYW1lTGluZVNlZ21lbnQsXG4gICAgYXJlUG9pbnRQYWlyc0VxdWFsOiBhcmVQb2ludFBhaXJzRXF1YWwsXG4gICAgcmVtb3ZlQ29sbGluZWFyUG9pbnRzOiByZW1vdmVDb2xsaW5lYXJQb2ludHMsXG4gICAgcG9seWdvbkFyZWFPdmVyVGhyZXNoaG9sZDogcG9seWdvbkFyZWFPdmVyVGhyZXNoaG9sZCxcbiAgICBpc0luUmFuZ2U6IGlzSW5SYW5nZSxcbiAgICBwb2ludHNPbk9uZUxpbmU6IHBvaW50c09uT25lTGluZSxcbiAgICBpc0Nsb2NrV2lzZTogaXNDbG9ja1dpc2UsXG4gICAgcmVtb3ZlRHVwbGljYXRlczogcmVtb3ZlRHVwbGljYXRlc1xuICB9O1xuXG59KS5jYWxsKHRoaXMpO1xuIiwiKGZ1bmN0aW9uKCkge1xuICB2YXIgcmVuZGVyO1xuXG4gIHJlbmRlciA9IGZ1bmN0aW9uKHVpKSB7XG4gICAgdmFyIGxvY2FsUmVuZGVyZXI7XG4gICAgbG9jYWxSZW5kZXJlciA9IGZ1bmN0aW9uKCkge1xuICAgICAgcmVxdWVzdEFuaW1hdGlvbkZyYW1lKGxvY2FsUmVuZGVyZXIpO1xuICAgICAgcmV0dXJuIHVpLnJlbmRlcmVyLnJlbmRlcih1aS5zY2VuZSwgdWkuY2FtZXJhKTtcbiAgICB9O1xuICAgIHJldHVybiBsb2NhbFJlbmRlcmVyKCk7XG5cbiAgICAvKlxuICAgIFx0bGVuID0gYW5pbWF0aW9ucy5sZW5ndGhcbiAgICBcdGlmIGxlblxuICAgIFx0XHRsb29wXG4gICAgXHRcdFx0bGVuLS1cbiAgICBcdFx0XHRicmVhayB1bmxlc3MgbGVuID49IDBcbiAgICBcdFx0XHRhbmltYXRpb24gPSBhbmltYXRpb25zW2xlbl1cbiAgICBcdFx0XHRpZiBhbmltYXRpb24uc3RhdHVzID4gMS4wXG4gICAgXHRcdFx0XHRhbmltYXRpb25zLnNwbGljZSggbGVuLCAxIClcbiAgICBcdFx0XHRhbmltYXRpb24uZG9BbmltYXRpb25TdGVwKClcbiAgICAgKi9cbiAgfTtcblxuICBtb2R1bGUuZXhwb3J0cyA9IHJlbmRlcjtcblxufSkuY2FsbCh0aGlzKTtcbiIsIihmdW5jdGlvbigpIHtcbiAgbW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbihnbG9iYWxDb25maWcpIHtcbiAgICByZXR1cm4ge1xuICAgICAgc2NlbmU6IG5ldyBUSFJFRS5TY2VuZSgpLFxuICAgICAgY2FtZXJhOiBuZXcgVEhSRUUuUGVyc3BlY3RpdmVDYW1lcmEoZ2xvYmFsQ29uZmlnLmZvdiwgd2luZG93LmlubmVyV2lkdGggLyB3aW5kb3cuaW5uZXJIZWlnaHQsIGdsb2JhbENvbmZpZy5jYW1lcmFOZWFyUGxhbmUsIGdsb2JhbENvbmZpZy5jYW1lcmFGYXJQbGFuZSksXG4gICAgICByZW5kZXJlcjogbmV3IFRIUkVFLldlYkdMUmVuZGVyZXIoe1xuICAgICAgICBhbHBoYTogdHJ1ZSxcbiAgICAgICAgYW50aWFsaWFzaW5nOiB0cnVlLFxuICAgICAgICBwcmVzZXJ2ZURyYXdpbmdCdWZmZXI6IHRydWVcbiAgICAgIH0pLFxuICAgICAgY29udHJvbHM6IG51bGwsXG4gICAgICBzdGxMb2FkZXI6IG5ldyBUSFJFRS5TVExMb2FkZXIoKSxcbiAgICAgIGZpbGVSZWFkZXI6IG5ldyBGaWxlUmVhZGVyKCksXG4gICAgICBrZXlVcEhhbmRsZXI6IGZ1bmN0aW9uKGV2ZW50KSB7XG4gICAgICAgIHZhciBtZXNoLCBfaSwgX2xlbiwgX3JlZjtcbiAgICAgICAgaWYgKGV2ZW50LmtleUNvZGUgPT09IDY3KSB7XG4gICAgICAgICAgX3JlZiA9IGdsb2JhbENvbmZpZy5tZXNoZXM7XG4gICAgICAgICAgZm9yIChfaSA9IDAsIF9sZW4gPSBfcmVmLmxlbmd0aDsgX2kgPCBfbGVuOyBfaSsrKSB7XG4gICAgICAgICAgICBtZXNoID0gX3JlZltfaV07XG4gICAgICAgICAgICB0aGlzLnNjZW5lLnJlbW92ZShtZXNoKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgcmV0dXJuIGdsb2JhbENvbmZpZy5tZXNoZXMgPSBbXTtcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICAgIGxvYWRIYW5kbGVyOiBmdW5jdGlvbihldmVudCkge1xuICAgICAgICB2YXIgZ2VvbWV0cnk7XG4gICAgICAgIGdlb21ldHJ5ID0gdGhpcy5zdGxMb2FkZXIucGFyc2UoZXZlbnQudGFyZ2V0LnJlc3VsdCk7XG4gICAgICAgIHJldHVybiAkKHRoaXMpLnRyaWdnZXIoJ2dlb21ldHJ5LWxvYWRlZCcsIGdlb21ldHJ5KTtcblxuICAgICAgICAvKlxuICAgICAgICBcdFx0XHRvYmplY3RNYXRlcmlhbCA9IG5ldyBUSFJFRS5NZXNoTGFtYmVydE1hdGVyaWFsKFxuICAgICAgICBcdFx0XHRcdHtcbiAgICAgICAgXHRcdFx0XHRcdGNvbG9yOiBnbG9iYWxDb25maWcuZGVmYXVsdE9iamVjdENvbG9yXG4gICAgICAgIFx0XHRcdFx0XHRhbWJpZW50OiBnbG9iYWxDb25maWcuZGVmYXVsdE9iamVjdENvbG9yXG4gICAgICAgIFx0XHRcdFx0fVxuICAgICAgICBcdFx0XHQpXG4gICAgICAgIFx0XHRcdG9iamVjdCA9IG5ldyBUSFJFRS5NZXNoKCBnZW9tZXRyeSwgb2JqZWN0TWF0ZXJpYWwgKVxuICAgICAgICBcdFx0XHRAc2NlbmUuYWRkKCBvYmplY3QgKVxuICAgICAgICBcdFx0XHRnbG9iYWxDb25maWcubWVzaGVzLnB1c2goIG9iamVjdCApXG4gICAgICAgICAqL1xuICAgICAgfSxcbiAgICAgIGRyb3BIYW5kbGVyOiBmdW5jdGlvbihldmVudCkge1xuICAgICAgICB2YXIgZmlsZSwgZmlsZXMsIF9pLCBfbGVuLCBfcmVmLCBfcmVzdWx0cztcbiAgICAgICAgZXZlbnQuc3RvcFByb3BhZ2F0aW9uKCk7XG4gICAgICAgIGV2ZW50LnByZXZlbnREZWZhdWx0KCk7XG4gICAgICAgIGZpbGVzID0gKF9yZWYgPSBldmVudC50YXJnZXQuZmlsZXMpICE9IG51bGwgPyBfcmVmIDogZXZlbnQuZGF0YVRyYW5zZmVyLmZpbGVzO1xuICAgICAgICBfcmVzdWx0cyA9IFtdO1xuICAgICAgICBmb3IgKF9pID0gMCwgX2xlbiA9IGZpbGVzLmxlbmd0aDsgX2kgPCBfbGVuOyBfaSsrKSB7XG4gICAgICAgICAgZmlsZSA9IGZpbGVzW19pXTtcbiAgICAgICAgICBpZiAoZmlsZS5uYW1lLmNvbnRhaW5zKCcuc3RsJykpIHtcbiAgICAgICAgICAgIF9yZXN1bHRzLnB1c2godGhpcy5maWxlUmVhZGVyLnJlYWRBc0JpbmFyeVN0cmluZyhmaWxlKSk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIF9yZXN1bHRzLnB1c2godm9pZCAwKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgcmV0dXJuIF9yZXN1bHRzO1xuICAgICAgfSxcbiAgICAgIGRyYWdPdmVySGFuZGxlcjogZnVuY3Rpb24oZXZlbnQpIHtcbiAgICAgICAgZXZlbnQuc3RvcFByb3BhZ2F0aW9uKCk7XG4gICAgICAgIGV2ZW50LnByZXZlbnREZWZhdWx0KCk7XG4gICAgICAgIHJldHVybiBldmVudC5kYXRhVHJhbnNmZXIuZHJvcEVmZmVjdCA9ICdjb3B5JztcbiAgICAgIH0sXG4gICAgICB3aW5kb3dSZXNpemVIYW5kbGVyOiBmdW5jdGlvbihldmVudCkge1xuICAgICAgICB0aGlzLmNhbWVyYS5hc3BlY3QgPSB3aW5kb3cuaW5uZXJXaWR0aCAvIHdpbmRvdy5pbm5lckhlaWdodDtcbiAgICAgICAgdGhpcy5jYW1lcmEudXBkYXRlUHJvamVjdGlvbk1hdHJpeCgpO1xuICAgICAgICB0aGlzLnJlbmRlcmVyLnNldFNpemUod2luZG93LmlubmVyV2lkdGgsIHdpbmRvdy5pbm5lckhlaWdodCk7XG4gICAgICAgIHJldHVybiB0aGlzLnJlbmRlcmVyLnJlbmRlcih0aGlzLnNjZW5lLCB0aGlzLmNhbWVyYSk7XG4gICAgICB9LFxuICAgICAgaW5pdDogZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBhbWJpZW50TGlnaHQsIGRpcmVjdGlvbmFsTGlnaHQsIGdlb21ldHJ5WEF4aXMsIGdlb21ldHJ5WUF4aXMsIGdlb21ldHJ5WkF4aXMsIGdyaWRMaW5lR2VvbWV0cnlYTmVnYXRpdmUsIGdyaWRMaW5lR2VvbWV0cnlYUG9zaXRpdmUsIGdyaWRMaW5lR2VvbWV0cnlZTmVnYXRpdmUsIGdyaWRMaW5lR2VvbWV0cnlZUG9zaXRpdmUsIGdyaWRMaW5lWE5lZ2F0aXZlLCBncmlkTGluZVhQb3NpdGl2ZSwgZ3JpZExpbmVZTmVnYXRpdmUsIGdyaWRMaW5lWVBvc2l0aXZlLCBpLCBtYXRlcmlhbCwgbWF0ZXJpYWxHcmlkMTAsIG1hdGVyaWFsR3JpZDUsIG1hdGVyaWFsR3JpZE5vcm1hbCwgbWF0ZXJpYWxYQXhpcywgbWF0ZXJpYWxZQXhpcywgbWF0ZXJpYWxaQXhpcywgbnVtLCBzY2VuZVJvdGF0aW9uLCB4QXhpcywgeUF4aXMsIHpBeGlzLCBfaSwgX3JlZjtcbiAgICAgICAgdGhpcy5yZW5kZXJlci5zZXRTaXplKHdpbmRvdy5pbm5lcldpZHRoLCB3aW5kb3cuaW5uZXJIZWlnaHQpO1xuICAgICAgICB0aGlzLnJlbmRlcmVyLnNldENsZWFyQ29sb3IoMHhmNmY2ZjYsIDEpO1xuICAgICAgICBkb2N1bWVudC5ib2R5LmFwcGVuZENoaWxkKHRoaXMucmVuZGVyZXIuZG9tRWxlbWVudCk7XG4gICAgICAgIHNjZW5lUm90YXRpb24gPSBuZXcgVEhSRUUuTWF0cml4NCgpO1xuICAgICAgICBzY2VuZVJvdGF0aW9uLm1ha2VSb3RhdGlvbkF4aXMobmV3IFRIUkVFLlZlY3RvcjMoMSwgMCwgMCksIC1NYXRoLlBJIC8gMik7XG4gICAgICAgIHRoaXMuc2NlbmUuYXBwbHlNYXRyaXgoc2NlbmVSb3RhdGlvbik7XG4gICAgICAgIHRoaXMuY2FtZXJhLnBvc2l0aW9uLnNldChnbG9iYWxDb25maWcuYXhpc0xlbmd0aCwgZ2xvYmFsQ29uZmlnLmF4aXNMZW5ndGggKyAxMCwgZ2xvYmFsQ29uZmlnLmF4aXNMZW5ndGggLyAyKTtcbiAgICAgICAgdGhpcy5jYW1lcmEudXAuc2V0KDAsIDEsIDApO1xuICAgICAgICB0aGlzLmNhbWVyYS5sb29rQXQobmV3IFRIUkVFLlZlY3RvcjMoMCwgMCwgMCkpO1xuICAgICAgICB0aGlzLmNvbnRyb2xzID0gbmV3IFRIUkVFLk9yYml0Q29udHJvbHModGhpcy5jYW1lcmEpO1xuICAgICAgICB0aGlzLmNvbnRyb2xzLnRhcmdldC5zZXQoMCwgMCwgMCk7XG4gICAgICAgIG1hdGVyaWFsWEF4aXMgPSBuZXcgVEhSRUUuTGluZUJhc2ljTWF0ZXJpYWwoe1xuICAgICAgICAgIGNvbG9yOiBnbG9iYWxDb25maWcuYXhpc1hDb2xvcixcbiAgICAgICAgICBsaW5ld2lkdGg6IGdsb2JhbENvbmZpZy5heGlzTGluZVdpZHRoXG4gICAgICAgIH0pO1xuICAgICAgICBtYXRlcmlhbFlBeGlzID0gbmV3IFRIUkVFLkxpbmVCYXNpY01hdGVyaWFsKHtcbiAgICAgICAgICBjb2xvcjogZ2xvYmFsQ29uZmlnLmF4aXNZQ29sb3IsXG4gICAgICAgICAgbGluZXdpZHRoOiBnbG9iYWxDb25maWcuYXhpc0xpbmVXaWR0aFxuICAgICAgICB9KTtcbiAgICAgICAgbWF0ZXJpYWxaQXhpcyA9IG5ldyBUSFJFRS5MaW5lQmFzaWNNYXRlcmlhbCh7XG4gICAgICAgICAgY29sb3I6IGdsb2JhbENvbmZpZy5heGlzWkNvbG9yLFxuICAgICAgICAgIGxpbmV3aWR0aDogZ2xvYmFsQ29uZmlnLmF4aXNMaW5lV2lkdGhcbiAgICAgICAgfSk7XG4gICAgICAgIGdlb21ldHJ5WEF4aXMgPSBuZXcgVEhSRUUuR2VvbWV0cnkoKTtcbiAgICAgICAgZ2VvbWV0cnlZQXhpcyA9IG5ldyBUSFJFRS5HZW9tZXRyeSgpO1xuICAgICAgICBnZW9tZXRyeVpBeGlzID0gbmV3IFRIUkVFLkdlb21ldHJ5KCk7XG4gICAgICAgIGdlb21ldHJ5WEF4aXMudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMygwLCAwLCAwKSk7XG4gICAgICAgIGdlb21ldHJ5WEF4aXMudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMyhnbG9iYWxDb25maWcuYXhpc0xlbmd0aCwgMCwgMCkpO1xuICAgICAgICBnZW9tZXRyeVlBeGlzLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoMCwgMCwgMCkpO1xuICAgICAgICBnZW9tZXRyeVlBeGlzLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoMCwgZ2xvYmFsQ29uZmlnLmF4aXNMZW5ndGgsIDApKTtcbiAgICAgICAgZ2VvbWV0cnlaQXhpcy52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKDAsIDAsIDApKTtcbiAgICAgICAgZ2VvbWV0cnlaQXhpcy52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKDAsIDAsIGdsb2JhbENvbmZpZy5heGlzTGVuZ3RoKSk7XG4gICAgICAgIHhBeGlzID0gbmV3IFRIUkVFLkxpbmUoZ2VvbWV0cnlYQXhpcywgbWF0ZXJpYWxYQXhpcyk7XG4gICAgICAgIHlBeGlzID0gbmV3IFRIUkVFLkxpbmUoZ2VvbWV0cnlZQXhpcywgbWF0ZXJpYWxZQXhpcyk7XG4gICAgICAgIHpBeGlzID0gbmV3IFRIUkVFLkxpbmUoZ2VvbWV0cnlaQXhpcywgbWF0ZXJpYWxaQXhpcyk7XG4gICAgICAgIHRoaXMuc2NlbmUuYWRkKHhBeGlzKTtcbiAgICAgICAgdGhpcy5zY2VuZS5hZGQoeUF4aXMpO1xuICAgICAgICB0aGlzLnNjZW5lLmFkZCh6QXhpcyk7XG4gICAgICAgIG1hdGVyaWFsR3JpZE5vcm1hbCA9IG5ldyBUSFJFRS5MaW5lQmFzaWNNYXRlcmlhbCh7XG4gICAgICAgICAgY29sb3I6IGdsb2JhbENvbmZpZy5ncmlkQ29sb3JOb3JtYWwsXG4gICAgICAgICAgbGluZXdpZHRoOiBnbG9iYWxDb25maWcuZ3JpZExpbmVXaWR0aE5vcm1hbFxuICAgICAgICB9KTtcbiAgICAgICAgbWF0ZXJpYWxHcmlkNSA9IG5ldyBUSFJFRS5MaW5lQmFzaWNNYXRlcmlhbCh7XG4gICAgICAgICAgY29sb3I6IGdsb2JhbENvbmZpZy5ncmlkQ29sb3I1LFxuICAgICAgICAgIGxpbmV3aWR0aDogZ2xvYmFsQ29uZmlnLmdyaWRMaW5lV2lkdGg1XG4gICAgICAgIH0pO1xuICAgICAgICBtYXRlcmlhbEdyaWQxMCA9IG5ldyBUSFJFRS5MaW5lQmFzaWNNYXRlcmlhbCh7XG4gICAgICAgICAgY29sb3I6IGdsb2JhbENvbmZpZy5ncmlkQ29sb3IxMCxcbiAgICAgICAgICBsaW5ld2lkdGg6IGdsb2JhbENvbmZpZy5ncmlkTGluZVdpZHRoMTBcbiAgICAgICAgfSk7XG4gICAgICAgIGZvciAoaSA9IF9pID0gMCwgX3JlZiA9IGdsb2JhbENvbmZpZy5ncmlkU2l6ZSAvIGdsb2JhbENvbmZpZy5ncmlkU3RlcFNpemU7IDAgPD0gX3JlZiA/IF9pIDw9IF9yZWYgOiBfaSA+PSBfcmVmOyBpID0gMCA8PSBfcmVmID8gKytfaSA6IC0tX2kpIHtcbiAgICAgICAgICBudW0gPSBpICogZ2xvYmFsQ29uZmlnLmdyaWRTdGVwU2l6ZTtcbiAgICAgICAgICBpZiAoaSAlIDEwICogZ2xvYmFsQ29uZmlnLmdyaWRTdGVwU2l6ZSA9PT0gMCkge1xuICAgICAgICAgICAgbWF0ZXJpYWwgPSBtYXRlcmlhbEdyaWQxMDtcbiAgICAgICAgICB9IGVsc2UgaWYgKGkgJSA1ICogZ2xvYmFsQ29uZmlnLmdyaWRTdGVwU2l6ZSA9PT0gMCkge1xuICAgICAgICAgICAgbWF0ZXJpYWwgPSBtYXRlcmlhbEdyaWQ1O1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBtYXRlcmlhbCA9IG1hdGVyaWFsR3JpZE5vcm1hbDtcbiAgICAgICAgICB9XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVhQb3NpdGl2ZSA9IG5ldyBUSFJFRS5HZW9tZXRyeSgpO1xuICAgICAgICAgIGdyaWRMaW5lR2VvbWV0cnlZUG9zaXRpdmUgPSBuZXcgVEhSRUUuR2VvbWV0cnkoKTtcbiAgICAgICAgICBncmlkTGluZUdlb21ldHJ5WE5lZ2F0aXZlID0gbmV3IFRIUkVFLkdlb21ldHJ5KCk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVlOZWdhdGl2ZSA9IG5ldyBUSFJFRS5HZW9tZXRyeSgpO1xuICAgICAgICAgIGdyaWRMaW5lR2VvbWV0cnlYUG9zaXRpdmUudmVydGljZXMucHVzaChuZXcgVEhSRUUuVmVjdG9yMygtZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCBudW0sIDApKTtcbiAgICAgICAgICBncmlkTGluZUdlb21ldHJ5WFBvc2l0aXZlLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCBudW0sIDApKTtcbiAgICAgICAgICBncmlkTGluZUdlb21ldHJ5WVBvc2l0aXZlLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMobnVtLCAtZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVlQb3NpdGl2ZS52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKG51bSwgZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVhOZWdhdGl2ZS52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKC1nbG9iYWxDb25maWcuZ3JpZFNpemUsIC1udW0sIDApKTtcbiAgICAgICAgICBncmlkTGluZUdlb21ldHJ5WE5lZ2F0aXZlLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCAtbnVtLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVHZW9tZXRyeVlOZWdhdGl2ZS52ZXJ0aWNlcy5wdXNoKG5ldyBUSFJFRS5WZWN0b3IzKC1udW0sIC1nbG9iYWxDb25maWcuZ3JpZFNpemUsIDApKTtcbiAgICAgICAgICBncmlkTGluZUdlb21ldHJ5WU5lZ2F0aXZlLnZlcnRpY2VzLnB1c2gobmV3IFRIUkVFLlZlY3RvcjMoLW51bSwgZ2xvYmFsQ29uZmlnLmdyaWRTaXplLCAwKSk7XG4gICAgICAgICAgZ3JpZExpbmVYUG9zaXRpdmUgPSBuZXcgVEhSRUUuTGluZShncmlkTGluZUdlb21ldHJ5WFBvc2l0aXZlLCBtYXRlcmlhbCk7XG4gICAgICAgICAgZ3JpZExpbmVZUG9zaXRpdmUgPSBuZXcgVEhSRUUuTGluZShncmlkTGluZUdlb21ldHJ5WVBvc2l0aXZlLCBtYXRlcmlhbCk7XG4gICAgICAgICAgZ3JpZExpbmVYTmVnYXRpdmUgPSBuZXcgVEhSRUUuTGluZShncmlkTGluZUdlb21ldHJ5WE5lZ2F0aXZlLCBtYXRlcmlhbCk7XG4gICAgICAgICAgZ3JpZExpbmVZTmVnYXRpdmUgPSBuZXcgVEhSRUUuTGluZShncmlkTGluZUdlb21ldHJ5WU5lZ2F0aXZlLCBtYXRlcmlhbCk7XG4gICAgICAgICAgdGhpcy5zY2VuZS5hZGQoZ3JpZExpbmVYUG9zaXRpdmUpO1xuICAgICAgICAgIHRoaXMuc2NlbmUuYWRkKGdyaWRMaW5lWVBvc2l0aXZlKTtcbiAgICAgICAgICB0aGlzLnNjZW5lLmFkZChncmlkTGluZVhOZWdhdGl2ZSk7XG4gICAgICAgICAgdGhpcy5zY2VuZS5hZGQoZ3JpZExpbmVZTmVnYXRpdmUpO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMucmVuZGVyZXIuZG9tRWxlbWVudC5hZGRFdmVudExpc3RlbmVyKCdkcmFnb3ZlcicsIHRoaXMuZHJhZ092ZXJIYW5kbGVyLmJpbmQodGhpcyksIGZhbHNlKTtcbiAgICAgICAgdGhpcy5yZW5kZXJlci5kb21FbGVtZW50LmFkZEV2ZW50TGlzdGVuZXIoJ2Ryb3AnLCB0aGlzLmRyb3BIYW5kbGVyLmJpbmQodGhpcyksIGZhbHNlKTtcbiAgICAgICAgdGhpcy5maWxlUmVhZGVyLmFkZEV2ZW50TGlzdGVuZXIoJ2xvYWRlbmQnLCB0aGlzLmxvYWRIYW5kbGVyLmJpbmQodGhpcyksIGZhbHNlKTtcbiAgICAgICAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcigna2V5dXAnLCB0aGlzLmtleVVwSGFuZGxlci5iaW5kKHRoaXMpKTtcbiAgICAgICAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoJ3Jlc2l6ZScsIHRoaXMud2luZG93UmVzaXplSGFuZGxlci5iaW5kKHRoaXMpLCBmYWxzZSk7XG4gICAgICAgIGFtYmllbnRMaWdodCA9IG5ldyBUSFJFRS5BbWJpZW50TGlnaHQoMHg0MDQwNDApO1xuICAgICAgICB0aGlzLnNjZW5lLmFkZChhbWJpZW50TGlnaHQpO1xuICAgICAgICBkaXJlY3Rpb25hbExpZ2h0ID0gbmV3IFRIUkVFLkRpcmVjdGlvbmFsTGlnaHQoMHhmZmZmZmYpO1xuICAgICAgICBkaXJlY3Rpb25hbExpZ2h0LnBvc2l0aW9uLnNldCgwLCAyMCwgMzApO1xuICAgICAgICB0aGlzLnNjZW5lLmFkZChkaXJlY3Rpb25hbExpZ2h0KTtcbiAgICAgICAgZGlyZWN0aW9uYWxMaWdodCA9IG5ldyBUSFJFRS5EaXJlY3Rpb25hbExpZ2h0KDB4ODA4MDgwKTtcbiAgICAgICAgZGlyZWN0aW9uYWxMaWdodC5wb3NpdGlvbi5zZXQoMjAsIDAsIDMwKTtcbiAgICAgICAgcmV0dXJuIHRoaXMuc2NlbmUuYWRkKGRpcmVjdGlvbmFsTGlnaHQpO1xuICAgICAgfVxuICAgIH07XG4gIH07XG5cbn0pLmNhbGwodGhpcyk7XG4iLCIoZnVuY3Rpb24gKHByb2Nlc3Mpe1xuLy8gQ29weXJpZ2h0IEpveWVudCwgSW5jLiBhbmQgb3RoZXIgTm9kZSBjb250cmlidXRvcnMuXG4vL1xuLy8gUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGFcbi8vIGNvcHkgb2YgdGhpcyBzb2Z0d2FyZSBhbmQgYXNzb2NpYXRlZCBkb2N1bWVudGF0aW9uIGZpbGVzICh0aGVcbi8vIFwiU29mdHdhcmVcIiksIHRvIGRlYWwgaW4gdGhlIFNvZnR3YXJlIHdpdGhvdXQgcmVzdHJpY3Rpb24sIGluY2x1ZGluZ1xuLy8gd2l0aG91dCBsaW1pdGF0aW9uIHRoZSByaWdodHMgdG8gdXNlLCBjb3B5LCBtb2RpZnksIG1lcmdlLCBwdWJsaXNoLFxuLy8gZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwgY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdFxuLy8gcGVyc29ucyB0byB3aG9tIHRoZSBTb2Z0d2FyZSBpcyBmdXJuaXNoZWQgdG8gZG8gc28sIHN1YmplY3QgdG8gdGhlXG4vLyBmb2xsb3dpbmcgY29uZGl0aW9uczpcbi8vXG4vLyBUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZFxuLy8gaW4gYWxsIGNvcGllcyBvciBzdWJzdGFudGlhbCBwb3J0aW9ucyBvZiB0aGUgU29mdHdhcmUuXG4vL1xuLy8gVEhFIFNPRlRXQVJFIElTIFBST1ZJREVEIFwiQVMgSVNcIiwgV0lUSE9VVCBXQVJSQU5UWSBPRiBBTlkgS0lORCwgRVhQUkVTU1xuLy8gT1IgSU1QTElFRCwgSU5DTFVESU5HIEJVVCBOT1QgTElNSVRFRCBUTyBUSEUgV0FSUkFOVElFUyBPRlxuLy8gTUVSQ0hBTlRBQklMSVRZLCBGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTlxuLy8gTk8gRVZFTlQgU0hBTEwgVEhFIEFVVEhPUlMgT1IgQ09QWVJJR0hUIEhPTERFUlMgQkUgTElBQkxFIEZPUiBBTlkgQ0xBSU0sXG4vLyBEQU1BR0VTIE9SIE9USEVSIExJQUJJTElUWSwgV0hFVEhFUiBJTiBBTiBBQ1RJT04gT0YgQ09OVFJBQ1QsIFRPUlQgT1Jcbi8vIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLCBPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEVcbi8vIFVTRSBPUiBPVEhFUiBERUFMSU5HUyBJTiBUSEUgU09GVFdBUkUuXG5cbi8vIHJlc29sdmVzIC4gYW5kIC4uIGVsZW1lbnRzIGluIGEgcGF0aCBhcnJheSB3aXRoIGRpcmVjdG9yeSBuYW1lcyB0aGVyZVxuLy8gbXVzdCBiZSBubyBzbGFzaGVzLCBlbXB0eSBlbGVtZW50cywgb3IgZGV2aWNlIG5hbWVzIChjOlxcKSBpbiB0aGUgYXJyYXlcbi8vIChzbyBhbHNvIG5vIGxlYWRpbmcgYW5kIHRyYWlsaW5nIHNsYXNoZXMgLSBpdCBkb2VzIG5vdCBkaXN0aW5ndWlzaFxuLy8gcmVsYXRpdmUgYW5kIGFic29sdXRlIHBhdGhzKVxuZnVuY3Rpb24gbm9ybWFsaXplQXJyYXkocGFydHMsIGFsbG93QWJvdmVSb290KSB7XG4gIC8vIGlmIHRoZSBwYXRoIHRyaWVzIHRvIGdvIGFib3ZlIHRoZSByb290LCBgdXBgIGVuZHMgdXAgPiAwXG4gIHZhciB1cCA9IDA7XG4gIGZvciAodmFyIGkgPSBwYXJ0cy5sZW5ndGggLSAxOyBpID49IDA7IGktLSkge1xuICAgIHZhciBsYXN0ID0gcGFydHNbaV07XG4gICAgaWYgKGxhc3QgPT09ICcuJykge1xuICAgICAgcGFydHMuc3BsaWNlKGksIDEpO1xuICAgIH0gZWxzZSBpZiAobGFzdCA9PT0gJy4uJykge1xuICAgICAgcGFydHMuc3BsaWNlKGksIDEpO1xuICAgICAgdXArKztcbiAgICB9IGVsc2UgaWYgKHVwKSB7XG4gICAgICBwYXJ0cy5zcGxpY2UoaSwgMSk7XG4gICAgICB1cC0tO1xuICAgIH1cbiAgfVxuXG4gIC8vIGlmIHRoZSBwYXRoIGlzIGFsbG93ZWQgdG8gZ28gYWJvdmUgdGhlIHJvb3QsIHJlc3RvcmUgbGVhZGluZyAuLnNcbiAgaWYgKGFsbG93QWJvdmVSb290KSB7XG4gICAgZm9yICg7IHVwLS07IHVwKSB7XG4gICAgICBwYXJ0cy51bnNoaWZ0KCcuLicpO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBwYXJ0cztcbn1cblxuLy8gU3BsaXQgYSBmaWxlbmFtZSBpbnRvIFtyb290LCBkaXIsIGJhc2VuYW1lLCBleHRdLCB1bml4IHZlcnNpb25cbi8vICdyb290JyBpcyBqdXN0IGEgc2xhc2gsIG9yIG5vdGhpbmcuXG52YXIgc3BsaXRQYXRoUmUgPVxuICAgIC9eKFxcLz98KShbXFxzXFxTXSo/KSgoPzpcXC57MSwyfXxbXlxcL10rP3wpKFxcLlteLlxcL10qfCkpKD86W1xcL10qKSQvO1xudmFyIHNwbGl0UGF0aCA9IGZ1bmN0aW9uKGZpbGVuYW1lKSB7XG4gIHJldHVybiBzcGxpdFBhdGhSZS5leGVjKGZpbGVuYW1lKS5zbGljZSgxKTtcbn07XG5cbi8vIHBhdGgucmVzb2x2ZShbZnJvbSAuLi5dLCB0bylcbi8vIHBvc2l4IHZlcnNpb25cbmV4cG9ydHMucmVzb2x2ZSA9IGZ1bmN0aW9uKCkge1xuICB2YXIgcmVzb2x2ZWRQYXRoID0gJycsXG4gICAgICByZXNvbHZlZEFic29sdXRlID0gZmFsc2U7XG5cbiAgZm9yICh2YXIgaSA9IGFyZ3VtZW50cy5sZW5ndGggLSAxOyBpID49IC0xICYmICFyZXNvbHZlZEFic29sdXRlOyBpLS0pIHtcbiAgICB2YXIgcGF0aCA9IChpID49IDApID8gYXJndW1lbnRzW2ldIDogcHJvY2Vzcy5jd2QoKTtcblxuICAgIC8vIFNraXAgZW1wdHkgYW5kIGludmFsaWQgZW50cmllc1xuICAgIGlmICh0eXBlb2YgcGF0aCAhPT0gJ3N0cmluZycpIHtcbiAgICAgIHRocm93IG5ldyBUeXBlRXJyb3IoJ0FyZ3VtZW50cyB0byBwYXRoLnJlc29sdmUgbXVzdCBiZSBzdHJpbmdzJyk7XG4gICAgfSBlbHNlIGlmICghcGF0aCkge1xuICAgICAgY29udGludWU7XG4gICAgfVxuXG4gICAgcmVzb2x2ZWRQYXRoID0gcGF0aCArICcvJyArIHJlc29sdmVkUGF0aDtcbiAgICByZXNvbHZlZEFic29sdXRlID0gcGF0aC5jaGFyQXQoMCkgPT09ICcvJztcbiAgfVxuXG4gIC8vIEF0IHRoaXMgcG9pbnQgdGhlIHBhdGggc2hvdWxkIGJlIHJlc29sdmVkIHRvIGEgZnVsbCBhYnNvbHV0ZSBwYXRoLCBidXRcbiAgLy8gaGFuZGxlIHJlbGF0aXZlIHBhdGhzIHRvIGJlIHNhZmUgKG1pZ2h0IGhhcHBlbiB3aGVuIHByb2Nlc3MuY3dkKCkgZmFpbHMpXG5cbiAgLy8gTm9ybWFsaXplIHRoZSBwYXRoXG4gIHJlc29sdmVkUGF0aCA9IG5vcm1hbGl6ZUFycmF5KGZpbHRlcihyZXNvbHZlZFBhdGguc3BsaXQoJy8nKSwgZnVuY3Rpb24ocCkge1xuICAgIHJldHVybiAhIXA7XG4gIH0pLCAhcmVzb2x2ZWRBYnNvbHV0ZSkuam9pbignLycpO1xuXG4gIHJldHVybiAoKHJlc29sdmVkQWJzb2x1dGUgPyAnLycgOiAnJykgKyByZXNvbHZlZFBhdGgpIHx8ICcuJztcbn07XG5cbi8vIHBhdGgubm9ybWFsaXplKHBhdGgpXG4vLyBwb3NpeCB2ZXJzaW9uXG5leHBvcnRzLm5vcm1hbGl6ZSA9IGZ1bmN0aW9uKHBhdGgpIHtcbiAgdmFyIGlzQWJzb2x1dGUgPSBleHBvcnRzLmlzQWJzb2x1dGUocGF0aCksXG4gICAgICB0cmFpbGluZ1NsYXNoID0gc3Vic3RyKHBhdGgsIC0xKSA9PT0gJy8nO1xuXG4gIC8vIE5vcm1hbGl6ZSB0aGUgcGF0aFxuICBwYXRoID0gbm9ybWFsaXplQXJyYXkoZmlsdGVyKHBhdGguc3BsaXQoJy8nKSwgZnVuY3Rpb24ocCkge1xuICAgIHJldHVybiAhIXA7XG4gIH0pLCAhaXNBYnNvbHV0ZSkuam9pbignLycpO1xuXG4gIGlmICghcGF0aCAmJiAhaXNBYnNvbHV0ZSkge1xuICAgIHBhdGggPSAnLic7XG4gIH1cbiAgaWYgKHBhdGggJiYgdHJhaWxpbmdTbGFzaCkge1xuICAgIHBhdGggKz0gJy8nO1xuICB9XG5cbiAgcmV0dXJuIChpc0Fic29sdXRlID8gJy8nIDogJycpICsgcGF0aDtcbn07XG5cbi8vIHBvc2l4IHZlcnNpb25cbmV4cG9ydHMuaXNBYnNvbHV0ZSA9IGZ1bmN0aW9uKHBhdGgpIHtcbiAgcmV0dXJuIHBhdGguY2hhckF0KDApID09PSAnLyc7XG59O1xuXG4vLyBwb3NpeCB2ZXJzaW9uXG5leHBvcnRzLmpvaW4gPSBmdW5jdGlvbigpIHtcbiAgdmFyIHBhdGhzID0gQXJyYXkucHJvdG90eXBlLnNsaWNlLmNhbGwoYXJndW1lbnRzLCAwKTtcbiAgcmV0dXJuIGV4cG9ydHMubm9ybWFsaXplKGZpbHRlcihwYXRocywgZnVuY3Rpb24ocCwgaW5kZXgpIHtcbiAgICBpZiAodHlwZW9mIHAgIT09ICdzdHJpbmcnKSB7XG4gICAgICB0aHJvdyBuZXcgVHlwZUVycm9yKCdBcmd1bWVudHMgdG8gcGF0aC5qb2luIG11c3QgYmUgc3RyaW5ncycpO1xuICAgIH1cbiAgICByZXR1cm4gcDtcbiAgfSkuam9pbignLycpKTtcbn07XG5cblxuLy8gcGF0aC5yZWxhdGl2ZShmcm9tLCB0bylcbi8vIHBvc2l4IHZlcnNpb25cbmV4cG9ydHMucmVsYXRpdmUgPSBmdW5jdGlvbihmcm9tLCB0bykge1xuICBmcm9tID0gZXhwb3J0cy5yZXNvbHZlKGZyb20pLnN1YnN0cigxKTtcbiAgdG8gPSBleHBvcnRzLnJlc29sdmUodG8pLnN1YnN0cigxKTtcblxuICBmdW5jdGlvbiB0cmltKGFycikge1xuICAgIHZhciBzdGFydCA9IDA7XG4gICAgZm9yICg7IHN0YXJ0IDwgYXJyLmxlbmd0aDsgc3RhcnQrKykge1xuICAgICAgaWYgKGFycltzdGFydF0gIT09ICcnKSBicmVhaztcbiAgICB9XG5cbiAgICB2YXIgZW5kID0gYXJyLmxlbmd0aCAtIDE7XG4gICAgZm9yICg7IGVuZCA+PSAwOyBlbmQtLSkge1xuICAgICAgaWYgKGFycltlbmRdICE9PSAnJykgYnJlYWs7XG4gICAgfVxuXG4gICAgaWYgKHN0YXJ0ID4gZW5kKSByZXR1cm4gW107XG4gICAgcmV0dXJuIGFyci5zbGljZShzdGFydCwgZW5kIC0gc3RhcnQgKyAxKTtcbiAgfVxuXG4gIHZhciBmcm9tUGFydHMgPSB0cmltKGZyb20uc3BsaXQoJy8nKSk7XG4gIHZhciB0b1BhcnRzID0gdHJpbSh0by5zcGxpdCgnLycpKTtcblxuICB2YXIgbGVuZ3RoID0gTWF0aC5taW4oZnJvbVBhcnRzLmxlbmd0aCwgdG9QYXJ0cy5sZW5ndGgpO1xuICB2YXIgc2FtZVBhcnRzTGVuZ3RoID0gbGVuZ3RoO1xuICBmb3IgKHZhciBpID0gMDsgaSA8IGxlbmd0aDsgaSsrKSB7XG4gICAgaWYgKGZyb21QYXJ0c1tpXSAhPT0gdG9QYXJ0c1tpXSkge1xuICAgICAgc2FtZVBhcnRzTGVuZ3RoID0gaTtcbiAgICAgIGJyZWFrO1xuICAgIH1cbiAgfVxuXG4gIHZhciBvdXRwdXRQYXJ0cyA9IFtdO1xuICBmb3IgKHZhciBpID0gc2FtZVBhcnRzTGVuZ3RoOyBpIDwgZnJvbVBhcnRzLmxlbmd0aDsgaSsrKSB7XG4gICAgb3V0cHV0UGFydHMucHVzaCgnLi4nKTtcbiAgfVxuXG4gIG91dHB1dFBhcnRzID0gb3V0cHV0UGFydHMuY29uY2F0KHRvUGFydHMuc2xpY2Uoc2FtZVBhcnRzTGVuZ3RoKSk7XG5cbiAgcmV0dXJuIG91dHB1dFBhcnRzLmpvaW4oJy8nKTtcbn07XG5cbmV4cG9ydHMuc2VwID0gJy8nO1xuZXhwb3J0cy5kZWxpbWl0ZXIgPSAnOic7XG5cbmV4cG9ydHMuZGlybmFtZSA9IGZ1bmN0aW9uKHBhdGgpIHtcbiAgdmFyIHJlc3VsdCA9IHNwbGl0UGF0aChwYXRoKSxcbiAgICAgIHJvb3QgPSByZXN1bHRbMF0sXG4gICAgICBkaXIgPSByZXN1bHRbMV07XG5cbiAgaWYgKCFyb290ICYmICFkaXIpIHtcbiAgICAvLyBObyBkaXJuYW1lIHdoYXRzb2V2ZXJcbiAgICByZXR1cm4gJy4nO1xuICB9XG5cbiAgaWYgKGRpcikge1xuICAgIC8vIEl0IGhhcyBhIGRpcm5hbWUsIHN0cmlwIHRyYWlsaW5nIHNsYXNoXG4gICAgZGlyID0gZGlyLnN1YnN0cigwLCBkaXIubGVuZ3RoIC0gMSk7XG4gIH1cblxuICByZXR1cm4gcm9vdCArIGRpcjtcbn07XG5cblxuZXhwb3J0cy5iYXNlbmFtZSA9IGZ1bmN0aW9uKHBhdGgsIGV4dCkge1xuICB2YXIgZiA9IHNwbGl0UGF0aChwYXRoKVsyXTtcbiAgLy8gVE9ETzogbWFrZSB0aGlzIGNvbXBhcmlzb24gY2FzZS1pbnNlbnNpdGl2ZSBvbiB3aW5kb3dzP1xuICBpZiAoZXh0ICYmIGYuc3Vic3RyKC0xICogZXh0Lmxlbmd0aCkgPT09IGV4dCkge1xuICAgIGYgPSBmLnN1YnN0cigwLCBmLmxlbmd0aCAtIGV4dC5sZW5ndGgpO1xuICB9XG4gIHJldHVybiBmO1xufTtcblxuXG5leHBvcnRzLmV4dG5hbWUgPSBmdW5jdGlvbihwYXRoKSB7XG4gIHJldHVybiBzcGxpdFBhdGgocGF0aClbM107XG59O1xuXG5mdW5jdGlvbiBmaWx0ZXIgKHhzLCBmKSB7XG4gICAgaWYgKHhzLmZpbHRlcikgcmV0dXJuIHhzLmZpbHRlcihmKTtcbiAgICB2YXIgcmVzID0gW107XG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCB4cy5sZW5ndGg7IGkrKykge1xuICAgICAgICBpZiAoZih4c1tpXSwgaSwgeHMpKSByZXMucHVzaCh4c1tpXSk7XG4gICAgfVxuICAgIHJldHVybiByZXM7XG59XG5cbi8vIFN0cmluZy5wcm90b3R5cGUuc3Vic3RyIC0gbmVnYXRpdmUgaW5kZXggZG9uJ3Qgd29yayBpbiBJRThcbnZhciBzdWJzdHIgPSAnYWInLnN1YnN0cigtMSkgPT09ICdiJ1xuICAgID8gZnVuY3Rpb24gKHN0ciwgc3RhcnQsIGxlbikgeyByZXR1cm4gc3RyLnN1YnN0cihzdGFydCwgbGVuKSB9XG4gICAgOiBmdW5jdGlvbiAoc3RyLCBzdGFydCwgbGVuKSB7XG4gICAgICAgIGlmIChzdGFydCA8IDApIHN0YXJ0ID0gc3RyLmxlbmd0aCArIHN0YXJ0O1xuICAgICAgICByZXR1cm4gc3RyLnN1YnN0cihzdGFydCwgbGVuKTtcbiAgICB9XG47XG5cbn0pLmNhbGwodGhpcyxyZXF1aXJlKCdfcHJvY2VzcycpKSIsIi8vIHNoaW0gZm9yIHVzaW5nIHByb2Nlc3MgaW4gYnJvd3NlclxuXG52YXIgcHJvY2VzcyA9IG1vZHVsZS5leHBvcnRzID0ge307XG5cbnByb2Nlc3MubmV4dFRpY2sgPSAoZnVuY3Rpb24gKCkge1xuICAgIHZhciBjYW5TZXRJbW1lZGlhdGUgPSB0eXBlb2Ygd2luZG93ICE9PSAndW5kZWZpbmVkJ1xuICAgICYmIHdpbmRvdy5zZXRJbW1lZGlhdGU7XG4gICAgdmFyIGNhbk11dGF0aW9uT2JzZXJ2ZXIgPSB0eXBlb2Ygd2luZG93ICE9PSAndW5kZWZpbmVkJ1xuICAgICYmIHdpbmRvdy5NdXRhdGlvbk9ic2VydmVyO1xuICAgIHZhciBjYW5Qb3N0ID0gdHlwZW9mIHdpbmRvdyAhPT0gJ3VuZGVmaW5lZCdcbiAgICAmJiB3aW5kb3cucG9zdE1lc3NhZ2UgJiYgd2luZG93LmFkZEV2ZW50TGlzdGVuZXJcbiAgICA7XG5cbiAgICBpZiAoY2FuU2V0SW1tZWRpYXRlKSB7XG4gICAgICAgIHJldHVybiBmdW5jdGlvbiAoZikgeyByZXR1cm4gd2luZG93LnNldEltbWVkaWF0ZShmKSB9O1xuICAgIH1cblxuICAgIHZhciBxdWV1ZSA9IFtdO1xuXG4gICAgaWYgKGNhbk11dGF0aW9uT2JzZXJ2ZXIpIHtcbiAgICAgICAgdmFyIGhpZGRlbkRpdiA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoXCJkaXZcIik7XG4gICAgICAgIHZhciBvYnNlcnZlciA9IG5ldyBNdXRhdGlvbk9ic2VydmVyKGZ1bmN0aW9uICgpIHtcbiAgICAgICAgICAgIHZhciBxdWV1ZUxpc3QgPSBxdWV1ZS5zbGljZSgpO1xuICAgICAgICAgICAgcXVldWUubGVuZ3RoID0gMDtcbiAgICAgICAgICAgIHF1ZXVlTGlzdC5mb3JFYWNoKGZ1bmN0aW9uIChmbikge1xuICAgICAgICAgICAgICAgIGZuKCk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgfSk7XG5cbiAgICAgICAgb2JzZXJ2ZXIub2JzZXJ2ZShoaWRkZW5EaXYsIHsgYXR0cmlidXRlczogdHJ1ZSB9KTtcblxuICAgICAgICByZXR1cm4gZnVuY3Rpb24gbmV4dFRpY2soZm4pIHtcbiAgICAgICAgICAgIGlmICghcXVldWUubGVuZ3RoKSB7XG4gICAgICAgICAgICAgICAgaGlkZGVuRGl2LnNldEF0dHJpYnV0ZSgneWVzJywgJ25vJyk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBxdWV1ZS5wdXNoKGZuKTtcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICBpZiAoY2FuUG9zdCkge1xuICAgICAgICB3aW5kb3cuYWRkRXZlbnRMaXN0ZW5lcignbWVzc2FnZScsIGZ1bmN0aW9uIChldikge1xuICAgICAgICAgICAgdmFyIHNvdXJjZSA9IGV2LnNvdXJjZTtcbiAgICAgICAgICAgIGlmICgoc291cmNlID09PSB3aW5kb3cgfHwgc291cmNlID09PSBudWxsKSAmJiBldi5kYXRhID09PSAncHJvY2Vzcy10aWNrJykge1xuICAgICAgICAgICAgICAgIGV2LnN0b3BQcm9wYWdhdGlvbigpO1xuICAgICAgICAgICAgICAgIGlmIChxdWV1ZS5sZW5ndGggPiAwKSB7XG4gICAgICAgICAgICAgICAgICAgIHZhciBmbiA9IHF1ZXVlLnNoaWZ0KCk7XG4gICAgICAgICAgICAgICAgICAgIGZuKCk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICB9LCB0cnVlKTtcblxuICAgICAgICByZXR1cm4gZnVuY3Rpb24gbmV4dFRpY2soZm4pIHtcbiAgICAgICAgICAgIHF1ZXVlLnB1c2goZm4pO1xuICAgICAgICAgICAgd2luZG93LnBvc3RNZXNzYWdlKCdwcm9jZXNzLXRpY2snLCAnKicpO1xuICAgICAgICB9O1xuICAgIH1cblxuICAgIHJldHVybiBmdW5jdGlvbiBuZXh0VGljayhmbikge1xuICAgICAgICBzZXRUaW1lb3V0KGZuLCAwKTtcbiAgICB9O1xufSkoKTtcblxucHJvY2Vzcy50aXRsZSA9ICdicm93c2VyJztcbnByb2Nlc3MuYnJvd3NlciA9IHRydWU7XG5wcm9jZXNzLmVudiA9IHt9O1xucHJvY2Vzcy5hcmd2ID0gW107XG5cbmZ1bmN0aW9uIG5vb3AoKSB7fVxuXG5wcm9jZXNzLm9uID0gbm9vcDtcbnByb2Nlc3MuYWRkTGlzdGVuZXIgPSBub29wO1xucHJvY2Vzcy5vbmNlID0gbm9vcDtcbnByb2Nlc3Mub2ZmID0gbm9vcDtcbnByb2Nlc3MucmVtb3ZlTGlzdGVuZXIgPSBub29wO1xucHJvY2Vzcy5yZW1vdmVBbGxMaXN0ZW5lcnMgPSBub29wO1xucHJvY2Vzcy5lbWl0ID0gbm9vcDtcblxucHJvY2Vzcy5iaW5kaW5nID0gZnVuY3Rpb24gKG5hbWUpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ3Byb2Nlc3MuYmluZGluZyBpcyBub3Qgc3VwcG9ydGVkJyk7XG59O1xuXG4vLyBUT0RPKHNodHlsbWFuKVxucHJvY2Vzcy5jd2QgPSBmdW5jdGlvbiAoKSB7IHJldHVybiAnLycgfTtcbnByb2Nlc3MuY2hkaXIgPSBmdW5jdGlvbiAoZGlyKSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKCdwcm9jZXNzLmNoZGlyIGlzIG5vdCBzdXBwb3J0ZWQnKTtcbn07XG4iXX0=
