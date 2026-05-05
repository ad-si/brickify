import {
  runCsgJob,
  clearCsgWorkerCache,
} from "./CsgWorkerJob.js"
import type { CsgJobInput, CsgJobResult } from "./CsgWorkerJob.js"

declare const IS_STATIC_BUILD: boolean | undefined

interface PendingRequest {
  resolve: (result: CsgJobResult) => void
  reject: (error: Error) => void
}

interface WorkerReply {
  requestId: number
  state: "finished" | "error"
  data?: CsgJobResult
  error?: string
}

export default class CsgWorkerClient {
  private worker: Worker | null = null
  private pending = new Map<number, PendingRequest>()
  private nextRequestId = 0
  private workerUnavailable = false

  extractCsg (input: CsgJobInput): Promise<CsgJobResult> {
    const worker = this._getWorker()
    if (!worker) {
      try {
        return Promise.resolve(runCsgJob(input))
      }
      catch (err) {
        return Promise.reject(err instanceof Error ? err : new Error(String(err)))
      }
    }

    return new Promise<CsgJobResult>((resolve, reject) => {
      const requestId = ++this.nextRequestId
      this.pending.set(requestId, { resolve, reject })
      worker.postMessage({
        type: "extractCsg",
        requestId,
        data: input,
      })
    })
  }

  clearCache () {
    if (this.worker) {
      this.worker.postMessage({ type: "clearCache" })
    }
    else {
      clearCsgWorkerCache()
    }
  }

  terminate () {
    if (this.worker) {
      this.worker.terminate()
      this.worker = null
    }
    this.pending.clear()
  }

  private _getWorker (): Worker | null {
    if (this.workerUnavailable) return null
    if (this.worker != null) return this.worker
    if (typeof window === "undefined" || typeof Worker === "undefined") {
      this.workerUnavailable = true
      return null
    }
    try {
      const workerPath = (typeof IS_STATIC_BUILD !== "undefined" && IS_STATIC_BUILD)
        ? "./js/workers/csg.worker.js"
        : "/js/workers/csg.worker.js"
      const worker = new Worker(workerPath)
      worker.addEventListener("message", this._handleMessage)
      worker.addEventListener("error", this._handleError)
      this.worker = worker
      return worker
    }
    catch {
      this.workerUnavailable = true
      return null
    }
  }

  private _handleMessage = (event: MessageEvent<WorkerReply>) => {
    const { requestId, state, data, error } = event.data
    const pending = this.pending.get(requestId)
    if (!pending) return
    this.pending.delete(requestId)
    if (state === "finished" && data) {
      pending.resolve(data)
    }
    else {
      pending.reject(new Error(error ?? "CSG worker error"))
    }
  }

  private _handleError = (event: Event) => {
    const error = new Error((event as ErrorEvent).message || "CSG worker error")
    for (const pending of this.pending.values()) {
      pending.reject(error)
    }
    this.pending.clear()
  }
}
