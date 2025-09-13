import fsp from "fs-promise"
import yaml from "js-yaml"
import log from "winston"


const samplesDirectory = "modelSamples/"

let samples = null


export function loadSamples () {
  if (samples !== null) {
    return samples
  }

  samples = {}

  fsp
    .readdirSync(samplesDirectory)
    .filter(file => file.endsWith(".yaml"))
    .map(file => yaml.load(fsp.readFileSync(samplesDirectory + file)))
    .forEach(sample => samples[sample.name] = sample)

  log.info("Sample models loaded")

  return samples
}


export function exists (name) {
  if (samples[name] != null) {
    return Promise.resolve(name)
  }
  else {
    return Promise.reject(name)
  }
}


export function get (name) {
  if (samples[name] != null) {
    return fsp.readFile(samplesDirectory + name)
  }
  else {
    return Promise.reject(name)
  }
}


export function getSamples () {
  return Object.keys(loadSamples())
    .map(key => samples[key])
    .sort((a, b) => a.printTime - b.printTime)
}
