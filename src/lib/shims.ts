if (DEV_MODE) {
  const logLabel = '[rm-google-ai-overview-ios]';

  // Bind the timestamp object - toString() gets called at log-time
  console.log = console.log.bind(console, logLabel);
  console.warn = console.warn.bind(console, logLabel);
  console.error = console.error.bind(console, logLabel);
  console.debug = console.debug.bind(console, logLabel);

  console.warn('Debug mode is enabled');
  console.warn('Build time: ', process.env.BUILD_TS);
  console.warn('Current time: ', new Date().toString());
}
