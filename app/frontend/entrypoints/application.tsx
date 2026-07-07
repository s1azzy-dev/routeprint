import { createInertiaApp } from "@inertiajs/react"

void createInertiaApp({
  pages: "../pages",
  strictMode: true,
  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => ({ queryStringArrayFormat: "brackets" }),
  },
})
