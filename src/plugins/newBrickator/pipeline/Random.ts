let seed = 42
let usePseudoRandomVal = false

export const setSeed = (number: number): number => seed = number

export const getSeed = (): number => seed

export function usePseudoRandom(bool: boolean): void {
  usePseudoRandomVal = bool
}

export function next(max: number): number {
  if (usePseudoRandomVal) {
    const newSeed = ((499 * seed) + 167) % 99991
    seed = newSeed
    return seed % max
  }

  return Math.floor(Math.random() * max)
}
