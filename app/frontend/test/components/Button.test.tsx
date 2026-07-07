import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { Button } from "../../components/ui/button"
import { checkAccessibility } from "../accessibility"

describe("Button", () => {
  it("renders the accessible button contract", async () => {
    const { container } = render(<Button>Save flight</Button>)

    expect(screen.getByRole("button", { name: "Save flight" })).toBeVisible()
    await expect(
      checkAccessibility(container, {
        rules: { "color-contrast": { enabled: false } },
      }),
    ).resolves.toHaveProperty("violations", [])
  })
})
