import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { createServer } from "./server.mjs";

let server;
let baseURL;

before(async () => {
  server = createServer();
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  baseURL = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve) => server.close(resolve));
});

test("health reports service status", async () => {
  const response = await fetch(`${baseURL}/health`);
  assert.equal(response.status, 200);
  assert.equal((await response.json()).status, "ok");
});

test("feed filters and emits request-local media URLs", async () => {
  const response = await fetch(`${baseURL}/v1/items?query=night`);
  const body = await response.json();
  assert.equal(body.items.length, 2);
  assert.match(body.items[0].imageURL, new RegExp(`127.0.0.1:${server.address().port}`));
});

test("posters support etags", async () => {
  const first = await fetch(`${baseURL}/v1/media/aurora/poster.svg`);
  assert.equal(first.status, 200);
  const second = await fetch(`${baseURL}/v1/media/aurora/poster.svg`, {
    headers: { "If-None-Match": first.headers.get("etag") }
  });
  assert.equal(second.status, 304);
});

test("missing items use the error envelope", async () => {
  const response = await fetch(`${baseURL}/v1/items/missing`);
  assert.equal(response.status, 404);
  assert.equal((await response.json()).error.code, "not_found");
});
