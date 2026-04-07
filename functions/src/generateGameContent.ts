import "./loadEnv";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {GoogleGenerativeAI} from "@google/generative-ai";

const sharedSystem = `You write short text for a friendly turn-based group question game (10 questions total) inside a split-expense app. The game only continues after everyone pays; members take turns asking one question each in circular order.

Output rules: Return ONLY the required question or message — nothing else. No title, no quotes, no numbering, no explanation, no markdown. English or Hinglish is fine if natural for the group. Keep it safe for friends or office groups: not offensive, not sensitive, not sexual, not political, not medical/legal advice, no slurs. One line when possible.`;

function buildUserPrompt(kind: string, data: Record<string, unknown>): string {
  const groupName = (data.groupName as string) || "Group";
  const recipientName = (data.recipientName as string) || "Friend";
  const interests = (data.interests as string) || "";
  switch (kind) {
    case "question_favorite":
      return `Favorite mode: use the player's interests, hobbies, or favorite topics (may include Hindi e.g. पसंदीदा): ${interests}
Output exactly ONE short question tied to those interests. It must be simple, easy to answer in chat, and fun — not offensive or sensitive.`;
    case "question_random":
      return `Non-favorite mode: output exactly ONE random, fun, engaging question. It must NOT relate to anyone's hobbies or interests. Short, simple, easy to answer, suitable for friends or office groups — not offensive or sensitive.`;
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
      const first = (data.firstName as string) || "";
      const second = (data.secondName as string) || "";
      const third = (data.thirdName as string) || "";
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

export const generateGameContent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required");
  }
  const kind = data.kind as string;
  const groupId = data.groupId as string;
  if (!kind || !groupId) {
    throw new functions.https.HttpsError("invalid-argument", "kind and groupId required");
  }
  const db = admin.firestore();
  const groupDoc = await db.collection("groups").doc(groupId).get();
  if (!groupDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Group not found");
  }
  const members = (groupDoc.data()?.members || {}) as Record<string, unknown>;
  if (!members[context.auth.uid]) {
    throw new functions.https.HttpsError("permission-denied", "Not a group member");
  }
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "AI not configured. Set GEMINI_API_KEY for Cloud Functions.",
    );
  }
  const userPrompt = buildUserPrompt(kind, data as Record<string, unknown>);
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({
    model: process.env.GEMINI_MODEL || "gemini-1.5-flash",
    systemInstruction: sharedSystem,
  });
  const result = await model.generateContent(userPrompt);
  const raw = (result.response.text() || "").trim().replace(/^["']|["']$/g, "");
  if (!raw) {
    throw new functions.https.HttpsError("internal", "Empty AI response");
  }
  return { text: raw };
});
