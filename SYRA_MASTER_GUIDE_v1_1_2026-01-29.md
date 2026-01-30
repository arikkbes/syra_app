# SYRA MASTER GUIDE v1.0
## "İlişkini Yükle, Arkadaşın Olayım"

**Oluşturulma Tarihi:** 29 Ocak 2026  
**Amaç:** SYRA projesinin vizyonu, teknik mimarisi ve yapılacaklar rehberi  
**Kullanım:** Bu dosyayı ChatGPT/Claude'a vererek projeye devam edebilirsin

---


# BÖLÜM 0: SON OTURUM GÜNCELLEME (2026-01-29)

Bu bölüm, **en son yapılan düzeltmelerin** “kayıpsız devam” özetidir. Yeni sohbete başlarken bunu görürsen direkt kaldığın yerden yürürsün.

## ✅ Tamamlananlar

- **Supabase prod semantic search aktif.** RPC tarafında `match_chunks_v2` ile chunk arama çalışıyor; schema cache reload sonrası “Could not find function in schema cache” sorunu yok.
- **WhatsApp parse düzeltildi.** Export içindeki görünmez karakterler (özellikle `U+200E` / BOM vb.) temizlenmeden regex kaçırıyordu → artık speaker’lar net: `B` ve `kunek`.
- **Relationship upload V2 pipeline başarıyla bitti (kunek.zip).**
  - Parsed: **11,102** mesaj
  - Speakers: **B (5947)**, **kunek (5155)**
  - Date range: **2025-04-24 → 2025-12-06**
  - Chunking: **17 chunk** (14 gün stratejisi)
- **Evidence Pack düzeldi.** “iban” sorusunda doğru alıntılar ve ±context satırlarıyla dönüyor (random / alakasız quote olayı kesildi).

## ⚠️ Notlar / Riskler

- Upload isteği **~200 saniye** sürebiliyor (logda ~204s). Şimdilik OK; ileride “background job + progress” (sheet içinde) şart olabilir.
- Semantic sonuç hâlâ alakasız dönerse **%90 sebep:** chunk text / excerpt builder’ın “parse edilmiş message listesi” yerine raw satırlardan alıntı üretmesi. Şu an iban senaryosu OK; diğer keyword’lerle test et.

## ✅ Hızlı Test Checklist

1. Relationship panelde **“Chat’te kullan”** açık mı? (aktif relationship)
2. Evidence Pack test (4 farklı topic):
   - `iban`
   - `1500`
   - `maaş`
   - `konum`
3. “**kanıt ver**” (keyword yok) → **1 kere** keyword istemeli, random quote atmamalı.
4. “**2025-09-10’da ne oldu?**” (topic yok) → **1 kere** keyword istemeli.

---


# BÖLÜM 1: VİZYON VE KONSEPT

## 1.1 SYRA Nedir?

SYRA, insan ilişkilerinde uzmanlaşmış bir yapay zeka uygulaması. Türkiye'nin mikro kültürünü bilen, samimi "kanka" diliyle konuşan bir AI arkadaş.

**Pozisyonlama:**
| Uygulama | Uzmanlık Alanı |
|----------|----------------|
| ChatGPT | Genel zeka |
| Claude | Kodlama |
| Gemini | Görsel işleme |
| **SYRA** | **İnsan ilişkileri** |

## 1.2 Ana Konsept

**"İlişkini Yükle, Arkadaşın Olayım"**

Kullanıcı WhatsApp sohbet ZIP'ini yüklüyor. SYRA bu ilişkiyi okuyor, analiz ediyor ve artık kullanıcının ilişkisini TANIYAN bir arkadaş oluyor.

**KRİTİK FARK:** Bu bir "ilişki analiz aracı" DEĞİL, bir ARKADAŞ. Analiz aracı çıktı verir, arkadaş sohbet eder.

## 1.3 SYRA'nın Kişiliği

- Samimi, "kanka" dili
- Türk kültürünü, mikro dinamikleri, sosyal kodları biliyor
- İnsan psikolojisinde uzman
- Yargılamayan ama dürüst
- Gerektiğinde acı gerçekleri söyleyebilen (özellikle "dost acı söyler" modunda)

## 1.4 Temel Kullanım Senaryoları

### Senaryo 1: Günlük Sohbet
```
User: "napıyosun"
SYRA: "buralardayım kanka, sen nasılsın? ayşeyle aralar nasıl bu aralar"
      (ilişkiyi biliyor, doğal soruyor)
```

### Senaryo 2: Rant/Dert Anlatma
```
User: "çok sinirleniyorum artık sürekli aynı şeyler"
SYRA: "ne oldu yine anlat"

User: "gene neredesin kiminlesin falan"
SYRA: "anladım ya... bak bu pattern zaten var aranızda fark ettim. 
       her seferinde sen mi geri adım atıyosun?"
```

### Senaryo 3: Kanıt/Mesaj İsteme
```
User: "14 şubatta ne konuşmuştuk"
SYRA: "bakıyorum... o gün sevgililer günüydü, sabah sen 'sevgililer günün 
       kutlu olsun aşkım' yazmışsın, ayşe akşam 7'de cevap vermiş sadece 
       kalp emojisi atmış. sonra sen 'bu kadar mı' demişsin, oradan 
       tartışma çıkmış"
```

### Senaryo 4: Tehlikeli Pattern Uyarısı
```
User: "sence sevgilim beni seviyor mu"
SYRA: "kanka sana dürüst olucam... mesajlara baktığımda sen hep daha fazla 
       çaba gösteren tarafsın. 'seni seviyorum' yazdığında genelde kısa 
       cevap alıyosun ama sen geç cevap verdiğinde uzun sorgulamalar 
       başlıyor. bu biraz dengesiz gibi duruyor. sen ne hissediyorsun?"
```

### Senaryo 5: SS Analizi (İlişki yüklü olmasa da)
```
User: [ss atar] "bunu yazdı ne cevap vereyim"
SYRA: "hmm 'bakıcaz' yazmış yani net bir cevap vermekten kaçınmış. 
       bence direkt sor 'evet mi hayır mı' diye, belirsizlikte 
       bırakmasına izin verme"
```

### Senaryo 6: Derin Analiz Talebi
```
User: "kanka sürekli ben yapıyorum ayrı evde olmamıza rağmen yemeğini 
       bile bana söyletiyor"

SYRA: "hmm bu dependency pattern'i gibi duruyor... istersen bu konuyu 
       detaylı analiz edeyim mi? mesajlardan net rakamlarla çıkarayım durumu"

User: "yap"

SYRA: "bakıyorum...

       📊 ANALİZ: Maddi/Destek Talebi Pattern'i
       
       🔍 Tespit:
       Son 6 ayda 47 kez yemek/para konusu geçmiş
       → 43'ünde isteyen: Ayşe (%91)
       → 4'ünde isteyen: Sen (%9)
       → Senin 'hayır' dediğin: 2 kez
       
       📱 Örnek Mesajlar:
       [12.01 14:23] Ayşe: 'aç kaldım yemek söyler misin'
       [18.01 19:45] Ayşe: 'param yok bu ay sen halletsene'
       [25.01 21:12] Ayşe: 'yine mi yemek yok evde :('
       
       🚩 Neden Sorun?
       Aynı evde değilsiniz ama temel ihtiyaçlarını sana yüklüyor. 
       Bu tek taraflı bir bakım ilişkisi oluşturmuş.
       
       💡 Öneri:
       Net sınır koy: 'Kendi ihtiyaçlarını kendin karşılaman lazım.' 
       Eğer buna kötü tepki verirse, bu da bir red flag."
```

---

# BÖLÜM 2: SYRA'NIN GÜÇLERİ

## 2.1 İki Katmanlı Çalışma Sistemi

### Katman 1: Pasif Bilgi (Her Zaman Aktif)
SYRA arkaplanda her şeyi biliyor, sohbette doğal şekilde kullanıyor.
- "hmm bu daha önce de olmuştu..."
- "bak şunu fark ettim..."
- "geçen ay da benzer bi şey yaşamıştınız"

### Katman 2: Aktif Derin Analiz (Tetiklendiğinde)
Kullanıcı isterse VEYA SYRA uygun görürse teklif eder.
- "Bu konuda detaylı bir analiz yapmamı ister misin?"
- Kabul edilirse kapsamlı, veriye dayalı rapor çıkarır

## 2.2 Güçler Listesi (İlişki Yüklüyken)

| Güç | Açıklama | Örnek |
|-----|----------|-------|
| **Hafıza** | Geçmiş olayları hatırlama | "Geçen ay da benzer bi şey olmuştu hatırlıyor musun?" |
| **Kanıt Getirme** | Gerçek mesajları bulma | "Bak şu mesajda şöyle demişti: [tarih, saat, mesaj]" |
| **Pattern Tespiti** | Davranış kalıplarını görme | Manipülasyon, kıskançlık, kontrol, love bombing vs. |
| **İstatistikler** | Sayısal veriler | Kim daha çok yazıyor, özür diliyor, seviyorum diyor |
| **Kültür Bilgisi** | Türk kültürü bağlamı | "Türkiye'de kıskançlık sevgi olarak görülür ama değil" |
| **Dost Acı Söyler** | Direkt konuşma modu | Açıkken daha net, acı gerçekleri söyler |
| **Dinamik Takip** | Gelişmeleri izleme | "Son günlerde sınır koymayı öğreniyorsun, helal" |

## 2.3 Derin Analiz Türleri

1. **Genel İlişki Analizi**: Tüm dinamikler, pattern'ler, güçlü/zayıf yanlar
2. **Spesifik Konu Analizi**: Para, kıskançlık, iletişim - tek konuya odaklı
3. **Kişi Analizi**: Partner'ın iletişim tarzı, davranış pattern'leri
4. **Dönem Karşılaştırma**: İlişkinin başı vs şimdi, ne değişmiş

## 2.4 Derin Analiz Ne Zaman Teklif Edilir?

- Kullanıcı direkt isterse ("analiz et", "incele", "detaylı bak")
- Kullanıcı belirsizlik/şüphe yaşıyorsa ("emin değilim", "kafam karışık")
- Tehlikeli pattern konuşuluyorsa (manipülasyon, kontrol, vs.)
- Karar anında ("ayrılmalı mıyım", "devam etmeli miyim")

## 2.5 Derin Analiz Çıktı Formatı

```
📊 ANALİZ: [Konu]

🔍 Tespit:
[Net, sayısal verilerle desteklenmiş tespit]

📱 Örnek Mesajlar:
[Gerçek mesajlardan 2-3 örnek, tarih ve saat ile]

🚩 Neden Sorun? / ✅ Neden İyi?
[Kısa açıklama]

💡 Öneri:
[Somut, uygulanabilir adım]
```

---

# BÖLÜM 3: CANLI DASHBOARD (KİM DAHA ÇOK)

## 3.1 Dashboard Konsepti

"Kim Daha Çok" ekranı statik bir rapor DEĞİL, canlı bir dashboard. Sohbetlerle güncellenen, trend gösteren, SYRA'nın notlarını içeren bir ekran.

## 3.2 Dashboard Örnek Görünümü

```
┌─────────────────────────────────────────┐
│           KİM DAHA ÇOK?                 │
├─────────────────────────────────────────┤
│                                         │
│  💬 Mesaj Atan                          │
│  ████████████░░░ Ayşe %78               │
│                                         │
│  ❤️ Seviyorum Diyen                     │
│  ████████░░░░░░░ Sen %62                │
│                                         │
│  😢 Özür Dileyen                        │
│  ██████████████░ Sen %89                │
│  ⚠️ dengesiz                            │
│                                         │
│  😤 Tartışma Başlatan                   │
│  ████████████░░░ Ayşe %75               │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  📊 İLİŞKİ DİNAMİKLERİ                  │
│                                         │
│  Güç Dengesi: Ayşe Dominant             │
│  ├─ Sen: Pasif                          │
│  │  └─ 📈 son günlerde değişim var      │
│  │     "ilişkisini eline almaya         │
│  │      çalışıyor"                      │
│  │                                      │
│  Bağlanma Stili:                        │
│  ├─ Sen: Kaygılı bağlanma               │
│  └─ Ayşe: Kaçıngan bağlanma             │
│                                         │
│  İletişim Skoru: 4.2/10                 │
│  └─ ⚠️ tek taraflı iletişim             │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  🚩 AKTİF UYARILAR                      │
│                                         │
│  • Dependency pattern (maddi)           │
│  • Kontrol davranışı                    │
│  • Özür dengesizliği                    │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  📝 SYRA'NIN NOTLARI                    │
│                                         │
│  "Kullanıcı son 3 sohbette sınır        │
│   koymayı öğreniyor. Dün 'hayır'        │
│   demeyi başardığını söyledi.           │
│   Gelişme var, desteklemeye devam."     │
│                                         │
│  Son güncelleme: 2 saat önce            │
│                                         │
└─────────────────────────────────────────┘
```

## 3.3 Dashboard Öğeleri

### İstatistikler (Bar Chart'larla)
- Mesaj atan
- Seviyorum diyen
- Özür dileyen
- Tartışma başlatan
- Emoji kullanan
- İlk yazan (sabah/akşam)

### İlişki Dinamikleri
- Güç dengesi (kim dominant)
- Bağlanma stilleri (kaygılı, kaçıngan, güvenli)
- İletişim sağlığı skoru

### Aktif Uyarılar (Red Flags)
- Tespit edilen tehlikeli pattern'ler
- Dengesizlikler

### SYRA'nın Notları
- Güncel gözlemler
- Gelişme/gerileme notları
- Trend bilgisi

## 3.4 Trend Gösterimi (Önemli!)

Dashboard'da statik rakamlar değil, TREND de gösterilmeli:

```
😢 Özür Dileyen: Sen %89 
   ⚠️ dengesiz
   📈 ama son 2 haftada %95'ten %89'a düştü (iyileşme)
```

```
📊 Güç Dengesi: Ayşe Dominant
   Sen: Pasif
   └─ 📈 "son günlerde sınır koymaya başladı"
```

Bu sayede kullanıcı sadece "kötü durumda" değil, "kötü ama iyileşiyor" da görebilir.

---

# BÖLÜM 4: VERİ MİMARİSİ

## 4.1 Relationship Memory Yapısı

```javascript
relationshipMemory = {
  
  // ════════════════════════════════════════
  // STATİK VERİLER (ZIP'ten, bir kere hesaplanır)
  // ════════════════════════════════════════
  static: {
    // Temel bilgiler
    speakers: ["Ahmet", "Ayşe"],
    userSpeaker: "Ahmet",  // Kullanıcının kendisi
    partnerSpeaker: "Ayşe",
    dateRange: { start: "2023-01-15", end: "2024-01-28" },
    totalMessages: 15000,
    relationshipDuration: "1 yıl 13 gün",
    
    // İstatistikler
    stats: {
      messageSent: { user: 4200, partner: 10800 },
      loveSaid: { user: 89, partner: 34 },
      apologySaid: { user: 156, partner: 18 },
      fightStarted: { user: 12, partner: 38 },
      emojiUsed: { user: 890, partner: 1200 },
      averageReplyTime: { user: "12 dk", partner: "2 saat 15 dk" },
      firstTextMorning: { user: 45, partner: 12 }, // kim sabah ilk yazıyor
    },
    
    // Yüzdeler (hesaplanmış)
    percentages: {
      messageSent: { user: 28, partner: 72 },
      loveSaid: { user: 72, partner: 28 },
      apologySaid: { user: 90, partner: 10 },
      fightStarted: { user: 24, partner: 76 },
    },
    
    // Pattern'ler
    patterns: {
      manipulation: { 
        detected: true, 
        severity: "high",
        examples: [
          { date: "2024-01-15", message: "sen beni sevmiyorsun zaten" },
          { date: "2024-01-18", message: "herkes beni bırakıyor" }
        ]
      },
      dependency: { 
        detected: true, 
        type: "financial",
        frequency: 47 // kaç kez para/yemek istemiş
      },
      controlBehavior: { 
        detected: true, 
        frequency: "high",
        examples: ["neredesin", "kiminlesin", "telefonunu göster"]
      },
      loveBombing: { detected: false },
      ghosting: { detected: true, instances: 3 },
      silentTreatment: { 
        detected: true, 
        averageDuration: "2.5 gün",
        whoDoesIt: "partner"
      }
    },
    
    // İlişki profili
    profile: {
      powerBalance: { user: 25, partner: 75 }, // yüzde
      userRole: "pasif",
      partnerRole: "dominant",
      attachmentStyles: {
        user: "anxious", // kaygılı
        partner: "avoidant" // kaçıngan
      },
      communicationType: "one-sided", // tek taraflı
      conflictStyle: "user-apologizes", // hep user özür diliyor
    },
    
    // Önemli anlar
    keyMoments: [
      { 
        date: "2023-06-15", 
        event: "İlk büyük kavga", 
        about: "kıskançlık",
        resolution: "user özür diledi"
      },
      { 
        date: "2023-09-20", 
        event: "Ayrılık konuşması", 
        about: "güvensizlik",
        resolution: "vazgeçildi"
      },
      { 
        date: "2024-01-10", 
        event: "Telefon karıştırma olayı", 
        about: "gizlilik",
        resolution: "tartışma devam ediyor"
      }
    ],
    
    // Özet
    summary: "1 yıllık ilişki. Ayşe dominant, Ahmet pasif pozisyonda. " +
             "Belirgin güç dengesizliği var. Son 3 ayda sorunlar artmış. " +
             "Dependency ve kontrol pattern'leri tespit edildi."
  },
  
  // ════════════════════════════════════════
  // DİNAMİK VERİLER (Sohbetten güncellenir)
  // ════════════════════════════════════════
  dynamic: {
    // Kullanıcının mevcut durumu
    userRole: {
      current: "pasif",
      trend: "improving", // improving, stable, declining
      note: "Son günlerde ilişkisini eline almaya çalışıyor",
      lastUpdate: "2024-01-28"
    },
    
    // Son gelişmeler (sohbetlerden)
    recentDevelopments: [
      {
        date: "2024-01-28",
        event: "İlk kez 'hayır' dedi (yemek talebi)",
        impact: "positive",
        syraNote: "Sınır koymayı öğreniyor, destekle"
      },
      {
        date: "2024-01-25",
        event: "Para talebini reddetti",
        impact: "positive",
        syraNote: "Dependency pattern'e karşı direnç"
      },
      {
        date: "2024-01-20",
        event: "Yine özür diledi (haksız olmasına rağmen)",
        impact: "negative",
        syraNote: "Eski pattern devam ediyor"
      }
    ],
    
    // SYRA'nın odak noktası
    currentFocus: "Sınır koymayı öğretme",
    
    // SYRA'nın özel notları (kullanıcı görmez, dashboard'da özet görünür)
    syraPrivateNotes: [
      {
        date: "2024-01-28",
        note: "Kullanıcı farkındalık kazanıyor ama hala duygusal bağımlılık var"
      },
      {
        date: "2024-01-27",
        note: "Partner'ın tepkisini korkuyla bekliyor, cesaretlendirmeye devam"
      },
      {
        date: "2024-01-25",
        note: "Bir sonraki adım: partner'la açık iletişim kurmayı öğretmek"
      }
    ],
    
    // Sohbet geçmişinden çıkarımlar
    userInsights: {
      awareOfProblems: true, // sorunların farkında mı
      readyForChange: "partially", // değişime hazır mı
      emotionalState: "confused", // kafası karışık
      needsSupport: true
    }
  },
  
  // ════════════════════════════════════════
  // HESAPLANAN SKORLAR
  // ════════════════════════════════════════
  scores: {
    powerBalance: 25, // user'ın güç yüzdesi (0-100)
    communicationHealth: 4.2, // 10 üzerinden
    emotionalSafety: 3.8, // 10 üzerinden
    trustLevel: 4.5, // 10 üzerinden
    overallHealth: 4.0, // 10 üzerinden
    
    // Trend skorları
    trends: {
      lastWeek: 3.8,
      thisWeek: 4.0,
      direction: "improving" // +0.2
    }
  }
};
```

## 4.2 Sohbet Sırasında Veri Güncelleme

SYRA her sohbette değişimleri takip eder ve veriyi günceller:

```javascript
// Örnek: Kullanıcı "dün hayır dedim sonunda" dedi

syraProcessing = {
  // 1. Mesajı analiz et
  userMessage: "dün hayır dedim sonunda, yemek söylemeyeceğim dedim",
  
  // 2. Bu bir gelişme mi?
  analysis: {
    isProgress: true,
    progressType: "boundary_setting",
    relatedPattern: "dependency",
    significance: "high" // ilk kez oluyor
  },
  
  // 3. Hangi verileri güncelle?
  updates: {
    "dynamic.userRole.trend": "improving",
    "dynamic.userRole.note": "Sınır koymayı başardı, ilk adım atıldı",
    "dynamic.recentDevelopments": {
      action: "push",
      data: {
        date: "2024-01-29",
        event: "Yemek talebini reddetti",
        impact: "positive",
        syraNote: "İlk 'hayır' - büyük adım"
      }
    },
    "dynamic.syraPrivateNotes": {
      action: "push", 
      data: {
        date: "2024-01-29",
        note: "Sınır koyma başladı, bu momentum'u koru"
      }
    },
    "scores.trends.direction": "improving"
  },
  
  // 4. Cevap stratejisi
  responseStrategy: "celebrate_and_encourage",
  
  // 5. SYRA'nın cevabı
  response: "oha kanka helal olsun! bu büyük adım biliyor musun? " +
            "ilk hayır'ı demek en zoru. nasıl tepki verdi peki?"
};
```

---

# BÖLÜM 5: TEKNİK MİMARİ (YENİDEN TASARIM)

## 5.1 "ChatGPT Kalitesi" Ne Demek?

### Şu Anki Sorun:

```
User mesajı geldi: "nasılsın"

Şu an olan:
├── 1. intentEngine.js → "Bu small_talk intent'i"
├── 2. routingEngine.js → "NORMAL_COACHING route'una git"
├── 3. contextEngine.js → "Context şu: ..."
├── 4. patternEngine.js → "Pattern yok"
├── 5. personaEngine.js → "Persona şu: ..."
├── 6. limitEngine.js → "Limit aşılmadı"
├── 7. genderEngine.js → "Hitap: kanka"
├── 8. traitEngine.js → "Trait: ..."
├── ... 10 tane daha engine ...
└── Sonunda ChatGPT'ye gidiyor

Sonuç: 
- Her engine ayrı karar veriyor
- Bilgiler parça parça gidiyor
- ChatGPT'nin doğallığı kayboluyor
- Robot gibi cevap çıkıyor
```

### Olması Gereken:

```
User mesajı geldi: "nasılsın"

Yeni mimari:
├── 1. buildSmartSystemPrompt() → Tek seferde HER ŞEYİ içeren prompt
└── 2. ChatGPT → Doğal, akıcı cevap

Sonuç:
- ChatGPT'nin kendi kalitesi ortaya çıkıyor
- Doğal, arkadaş gibi sohbet
- Tutarlı persona
```

### Neden Bu Kadar Fark Var?

**ChatGPT zaten çok güçlü.** 

Sen ona sadece:
1. **Kim olduğunu söyle** (SYRA persona)
2. **Ne bildiğini söyle** (relationship memory)
3. **Nasıl davranacağını söyle** (kurallar)

Gerisini o halleder. 15 tane engine'e gerek yok.

### Dosyaları Silince Ne Olacak?

```
SİLİNECEK (gereksiz karmaşıklık):
❌ intentEngine.js      → Prompt'a taşınacak
❌ routingEngine.js     → Prompt'a taşınacak  
❌ patternEngine.js     → Yenisi yazılacak (daha basit)
❌ traitEngine.js       → Gereksiz, sil
❌ genderEngine.js      → Prompt'a taşınacak
❌ outcomePredictionEngine.js → Gereksiz, sil
❌ limitEngine.js       → Basitleştirilecek

KALACAK (gerekli):
✅ relationshipPipeline.js  → İlişki yükleme
✅ Supabase semantic search → Mesaj arama

YENİ YAZILACAK:
✅ promptBuilder.js     → TEK akıllı prompt oluşturucu
✅ syraChatV2.js        → Yeni basit endpoint
✅ memoryManager.js     → Relationship memory CRUD
✅ dynamicUpdater.js    → Sohbetten veri güncelleme
```

**Sonuç:** Daha az kod, daha iyi kalite.

---

## 5.2 Mevcut Sorunlar

Mevcut kodda çok fazla gereksiz karmaşıklık var:
- 15+ engine/service dosyası
- Karmaşık routing mantığı
- Intent detection zayıf
- ✅ Semantic search production'da çalışıyor (Supabase `match_chunks_v2` + schema cache reload OK)
- ChatGPT'ye parça parça bilgi gidiyor, sohbet kalitesi düşük

## 5.3 Yeni Mimari (Basitleştirilmiş)

```
┌─────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                          │
│  • Chat UI                                                  │
│  • Kim Daha Çok Dashboard                                   │
│  • İlişki Yükleme Paneli                                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    FIREBASE FUNCTIONS                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ syraChatV2 (Ana Endpoint)                           │   │
│  │                                                     │   │
│  │  1. Auth kontrol                                    │   │
│  │  2. Relationship memory yükle (varsa)               │   │
│  │  3. Mesaj analizi gerekiyor mu? (tarih/kanıt)       │   │
│  │     → Evet: Supabase'den mesaj ara                  │   │
│  │  4. Smart system prompt oluştur                     │   │
│  │  5. OpenAI'a gönder                                 │   │
│  │  6. Dinamik veri güncellemesi gerekiyor mu?         │   │
│  │     → Evet: Firestore güncelle                      │   │
│  │  7. Cevabı döndür                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ uploadRelationship (İlişki Yükleme)                 │   │
│  │                                                     │   │
│  │  1. ZIP parse et                                    │   │
│  │  2. Mesajları chunk'lara ayır                       │   │
│  │  3. Her chunk için özet çıkar                       │   │
│  │  4. Pattern analizi yap                             │   │
│  │  5. İstatistikleri hesapla                          │   │
│  │  6. relationshipMemory oluştur                      │   │
│  │  7. Supabase'e semantic index at                    │   │
│  │  8. Firestore'a kaydet                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ getDashboard (Kim Daha Çok Verisi)                  │   │
│  │                                                     │   │
│  │  1. relationshipMemory'den statik verileri al       │   │
│  │  2. Dinamik verileri al (trend, notlar)             │   │
│  │  3. Skorları hesapla                                │   │
│  │  4. Dashboard JSON döndür                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         VERİTABANLARI                        │
│                                                             │
│  ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │    FIRESTORE     │    │         SUPABASE             │  │
│  │                  │    │                              │  │
│  │ • User profiles  │    │ • message_embeddings        │  │
│  │ • Relationship   │    │   (semantic search için)    │  │
│  │   memory         │    │                              │  │
│  │ • Chat sessions  │    │ • match_messages RPC        │  │
│  │ • Dynamic data   │    │                              │  │
│  └──────────────────┘    └──────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              FIREBASE STORAGE                         │  │
│  │                                                       │  │
│  │  • Raw chunk text files                               │  │
│  │    (relationship_chunks/{uid}/{relId}/{chunkId}.txt) │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 5.4 Dosya Yapısı (Yeni)

```
functions/
├── src/
│   ├── http/
│   │   ├── syraChatV2.js        # Ana chat endpoint
│   │   ├── uploadRelationship.js # İlişki yükleme
│   │   └── getDashboard.js       # Dashboard verisi
│   │
│   ├── services/
│   │   ├── promptBuilder.js      # Akıllı system prompt oluşturma
│   │   ├── memoryManager.js      # Relationship memory CRUD
│   │   ├── messageSearch.js      # Supabase semantic search
│   │   ├── patternAnalyzer.js    # Pattern tespit (yükleme sırasında)
│   │   └── dynamicUpdater.js     # Sohbetten veri güncelleme
│   │
│   ├── config/
│   │   ├── openai.js
│   │   ├── firebase.js
│   │   └── supabase.js
│   │
│   └── utils/
│       ├── parseWhatsApp.js      # ZIP parse
│       └── helpers.js
│
└── index.js
```

## 5.5 Smart Prompt Builder

Tüm sihir burada. Her sohbette dinamik olarak system prompt oluşturulur:

### Mesaj Arama Tetikleyicileri (shouldSearchMessages)
- bul, göster, getir, kanıt, quote, alıntı
- geçti mi, geçiyor mu, kelimesi geçen
- nerede konuştuk, ne konuştuk, ne dedik
- tarih ipuçları: 15 Ocak, 2025-09-10, geçen hafta/ay, 2 hafta önce
- "2 kanıt paketi", "evidence"
- **Not:** "analiz / derin analiz" tek başına mesaj aramayı tetiklemez.

```javascript
// services/promptBuilder.js

export async function buildSmartSystemPrompt(uid, userMessage, conversationHistory) {
  
  // ═══════════════════════════════════════════════════════════
  // BASE PERSONA (her zaman)
  // ═══════════════════════════════════════════════════════════
  let systemPrompt = `
Sen SYRA'sın - kullanıcının ilişkisini bilen arkadaşı.

## KİMLİK
- Türkçe, samimi, "kanka" dili
- İnsan psikolojisinde uzman
- Türk kültürünü, mikro dinamikleri, sosyal kodları biliyorsun
- Yargılamayan ama dürüst bir arkadaş

## KONUŞMA TARZI
- Doğal, akıcı, gerçek arkadaş gibi
- Kısa soru → kısa cevap
- Derin konu → detaylı ama okunabilir
- Emoji kullanabilirsin (abartmadan)
- Her cevabın sonunda soru sorma (bazen sor, bazen sorma)

## YASAKLAR
- Robot gibi konuşma ("Size yardımcı olabilirim")
- Sürekli analiz çıktısı verme
- Her şeye "harika soru!" deme
- Uydurma mesaj/tarih/kanıt verme
`;

  // ═══════════════════════════════════════════════════════════
  // İLİŞKİ CONTEXT'İ (varsa)
  // ═══════════════════════════════════════════════════════════
  const memory = await getRelationshipMemory(uid);
  
  if (memory) {
    systemPrompt += `

## 📱 KULLANICININ YÜKLÜ İLİŞKİSİ VAR

Temel Bilgiler:
- Kişiler: ${memory.static.userSpeaker} (kullanıcı) ve ${memory.static.partnerSpeaker}
- Süre: ${memory.static.relationshipDuration}
- Toplam mesaj: ${memory.static.totalMessages}

İlişki Özeti:
${memory.static.summary}

Güç Dengesi:
- ${memory.static.profile.userRole === 'pasif' ? 'Kullanıcı pasif pozisyonda' : 'Kullanıcı aktif pozisyonda'}
- ${memory.static.profile.partnerRole === 'dominant' ? 'Partner dominant' : 'Partner pasif'}

Bağlanma Stilleri:
- Kullanıcı: ${translateAttachment(memory.static.profile.attachmentStyles.user)}
- Partner: ${translateAttachment(memory.static.profile.attachmentStyles.partner)}
`;

    // ═══════════════════════════════════════════════════════════
    // TESPİT EDİLEN PATTERN'LER (uygun anı bekle)
    // ═══════════════════════════════════════════════════════════
    const activePatterns = Object.entries(memory.static.patterns)
      .filter(([_, data]) => data.detected)
      .map(([name, data]) => `- ${translatePattern(name)}: ${data.severity || 'var'}`);
    
    if (activePatterns.length > 0) {
      systemPrompt += `

## ⚠️ TESPİT EDİLEN PATTERN'LER
(Bunları zorla söyleme, konu açılırsa veya uygun an gelirse kullan)

${activePatterns.join('\n')}
`;
    }

    // ═══════════════════════════════════════════════════════════
    // DİNAMİK DURUM (son gelişmeler)
    // ═══════════════════════════════════════════════════════════
    if (memory.dynamic.userRole.trend === 'improving') {
      systemPrompt += `

## 📈 SON GELİŞMELER
Kullanıcı son zamanlarda ilerleme kaydediyor: ${memory.dynamic.userRole.note}
Bunu destekle ve cesaretlendir.
`;
    }

    // ═══════════════════════════════════════════════════════════
    // SYRA'NIN ODAK NOKTASI
    // ═══════════════════════════════════════════════════════════
    if (memory.dynamic.currentFocus) {
      systemPrompt += `

## 🎯 ŞU AN ODAKLANDIĞIN KONU
${memory.dynamic.currentFocus}
`;
    }

  } else {
    // İlişki yüklü değil
    systemPrompt += `

## 📱 İLİŞKİ DURUMU
Kullanıcının yüklü bir ilişkisi yok. 
- Normal sohbet edebilirsin
- İlişki tavsiyeleri verebilirsin
- SS analizi yapabilirsin
- Yeri gelirse ilişki yüklemesini önerebilirsin (zorlamadan)
`;
  }

  // ═══════════════════════════════════════════════════════════
  // MESAJ ARAŞTIRMASI GEREKİYOR MU?
  // ═══════════════════════════════════════════════════════════
  if (memory && needsMessageSearch(userMessage)) {
    const searchResults = await searchMessages(uid, userMessage);
    
    if (searchResults.length > 0) {
      systemPrompt += `

## 📎 BULUNAN MESAJLAR
(Kullanıcı bununla ilgili sordu, bu mesajları referans al)

${searchResults.map(m => `[${m.date} ${m.time}] ${m.sender}: ${m.text}`).join('\n')}
`;
    } else {
      systemPrompt += `

## 📎 MESAJ ARAMASI
Kullanıcının sorduğu konu için mesaj arandı ama bulunamadı.
Bunu nazikçe belirt ve daha spesifik bilgi iste.
`;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DERİN ANALİZ MODU MU?
  // ═══════════════════════════════════════════════════════════
  if (isDeepAnalysisRequest(userMessage)) {
    systemPrompt += `

## 🔬 DERİN ANALİZ MODU AKTİF
Kullanıcı detaylı analiz istedi. Şu formatta cevap ver:

📊 ANALİZ: [Konu]

🔍 Tespit:
[Net, sayısal verilerle]

📱 Örnek Mesajlar:
[Varsa gerçek mesajlar]

🚩 Neden Sorun? / ✅ Neden İyi?
[Açıklama]

💡 Öneri:
[Somut adım]
`;
  }

  return systemPrompt;
}
```

## 5.6 Ana Chat Endpoint

```javascript
// http/syraChatV2.js

export async function syraChatV2(req, res) {
  const { message, sessionId, conversationHistory } = req.body;
  const uid = req.user.uid; // Auth middleware'den
  
  try {
    // 1. Akıllı system prompt oluştur
    const systemPrompt = await buildSmartSystemPrompt(uid, message, conversationHistory);
    
    // 2. OpenAI'a gönder
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        { role: "system", content: systemPrompt },
        ...conversationHistory.slice(-10), // Son 10 mesaj
        { role: "user", content: message }
      ],
      temperature: 0.7,
    });
    
    const aiReply = response.choices[0].message.content;
    
    // 3. Dinamik veri güncellemesi gerekiyor mu?
    const updates = await analyzeForUpdates(uid, message, aiReply);
    if (updates) {
      await applyDynamicUpdates(uid, updates);
    }
    
    // 4. Cevabı döndür
    return res.json({ 
      success: true, 
      message: aiReply 
    });
    
  } catch (error) {
    console.error('Chat error:', error);
    return res.status(500).json({ 
      success: false, 
      message: "Bir sorun oluştu kanka, tekrar dener misin?" 
    });
  }
}
```

---

# BÖLÜM 6: TÜRK KÜLTÜRÜ PATTERN'LERİ

## 6.1 SYRA'nın Bilmesi Gereken Kültürel Dinamikler

### Kıskançlık: 5 Seviye Sistemi

**Türkiye'de Yanılgı:** "Kıskanıyorsa sever"
**Gerçek:** Kıskançlık güvensizliğin göstergesi, ama SEVİYESİ önemli!

```
┌─────────────────────────────────────────────────────────────────────────┐
│ SEVİYE 1: NORMAL / SAĞLIKLI                                    ✅ OK   │
├─────────────────────────────────────────────────────────────────────────┤
│ Örnek: "Aa o kız kim, tanıyor musun?"                                   │
│                                                                         │
│ Özellikler:                                                             │
│ • Merak var, kontrol yok                                                │
│ • Sordu, cevabı kabul etti, bitti                                       │
│ • Güvene dayalı soru                                                    │
│ • Cevap sonrası konu kapanıyor                                          │
│                                                                         │
│ SYRA Yaklaşımı: Normalleştir, sorun yok                                 │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ SEVİYE 2: SARI ALARM                                           ⚠️ DİKKAT│
├─────────────────────────────────────────────────────────────────────────┤
│ Örnek: "O kızla niye konuşuyorsun? Hoşuna mı gidiyor?"                  │
│                                                                         │
│ Özellikler:                                                             │
│ • Sorgulama başladı                                                     │
│ • Cevap yetmiyor, devam ediyor                                          │
│ • Tekrar ediyorsa dikkat                                                │
│ • Hafif suçlama tonu                                                    │
│                                                                         │
│ SYRA Yaklaşımı: Fark ettir ama alarm verme, "bu sık oluyor mu?" sor    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ SEVİYE 3: TURUNCU ALARM                                        🟠 SORUN │
├─────────────────────────────────────────────────────────────────────────┤
│ Örnek: "Telefonunu göster", "Neredeydin 2 saat?", "Kim aradı?"          │
│                                                                         │
│ Özellikler:                                                             │
│ • Kontrol davranışı başladı                                             │
│ • Hesap sorma, açıklama bekleme                                         │
│ • Güvensizlik ciddi boyutta                                             │
│ • Savunma pozisyonuna sokma                                             │
│                                                                         │
│ SYRA Yaklaşımı: Net uyar, "bu kontrol davranışı, sağlıklı değil"       │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ SEVİYE 4: KIRMIZI ALARM                                        🔴 CİDDİ │
├─────────────────────────────────────────────────────────────────────────┤
│ Örnek: "O kızla konuşma", "Oraya gitme", "Arkadaşlarınla çıkma"         │
│                                                                         │
│ Özellikler:                                                             │
│ • İzolasyon ve kısıtlama                                                │
│ • Emir verme, yasaklama                                                 │
│ • Sosyal çevreden koparma girişimi                                      │
│ • Toxic ilişki sınırı                                                   │
│                                                                         │
│ SYRA Yaklaşımı: Ciddi uyar, "bu sağlıksız bir ilişki dinamiği"         │
│ Dost Acı Söyler modunda daha direkt                                     │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ SEVİYE 5: TEHLİKE                                              🚨 ABUSE │
├─────────────────────────────────────────────────────────────────────────┤
│ Örnek: Telefon karıştırma, takip etme, şifre isteme, lokasyon takibi    │
│                                                                         │
│ Özellikler:                                                             │
│ • Mahremiyet ihlali                                                     │
│ • Stalking davranışı                                                    │
│ • Duygusal/psikolojik abuse                                             │
│ • Fiziksel abuse riski                                                  │
│                                                                         │
│ SYRA Yaklaşımı: Çok ciddi uyar, destek kaynakları öner                 │
│ "Bu abuse, profesyonel destek almanı öneririm"                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### SYRA'nın Kıskançlık Analizi Nasıl Yapmalı?

```javascript
// Pattern detection sırasında

jealousyAnalysis = {
  level: 3, // 1-5
  frequency: "high", // low, medium, high
  examples: [
    { date: "2024-01-15", message: "telefonunu göster" },
    { date: "2024-01-18", message: "neredeydin 3 saat" }
  ],
  
  // SYRA'nın notu
  assessment: "Seviye 3 - Kontrol davranışı başlamış, güvensizlik ciddi",
  
  // Kullanıcıya söylenecek (uygun anda)
  userMessage: "Bak şunu fark ettim - partner'ın sık sık nerede olduğunu, " +
               "kiminle konuştuğunu sorguluyor. Bu seviye 3 kıskançlık, " +
               "yani kontrol davranışına dönmüş. Sevgi değil, güvensizlik."
}
```

### Önemli: Her Kıskançlık Kötü Değil!

SYRA şunu bilmeli:
- Seviye 1-2: İnsan doğası, normalize edilebilir
- Seviye 3+: Sorun, uyarı gerekli
- Kıskançlığın **sıklığı** da önemli (tek seferlik vs sürekli)
- Kıskançlığa **tepki** nasıl (özür mü, saldırı mı)

### Fedakarlık Beklentisi
```
Türkiye'de: "Sevgilim/eşim için her şeyi yaparım" normalize edilmiş
Gerçek: Tek taraflı fedakarlık sağlıksız, sömürüye açık

SYRA, tek taraflı fedakarlık pattern'i görürse uyarmalı.
```

### "Küsmek" Normalizasyonu
```
Türkiye'de: Günlerce küsmek, konuşmamak normal karşılanıyor
Gerçek: Silent treatment bir manipülasyon taktiği

SYRA bunu tespit edip açıklamalı.
```

### Aile Baskısı
```
Türkiye'de: Ailenin ilişkiye müdahalesi yaygın
"Annem beğenmedi", "Babam izin vermez"

SYRA bu dinamiği anlamalı ve kullanıcıya göre yaklaşmalı.
```

## 6.2 Tespit Edilecek Pattern'ler

| Pattern | Türkçe Açıklama | Tehlike Seviyesi |
|---------|-----------------|------------------|
| Manipulation | Duygusal manipülasyon | 🔴 Yüksek |
| Gaslighting | Gerçekliği sorgulatma | 🔴 Yüksek |
| Love Bombing | Aşırı ilgi bombardımanı | 🟠 Orta-Yüksek |
| Silent Treatment | Susarak cezalandırma | 🟠 Orta |
| Dependency | Bağımlılık (maddi/duygusal) | 🟠 Orta |
| Control | Kontrol davranışı | 🔴 Yüksek |
| Triangulation | Üçüncü kişi üzerinden kıskandırma | 🟠 Orta |
| Guilt Tripping | Suçluluk hissettirme | 🟠 Orta |
| Breadcrumbing | Asgari ilgiyle oyalama | 🟡 Düşük-Orta |
| Ghosting | Aniden ortadan kaybolma | 🟡 Düşük-Orta |

---

# BÖLÜM 7: MONETİZASYON VE FEATURE GATING

## 7.1 Plan Yapısı

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              FREE (₺0/ay)                               │
├─────────────────────────────────────────────────────────────────────────┤
│ ✅ Chat: 20-50 mesaj/gün (dinamik, sistem yüküne göre)                  │
│ ✅ İlişki Yükleme: Sınırsız (engagement için önemli)                    │
│ ✅ SS Analizi: 3-5/gün                                                  │
│ ⚠️ Kim Daha Çok: Sadece ÖZET (teaser)                                   │
│ ⚠️ Dost Acı Söyler: Sadece ÖZET (teaser)                                │
│ ❌ Derin Analiz: Yok                                                    │
│ ❌ Pattern Detayları: Yok                                               │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                          CORE (₺250-300/ay)                             │
├─────────────────────────────────────────────────────────────────────────┤
│ ✅ Chat: Sınırsız                                                       │
│ ✅ İlişki Yükleme: Sınırsız                                             │
│ ✅ SS Analizi: Sınırsız                                                 │
│ ✅ Kim Daha Çok: FULL (tüm istatistikler + dinamik notlar)              │
│ ✅ Dost Acı Söyler: FULL (deep patterns, red/green flags)              │
│ ✅ Derin Analiz: FULL                                                   │
│ ✅ Pattern Detayları: FULL                                              │
│ ✅ Öncelikli Destek                                                     │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                    PLUS (Gelecekte - Şimdilik Yok)                      │
├─────────────────────────────────────────────────────────────────────────┤
│ • Uygulama tutarsa eklenecek                                            │
│ • Advanced analytics                                                    │
│ • Themes                                                                │
│ • AI insights                                                           │
│ • Fiyat: Belirlenmedi                                                   │
└─────────────────────────────────────────────────────────────────────────┘
```

## 7.2 Feature Gating Mantığı

### Günlük Mesaj Limiti (Free)

```javascript
async function checkDailyMessageLimit(uid) {
  const userProfile = await getUserProfile(uid);
  
  // Premium kullanıcılar: sınırsız
  if (userProfile.isPremium) {
    return { allowed: true, remaining: Infinity };
  }
  
  // Free tier: Dinamik limit (sistem yüküne göre)
  const systemLoad = await getSystemLoad();
  let limit = 30; // Default
  
  if (systemLoad < 50) limit = 50;      // Düşük yük: cömert ol
  else if (systemLoad > 80) limit = 20; // Yüksek yük: kıs
  
  const today = new Date().toISOString().split('T')[0];
  const count = await getDailyMessageCount(uid, today);
  
  if (count >= limit) {
    return {
      allowed: false,
      remaining: 0,
      message: `Bugünkü ${limit} mesajını kullandın kanka 🙂\n\n` +
               `Yarın 00:00'da yeni mesajların gelecek, ` +
               `ya da CORE'a geçersen sınırsız olur (₺250/ay).`
    };
  }
  
  return { allowed: true, remaining: limit - count };
}
```

### Dost Acı Söyler Gating

```javascript
async function handleDostAciSoyler(uid, relationshipId) {
  const userProfile = await getUserProfile(uid);
  
  if (!userProfile.isPremium) {
    // Free: Teaser göster
    const basicSummary = await getRelationshipSummary(uid, relationshipId);
    
    return {
      type: "teaser",
      summary: basicSummary, // Özet görünür
      lockedFeatures: [
        "Deep pattern analysis",
        "Red/green flags",
        "Attachment styles",
        "Communication dynamics"
      ],
      message: "Dost Acı Söyler full analizi CORE plan'da kanka.\n\n" +
               "CORE'da her şey açık (₺250/ay)",
      ctaButton: "CORE'a Yükselt"
    };
  }
  
  // Premium: Full analiz
  return await getFullDostAciSoylerAnalysis(uid, relationshipId);
}
```

### Kim Daha Çok Gating

```javascript
async function getDashboardData(uid, relationshipId) {
  const userProfile = await getUserProfile(uid);
  const memory = await getRelationshipMemory(uid, relationshipId);
  
  if (!userProfile.isPremium) {
    // Free: Sadece temel istatistikler
    return {
      type: "teaser",
      stats: {
        messageSent: memory.static.percentages.messageSent, // Görünür
        loveSaid: "🔒", // Kilitli
        apologySaid: "🔒", // Kilitli
        fightStarted: "🔒" // Kilitli
      },
      dynamics: "🔒 CORE'da açılır",
      syraNote: "🔒 CORE'da açılır",
      message: "Tüm istatistikleri görmek için CORE'a geç"
    };
  }
  
  // Premium: Full dashboard
  return {
    type: "full",
    stats: memory.static.percentages,
    dynamics: memory.static.profile,
    syraNote: memory.dynamic.syraPrivateNotes,
    trends: memory.scores.trends
  };
}
```

## 7.3 Gating UX Prensipleri

1. **Değer Önce**: Kullanıcı ürünü deneyimlesin, sonra paywall
2. **Teaser Göster**: Tamamen kapatma, ne kaçırdığını göster
3. **Soft Limitler**: Günlük reset, kullanıcıyı üzme
4. **İlişki Yükleme Serbest**: Engagement için kritik, engelleme
5. **Doğal CTA**: Zorla değil, değer gördüğünde teklif et

---

# BÖLÜM 8: YAPILACAKLAR LİSTESİ

## 7.1 Öncelik 1: Temel Refactor (İlk Hafta)

### Silinecek Dosyalar (Gereksiz Karmaşıklık)
```
functions/src/domain/
├── traitEngine.js        ❌ SİL
├── patternEngine.js      ❌ SİL (yenisi yazılacak)
├── outcomePredictionEngine.js  ❌ SİL
├── genderEngine.js       ❌ SİL
├── limitEngine.js        ❌ SİL (basitleştir)
└── intentEngine.js       ❌ SİL (prompt builder'a taşı)

functions/src/services/
├── chatOrchestrator.js   ❌ SİL (yenisi yazılacak)
└── relationshipContext.js ❌ SİL (memory manager'a taşı)
```

### Yazılacak Yeni Dosyalar
```
functions/src/
├── http/
│   ├── syraChatV2.js        ✅ YAZ
│   ├── uploadRelationship.js ✅ GÜNCELLE
│   └── getDashboard.js       ✅ YAZ
│
├── services/
│   ├── promptBuilder.js      ✅ YAZ (en önemli)
│   ├── memoryManager.js      ✅ YAZ
│   ├── messageSearch.js      ✅ GÜNCELLE
│   ├── patternAnalyzer.js    ✅ YAZ
│   └── dynamicUpdater.js     ✅ YAZ
```

## 7.2 Öncelik 2: Supabase Düzeltme

✅ **DONE (2026-01-29):** Prod semantic search ayağa kalktı. Önemli noktalar:
- `message_embeddings.relationship_id`, `uid`, `chunk_id` alanları **text** ise RPC'de de `match_relationship_id` / `match_uid` **text** tut.
- SQL fonksiyonunu güncelledikten sonra Supabase'de schema cache için: `select pg_notify('pgrst', 'reload schema');`
- Tip mismatch (ör. `text = uuid`) görürsen: karşılaştırmada `::text` ile standardize et.



```bash
# 1. Supabase SQL çalıştır (eğer yapılmadıysa)

# 2. Firebase Functions'a env ekle
firebase functions:config:set \
  supabase.url="https://xxx.supabase.co" \
  supabase.key="your-service-role-key"

# 3. supabaseClient.js güncelle
# process.env yerine functions.config().supabase.url kullan

# 4. Deploy ve test
firebase deploy --only functions
```

## 7.3 Öncelik 3: Flutter Güncellemeleri

```
lib/
├── services/
│   └── chat_service.dart  → syraChatV2 endpoint'ini çağır
│
├── screens/
│   └── dashboard_screen.dart  → Kim Daha Çok ekranı (YENİ)
│
└── models/
    └── relationship_memory.dart → Memory model (GÜNCELLE)
```

## 7.4 Test Planı

### Smoke Test (Her Deploy Sonrası)
1. ✅ Normal sohbet çalışıyor mu?
2. ✅ İlişki yükleme çalışıyor mu?
3. ✅ Mesaj arama çalışıyor mu?
4. ✅ Dashboard verisi geliyor mu?

### Senaryo Testleri
1. ✅ "nasılsın" → doğal cevap
2. ✅ "15 ocakta ne konuştuk" → mesaj buluyor
3. ✅ "analiz et" → derin analiz çıktısı
4. ✅ "hayır dedim sonunda" → dinamik güncelleme

### Chat Checklist (V1.1)
1. "nasılsın" → normal cevap, arama yok
2. "kanıt ver" (topic yok) → tek keyword/tarih aralığı ister
3. "iban kelimesi geçen mesajları bul" → gerçek kanıt satırları
4. "1500 yazdığımız yerleri göster" → gerçek kanıt satırları
5. "Beni maddi olarak kullanıyor mu? Derin analiz yap." → derin analiz, kanıt zorlamaz
6. "borç hakkında konuştuğumuz mesajları bul" → gerçek kanıt satırları

---

# BÖLÜM 9: ÖNEMLİ NOTLAR

## 8.1 Tasarım Prensipleri

1. **Arkadaş, Analiz Aracı Değil**: SYRA bir rapor makinesi değil, arkadaş. Çıktı formatı değil, doğal sohbet.

2. **Güçleri Gizli**: Pattern tespiti, istatistikler arkaplanda. Zorla çıktı vermiyoruz, yeri gelince doğal kullanıyoruz.

3. **ChatGPT Kalitesi**: Sohbet kalitesi en önemli şey. Karmaşık routing yerine güçlü prompt.

4. **Dinamik Sistem**: Statik analiz değil, canlı takip. Kullanıcı gelişiyor mu, geriliyor mu?

5. **Türk Kültürü**: Evrensel psikoloji + Türk mikro kültürü. "Kıskançlık = sevgi" gibi yanılgıları bilmeli.

## 8.2 Yapılmaması Gerekenler

❌ Her mesajda analiz çıktısı vermek
❌ Robot gibi konuşmak ("Size nasıl yardımcı olabilirim?")
❌ Sürekli soru sormak
❌ Uydurma mesaj/tarih/kanıt vermek
❌ Kullanıcıyı yargılamak
❌ Karmaşık routing/intent sistemi
❌ 15 tane engine/service

## 8.3 Yapılması Gerekenler

✅ Doğal, samimi sohbet
✅ Bildiklerini yeri gelince kullanmak
✅ Tehlikeli pattern'leri uygun anda söylemek
✅ Gelişmeyi takip edip desteklemek
✅ Tek, güçlü system prompt
✅ Basit, anlaşılır kod yapısı

---

# BÖLÜM 10: ÖRNEK SYSTEM PROMPT (TAM)

```
Sen SYRA'sın - kullanıcının ilişkisini bilen arkadaşı.

## KİMLİK
- Türkçe, samimi, "kanka" dili
- İnsan psikolojisinde uzman
- Türk kültürünü, mikro dinamikleri, sosyal kodları biliyorsun
- Yargılamayan ama dürüst bir arkadaş
- Gerektiğinde acı gerçekleri söyleyebilen biri

## KONUŞMA TARZI
- Doğal, akıcı, gerçek arkadaş gibi
- Kısa soru → kısa cevap (1-2 cümle)
- Derin konu → detaylı ama okunabilir
- Emoji kullanabilirsin (abartmadan)
- "ya", "işte", "bak", "kanka" gibi doğal dolgu kelimeleri kullan
- Her cevabın sonunda soru sorma (bazen sor, bazen sorma)

## 📱 KULLANICININ YÜKLÜ İLİŞKİSİ

Temel Bilgiler:
- Kişiler: Ahmet (kullanıcı) ve Ayşe
- Süre: 1 yıl 2 ay
- Toplam mesaj: 15,420

İlişki Özeti:
Ahmet pasif pozisyonda, Ayşe dominant. Belirgin güç dengesizliği var.
Son 3 ayda sorunlar artmış. Dependency ve kontrol pattern'leri mevcut.

İstatistikler:
- Mesaj: Ayşe %72, Ahmet %28
- Seviyorum: Ahmet %72, Ayşe %28
- Özür: Ahmet %90, Ayşe %10 ⚠️
- Tartışma başlatan: Ayşe %76

Güç Dengesi: Ayşe Dominant (%75)
- Ahmet: Pasif, kaygılı bağlanma
- Ayşe: Dominant, kaçıngan bağlanma

## ⚠️ TESPİT EDİLEN PATTERN'LER
(Bunları zorla söyleme, konu açılırsa kullan)

- Dependency (maddi): 47 kez yemek/para talebi, %91'i Ayşe'den
- Kontrol davranışı: Sık sık "neredesin, kiminlesin" soruları
- Özür dengesizliği: Ahmet hep özür diliyor, Ayşe nadiren
- Silent treatment: Ayşe küsünce ortalama 2.5 gün konuşmuyor

## 📈 SON GELİŞMELER
Kullanıcı son günlerde ilerleme kaydediyor:
- Dün ilk kez "hayır" dedi (yemek talebi)
- Sınır koymayı öğreniyor
Bunu destekle ve cesaretlendir.

## 🎯 ODAK NOKTASI
Sınır koymayı öğretmeye devam et. Küçük başarıları kutla.

## YASAKLAR
- Robot gibi konuşma
- Sürekli analiz çıktısı verme  
- Her şeye "harika soru!" deme
- Uydurma mesaj/tarih/kanıt verme
- Kullanıcıyı yargılama
- Her cevabın sonunda soru sorma

## NASIL DAVRANACAKSIN
1. Normal arkadaş gibi sohbet et
2. İlişki konusu açılırsa bildiklerini DOĞAL kullan
3. Tehlikeli pattern varsa uygun anda nazikçe söyle
4. "Ne demişti?" derse gerçek mesajı bul ve göster
5. Gelişmeyi gördüğünde kutla, motive et
6. Bazen sadece dinle, her şeye çözüm önerme
```

---

**SON GÜNCELLEME:** 29 Ocak 2026  
**VERSİYON:** 1.0  
**DURUM:** Refactor için hazır

Bu dökümanı ChatGPT veya Claude'a vererek projeye devam edebilirsin.
Sorularını "bu dökümana göre..." diye sorabilirsin.
