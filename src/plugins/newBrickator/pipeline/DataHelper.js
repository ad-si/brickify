// Returns whether or not at least one element of the input
// array in not null/undefined
export function anyDefinedInArray (array) {
  return array.some(entry => entry != null)
}

// Returns the union of all sets in the argument
// input sets remain intact
export function union (arrayOfSets) {
  const union = new Set()
  for (const set of Array.from(arrayOfSets)) {
    set.forEach(element => union.add(element))
  }
  return union
}

// Returns the intersect of two sets
export function intersection (set1, set2) {
  const intersection = new Set()
  set1.forEach((element) => {
    if (set2.has(element)) {
      return intersection.add(element)
    }
  })
  return intersection
}

// Returns set1 \ set2
export function difference (set1, set2) {
  const difference = new Set()
  set1.forEach((element) => {
    if (!set2.has(element)) {
      return difference.add(element)
    }
  })
  return difference
}

export function smallestElement (set) {
  let min = null
  set.forEach((element) => {
    if (min == null) {
      min = element
    }
    if (element < min) {
      return min = element
    }
  })
  return min
}
