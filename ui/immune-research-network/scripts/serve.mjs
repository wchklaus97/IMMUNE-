import { createReadStream, existsSync, statSync } from "node:fs";
import { pipeline } from "node:stream/promises";
import { extname, isAbsolute, join, normalize, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { createServer } from "node:http";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(__dirname, "..");
const HOST = "127.0.0.1";
const PORT = Number(process.env.PORT || 4173);

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".json": "application/json; charset=utf-8",
  ".mjs": "text/javascript; charset=utf-8"
};

function isInsideRoot(target) {
  const rel = relative(ROOT, target);
  return rel !== "" && !rel.startsWith("..") && !isAbsolute(rel);
}

function safePath(urlPath) {
  const decoded = decodeURIComponent((urlPath || "/").split("?")[0]);
  const relativePath = decoded.replace(/^\/+/, "");
  if (!relativePath) return join(ROOT, "index.html");
  const absolute = normalize(resolve(ROOT, relativePath));
  if (!isInsideRoot(absolute)) return null;
  return absolute;
}

const server = createServer(async (req, res) => {
  try {
    let target = safePath(req.url || "/");
    if (!target) {
      res.writeHead(403);
      res.end("Forbidden");
      return;
    }
    if (target.endsWith("\\") || target.endsWith("/")) {
      target = join(target, "index.html");
    }
    if (!existsSync(target) && (req.url === "/" || req.url === "")) {
      target = join(ROOT, "index.html");
    }
    if (!existsSync(target)) {
      res.writeHead(404);
      res.end("Not Found");
      return;
    }
    const info = statSync(target);
    if (info.isDirectory()) {
      target = join(target, "index.html");
      if (!existsSync(target)) {
        res.writeHead(404);
        res.end("Not Found");
        return;
      }
    }
    const type = MIME[extname(target).toLowerCase()] || "application/octet-stream";
    const size = statSync(target).size;
    res.writeHead(200, {
      "Content-Type": type,
      "Content-Length": size,
      "Cache-Control": "no-cache"
    });
    if (req.method === "HEAD") {
      res.end();
      return;
    }
    await pipeline(createReadStream(target), res);
  } catch (error) {
    if (!res.headersSent) {
      res.writeHead(500);
      res.end(String(error));
    }
  }
});

server.listen(PORT, HOST, () => {
  console.log(`IMMUNE research network dev server: http://${HOST}:${PORT}/`);
});
