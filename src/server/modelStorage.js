let createCacheDirectory
import fs from "fs"
import fsp from "fs-promise"
import mkdirp from "mkdirp"
import { md5 } from "blueimp-md5"
import log from "winston"

const cacheDirectory = "modelCache/";

// create cache directory on require (read: on server startup)
(createCacheDirectory = () => mkdirp(cacheDirectory, (error) => {
  if (error != null) {
    return log.warn("Unable to create cache directory: " + error)
  }
}))()

// API

export function exists (hash) {
  if (!checkHash(hash)) {
    return Promise.reject("invalid hash")
  }

  return new Promise((resolve, reject) => fs.exists(cacheDirectory + hash, (exists) => {
    if (exists) {
      return resolve(hash)
    }
    else {
      return reject(hash)
    }
  }))
}

export function get (hash) {
  if (!checkHash(hash)) {
    return Promise.reject("invalid hash")
  }

  return fsp.readFile(cacheDirectory + hash)
}

export function store (hash, model) {
  if (!checkHash(hash)) {
    return Promise.reject("invalid hash")
  }

  if (hash !== md5(model)) {
    return Promise.reject("wrong hash")
  }

  return fsp.writeFile(cacheDirectory + hash, model)
    .then(() => hash)
}

// checks if the hash has the correct format
var checkHash = function (hash) {
  const p = /^[0-9a-z]{32}$/
  return p.test(hash)
}
