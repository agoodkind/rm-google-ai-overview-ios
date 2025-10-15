const normalizeDevHost = (url: string) => {
  // Replace 0.0.0.0 with localhost for macOS sandbox compatibility
  return url.replace("://0.0.0.0:", "://localhost:");
};

export const testLocalhostConnect = async (baseUrl: string) => {
  try {
    const normalizedUrl = normalizeDevHost(baseUrl);
    const resp = await fetch(normalizedUrl, { method: "HEAD" });
    return resp.ok;
  } catch {
    return false;
  }
};
