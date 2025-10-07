/// <reference types="node" />

/**
 * Environment variables injected at build time by esbuild
 * Add your custom environment variables here
 */
declare namespace NodeJS {
  interface ProcessEnv {
    readonly NODE_ENV: 'development' | 'production';
    // Add your custom environment variables here
    // readonly API_KEY?: string;
    // readonly API_URL?: string;
    // readonly ENABLE_DEBUG?: string;
    // readonly ENABLE_ANALYTICS?: string;
  }
}
