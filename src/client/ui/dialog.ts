export interface DialogButton {
  label: string
  className?: string
  // Return false to keep the dialog open; otherwise it closes after the callback.
  callback?: () => boolean | void
}

export interface DialogOptions {
  title?: string
  message?: string
  buttons?: DialogButton[]
  closeButton?: boolean
  // Called when the user dismisses the dialog via Esc or the X close button.
  onCancel?: () => void
}

export interface AlertOptions {
  title?: string
  message: string
}

const buildHeader = (title: string, onClose: () => void): HTMLElement => {
  const header = document.createElement("div")
  header.className = "appDialog-header"

  const close = document.createElement("button")
  close.type = "button"
  close.className = "appDialog-close"
  close.setAttribute("aria-label", "Close")
  close.innerHTML = "&times;"
  close.addEventListener("click", onClose)

  const h = document.createElement("h4")
  h.className = "appDialog-title"
  h.textContent = title

  header.append(close, h)
  return header
}

export function show (options: DialogOptions): HTMLDialogElement {
  const el = document.createElement("dialog")
  el.className = "appDialog"

  let cancelled = true

  const dismiss = () => {
    cancelled = true
    el.close()
  }

  if (options.title != null || options.closeButton) {
    el.appendChild(buildHeader(options.title ?? "", dismiss))
  }

  if (options.message != null) {
    const body = document.createElement("div")
    body.className = "appDialog-body"
    body.innerHTML = options.message
    el.appendChild(body)
  }

  const buttons = options.buttons ?? []
  if (buttons.length > 0) {
    const footer = document.createElement("div")
    footer.className = "appDialog-footer"
    for (const btn of buttons) {
      const b = document.createElement("button")
      b.type = "button"
      b.className = `btn ${btn.className ?? "btn-default"}`
      b.textContent = btn.label
      b.addEventListener("click", () => {
        const result = btn.callback?.()
        if (result !== false) {
          cancelled = false
          el.close()
        }
      })
      footer.appendChild(b)
    }
    el.appendChild(footer)
  }

  el.addEventListener("cancel", (event) => {
    event.preventDefault()
    dismiss()
  })

  el.addEventListener("close", () => {
    if (cancelled) options.onCancel?.()
    el.remove()
  })

  document.body.appendChild(el)
  el.showModal()
  return el
}

export function alert (options: AlertOptions | string): HTMLDialogElement {
  const opts: AlertOptions = typeof options === "string" ? { message: options } : options
  const dialogOpts: DialogOptions = {
    message: opts.message,
    buttons: [{ label: "OK", className: "btn-primary" }],
  }
  if (opts.title != null) dialogOpts.title = opts.title
  return show(dialogOpts)
}

export function confirm (
  message: string,
  callback: (result: boolean) => void,
): HTMLDialogElement {
  let answered = false
  return show({
    message,
    buttons: [
      {
        label: "Cancel",
        className: "btn-default",
        callback: () => {
          answered = true
          callback(false)
        },
      },
      {
        label: "OK",
        className: "btn-primary",
        callback: () => {
          answered = true
          callback(true)
        },
      },
    ],
    onCancel: () => {
      if (!answered) callback(false)
    },
  })
}

export function hideAll (): void {
  document.querySelectorAll<HTMLDialogElement>("dialog.appDialog[open]")
    .forEach((d) => { d.close() })
}
