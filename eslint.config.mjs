import eslintConfigPrettier from "eslint-config-prettier"
import jsxA11y from "eslint-plugin-jsx-a11y"
import react from "eslint-plugin-react"
import reactHooks from "eslint-plugin-react-hooks"
import tseslint from "typescript-eslint"

export default tseslint.config(
  {
    ignores: [
      "app/assets/builds/**",
      "app/javascript/**",
      "coverage/**",
      "eslint.config.mjs",
      "**/*.cjs",
      "**/*.js",
      "**/*.mjs",
      "node_modules/**",
      "public/vite*/**",
      "tmp/**",
      "vendor/**",
    ],
  },
  ...tseslint.configs.recommendedTypeChecked,
  {
    files: ["app/frontend/**/*.{ts,tsx}", "vite.config.ts"],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  {
    files: ["app/frontend/**/*.tsx"],
    ...react.configs.flat.recommended,
    ...react.configs.flat["jsx-runtime"],
    ...reactHooks.configs.flat.recommended,
    ...jsxA11y.flatConfigs.recommended,
    settings: {
      react: {
        version: "detect",
      },
    },
  },
  eslintConfigPrettier,
)
