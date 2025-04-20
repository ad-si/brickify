import path from "path"

export default function (_request, response) {
  return response.render(path.join("app", "app"), {
    page: "editor",
    pageTitle: "editor",
  })
}
