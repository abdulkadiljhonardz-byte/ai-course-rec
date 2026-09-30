"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {isAllowedOrigin, isRateLimited, validatedInput} = require("./proxy_helpers");

test("allows the same host, GitHub Pages, and local development", () => {
  assert.equal(isAllowedOrigin("", "course.up.railway.app"), true);
  assert.equal(isAllowedOrigin("https://course.up.railway.app", "course.up.railway.app"), true);
  assert.equal(isAllowedOrigin("https://abdulkadiljhonardz-byte.github.io", "course.up.railway.app"), true);
  assert.equal(isAllowedOrigin("http://localhost:3000", "localhost:3000"), true);
  assert.equal(isAllowedOrigin("https://example.com", "course.up.railway.app"), false);
});

test("validates a bounded recommendation payload", () => {
  const input = JSON.stringify({
    student_profile: {math_grade: 90},
    available_courses: [{code: "BSIT"}],
  });
  assert.equal(validatedInput({input}), input);
  assert.throws(() => validatedInput({input: "not-json"}));
});

test("limits a client after six requests per minute", () => {
  const address = `test-${Date.now()}`;
  for (let count = 0; count < 6; count += 1) {
    assert.equal(isRateLimited(address, 1_000 + count), false);
  }
  assert.equal(isRateLimited(address, 1_007), true);
});
