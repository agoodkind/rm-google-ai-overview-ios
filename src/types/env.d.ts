/// <reference types="node" />

/**
 * Environment variables injected at build time by esbuild
 * Add your custom environment variables here
 */
declare namespace NodeJS {
  interface ProcessEnv {
    readonly CONFIGURATION: "Debug" | "Preview" | "Release";
    readonly BUILD_TS: string;
  }
}

export global {}
