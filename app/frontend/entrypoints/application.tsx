import { createInertiaApp } from "@inertiajs/react"

import AppShell from "@/components/routeprint/app-shell"

void createInertiaApp({
  pages: "../pages",
  layout: () => AppShell,
  strictMode: true,
  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => ({ queryStringArrayFormat: "brackets" }),
  },
})
