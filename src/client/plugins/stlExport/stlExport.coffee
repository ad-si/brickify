common = require '../../common/pluginCommon'

module.exports.pluginName = 'stl Export Plugin'
module.exports.category = common.CATEGORY_EXPORT

#Called when the plugin is initialized.
#You should create your plugin dependent datastructures here
module.exports.init = (globalConfig, stateSync) ->
    console.log 'stl Export Plugin initialization'

#Called when the plugin is initialized.
#You should create your visible geometry
#and add it as a child to the node here
module.exports.init3d = (threejsNode) ->
    console.log 'stl Export Plugin initializes 3d - nothing to do'

# Is called when the server changes the state,
# where state is the new state and delta the difference to the old state
module.exports.handleStateChange = (delta, state) ->
    console.log 'stl Export Plugin state change - nothing to do'

#if set to true, update3D() will be called every frame
#consider setting it to false to improve performance
module.exports.needs3dAnimation = false

# Is called every frame
# Use it for animations or updates that have to be performed every frame
module.exports.update3D = () ->


#helper methods
stringifyVector = (vec) ->
  "" + vec.x + " " + vec.y + " " + vec.z

stringifyVertex = (vec) ->
  "vertex " + stringifyVector(vec) + " \n"


#main method creating an ASCII .stl string
generateSTL = (threejsGeometry) ->
    vertices = threejsGeometry.vertices
    faces = threejsGeometry.faces
    stl = "solid pixel"
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
saveSTL = (geometry) ->
    stlString = generateSTL(geometry)
    blob = new Blob([stlString], type: "text/plain" )
    saveAs blob, "pixel_printer.stl"
    return

