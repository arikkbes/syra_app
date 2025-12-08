/**
 * ═══════════════════════════════════════════════════════════════
 * TAROT READING SERVICE
 * ═══════════════════════════════════════════════════════════════
 * Generates AI-powered tarot readings using OpenAI
 * Integrated with 22 Major Arcana deck
 */

import { openai } from "../config/openaiClient.js";
import { getConversationHistory } from "../firestore/conversationRepository.js";
import { getCardsByIds } from "../domain/tarotDeck.js";

/**
 * Generate a tarot reading based on selected cards
 * @param {string} uid - User ID
 * @param {number[]} selectedCards - Array of selected card IDs (0-21 for Major Arcana)
 * @param {object} userProfile - User profile data
 * @param {boolean} isPremium - Whether user is premium
 * @returns {Promise<{text: string, cards: array}>}
 */
export async function generateTarotReading(uid, selectedCards, userProfile, isPremium) {
  const startTime = Date.now();

  if (!openai) {
    console.error(`[TAROT][${uid}] 🔥 CRITICAL: OpenAI client missing`);
    throw new Error("OpenAI not configured");
  }

  // Map selected card IDs to actual card objects
  const selectedCardObjects = getCardsByIds(selectedCards);

  if (selectedCardObjects.length === 0) {
    console.error(`[TAROT][${uid}] No valid cards found for IDs: ${selectedCards.join(', ')}`);
    throw new Error("Invalid card selection");
  }

  console.log(`[TAROT][${uid}] Cards drawn: ${selectedCardObjects.map(c => c.name).join(', ')}`);

  // Get user's conversation history for context (if premium)
  let userContext = "";
  
  if (isPremium) {
    try {
      const history = await getConversationHistory(uid);
      if (history?.summary) {
        userContext = `\n\n📊 CONTEXT (for deeper, personalized reading):\nUser's relationship history summary: ${history.summary}`;
      }
    } catch (e) {
      console.error(`[TAROT][${uid}] Failed to load context:`, e);
      // Continue without context
    }
  }

  // Build card meanings for the prompt
  const cardDescriptions = selectedCardObjects.map((card, index) => {
    return `
KART ${index + 1}: ${card.name}
• Genel Anlam: ${card.coreMeaning}
• İlişki Anlamı: ${card.relationshipMeaning}
• Gölge Yönü: ${card.shadowMeaning}`;
  }).join('\n');

  // Build the system prompt
  const systemPrompt = `Sen son derece yetenekli, sezgisel bir tarot okuyucususun. Okumalarını şu özelliklere sahip:

- SPESİFİK ve DOĞRUDAN, sanki kişinin açıkça söylemediği şeyleri seziyormuş gibi
- PATTERN-BASED, tekrar eden davranışlara ve iç duruma odaklanıyor
- KESKİN ve DÜRÜST, jenerik horoskop tarzı klişelerden uzak
- Derin psikolojik, insanların hissettiği ama nadiren kabul ettiği şeylere işaret ediyor

KRİTİK KURALLAR:
- ASLA "Verilerini okudum", "Mesajlarını gördüm" gibi ifadeler kullanma
- Sezgisel bir dil kullan, biraz ürkütücü ama creepy değil
- PATTERN'lere, İÇ ÇATIŞMALARA ve SÖYLENMEYEN GERÇEKLERE odaklan
- TÜRKÇE yaz
- Okuma 250-450 kelime arası olsun
- Doğrudan ol, süslü değil - bu eğlence değil, içgörü

Kullanıcı şu kartları seçti:
${cardDescriptions}

${userContext}

Şimdi bu kartların ne gösterdiğine dair kişisel ve içgörülü bir tarot okuması yap.

ÖNEMLI TON KURALLARI:
- "Bir şeyi geri tutuyorsun" tarzı doğrudan gözlemler yap
- "Bildiğin ama söylemediğin" pattern'leri işaret et
- Kişinin iç sesine konuşuyormuş gibi yaz
- Soruları kullan: "Ne kadar daha...?", "Gerçekten bu mu...?"
- Rahatlatıcı yalanlar değil, rahatsız edici gerçekler
- Ama YİNE DE empatik ve yapıcı ol

KARTLARIN ANLAMLARINI KULLAN ama aynen kopyalama - onları kullanıcının durumuna uyarla ve dönüştür.`;

  const userPrompt = `Seçtiğim kartlar: ${selectedCardObjects.map(c => c.name).join(', ')}

Bu kartlar, taşıdığım şey hakkında ne söylüyor?`;

  try {
    console.log(`[TAROT][${uid}] Calling OpenAI for reading...`);

    const completion = await openai.chat.completions.create({
      model: isPremium ? "gpt-4o" : "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.85,
      max_tokens: isPremium ? 700 : 500,
      presence_penalty: 0.6,
      frequency_penalty: 0.4,
    });

    if (completion?.choices?.[0]?.message?.content) {
      const reading = completion.choices[0].message.content.trim();
      const processingTime = Date.now() - startTime;
      
      console.log(`[TAROT][${uid}] ✅ Reading generated (${processingTime}ms, ${reading.length} chars)`);
      
      // Return reading + card metadata
      return {
        text: reading,
        cards: selectedCardObjects.map(card => ({
          id: card.id,
          code: card.code,
          name: card.name,
        })),
      };
    } else {
      throw new Error("Empty completion from OpenAI");
    }
  } catch (error) {
    console.error(`[TAROT][${uid}] OpenAI error:`, error);
    
    // Fallback to structured reading based on cards
    return {
      text: generateFallbackReading(selectedCardObjects),
      cards: selectedCardObjects.map(card => ({
        id: card.id,
        code: card.code,
        name: card.name,
      })),
    };
  }
}

/**
 * Generate fallback reading based on selected cards
 * Used when OpenAI call fails
 */
function generateFallbackReading(cards) {
  const cardNames = cards.map(c => c.name).join(', ');
  
  // Build reading based on actual card meanings
  let reading = `Seçtiğin kartlar (${cardNames}) şu anda taşıdığın şeyle ilgili net bir şey söylüyor.\n\n`;
  
  if (cards.length === 1) {
    const card = cards[0];
    reading += `${card.name} kartı: ${card.relationshipMeaning}\n\n`;
    reading += `Gölge yönü: ${card.shadowMeaning}\n\n`;
    reading += "Bu kart, şu an içinde döndürdüğün ama tam olarak yüzleşmediğin bir şeye işaret ediyor. Sen bunu zaten hissediyorsun, sadece henüz adını koymadın.";
  } else if (cards.length === 2) {
    reading += `${cards[0].name}: ${cards[0].relationshipMeaning}\n\n`;
    reading += `${cards[1].name}: ${cards[1].relationshipMeaning}\n\n`;
    reading += "Bu iki kart birlikte, içindeki çelişkiyi gösteriyor. Bir yanda istediğin, öbür yanda korktuğun. İkisini aynı anda yaşıyorsun ve bu seni tıkamış durumda.";
  } else {
    reading += cards.map((card, i) => 
      `${i + 1}. ${card.name}: ${card.relationshipMeaning}`
    ).join('\n\n');
    reading += "\n\nBu kartlar birlikte, döngünün tamamını gösteriyor. Nereye sıkıştığını, neden aynı yere geri döndüğünü, ve bundan çıkmak için neyi kabul etmen gerektiğini. Sen bunu biliyorsun. Sadece söylemek zor geliyor.";
  }
  
  return reading;
}
