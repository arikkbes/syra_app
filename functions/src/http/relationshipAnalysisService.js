/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP ANALYSIS SERVICE
 * ═══════════════════════════════════════════════════════════════
 * Analyzes WhatsApp chat using LLM and returns structured insights
 */

import { openai } from "../config/openaiClient.js";

/**
 * Analyze WhatsApp chat text and return structured JSON
 */
export async function analyzeWhatsAppChat(chatText) {
  const prompt = `Sen bir ilişki danışmanı AI'sın. Sana bir WhatsApp sohbet dışa aktarımı verildi. Bu sohbeti analiz et ve aşağıdaki JSON formatında bir analiz döndür:

{
  "totalMessages": <yaklaşık mesaj sayısı, integer>,
  "startDate": "<ilk mesajın tarihi, ISO format veya null>",
  "endDate": "<son mesajın tarihi, ISO format veya null>",
  "shortSummary": "<1-3 cümlelik genel ilişki özeti, Türkçe>",
  "energyTimeline": [
    {
      "label": "<dönem açıklaması, örn: 'İlk Ay', 'Son Dönem'>",
      "level": "<'low', 'medium' veya 'high'>",
      "description": "<kısa açıklama, opsiyonel>"
    }
    // 3-7 nokta
  ],
  "keyMoments": [
    {
      "title": "<önemli anın başlığı>",
      "description": "<detaylı açıklama>",
      "date": "<tarih varsa ISO format, yoksa null>"
    }
    // 3-5 nokta
  ]
}

Sohbet:
---
${chatText}
---

ÖNEMLİ: Sadece JSON döndür, başka bir şey yazma. Türkçe açıklamalar kullan.`;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini", // Cost-effective model for this task
      messages: [
        {
          role: "system",
          content: "Sen bir ilişki danışmanı AI'sın. WhatsApp sohbetlerini analiz ediyorsun ve yapılandırılmış JSON döndürüyorsun.",
        },
        {
          role: "user",
          content: prompt,
        },
      ],
      temperature: 0.7,
      max_tokens: 2000,
      response_format: { type: "json_object" },
    });

    const responseText = completion.choices[0].message.content.trim();
    console.log("LLM response:", responseText);

    // Parse JSON
    const analysis = JSON.parse(responseText);

    // Validate and set defaults
    return {
      totalMessages: analysis.totalMessages || 0,
      startDate: analysis.startDate || null,
      endDate: analysis.endDate || null,
      shortSummary: analysis.shortSummary || "Analiz tamamlandı.",
      energyTimeline: Array.isArray(analysis.energyTimeline)
        ? analysis.energyTimeline
        : [],
      keyMoments: Array.isArray(analysis.keyMoments)
        ? analysis.keyMoments
        : [],
    };
  } catch (error) {
    console.error("analyzeWhatsAppChat error:", error);
    
    // Fallback response
    return {
      totalMessages: estimateMessageCount(chatText),
      startDate: null,
      endDate: null,
      shortSummary: "Analiz tamamlandı ancak detaylı sonuç alınamadı.",
      energyTimeline: [],
      keyMoments: [],
    };
  }
}

/**
 * Estimate message count from text
 */
function estimateMessageCount(text) {
  // WhatsApp messages typically start with timestamp patterns
  // Examples: "[01/01/2024, 10:30:45]", "01/01/2024, 10:30 -"
  const timestampPatterns = [
    /\[\d{1,2}\/\d{1,2}\/\d{4},\s\d{1,2}:\d{2}:\d{2}\]/g,
    /\d{1,2}\/\d{1,2}\/\d{4},\s\d{1,2}:\d{2}\s-/g,
    /\d{1,2}\.\d{1,2}\.\d{4},\s\d{1,2}:\d{2}\s-/g,
  ];

  let maxCount = 0;
  for (const pattern of timestampPatterns) {
    const matches = text.match(pattern);
    if (matches) {
      maxCount = Math.max(maxCount, matches.length);
    }
  }

  return maxCount || Math.floor(text.split("\n").length / 2);
}
