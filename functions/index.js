"use strict";

const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {
  clientAddress,
  isAllowedOrigin,
  isRateLimited,
  validatedInput,
} = require("./proxy_helpers");

const groqApiKey = defineSecret("GROQ_API_KEY");

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

exports.groqProxy = onRequest(
    {
      region: "asia-southeast1",
      secrets: [groqApiKey],
      timeoutSeconds: 40,
      memory: "256MiB",
      maxInstances: 3,
    },
    async (request, response) => {
      const origin = request.get("origin") || "";
      if (!isAllowedOrigin(origin)) {
        response.status(403).json({error: {message: "Origin is not allowed."}});
        return;
      }

      response.set("Access-Control-Allow-Origin", origin);
      response.set("Vary", "Origin");
      response.set("Access-Control-Allow-Headers", "Content-Type");
      response.set("Access-Control-Allow-Methods", "POST, OPTIONS");
      response.set("Cache-Control", "no-store");

      if (request.method === "OPTIONS") {
        response.status(204).send("");
        return;
      }
      if (request.method !== "POST") {
        response.status(405).json({error: {message: "Method not allowed."}});
        return;
      }
      if (isRateLimited(clientAddress(request))) {
        response.status(429).json({
          error: {message: "Too many requests. Please try again in a minute."},
        });
        return;
      }

      let input;
      try {
        input = validatedInput(request.body);
      } catch (error) {
        response.status(400).json({error: {message: error.message}});
        return;
      }

      try {
        const groqResponse = await fetch(
            "https://api.groq.com/openai/v1/responses",
            {
              method: "POST",
              headers: {
                "Authorization": `Bearer ${groqApiKey.value()}`,
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
            },
        );
        const responseText = await groqResponse.text();
        response.status(groqResponse.status).type("application/json").send(responseText);
      } catch (_) {
        response.status(502).json({
          error: {message: "The AI service is temporarily unavailable."},
        });
      }
    },
);
