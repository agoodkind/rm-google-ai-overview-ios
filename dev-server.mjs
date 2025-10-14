#!/usr/bin/env node
// Lightweight dev server with esbuild watch + SSE reload.
// Usage: node dev-server.mjs [--port 5173]
import { context } from "esbuild";
import { readFile } from "node:fs/promises";
import http from "node:http";
import { extname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { entries as configEntries } from "./build.config.mjs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = resolve(__filename, "..");
const port = Number(process.env.PORT) || Number(process.argv[2]) || 5173;

const clients = new Set();
function pushReload() {
  const msg = `data: reload\n\n`;
  for (const res of clients) {
    res.write(msg);
  }
}

function sse(req, res) {
  res.writeHead(200, {
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
    "Access-Control-Allow-Origin": "*",
  });
  res.write("\n");
  clients.add(res);
  req.on("close", () => clients.delete(res));
}

const scriptEntry = configEntries.find((e) => e.name === "appView");
if (!scriptEntry) {
  console.error("appView entry not found");
  process.exit(1);
}

// Start esbuild in watch mode for appView + styles entries (reuse existing build logic by spawning build.mjs? simpler direct call).
const watchTargets = ["appView", "appStyles"];

async function startEsbuild() {
  const ctxs = [];
  for (const name of watchTargets) {
    const entry = configEntries.find((e) => e.name === name);
    if (!entry) continue;
    const outfile = resolve(__dirname, entry.output);
    const opts = {
      entryPoints: [resolve(__dirname, entry.input)],
      bundle: true,
      outfile,
      sourcemap: "inline",
      format: "iife",
      jsx: "automatic",
      minify: false,
      logLevel: "silent",
      define: {
        "process.env.BUILD_ENV": '"development"',
      },
      plugins: [
        {
          name: "notify",
          setup(build) {
            build.onEnd((r) => {
              if (r.errors.length === 0) pushReload();
            });
          },
        },
      ],
      loader: { ".png": "dataurl", ".css": "css" },
    };
    const ctx = await context(opts);
    await ctx.watch();
    ctxs.push(ctx);
  }
  console.log("Watching (dev server)");
  return ctxs;
}

function contentType(path) {
  switch (extname(path)) {
    case ".js":
      return "text/javascript";
    case ".css":
      return "text/css";
    case ".html":
      return "text/html";
    case ".png":
      return "image/png";
    default:
      return "application/octet-stream";
  }
}

const mainHtmlPath = resolve(
  __dirname,
  "xcode/Shared (App)/Resources/Base.lproj/Main.html",
);
const scriptOut = resolve(__dirname, scriptEntry.output);
const styleOut = resolve(__dirname, "xcode/Shared (App)/Resources/Style.css");

// Use external script to comply with strict CSP (no inline script needed)
const RELOAD_SNIPPET = `<script src="/__dev__/reload.js" defer></script>`;

http
  .createServer(async (req, res) => {
    if (req.url === "/__dev__/sse") return sse(req, res);
    if (req.url === "/__dev__/reload.js") {
      const js =
        "const es=new EventSource('/__dev__/sse');es.onmessage=e=>{if(e.data==='reload')location.reload();};";
      res.writeHead(200, { "Content-Type": "text/javascript" });
      return res.end(js);
    }
    if (req.url === "/" || req.url === "/index.html") {
      let html = await readFile(mainHtmlPath, "utf8");
      // Inject reload snippet before closing body.
      html = html.replace("</body>", `${RELOAD_SNIPPET}</body>`);
      res.writeHead(200, { "Content-Type": "text/html" });
      return res.end(html);
    }
    if (req.url === "/Script.js") {
      const js = await readFile(scriptOut);
      res.writeHead(200, { "Content-Type": "text/javascript" });
      return res.end(js);
    }
    if (req.url === "/Style.css") {
      const css = await readFile(styleOut);
      res.writeHead(200, { "Content-Type": "text/css" });
      return res.end(css);
    }
    // allow icon and other static resources under Resources
    if (req.url && req.url.startsWith("/")) {
      const p = resolve(
        __dirname,
        "xcode/Shared (App)/Resources",
        "." + req.url,
      );
      try {
        const buf = await readFile(p);
        res.writeHead(200, { "Content-Type": contentType(p) });
        return res.end(buf);
      } catch {}
    }
    res.writeHead(404);
    res.end("Not found");
  })
  .listen(port, () => console.log(`Dev server http://localhost:${port}`));

await startEsbuild();
