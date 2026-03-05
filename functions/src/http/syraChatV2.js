/**
 * ═══════════════════════════════════════════════════════════════
 * SYRA CHAT V2 HANDLER
 * ═══════════════════════════════════════════════════════════════
 * New simplified endpoint aligned with MASTER GUIDE v1.1
 */

import crypto from "crypto";
import { auth } from "../config/firebaseAdmin.js";
import { requireOpenAI } from "../config/openaiClient.js";
import {
  buildSmartSystemPrompt,
  isSmartReadRequest,
  isEvidenceRequest,
  isDeepAnalysisRequest,
} from "../services/promptBuilder.js";
import { persistParticipantAlias } from "../services/relationshipRetrieval.js";
import { resolveUserPlan } from "../services/planResolver.js";
import {
  addDailyUsage,
  getDailyUsage,
  getIstanbulDateKey,
} from "../services/usageTracker.js";
import { selectModel } from "../services/modelRouter.js";
import {
  getConversationHistory,
  saveConversationHistory,
} from "../firestore/conversationRepository.js";

const MAX_HISTORY = 10;

// ── Reply mode flags (mutually exclusive) ────────────────────────────
const REPLY_AS_MESSAGE = true;      // structural: replied msg as own messages[] item
const REPLY_CONTEXT_PREFIX = false; // legacy: prepend text to user message
const EVIDENCE_FIRST_INTROS = [
  "Kanka bulduklarım bunlar:",
  "Kanka kayıtlar buralarda:",
  "Kanka şunları yakaladım:",
  "Kanka burada net çıkanlar:",
  "Kanka geçmişte geçenler:",
  "Kanka iz bırakanlar:",
  "Kanka konuşmadan düşenler:",
  "Kanka işaretlediklerim:",
  "Kanka not ettiklerim:",
  "Kanka hızlıca çıkanlar:",
  "Kanka bulduğum satırlar:",
  "Kanka elde olanlar:",
];
const EVIDENCE_MORE_INTROS = [
  "Bunlar da var:",
  "Kanka bunlar da çıktı:",
  "Kanka devamı burada:",
  "Kanka kalanlar şunlar:",
  "Kanka yeni yakalananlar:",
  "Kanka ek çıkanlar:",
  "Kanka sıradakiler:",
  "Kanka devamını döküyorum:",
  "Kanka başka bulduklarım:",
  "Kanka kalan parçalar:",
];
const EVIDENCE_EMPTY_FOLLOWUP = [
  "Kanka bu kadar, başka yok.",
  "Kanka bitti, elimde başka yok.",
  "Kanka buraya kadarmış, başka çıkmadı.",
  "Kanka bu kadar, gerisi yok.",
  "Kanka başka kayıt yok.",
  "Kanka bende bu kadar var.",
  "Kanka son bu, yenisi yok.",
  "Kanka daha yok, hepsi bu.",
  "Kanka şimdilik bu kadar, başka yok.",
  "Kanka şu an başka çıkmadı.",
];
const EVIDENCE_NO_RESULTS = [
  "Kanka bulamadım, hiç iz çıkmadı.",
  "Kanka burada kayıt yok.",
  "Kanka bir şey düşmemiş.",
  "Kanka denk gelen bir kayıt yok.",
  "Kanka iz bulamadım.",
  "Kanka kayıt çıkmadı.",
  "Kanka geçmişte bunun izi yok.",
  "Kanka bu konuda kayıt yok.",
  "Kanka bulamadım, daha dar bir kelime söyle.",
  "Kanka bulamadım, tarih aralığı verir misin?",
];

export async function syraChatV2Handler(req, res) {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({
      success: false,
      message: "Sadece POST metodu kabul edilir.",
      code: "METHOD_NOT_ALLOWED",
    });
  }

  const requestId = crypto.randomUUID();
  const startTime = Date.now();

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme hatası. Lütfen tekrar giriş yap.",
        code: "UNAUTHORIZED",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    let uid;

    try {
      const decoded = await auth.verifyIdToken(idToken);
      uid = decoded.uid;
    } catch (err) {
      console.error("Token verification failed:", err);
      return res.status(401).json({
        success: false,
        message: "Geçersiz oturum. Lütfen tekrar giriş yap.",
        code: "INVALID_TOKEN",
      });
    }

    const { message: rawMessage, sessionId: rawSessionId, replyTo, mode: rawMode } =
      req.body || {};

    if (!rawMessage || typeof rawMessage !== "string" || !rawMessage.trim()) {
      return res.status(400).json({
        success: false,
        message: "Mesaj boş olamaz.",
        code: "EMPTY_MESSAGE",
      });
    }

    const originalMessage = rawMessage.trim();
    const sessionId = sanitizeSessionId(rawSessionId);
    const historyData = await getConversationHistory(uid, sessionId);
    const serverHistory = sanitizeConversationHistory(historyData?.messages || []);
    const sessionScopeActive = getSessionConsentScope(historyData?.messages || []);
    console.log(`syraChatV2 consentScope=${sessionScopeActive ? "session" : "none"} mode=${rawMode || "standard"}`);
    const lastTemplateId = getLastAssistantTemplateId(historyData?.messages || []);
    const replyToPresent = !!replyTo && typeof replyTo === "object";
    let message = originalMessage;
    let replyToRole = "user";
    let replyModeUsed = "none";
    let replyMessage = null;

    if (replyToPresent) {
      replyToRole = replyTo.role === "assistant" ? "assistant" : "user";
      const replyContent =
        typeof replyTo.content === "string" ? replyTo.content : "";

      if (REPLY_AS_MESSAGE) {
        replyMessage = { role: replyToRole, content: replyContent };
        replyModeUsed = "as_message";
      } else if (REPLY_CONTEXT_PREFIX) {
        const replyContext = `=== REPLY CONTEXT ===\nUser is replying to this message:\n"${replyContent}"\nThe user's new message should be interpreted as a follow-up to that quoted content.\n\n`;
        message = replyContext + originalMessage;
        replyModeUsed = "prefix";
      }
    }

    const promptHistory = (replyToPresent && !REPLY_AS_MESSAGE) ? [] : serverHistory;
    const mode = rawMode || "standard";

    // ── Consent gate: check pending action from last assistant message ──
    const pendingAction = getLastPendingAction(historyData?.messages || []);
    let consentApproved = false;
    let savedQuery = null;

    if (pendingAction?.type === "awaiting_zip_consent") {
      const ruleResult = isAffirmativeReply(originalMessage)
        ? "YES"
        : isNegativeReply(originalMessage)
        ? "NO"
        : "UNCLEAR";
      console.log(`syraChatV2 consentRule=${ruleResult} mode=${mode}`);

      if (ruleResult === "YES") {
        consentApproved = true;
        savedQuery = pendingAction.savedQuery;
        console.log(
          `syraChatV2 consentGate=approved savedQuery="${(savedQuery || "").substring(0, 50)}" mode=${mode}`
        );
      } else if (ruleResult === "NO") {
        console.log(`syraChatV2 consentGate=declined mode=${mode}`);
      } else {
        const llmResult = await classifyConsentReplyLLM(originalMessage);
        console.log(`syraChatV2 consentLLM=${llmResult} mode=${mode}`);
        if (llmResult === "YES") {
          consentApproved = true;
          savedQuery = pendingAction.savedQuery;
          console.log(
            `syraChatV2 consentGate=approved(llm) savedQuery="${(savedQuery || "").substring(0, 50)}" mode=${mode}`
          );
        } else if (llmResult === "NO") {
          console.log(`syraChatV2 consentGate=declined(llm) mode=${mode}`);
        } else {
          // UNCLEAR even after LLM — ask follow-up, keep pendingAction alive
          const followUpReply = "Onaylıyor musun? (Evet/Hayır)";
          await persistSessionMessages(uid, sessionId, originalMessage, followUpReply, {
            requestId,
            guard: "consent_followup",
            pendingAction: { type: "awaiting_zip_consent", savedQuery: pendingAction.savedQuery },
          });
          console.log(`syraChatV2 consentGate=followup mode=${mode}`);
          return res.status(200).json({
            success: true,
            message: followUpReply,
            meta: {
              requestId,
              sessionId,
              guard: "consent_followup",
              totalProcessingTime: Date.now() - startTime,
            },
          });
        }
      }
    }

    if (pendingAction?.type === "awaiting_scope_consent") {
      const scopeRule = isAffirmativeReply(originalMessage) ? "YES"
        : isNegativeReply(originalMessage) ? "NO" : "UNCLEAR";
      if (scopeRule === "YES") {
        await persistSessionMessages(uid, sessionId, originalMessage, "Tamam, bu sohbette tekrar sormam.", {
          requestId, guard: "scope_accepted", consentScope: "session",
        });
        console.log(`syraChatV2 consentScope=accepted sessionId=${sessionId}`);
        return res.status(200).json({
          success: true, message: "Tamam, bu sohbette tekrar sormam.",
          meta: { requestId, sessionId, guard: "scope_accepted", totalProcessingTime: Date.now() - startTime },
        });
      }
      // NO/UNCLEAR → fall through; treat message as normal query
    }

    if (pendingAction?.type === "awaiting_alias_confirm") {
      const aliasRule = isAffirmativeReply(originalMessage) ? "YES"
        : isNegativeReply(originalMessage) ? "NO" : "UNCLEAR";
      console.log(`syraChatV2 aliasResolved=${pendingAction.alias}->${pendingAction.speakerName} rule=${aliasRule}`);
      if (aliasRule === "YES") {
        await persistParticipantAlias(
          uid, pendingAction.relationshipId,
          normalizeTurkishTextSimple(pendingAction.alias),
          pendingAction.speakerName
        );
        consentApproved = true;
        savedQuery = pendingAction.savedQuery;
      }
      // NO/UNCLEAR → fall through as normal chat
    }

    const queryForPrompt = consentApproved ? savedQuery : message;

    const { systemPrompt, meta } = await buildSmartSystemPrompt(
      uid,
      queryForPrompt,
      promptHistory,
      mode
    );
    if (replyToPresent && !REPLY_AS_MESSAGE) {
      meta.messageSearch.followUp = false;
      meta.messageSearch.lastQueryUsed = "-";
    }

    if (consentApproved) {
      meta.consentApproved = true;
    }

    // ── Smart read / deep intent flag ──────────────────────────────────
    const hasSmartReadIntent =
      isSmartReadRequest(originalMessage) || isDeepAnalysisRequest(originalMessage);

    // ── Upload CTA guard: evidence intent but no relationship uploaded ──
    if (hasSmartReadIntent && !meta.relationship.hasRelationship) {
      const uploadCta =
        "Kanka sohbet geçmişin yüklü değil. ZIP dosyasını yüklersen geçmişine bakabilirim.";

      await persistSessionMessages(uid, sessionId, originalMessage, uploadCta, {
        requestId,
        guard: "no_relationship_upload_cta",
      });

      console.log(`syraChatV2 guard=no_relationship_upload_cta mode=${mode}`);
      return res.status(200).json({
        success: true,
        message: uploadCta,
        meta: {
          requestId,
          sessionId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          relationship: meta.relationship,
          guard: "no_relationship_upload_cta",
          totalProcessingTime: Date.now() - startTime,
        },
      });
    }

    // ── Alias clarify return ────────────────────────────────────────────
    if (meta.messageSearch.aliasNeeded && meta.relationship.hasRelationship) {
      const aliasName = meta.messageSearch.aliasNeeded;
      const partnerName = meta.relationship.partnerParticipant || "partner";
      const clarifyMsg = `${aliasName}, ${partnerName} adının takma adı mı? Evet dersen kaydederim.`;
      await persistSessionMessages(uid, sessionId, originalMessage, clarifyMsg, {
        requestId,
        guard: "alias_clarify",
        pendingAction: {
          type: "awaiting_alias_confirm",
          alias: aliasName,
          speakerName: meta.relationship.partnerParticipant,
          relationshipId: meta.relationship.relationshipId,
          savedQuery: originalMessage,
        },
      });
      console.log(`syraChatV2 aliasNeeded=${aliasName} mode=${mode}`);
      return res.status(200).json({
        success: true, message: clarifyMsg,
        meta: { requestId, sessionId, guard: "alias_clarify", relationship: meta.relationship, totalProcessingTime: Date.now() - startTime },
      });
    }

    // ── Consent gate: compute need + strip evidence from effectiveSystemPrompt ──
    const consentNeeded =
      !consentApproved &&
      !pendingAction &&
      !sessionScopeActive &&
      hasSmartReadIntent &&
      meta.relationship.hasRelationship &&
      !meta.messageSearch.followUp;

    let effectiveSystemPrompt = systemPrompt;
    let consentPhraseToAppend = null;

    if (consentNeeded) {
      consentPhraseToAppend = pickConsentPhrase();
      // Strip evidence sections so LLM doesn't reveal evidence before consent
      const NEXT_MARKERS = ["\nDERİN ANALİZ", "\nMOD:"];
      for (const marker of [
        "\n\nBULUNAN MESAJLAR",
        "\n\nMESAJ BULUNAMADI",
        "\n\nSESSIZ OKUMA BAGLAMI",
        "\n\nGEÇMİŞTE İLGİLİ YER BULUNAMADI",
      ]) {
        const start = effectiveSystemPrompt.indexOf(marker);
        if (start === -1) continue;
        let end = effectiveSystemPrompt.length;
        for (const next of NEXT_MARKERS) {
          const pos = effectiveSystemPrompt.indexOf(next, start + 1);
          if (pos !== -1 && pos < end) end = pos;
        }
        effectiveSystemPrompt = effectiveSystemPrompt.slice(0, start) + effectiveSystemPrompt.slice(end);
      }
      console.log(`syraChatV2 consentGate=pending phrase="${consentPhraseToAppend.substring(0, 40)}" mode=${mode}`);
    }

    // ── Deterministic evidence guards (Kanıt Modu only) ───────────────
    const shouldSearch =
      isSmartReadRequest(originalMessage) && meta.relationship.hasRelationship;
    if (shouldSearch && meta.messageSearch.evidenceMode && meta.messageSearch.found === 0 && !consentNeeded) {
      const template = selectEvidenceTemplate({
        bucket: "no_results",
        options: EVIDENCE_NO_RESULTS,
        lastTemplateId,
      });
      const safeReply = template.line;

      await persistSessionMessages(uid, sessionId, originalMessage, safeReply, {
        requestId,
        guard: "no_evidence",
        lastTemplateId: template.templateId,
        templateBucket: template.templateBucket,
      });

      console.log(
        `syraChatV2 evidenceReply templateBucket=${template.templateBucket} lastTemplateId=${template.templateId} evidenceCount=${meta.messageSearch.found} followUp=${meta.messageSearch.followUp ? "yes" : "no"} sessionId=${sessionId}`
      );
      return res.status(200).json({
        success: true,
        message: safeReply,
        meta: {
          requestId,
          sessionId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          relationship: meta.relationship,
          guard: "no_evidence",
          totalProcessingTime: Date.now() - startTime,
        },
      });
    }

    if (
      meta.messageSearch.requested &&
      meta.messageSearch.evidenceMode &&
      meta.messageSearch.found > 0 &&
      !meta.deepAnalysis.requested &&
      !consentApproved
    ) {
      const followUp = meta.messageSearch.followUp;
      const evidenceItems = Array.isArray(meta.messageSearch.items)
        ? meta.messageSearch.items
        : [];
      let visibleItems = [];
      let shownSize = 0;
      let remainingLen = 0;
      if (followUp) {
        let shown = getAllAssistantEvidenceLines(serverHistory);
        if (shown.size === 0) {
          shown = buildFallbackShownSet(evidenceItems, serverHistory);
        }
        const remaining = evidenceItems.filter(
          (item) => !shown.has(normalizeEvidenceLine(item))
        );
        shownSize = shown.size;
        remainingLen = remaining.length;
        visibleItems = remaining.length ? remaining : [];
      } else {
        visibleItems = evidenceItems.slice(0, 2);
      }
      console.log(
        `syraChatV2 evidencePaging shownSize=${shownSize} evidenceItemsLen=${evidenceItems.length} remainingLen=${remainingLen} followUp=${followUp ? "yes" : "no"}`
      );
      if (followUp && visibleItems.length === 0) {
        const template = selectEvidenceTemplate({
          bucket: "empty_followup",
          options: EVIDENCE_EMPTY_FOLLOWUP,
          lastTemplateId,
        });
        const safeReply = template.line;
        await persistSessionMessages(uid, sessionId, originalMessage, safeReply, {
          requestId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          guard: "deterministic_evidence_v2",
          lastTemplateId: template.templateId,
          templateBucket: template.templateBucket,
        });
        console.log(
          `syraChatV2 evidenceReply templateBucket=${template.templateBucket} lastTemplateId=${template.templateId} evidenceCount=${meta.messageSearch.found} followUp=${followUp ? "yes" : "no"} sessionId=${sessionId}`
        );
        return res.status(200).json({
          success: true,
          message: safeReply,
          meta: {
            requestId,
            sessionId,
            deepAnalysis: meta.deepAnalysis,
            messageSearch: meta.messageSearch,
            relationship: meta.relationship,
            guard: "deterministic_evidence_v2",
            totalProcessingTime: Date.now() - startTime,
          },
        });
      }
      const template = selectEvidenceTemplate({
        bucket: followUp ? "more" : "first",
        options: followUp ? EVIDENCE_MORE_INTROS : EVIDENCE_FIRST_INTROS,
        lastTemplateId,
      });
      const safeReply = `${template.line}\n- ${visibleItems.join("\n- ")}`;

      await persistSessionMessages(uid, sessionId, originalMessage, safeReply, {
        requestId,
        deepAnalysis: meta.deepAnalysis,
        messageSearch: meta.messageSearch,
        guard: "deterministic_evidence_v2",
        lastTemplateId: template.templateId,
        templateBucket: template.templateBucket,
      });

      console.log(
        `syraChatV2 evidenceReply templateBucket=${template.templateBucket} lastTemplateId=${template.templateId} evidenceCount=${meta.messageSearch.found} followUp=${followUp ? "yes" : "no"} sessionId=${sessionId}`
      );
      return res.status(200).json({
        success: true,
        message: safeReply,
        meta: {
          requestId,
          sessionId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          relationship: meta.relationship,
          guard: "deterministic_evidence_v2",
          totalProcessingTime: Date.now() - startTime,
        },
      });
    }

    const plan = await resolveUserPlan(uid);
    const dateKey = getIstanbulDateKey();
    const dailyUsage = await getDailyUsage(uid, dateKey);
    const decision = selectModel({ plan, meta, dailyUsage });

    console.log(
      `syraChatV2 requestId=${requestId} sessionId=${sessionId} historySource=server historyLen=${serverHistory.length} intentType=${meta.messageSearch.intentType || "-"} followUp=${meta.messageSearch.followUp ? "yes" : "no"} lastQueryUsed=${meta.messageSearch.lastQueryUsed || "-"} evidenceCount=${meta.messageSearch.found} plan=${plan} model=${decision.blocked ? "blocked" : decision.model} creditsUsed=${dailyUsage?.creditsUsed || 0} policyVersion=${decision.policyVersion} mode=${mode} consentApproved=${consentApproved ? "yes" : "no"}`
    );
    console.log(
      `syraChatV2 smartRead=${meta.messageSearch.requested} deepMode=${meta.messageSearch.deepMode || "none"} evidenceMode=${meta.messageSearch.evidenceMode || false} finderChunkCount=${meta.messageSearch.finderChunkCount || 0} excerptCount=${meta.messageSearch.excerptCount || 0} recentFocus=${meta.messageSearch.recentFocus || false}`
    );
    if (replyToPresent) {
      console.log(
        `syraChatV2 replyToPresent=yes role=${replyToRole} mode=${replyModeUsed}`
      );
    } else {
      console.log(
        `syraChatV2 replyToPresent=no followUp=${meta.messageSearch.followUp ? "yes" : "no"} lastQueryUsed=${meta.messageSearch.lastQueryUsed || "-"}`
      );
    }

    if (decision.blocked) {
      const guard = decision.reason === "credit_block" ? "credit_block" : "deep_block";
      await persistSessionMessages(uid, sessionId, originalMessage, decision.message, {
        requestId,
        deepAnalysis: meta.deepAnalysis,
        messageSearch: meta.messageSearch,
        guard,
        plan,
        dateKey,
        creditsUsed: dailyUsage?.creditsUsed || 0,
        policyVersion: decision.policyVersion,
        ...(decision.cap != null ? { cap: decision.cap } : {}),
      });

      return res.status(200).json({
        success: true,
        message: decision.message,
        meta: {
          requestId,
          sessionId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          relationship: meta.relationship,
          guard,
          totalProcessingTime: Date.now() - startTime,
        },
      });
    }

    const selectedModel = decision.model;

    const openai = requireOpenAI();
    const chatMessages = [
      { role: "system", content: effectiveSystemPrompt },
      ...serverHistory.slice(-MAX_HISTORY),
    ];
    if (replyMessage) {
      chatMessages.push(replyMessage);
    }
    chatMessages.push({ role: "user", content: message });

    const chatParams = {
      model: selectedModel,
      messages: chatMessages,
    };
    if (!selectedModel.startsWith("gpt-5")) {
      chatParams.temperature = 0.7;
    }
    const response = await openai.chat.completions.create(chatParams);

    let aiReply = response?.choices?.[0]?.message?.content?.trim() || "";

    if (
      meta.messageSearch.requested &&
      meta.messageSearch.found === 0 &&
      containsTimestampLikePattern(aiReply)
    ) {
      const safeReply =
        "Aradım ama bulamadım. Tek bir anahtar kelime veya tarih aralığı ver.";

      await persistSessionMessages(uid, sessionId, originalMessage, safeReply, {
        requestId,
        guard: "timestamp_blocked_no_evidence",
      });

      return res.status(200).json({
        success: true,
        message: safeReply,
        meta: {
          requestId,
          sessionId,
          deepAnalysis: meta.deepAnalysis,
          messageSearch: meta.messageSearch,
          relationship: meta.relationship,
          guard: "timestamp_blocked_no_evidence",
          totalProcessingTime: Date.now() - startTime,
        },
      });
    }

    const promptTokens = Number(response?.usage?.prompt_tokens) || 0;
    const completionTokens = Number(response?.usage?.completion_tokens) || 0;
    const totalTokens = promptTokens + completionTokens;
    const creditMultiplier = decision.model === "gpt-5.2" ? 16 : 1;
    const usageDelta = {
      model: decision.model,
      promptTokens,
      completionTokens,
      totalTokens,
      creditsUsed: totalTokens * creditMultiplier,
    };

    try {
      await addDailyUsage(uid, dateKey, {
        model: decision.model,
        promptTokens,
        completionTokens,
      });
    } catch (error) {
      console.error("[syraChatV2] addDailyUsage failed:", error);
    }

    // ── Append consent phrase if needed ─────────────────────────────────
    let consentMeta = {};
    if (consentPhraseToAppend) {
      aiReply = (aiReply || "").trimEnd() + "\n\n" + consentPhraseToAppend;
      consentMeta = {
        guard: "consent_gate",
        pendingAction: { type: "awaiting_zip_consent", savedQuery: originalMessage },
      };
    }

    // ── Scope offer after first consent approval ─────────────────────────
    let scopeMeta = {};
    if (consentApproved && !sessionScopeActive && !getScopeOffered(historyData?.messages || [])) {
      aiReply = (aiReply || "").trimEnd() + "\n\n" + SCOPE_OFFER_PHRASES[Math.floor(Math.random() * SCOPE_OFFER_PHRASES.length)];
      scopeMeta = {
        scopeOffered: true,
        pendingAction: { type: "awaiting_scope_consent" },
      };
      console.log(`syraChatV2 consentScope=offered sessionId=${sessionId}`);
    }

    await persistSessionMessages(uid, sessionId, originalMessage, aiReply, {
      requestId,
      deepAnalysis: meta.deepAnalysis,
      messageSearch: meta.messageSearch,
      plan,
      selectedModel: decision.model,
      usageDelta,
      policyVersion: decision.policyVersion,
      ...consentMeta,
      ...scopeMeta,
    });

    return res.status(200).json({
      success: true,
      message: aiReply || "Kanka bir sorun oldu, tekrar dener misin?",
      meta: {
        requestId,
        sessionId,
        deepAnalysis: meta.deepAnalysis,
        messageSearch: meta.messageSearch,
        relationship: meta.relationship,
        totalProcessingTime: Date.now() - startTime,
      },
    });
  } catch (error) {
    console.error("syraChatV2 error:", error);
    return res.status(500).json({
      success: false,
      message: "Something went wrong, please try again.",
      code: "INTERNAL_ERROR",
    });
  }
}

function getLastAssistantTemplateId(messages) {
  if (!Array.isArray(messages) || messages.length === 0) return null;
  for (let i = messages.length - 1; i >= 0; i -= 1) {
    const entry = messages[i];
    if (entry?.role !== "assistant") continue;
    const templateId = entry?.meta?.lastTemplateId;
    if (typeof templateId === "string" && templateId.trim()) {
      return templateId.trim();
    }
  }
  return null;
}

function selectEvidenceTemplate({ bucket, options, lastTemplateId }) {
  const safeOptions = Array.isArray(options) && options.length ? options : [];
  const prefixMap = {
    first: "first",
    more: "more",
    empty_followup: "empty",
    no_results: "nores",
  };
  const prefix = prefixMap[bucket] || "tpl";
  const fallbackLine =
    bucket === "more"
      ? "Bunlar da var:"
      : bucket === "empty_followup"
      ? "Kanka bu kadar, başka yok."
      : bucket === "no_results"
      ? "Kanka bulamadım, hiç iz çıkmadı."
      : "Kanka bulduklarım bunlar:";

  if (safeOptions.length === 0) {
    return {
      line: fallbackLine,
      templateId: `${prefix}_1`,
      templateBucket: bucket,
    };
  }

  let index = Math.floor(Math.random() * safeOptions.length);
  let templateId = `${prefix}_${index + 1}`;
  if (lastTemplateId === templateId && safeOptions.length > 1) {
    index = (index + 1) % safeOptions.length;
    templateId = `${prefix}_${index + 1}`;
  }

  return {
    line: safeOptions[index],
    templateId,
    templateBucket: bucket,
  };
}

function sanitizeSessionId(rawSessionId) {
  if (rawSessionId && typeof rawSessionId === "string" && rawSessionId.trim()) {
    let cleanSessionId = rawSessionId.trim().slice(0, 128);
    cleanSessionId = cleanSessionId.replace(/[^a-zA-Z0-9_-]/g, "_");
    return cleanSessionId;
  }
  return "legacy";
}

function sanitizeConversationHistory(conversationHistory) {
  if (!Array.isArray(conversationHistory)) return [];

  return conversationHistory
    .map((entry) => {
      if (!entry || typeof entry !== "object") return null;
      const role = normalizeRole(entry.role);
      const content = typeof entry.content === "string" ? entry.content.trim() : "";
      if (!role || !content) return null;
      return { role, content };
    })
    .filter(Boolean);
}

function getAllAssistantEvidenceLines(history) {
  if (!Array.isArray(history)) return new Set();

  const shown = new Set();
  history.forEach((entry) => {
    if (!entry || entry.role !== "assistant") return;
    const lines = extractEvidenceLines(entry.content);
    lines.forEach((line) => shown.add(line));
  });

  return shown;
}

function extractEvidenceLines(text) {
  if (!text) return new Set();

  const lines = String(text)
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => isEvidenceLine(line))
    .map((line) => normalizeEvidenceLine(line))
    .filter(Boolean);

  return new Set(lines);
}

function isEvidenceLine(line) {
  return /\[\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}/i.test(line || "");
}

function normalizeEvidenceLine(line) {
  if (!line) return "";
  return String(line).replace(/^[-*•·]\s*/, "").trim();
}

function buildFallbackShownSet(evidenceItems, history) {
  const shown = new Set();
  if (!Array.isArray(history)) return shown;
  const assistantTexts = history
    .filter((entry) => entry?.role === "assistant")
    .map((entry) => String(entry.content || ""));
  evidenceItems.forEach((item) => {
    const normalized = normalizeEvidenceLine(item);
    if (!normalized) return;
    const found = assistantTexts.some((content) => content.includes(item));
    if (found) shown.add(normalized);
  });
  return shown;
}

function normalizeRole(role) {
  if (!role) return null;
  const normalized = String(role).toLowerCase();
  if (normalized === "user" || normalized === "assistant") return normalized;
  return null;
}

function containsTimestampLikePattern(text) {
  if (!text) return false;

  const patterns = [
    /\[\d{1,2}[./]\d{1,2}[./]\d{2,4}\s+\d{1,2}:\d{2}(?::\d{2})?\]/,
    /\[\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}/i,
    /\b\d{4}-\d{2}-\d{2}t\d{2}:\d{2}:\d{2}\b/i,
  ];

  return patterns.some((pattern) => pattern.test(text));
}

async function persistSessionMessages(
  uid,
  sessionId,
  userMessage,
  assistantReply,
  assistantMeta
) {
  try {
    const historyData = await getConversationHistory(uid, sessionId);
    await saveConversationHistory(
      uid,
      sessionId,
      userMessage,
      assistantReply,
      historyData,
      assistantMeta
    );
  } catch (e) {
    console.error(`[${uid}] Session save error (sessionId=${sessionId}):`, e);
  }
}

// ── Consent gate helpers ────────────────────────────────────────────

function getLastPendingAction(messages) {
  if (!Array.isArray(messages) || messages.length === 0) return null;
  for (let i = messages.length - 1; i >= 0; i -= 1) {
    const entry = messages[i];
    if (entry?.role !== "assistant") continue;
    const pending = entry?.meta?.pendingAction;
    if (pending && typeof pending === "object" && pending.type) {
      return pending;
    }
    // Only check the very last assistant message
    return null;
  }
  return null;
}

const AFFIRMATIVE_TOKENS = new Set([
  "evet", "olur", "tamam", "okey", "okay", "ok", "yes",
  "bak", "bakayım", "bakayim", "bakıyorum", "bakiyorum", "bakarim",
]);
const AFFIRMATIVE_PHRASES = ["hadi bak"];

function isAffirmativeReply(msg) {
  const normalized = (msg || "").toLowerCase().trim();
  if (!normalized) return false;
  if (AFFIRMATIVE_TOKENS.has(normalized)) return true;
  if (AFFIRMATIVE_PHRASES.some((p) => normalized.includes(p))) return true;
  if (normalized.startsWith("bak")) return true;
  return false;
}

const NEGATIVE_TOKENS = new Set([
  "hayır", "hayir", "yok", "istemem", "istemiyorum", "no",
]);
const NEGATIVE_PHRASES = ["gerek yok", "gerek yok kanka", "değil", "degil"];

function isNegativeReply(msg) {
  const normalized = (msg || "").toLowerCase().trim();
  if (!normalized) return false;
  if (NEGATIVE_TOKENS.has(normalized)) return true;
  return NEGATIVE_PHRASES.some((p) => normalized.includes(p));
}

// ── Consent phrase banks ────────────────────────────────────────────
const CONSENT_PHRASES = [
  "Geçmiş konuşmalarına bakayım mı?",
  "Arşivine göz atayım mı?",
  "Sohbet geçmişinden bakayım mı?",
  "Konuşmalarına bir bakayım mı?",
  "Kayıtlara bakayım mı?",
  "Geçmişe bakayım mı?",
  "Arayayım mı?",
  "Geçmişten kontrol edeyim mi?",
  "Mesaj geçmişine bakabilir miyim?",
  "Konuşma arşivine göz atayım mı?",
];
function pickConsentPhrase() {
  return CONSENT_PHRASES[Math.floor(Math.random() * CONSENT_PHRASES.length)];
}

const SCOPE_OFFER_PHRASES = [
  "Not: istersen bu sohbette her seferinde sormadan bakabilirim.",
  "Bu oturumda tekrar izin istememi istemiyorsan söyle.",
  "Her seferinde sormadan devam edebilirim, ne dersin?",
  "İstersen bu sohbet boyunca otomatik bakabilirim.",
];

function getSessionConsentScope(history) {
  return Array.isArray(history) &&
    history.some((m) => m.role === "assistant" && m.meta?.consentScope === "session");
}

function getScopeOffered(history) {
  return Array.isArray(history) &&
    history.some((m) => m.role === "assistant" && m.meta?.scopeOffered === true);
}

function normalizeTurkishTextSimple(s) {
  return (s || "").toLowerCase()
    .replace(/ş/g, "s").replace(/ı/g, "i").replace(/ğ/g, "g")
    .replace(/ö/g, "o").replace(/ü/g, "u").replace(/ç/g, "c");
}

async function classifyConsentReplyLLM(message) {
  try {
    const openai = requireOpenAI();
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content:
            "You are a binary consent classifier. The assistant asked \"ZIP'ten bakayım mı?\" (Shall I look at your chat history?). Classify the user's reply as YES, NO, or UNCLEAR. Reply with exactly one word: YES, NO, or UNCLEAR.",
        },
        { role: "user", content: message },
      ],
    });
    const raw = (response?.choices?.[0]?.message?.content || "").trim().toUpperCase();
    if (raw === "YES" || raw === "NO" || raw === "UNCLEAR") return raw;
    return "UNCLEAR";
  } catch (e) {
    console.error("[classifyConsentReplyLLM] error:", e);
    return "UNCLEAR";
  }
}

// Manual test checklist:
// 1) Normal chat -> gpt-5-mini, no consent gate
// 2) "kanıt göster" -> returns "ZIP'ten bakayım mı?" (consent gate)
// 3) "evet" after consent -> evidence search + gpt-5.2 (premium) / gpt-5-mini (free)
// 4) "hayır" after consent -> normal chat with gpt-5-mini, honest about limits
// 5) "derin analiz yap" -> consent gate triggers
// 6) Free user deep analysis (no consent) -> blocked (upsell)
// 7) Dost Aci mode + normal chat -> gpt-5-mini with blunt tone
// 8) Follow-up "daha göster" -> existing deterministic pagination
// 9) Check debug logs -> selectedModel, consentGate status, mode printed
