import path from "path"
import type { Request, Response } from "express"
import { getSamples } from "../src/server/modelSamples.js"

const samples = getSamples()

export function getLandingpage (_request: Request, response: Response) {
  response.render(
    path.join("landingpage", "landingpage"),
    {
      page: "landing",
      samples,
    },
  )
}

export function getContribute (_request: Request, response: Response) {
  response.render(
    path.join("landingpage", "contribute"),
    { pageTitle: "Contribute" },
  )
}

export function getTeam (_request: Request, response: Response) {
  response.render(
    path.join("landingpage", "team"),
    { pageTitle: "Team" },
  )
}

export function getExamples (_request: Request, response: Response) {
  response.render(
    path.join("landingpage", "examples"),
    {
      page: "landing",
      pageTitle: "Examples",
      samples,
    },
  )
}
