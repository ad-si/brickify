#!/usr/bin/env node

import { startServer } from "../src/server/main.js"

const args = process.argv.slice(2)

if (args.length === 0) {
  console.log(
    "No arguments provided." +
    "Please provide one of the following commands: help, start",
  )
  process.exit(1)
}

if (args.length > 1) {
  console.log(
    "Too many arguments provided." +
    "Please provide one of the following commands: help, start",
  )
  process.exit(1)
}

if (args[0] === "help") {
  console.log("Available commands: help, start")
  process.exit(0)
}

if (args[0] === "start") {
  console.log("Starting the server...")
  await startServer()
}
