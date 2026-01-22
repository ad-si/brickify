/*
 * Base class to describe a part (in terms of special functionality) of a shader
 */
export default class ShaderPart {
  getVertexVariables () {
    return ""
  }

  getVertexPreMain () {
    return ""
  }

  getVertexInMain () {
    return ""
  }

  getFragmentVariables () {
    return ""
  }

  getFragmentPreMain () {
    return ""
  }

  getFragmentInMain () {
    return ""
  }
}
