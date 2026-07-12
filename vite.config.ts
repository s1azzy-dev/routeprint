import inertia from "@inertiajs/vite"
import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import RubyPlugin from "vite-plugin-ruby"
import { defineConfig } from "vitest/config"

const viteServerPort = 3036
const viteClientPort = Number(
  process.env.VITE_HMR_CLIENT_PORT ?? viteServerPort,
)

export default defineConfig({
  plugins: [inertia({ ssr: false }), react(), tailwindcss(), RubyPlugin()],
  server: {
    ws: {
      clientPort: viteClientPort,
      host: "localhost",
      port: viteServerPort,
    },
  },
  test: {
    environment: "jsdom",
    reporters: ["minimal"],
    setupFiles: ["./test/setup.ts"],
    coverage: {
      provider: "v8",
      reporter: ["text-summary", "html"],
      reportsDirectory: "../../coverage/frontend",
      include: ["**/*.{ts,tsx}"],
      exclude: [
        "test/**",
        "**/*.d.ts",
        "**/*.test.{ts,tsx}",
        "components/routeprint/route-map.tsx",
      ],
    },
  },
})
