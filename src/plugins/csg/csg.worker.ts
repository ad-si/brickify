import {
  runCsgJob,
  clearCsgWorkerCache,
} from "./CsgWorkerJob"
import type { CsgJobInput, CsgJobResult } from "./CsgWorkerJob"

interface ExtractMessage {
  type: "extractCsg"
  requestId: number
  data: CsgJobInput
}

interface ClearCacheMessage {
  type: "clearCache"
}

type WorkerInMessage = ExtractMessage | ClearCacheMessage

interface FinishedReply {
  state: "finished"
  requestId: number
  data: CsgJobResult
}

interface ErrorReply {
  state: "error"
  requestId: number
  error: string
}

self.onmessage = (event: MessageEvent<WorkerInMessage>) => {
  const message = event.data

  if (message.type === "clearCache") {
    clearCsgWorkerCache()
    return
  }

  try {
    const result = runCsgJob(message.data)
    const reply: FinishedReply = {
      state: "finished",
      requestId: message.requestId,
      data: result,
    }
    self.postMessage(reply)
  }
  catch (err) {
    const reply: ErrorReply = {
      state: "error",
      requestId: message.requestId,
      error: err instanceof Error ? err.message : String(err),
    }
    self.postMessage(reply)
  }
}
