import path from "path"
import type { Request, Response } from "express"

export default function (_request: Request, response: Response) {
  response.render(path.join("app", "app"), {
    page: "editor",
    pageTitle: "editor",
  })
}
