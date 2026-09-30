"use strict";

const allowedOrigins = new Set([
  "https://abdulkadiljhonardz-byte.github.io",
]);
const requestsByClient = new Map();

function isAllowedOrigin(origin) {
  if (allowedOrigins.has(origin)) return true;
  return /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
}

function clientAddress(request) {
  const forwarded = request.get("x-forwarded-for");
  return (forwarded ? forwarded.split(",")[0] : request.ip || "unknown").trim();
}

function isRateLimited(address, now = Date.now()) {
  const windowMs = 60_000;
  const limit = 6;
  const previous = requestsByClient.get(address) || [];
  const recent = previous.filter((timestamp) => now - timestamp < windowMs);
  recent.push(now);
  requestsByClient.set(address, recent);
  return recent.length > limit;
}

function validatedInput(requestBody) {
  if (!requestBody || typeof requestBody !== "object") {
    throw new Error("A JSON request body is required.");
  }

  const input = requestBody.input;
  if (typeof input !== "string" || input.length < 2 || input.length > 100_000) {
    throw new Error("The recommendation input is invalid.");
  }

  let decoded;
  try {
    decoded = JSON.parse(input);
  } catch (_) {
    throw new Error("The recommendation input must contain valid JSON.");
  }

  if (!decoded.student_profile || typeof decoded.student_profile !== "object") {
    throw new Error("A student profile is required.");
  }
  if (!Array.isArray(decoded.available_courses) ||
      decoded.available_courses.length < 1 ||
      decoded.available_courses.length > 50) {
    throw new Error("Between 1 and 50 courses are required.");
  }

  return input;
}

module.exports = {
  clientAddress,
  isAllowedOrigin,
  isRateLimited,
  validatedInput,
};
