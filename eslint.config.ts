import js from "@eslint/js";
import stylistic from "@stylistic/eslint-plugin";
import eslintPluginPrettierRecommended from "eslint-plugin-prettier/recommended";
import { defineConfig, globalIgnores } from "eslint/config";
import globals from "globals";
import tseslint from "typescript-eslint";

const baseConfig = defineConfig([
  {
    plugins: {
      "@stylistic": stylistic,
    },
    rules: {
      "sort-imports": ["warn"],
      "@stylistic/arrow-parens": ["error"],
      curly: ["error", "all"],
      "max-len": [
        "warn",
        {
          code: 80,
          ignoreUrls: true,
          ignoreStrings: true,
          ignoreTemplateLiterals: true,
          ignoreRegExpLiterals: true,
        },
      ],
      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],
    },
  },
]);

export default defineConfig([
  globalIgnores(["dist", "out", "node_modules", "xcode", "scripts/.build"]),
  js.configs.recommended,
  ...tseslint.configs.recommended,
  eslintPluginPrettierRecommended,
  ...baseConfig,
  {
    files: ["src/**/*.{ts,tsx}"],
    languageOptions: {
      ecmaVersion: 2020,
      globals,
      parser: tseslint.parser,
      parserOptions: {
        project: "./tsconfig.app.json",
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    settings: {
      react: {
        version: "detect",
      },
    },
  },
  {
    files: ["esbuild.mjs", "esbuild.config.mjs", "eslint.config.ts"],
    languageOptions: {
      globals: globals.node,
      parserOptions: {
        project: "./tsconfig.node.json",
      },
    },
  },
]);
