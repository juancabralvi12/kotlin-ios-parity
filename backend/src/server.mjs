import http from "node:http";
import { mkdir, stat, writeFile } from "node:fs/promises";
import { createReadStream } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { catalog, publicItem } from "./catalog.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const cacheDir = join(__dirname, "..", ".cache");
const port = Number(process.env.PORT || 8080);
const host = process.env.HOST || "0.0.0.0";
const sampleVideo = "https://cdn.truefilesize.com/mp4/sample-1mb.mp4";
let sequence = 0;
let jsonRequestCount = 0;

const sleep = (milliseconds) => new Promise((resolve) => setTimeout(resolve, milliseconds));

function originFor(request) {
  const protocol = request.headers["x-forwarded-proto"] || "http";
  return `${protocol}://${request.headers.host || `localhost:${port}`}`;
}

function commonHeaders(requestId, extra = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, X-Chaos-Level",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "X-Request-Id": requestId,
    ...extra
  };
}

function sendJson(response, status, body, requestId) {
  const payload = JSON.stringify(body);
  response.writeHead(status, commonHeaders(requestId, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(payload),
    "Cache-Control": "no-store"
  }));
  response.end(payload);
}

function errorBody(code, message) {
  return { error: { code, message } };
}

function posterSvg(item) {
  const [accent, secondary, background] = item.palette;
  const duration = item.durationSeconds ? `${item.durationSeconds}s clip` : "still image";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="720" viewBox="0 0 1200 720">
  <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="${background}"/><stop offset="1" stop-color="${secondary}"/></linearGradient></defs>
  <rect width="1200" height="720" fill="url(#g)"/>
  <circle cx="930" cy="105" r="270" fill="${accent}" opacity=".24"/>
  <circle cx="190" cy="650" r="390" fill="${secondary}" opacity=".3"/>
  <path d="M0 540 Q240 380 440 520 T840 475 T1200 430 V720 H0Z" fill="${background}" opacity=".6"/>
  <text x="72" y="100" fill="${accent}" font-family="system-ui,sans-serif" font-size="26" font-weight="700" letter-spacing="5">MEDIALAB / ${item.id.toUpperCase()}</text>
  <text x="72" y="570" fill="white" font-family="system-ui,sans-serif" font-size="72" font-weight="750">${item.title}</text>
  <text x="76" y="625" fill="white" opacity=".72" font-family="system-ui,sans-serif" font-size="28">${item.summary} · ${duration}</text>
  ${item.kind === "video" ? `<circle cx="1080" cy="600" r="58" fill="white" opacity=".92"/><path d="M1065 566 L1110 600 L1065 634Z" fill="${background}"/>` : ""}
</svg>`;
}

async function ensureVideo() {
  await mkdir(cacheDir, { recursive: true });
  const path = join(cacheDir, "sample.mp4");
  try {
    const info = await stat(path);
    if (info.size > 1000) return path;
  } catch {}

  const response = await fetch(sampleVideo);
  if (!response.ok) throw new Error(`Upstream video returned ${response.status}`);
  const bytes = Buffer.from(await response.arrayBuffer());
  await writeFile(path, bytes);
  return path;
}

async function serveVideo(request, response, requestId) {
  let path;
  try {
    path = await ensureVideo();
  } catch (error) {
    sendJson(response, 502, errorBody("upstream_unavailable", error.message), requestId);
    return;
  }
  const { size } = await stat(path);
  const range = request.headers.range;
  if (!range) {
    response.writeHead(200, commonHeaders(requestId, {
      "Content-Type": "video/mp4",
      "Content-Length": size,
      "Accept-Ranges": "bytes",
      "Cache-Control": "public, max-age=3600"
    }));
    createReadStream(path).pipe(response);
    return;
  }

  const match = /^bytes=(\d*)-(\d*)$/.exec(range);
  if (!match) {
    response.writeHead(416, commonHeaders(requestId, { "Content-Range": `bytes */${size}` }));
    response.end();
    return;
  }
  const start = match[1] ? Number(match[1]) : 0;
  const end = match[2] ? Math.min(Number(match[2]), size - 1) : size - 1;
  if (start > end || start >= size) {
    response.writeHead(416, commonHeaders(requestId, { "Content-Range": `bytes */${size}` }));
    response.end();
    return;
  }
  response.writeHead(206, commonHeaders(requestId, {
    "Content-Type": "video/mp4",
    "Content-Length": end - start + 1,
    "Content-Range": `bytes ${start}-${end}/${size}`,
    "Accept-Ranges": "bytes",
    "Cache-Control": "public, max-age=3600"
  }));
  createReadStream(path, { start, end }).pipe(response);
}

export function createServer() {
  return http.createServer(async (request, response) => {
    const requestId = `req-${Date.now().toString(36)}-${(++sequence).toString(36)}`;
    if (request.method === "OPTIONS") {
      response.writeHead(204, commonHeaders(requestId));
      response.end();
      return;
    }
    if (request.method !== "GET") {
      sendJson(response, 405, errorBody("method_not_allowed", "Only GET is supported"), requestId);
      return;
    }

    const url = new URL(request.url, originFor(request));
    const chaos = Math.max(0, Math.min(3, Number(request.headers["x-chaos-level"] || url.searchParams.get("chaos") || 0)));
    if (chaos) await sleep([0, 150, 600, 900][chaos]);

    if (url.pathname === "/health") {
      sendJson(response, 200, { status: "ok", service: "medialab-api", version: 1 }, requestId);
      return;
    }

    const mediaMatch = /^\/v1\/media\/([^/]+)\/(poster\.svg|video\.mp4)$/.exec(url.pathname);
    if (mediaMatch) {
      const item = catalog.find((candidate) => candidate.id === mediaMatch[1]);
      if (!item) {
        sendJson(response, 404, errorBody("not_found", "Media item not found"), requestId);
        return;
      }
      if (mediaMatch[2] === "poster.svg") {
        const etag = `"${item.checksum}"`;
        if (request.headers["if-none-match"] === etag) {
          response.writeHead(304, commonHeaders(requestId, { ETag: etag }));
          response.end();
          return;
        }
        const svg = posterSvg(item);
        response.writeHead(200, commonHeaders(requestId, {
          "Content-Type": "image/svg+xml; charset=utf-8",
          "Content-Length": Buffer.byteLength(svg),
          "Cache-Control": "public, max-age=300",
          ETag: etag
        }));
        response.end(svg);
        return;
      }
      if (item.kind !== "video") {
        sendJson(response, 404, errorBody("not_found", "This item has no video"), requestId);
        return;
      }
      await serveVideo(request, response, requestId);
      return;
    }

    if (url.pathname === "/v1/items") {
      jsonRequestCount += 1;
      if (chaos === 3 && jsonRequestCount % 5 === 0) {
        sendJson(response, 503, errorBody("chaos_unavailable", "Injected retryable failure"), requestId);
        return;
      }
    }

    if (url.pathname === "/v1/items") {
      const query = (url.searchParams.get("query") || "").trim().toLowerCase();
      const limit = Math.max(1, Math.min(20, Number(url.searchParams.get("limit") || 10)));
      const offset = Math.max(0, Number(url.searchParams.get("cursor") || 0));
      const matches = catalog.filter((item) =>
        !query || `${item.title} ${item.summary} ${item.tags.join(" ")}`.toLowerCase().includes(query)
      );
      const page = matches.slice(offset, offset + limit);
      sendJson(response, 200, {
        items: page.map((item) => publicItem(item, originFor(request))),
        nextCursor: offset + limit < matches.length ? String(offset + limit) : null,
        serverTime: new Date().toISOString()
      }, requestId);
      return;
    }

    sendJson(response, 404, errorBody("not_found", "Route not found"), requestId);
  });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const server = createServer();
  server.listen(port, host, () => {
    console.log(`MediaLab API listening on http://localhost:${port}`);
  });
}
