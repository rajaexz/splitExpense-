"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateGameContent = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const generative_ai_1 = require("@google/generative-ai");
const sharedSystem = `You write short text for a friendly group question game inside a split-expense app. Output rules: Return ONLY the required question or message. No title, no quotes, no numbering, no explanation, no markdown. English or Hinglish is fine if natural for the group. Keep it safe for friends or office groups: not offensive, not sexual, not political, not medical/legal advice, no slurs. One line when possible.`;
function buildUserPrompt(kind, data) {
    const groupName = data.groupName || "Group";
    const recipientName = data.recipientName || "Friend";
    const interests = data.interests || "";
    switch (kind) {
        case "question_favorite":
            return `The player's interests/hobbies or favorite topics (may include Hindi labels like पसंदीदा): ${interests}
Generate exactly ONE question that relates to these interests. The question must be short, simple, easy to answer in chat, and fun.`;
        case "question_random":
            return `Generate exactly ONE random, fun, engaging question. It must NOT be based on any specific hobbies or interests. Short, simple, easy to answer, suitable for friends or colleagues.`;
        case "turn_reminder":
            return `Recipient first name: ${recipientName}. Group name: ${groupName}.
Write one short message telling them it's their turn to ask a question in the game.`;
        case "payment_reminder":
            return `Recipient first name: ${recipientName}. Group name: ${groupName}.
Write one polite message asking them to complete their payment so the game can continue.`;
        case "poke":
            return `Recipient first name: ${recipientName}. Group name: ${groupName}.
Write one funny, friendly one-liner nudging them to pay. Light teasing only; not mean.`;
        case "winner_announcement": {
            const first = data.firstName || "";
            const second = data.secondName || "";
            const third = data.thirdName || "";
            return `1st place: ${first}. 2nd place: ${second}. 3rd place: ${third}. Group name: ${groupName}.
Write one short, exciting message announcing 1st, 2nd, and 3rd place.`;
        }
        case "game_complete":
            return `Group name: ${groupName}.
Write one friendly message that the game is completed and thank all members.`;
        default:
            throw new functions.https.HttpsError("invalid-argument", "Unknown kind");
    }
}
exports.generateGameContent = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    }
    const kind = data.kind;
    const groupId = data.groupId;
    if (!kind || !groupId) {
        throw new functions.https.HttpsError("invalid-argument", "kind and groupId required");
    }
    const db = admin.firestore();
    const groupDoc = await db.collection("groups").doc(groupId).get();
    if (!groupDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Group not found");
    }
    const members = (((_a = groupDoc.data()) === null || _a === void 0 ? void 0 : _a.members) || {});
    if (!members[context.auth.uid]) {
        throw new functions.https.HttpsError("permission-denied", "Not a group member");
    }
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
        throw new functions.https.HttpsError("failed-precondition", "AI not configured. Set GEMINI_API_KEY for Cloud Functions.");
    }
    const userPrompt = buildUserPrompt(kind, data);
    const genAI = new generative_ai_1.GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
        model: "gemini-1.5-flash",
        systemInstruction: sharedSystem,
    });
    const result = await model.generateContent(userPrompt);
    const raw = (result.response.text() || "").trim().replace(/^["']|["']$/g, "");
    if (!raw) {
        throw new functions.https.HttpsError("internal", "Empty AI response");
    }
    return { text: raw };
});
//# sourceMappingURL=generateGameContent.js.map