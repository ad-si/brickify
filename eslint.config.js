import eslintConfJs from "eslint-config-javascript"

export default [
  ...eslintConfJs,
  {
    ignores: ["public/**/*.js"],
  },
]
