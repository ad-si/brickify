let seed = 42
let usePseudoRandomVal = false

export const setSeed = number => seed = number

export const getSeed = () => seed

export function usePseudoRandom (bool) {
  usePseudoRandomVal = bool
}

export function next (max) {
  if (usePseudoRandomVal) {
    const newSeed = ((499 * seed) + 167) % 99991
    seed = newSeed
    return seed % max
  }

  return Math.floor(Math.random() * max)
}
