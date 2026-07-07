import axe, { type AxeResults, type RunOptions } from "axe-core"

export function checkAccessibility(
  container: Element,
  options?: RunOptions,
): Promise<AxeResults> {
  return options ? axe.run(container, options) : axe.run(container)
}
