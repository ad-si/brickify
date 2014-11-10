###
    #STL Export Plugin#

    Converts any ThreeJS geometry to ASCII-.stl data format
###

common = require '../../../common/pluginCommon'

module.exports.pluginName = 'stl Export Plugin'
module.exports.category = common.CATEGORY_EXPORT

# This plugin needs no initialization
module.exports.init = (globalConfig, stateSync) ->

module.exports.init3d = (threejsNode) ->

# This plugin performs no updates
module.exports.handleStateChange = (delta, state) ->
module.exports.needs3dAnimation = false
module.exports.update3D = () ->


#helper methods
stringifyVector = (vec) ->
  "" + vec.x + " " + vec.y + " " + vec.z

stringifyVertex = (vec) ->
  "vertex " + stringifyVector(vec) + " \n"


#main method creating an ASCII .stl string
generateAsciiStl = (threejsGeometry, filename) ->
    vertices = threejsGeometry.vertices
    faces = threejsGeometry.faces

    stl = "solid #{filename}"
    
    i = 0
    while i < faces.length
        stl += ("facet normal " + stringifyVector(faces[i].normal) + " \n")
        stl += ("outer loop \n")
        stl += stringifyVertex(vertices[faces[i].a])
        stl += stringifyVertex(vertices[faces[i].b])
        stl += stringifyVertex(vertices[faces[i].c])
        stl += ("endloop \n")
        stl += ("endfacet \n")
        i++
    stl += ("endsolid")
    stl

#method to save generated ASCII string to disk
module.exports.saveStl = (threejsGeometry, filename) ->
    stlString = generateAsciiStl(threejsGeometry)
    blob = new Blob([stlString], {type: "text/plain;charset=utf-8"})
    saveAs blob, filename
    return

