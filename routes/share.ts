import type { Request, Response } from "express"
import * as urlSessions from "../src/server/urlSessions.js"

interface RequestWithSession extends Request {
  session?: { id: string };
}

export default function (request: RequestWithSession, response: Response) {
  if (request.session != null) {
    const id = urlSessions.generateShareId(request.session.id)
    return response.send(id)
  }
  else {
    return response.status(400)
      .send("400: You don't have a session cookie associated with you (yet)")
  }
}
