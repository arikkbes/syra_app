/**
 * ═══════════════════════════════════════════════════════════════
 * CONVERSATION HISTORY REPOSITORY
 * ═══════════════════════════════════════════════════════════════
 * Manages long-term conversation memory and summaries
 */

import { db, FieldValue } from "../config/firebaseAdmin.js";
import { openai } from "../config/openaiClient.js";
import { SUMMARY_THRESHOLD, MAX_HISTORY_MESSAGES, MODEL_GPT4O_MINI } from "../utils/constants.js";

/**
 * Get conversation history for a user
 */
export async function getConversationHistory(uid) {
  try {
    const historyRef = db.collection("conversation_history").doc(uid);
    const historySnap = await historyRef.get();

    if (!historySnap.exists) {
      return { messages: [], summary: null };
    }

    const data = historySnap.data();
    return {
      messages: data.messages || [],
      summary: data.summary || null,
      lastSummaryAt: data.lastSummaryAt || null,
    };
  } catch (e) {
    console.error(`[${uid}] History load error:`, e);
    return { messages: [], summary: null };
  }
}

/**
 * Save new message to conversation history
 */
export async function saveConversationHistory(
  uid,
  userMessage,
  assistantReply,
  historyData
) {
  try {
    const historyRef = db.collection("conversation_history").doc(uid);

    const newUserMsg = {
      role: "user",
      content: userMessage,
      timestamp: new Date().toISOString(),
    };

    const newAssistantMsg = {
      role: "assistant",
      content: assistantReply,
      timestamp: new Date().toISOString(),
    };

    const updatedMessages = [
      ...(historyData.messages || []),
      newUserMsg,
      newAssistantMsg,
    ].slice(-MAX_HISTORY_MESSAGES);

    const needsSummary =
      updatedMessages.length >= SUMMARY_THRESHOLD &&
      (!historyData.lastSummaryAt ||
        updatedMessages.length - (historyData.lastSummaryAt || 0) >= 10);

    let newSummary = historyData.summary;
    let lastSummaryAt = historyData.lastSummaryAt;

    if (needsSummary && openai) {
      try {
        const summaryText = await createConversationSummary(
          updatedMessages,
          historyData.summary
        );
        if (summaryText) {
          newSummary = summaryText;
          lastSummaryAt = updatedMessages.length;
          console.log(`[${uid}] Created new summary`);
        }
      } catch (e) {
        console.error(`[${uid}] Summary creation error:`, e);
      }
    }

    await historyRef.set(
      {
        messages: updatedMessages,
        summary: newSummary,
        lastSummaryAt: lastSummaryAt,
        lastUpdated: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  } catch (e) {
    console.error(`[${uid}] History save error:`, e);
    throw e;
  }
}

/**
 * Create or update conversation summary using AI
 */
async function createConversationSummary(messages, existingSummary) {
  if (!openai) return null;

  try {
    const recentMessages = messages.slice(-20);
    const conversationText = recentMessages
      .map((m) => `${m.role}: ${m.content}`)
      .join("\n");

    const prompt = existingSummary
      ? `Önceki özet:\n${existingSummary}\n\nYeni mesajlar:\n${conversationText}\n\nBu konuşmanın güncellenmiş özetini çıkar (max 500 karakter).`
      : `Bu konuşmanın özetini çıkar (max 500 karakter):\n${conversationText}`;

    const summaryRes = await openai.chat.completions.create({
      model: MODEL_GPT4O_MINI,
      messages: [
        {
          role: "system",
          content:
            "Sen bir konuşma özetleme uzmanısın. Kısa, öz ve aksiyon odaklı özetler yaparsın.",
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.3,
      max_tokens: 300,
    });

    return summaryRes.choices[0].message.content.trim();
  } catch (e) {
    console.error("Summary creation error:", e);
    return null;
  }
}
