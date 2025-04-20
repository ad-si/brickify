let loadSamples
import fsp from "fs-promise"
import yaml from "js-yaml"
import log from "winston"

const samplesDirectory = "modelSamples/"

const samples = {};

// load samples on require (read: on server startup)
(loadSamples = function () {
  fsp
    .readdirSync(samplesDirectory)
    .filter(file => file.endsWith(".yaml"))
    .map(file => yaml.load(fsp.readFileSync(samplesDirectory + file)))
    .forEach(sample => samples[sample.name] = sample)
  return log.info("Sample models loaded")
})()

// API

export default function exists (name) {
  if (samples[name] != null) {
    return Promise.resolve(name)
  }
  else {
    return Promise.reject(name)
  }
}

export default function get (name) {
  if (samples[name] != null) {
    return fsp.readFile(samplesDirectory + name)
  }
  else {
    return Promise.reject(name)
  }
}

export default function getSamples () {
  return Object.keys(samples)
    .map(key => samples[key])
    .sort((a, b) => a.printTime - b.printTime)
}
