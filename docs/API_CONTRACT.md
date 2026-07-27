# MediaLab API contract

Base URLs:

- iOS simulator: `http://localhost:8080`
- Android emulator: `http://10.0.2.2:8080`

All JSON is UTF-8. Every response includes `X-Request-Id`. Development CORS is
enabled.

## `GET /health`

Returns `200`:

```json
{"status":"ok","service":"medialab-api","version":1}
```

## `GET /v1/items`

Query parameters:

- `query` — case-insensitive title/tag filter.
- `cursor` — opaque cursor returned by the prior page.
- `limit` — `1...20`, default `10`.
- `chaos` — `0...3`; adds deterministic latency and, at level 3, periodic 503s.

Returns `200`:

```json
{
  "items": [{
    "id": "aurora",
    "title": "Aurora Timelapse",
    "summary": "Night sky field capture",
    "kind": "video",
    "tags": ["night", "motion"],
    "durationSeconds": 15,
    "imageURL": "http://localhost:8080/v1/media/aurora/poster.svg",
    "videoURL": "http://localhost:8080/v1/media/aurora/video.mp4",
    "updatedAt": "2026-07-27T06:00:00.000Z",
    "byteSize": 2498125,
    "checksum": "demo-aurora-v1"
  }],
  "nextCursor": null,
  "serverTime": "2026-07-27T06:00:00.000Z"
}
```

URLs use the request's `Host`, so each emulator receives reachable URLs.

## `GET /v1/media/:id/poster.svg`

Returns a deterministic SVG poster with `ETag` and cache headers. Honors
`If-None-Match` with `304`.

## `GET /v1/media/:id/video.mp4`

Streams a short public sample video through the local backend and caches it on
disk. Supports `Range`, `206`, `Content-Range`, and `Accept-Ranges: bytes`.
The first request needs internet access; later requests use `backend/.cache`.

## Chaos and deterministic testing

Either pass `?chaos=N` or the `X-Chaos-Level: N` header:

- `0`: no artificial behavior.
- `1`: 150 ms latency.
- `2`: 600 ms latency.
- `3`: 900 ms latency; every fifth JSON request returns `503`.
