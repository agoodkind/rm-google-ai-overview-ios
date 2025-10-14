export const isDev = process.env.BUILD_ENV === 'development';
export const isTest = process.env.BUILD_ENV === 'testing';
export const isProd = process.env.BUILD_ENV === 'production';
export const buildTime = process.env.BUILD_TS;

if (isDev) {
  const logLabel = '[rm-google-ai-overview-ios]';

  // Bind the timestamp object - toString() gets called at log-time
  console.log = console.log.bind(console, logLabel);
  console.warn = console.warn.bind(console, logLabel);
  console.error = console.error.bind(console, logLabel);
  console.debug = console.debug.bind(console, logLabel);
}

export function log(
  level: 'log' | 'warn' | 'error' | 'debug',
  logFn: () => unknown,
) {
  if (isDev || level !== 'debug') {
    logFn();
  }
}
