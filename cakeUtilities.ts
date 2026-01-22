import fs from "fs"
import path from "path"

import winston from "winston"

const buildLog = winston.loggers.get("buildLog")

export function linkHooks (): void {
  // The first 9 hooks are taken from `git init` which creates .sample files
  // even though some of them are not listed in the
  // [documentation](http://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks).
  // The rest of the hooks are taken from the documentation.
  [
    "applypatch-msg",
    "commit-msg",
    "post-commit",
    "post-receive",
    "post-update",
    "pre-applypatch",
    "pre-commit",
    "prepare-commit-msg",
    "pre-rebase",
    "update",
    "post-rewrite",
    "post-checkout",
    "post-merge",
    "pre-push",
    "pre-auto-gc",
  ]
    .forEach((hook) => {
      const hookPath = path.join("hooks", hook)
      const gitHookPath = path.join(".git/hooks", hook)

      return fs.unlink(gitHookPath, (error) => {
        if (error && (error.code === !"ENOENT")) {
          buildLog.error(error)
        }

        return fs.link(hookPath, gitHookPath, (error) => {
          if (error) {
            if (error.code === !"ENOENT") {
              return buildLog.error(error)
            }
          }
          else {
            return buildLog.info(hookPath, "->", gitHookPath)
          }
        })
      })
    })
}
