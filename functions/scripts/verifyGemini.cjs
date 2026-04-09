/**
 * Quick check: GEMINI_API_KEY in functions/.env + @google/generative-ai can call the model.
 * Run: cd functions && npm run verify-gemini
 */
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });
const { GoogleGenerativeAI } = require("@google/generative-ai");

const key = process.env.GEMINI_API_KEY;
if (!key || !String(key).trim()) {
  console.error("FAIL: GEMINI_API_KEY missing or empty in functions/.env");
  process.exit(1);
}

const modelName = process.env.GEMINI_MODEL || "gemini-flash-latest";

(async () => {
  try {
    const genAI = new GoogleGenerativeAI(key.trim());
    const model = genAI.getGenerativeModel({ model: modelName });
    const result = await model.generateContent(
      "Reply with a single short greeting word only (e.g. Hello).",
    );
    const text = (result.response.text() || "").trim();
    if (!text) {
      console.error("FAIL: empty model response");
      process.exit(1);
    }
    console.log("");
    console.log("--- Gemini verify: SUCCESS (exit 0) ---");
    console.log("  Model:  ", modelName);
    console.log("  Reply:  ", text);
    console.log("-----------------------------------------");
    console.log("Next: run `npm run emulators` and test AI in the app.");
    console.log("");
    process.exit(0);
  } catch (e) {
    console.error("");
    console.error("--- Gemini verify: FAILED (exit 1) ---");
    console.error(e && e.message ? e.message : e);
    console.error("-----------------------------------------");
    process.exit(1);
  }
})();
