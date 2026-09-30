"use strict";

const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");
const {
  isAllowedOrigin,
  isRateLimited,
  validatedInput,
} = require("./proxy_helpers");

const port = Number(process.env.PORT || 3000);
const publicDirectory = path.join(__dirname, "public");
const groqApiKey = process.env.GROQ_API_KEY || "";

const instructions = `
You are a careful university course recommendation assistant. Rank only the
courses supplied in the input. Use grades, strand, SASE score, interests,
strengths, skills, weaknesses, course requirements, and the local baseline
score. Do not invent courses or admission guarantees. Scores must be from 0 to
100. Return the five strongest distinct matches (or all courses when fewer than
five are supplied), ordered from strongest to weakest. Give one or two concise,
student-friendly reasons and improvement areas. Return ONLY one valid JSON
object with this exact shape and no Markdown:
{"recommendations":[{"course_code":"ONE_OF_THE_SUPPLIED_CODES","score":0,"interest_matched":true,"reasons":["reason"],"improvements":["improvement"]}]}
`.trim();

const contentTypes = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".wasm": "application/wasm",
};

function json(response, status, value) {
  response.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(JSON.stringify(value));
}

function clientAddress(request) {
  const forwarded = request.headers["x-forwarded-for"];
  return (forwarded ? forwarded.split(",")[0] : request.socket.remoteAddress || "unknown").trim();
}

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 128_000) throw new Error("Request body is too large.");
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

async function handleRecommendation(request, response) {
  const origin = request.headers.origin || "";
  const host = request.headers.host || "";
  if (!isAllowedOrigin(origin, host)) {
    json(response, 403, {error: {message: "Origin is not allowed."}});
    return;
  }

  response.setHeader("Access-Control-Allow-Origin", origin);
  response.setHeader("Vary", "Origin");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type");
  response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (request.method === "OPTIONS") {
    response.writeHead(204);
    response.end();
    return;
  }
  if (request.method !== "POST") {
    json(response, 405, {error: {message: "Method not allowed."}});
    return;
  }
  if (!groqApiKey) {
    json(response, 503, {error: {message: "AI service is not configured."}});
    return;
  }
  if (isRateLimited(clientAddress(request))) {
    json(response, 429, {
      error: {message: "Too many requests. Please try again in a minute."},
    });
    return;
  }

  let input;
  try {
    input = validatedInput(await readJson(request));
  } catch (error) {
    json(response, 400, {error: {message: error.message}});
    return;
  }

  try {
    const upstream = await fetch("https://api.groq.com/openai/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${groqApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "openai/gpt-oss-20b",
        instructions,
        input,
        temperature: 0.2,
        max_output_tokens: 1200,
        reasoning: {effort: "low"},
        text: {format: {type: "text"}},
      }),
    });
    const responseBody = await upstream.text();
    response.writeHead(upstream.status, {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    });
    response.end(responseBody);
  } catch (_) {
    json(response, 502, {
      error: {message: "The AI service is temporarily unavailable."},
    });
  }
}

function serveStatic(request, response) {
  const url = new URL(request.url, "http://localhost");
  let relativePath = decodeURIComponent(url.pathname);
  if (relativePath === "/") relativePath = "/index.html";
  const requestedPath = path.resolve(publicDirectory, `.${relativePath}`);
  if (!requestedPath.startsWith(`${publicDirectory}${path.sep}`)) {
    response.writeHead(403);
    response.end("Forbidden");
    return;
  }

  let filePath = requestedPath;
  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(publicDirectory, "index.html");
  }
  fs.readFile(filePath, (error, data) => {
    if (error) {
      response.writeHead(404);
      response.end("Not found");
      return;
    }
    const immutable = /\.[a-f0-9]{8,}\./.test(path.basename(filePath));
    response.writeHead(200, {
      "Content-Type": contentTypes[path.extname(filePath)] || "application/octet-stream",
      "Cache-Control": immutable ? "public, max-age=31536000, immutable" : "no-cache",
      "X-Content-Type-Options": "nosniff",
    });
    response.end(data);
  });
}

const server = http.createServer(async (request, response) => {
  if (request.url === "/health") {
    json(response, groqApiKey ? 200 : 503, {status: groqApiKey ? "ok" : "unconfigured"});
    return;
  }
  if (request.url === "/api/recommend") {
    await handleRecommendation(request, response);
    return;
  }
  if (request.method !== "GET" && request.method !== "HEAD") {
    json(response, 405, {error: {message: "Method not allowed."}});
    return;
  }
  serveStatic(request, response);
});

server.listen(port, "0.0.0.0", () => {
  console.log(`MSU-Sulu Course Guide listening on port ${port}`);
});
