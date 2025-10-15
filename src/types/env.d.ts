/// <reference types="node" />

/**
 * Environment variables injected at build time by esbuild
 * Add your custom environment variables here
 */
declare namespace NodeJS {
  interface ProcessEnv {
    readonly NODE_ENV: "development" | "production";
    readonly BUILD_ENV: "development" | "preview" | "production";
    readonly BUILD_TS: string;
  }
}

export global {}
