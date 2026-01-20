import path from "path"
import { getSamples } from "../src/server/modelSamples.js"

const samples = getSamples()

export function getLandingpage (_request, response) {
  return response.render(
    path.join("landingpage", "landingpage"),
    {
      page: "landing",
      samples,
    },
  )
}

export function getContribute (_request, response) {
  return response.render(
    path.join("landingpage", "contribute"),
    { pageTitle: "Contribute" },
  )
}

export function getTeam (_request, response) {
  return response.render(
    path.join("landingpage", "team"),
    { pageTitle: "Team" },
  )
}

export function getExamples (_request, response) {
  return response.render(
    path.join("landingpage", "examples"),
    {
      page: "landing",
      pageTitle: "Examples",
      samples,
    },
  )
}
