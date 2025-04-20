/*
 * Generator for unique alphanumeric identifiers
 *
 * @module idGenerator
 */

const chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

const pattern = length => new RegExp(`^[${chars}]{${length}}$`)

const acceptAllFilter = () => true

/*
 * Generates a unique alphanumeric identifier
 *
 * @param {Function} filter a function that returns false for existent ids and
 *   true for unique ones.
 * @param {Number} length the number of characters in the id
 * @return {String} id
 *
 * @memberOf idGenerator
 */
export function generate (filter, length) {
  if (filter == null) {
    filter = acceptAllFilter
  }
  if (length == null) {
    length = 8
  }
  const generate = function () {
    let id = ""
    for (let i = 0, end = length; i < end; i++) {
      const index = Math.floor(Math.random() * chars.length)
      id += chars[index]
    }
    return id
  }

  const maxNumberOfTries = Math.pow(chars.length, length)

  for (let i = 0, end = maxNumberOfTries; i <= end; i++) {
    var id
    if (filter(id = generate())) {
      return id
    }
  }

  return null // no id could be found that was accepted by the filter
}

/*
 * Checks an identifier for syntactical correctness
 *
 * @param {String} id the identifier
 * @param {Number} length the required length of the identifier
 * @return {Boolean} true/false depending on the correctness of the identifier
 *
 * @memberOf idGenerator
 */
export function check (id, length) {
  if (length == null) {
    length = 8
  }
  return pattern(length)
    .test(id)
}
