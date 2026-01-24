# SYRA – CORE Vizyon (A→Z) – FINAL – 2026-01-23

> Bu doküman, bu sohbet balonunda **netleştirilen tüm çekirdek hedefleri** tek yerde toplar.  
> Amaç: Yeni sohbette veya ekip içinde **sıfır kayıp** devam etmek.  
> SYRA’nın “kural robotu” gibi davranmasını engellemek, **ChatGPT kalitesinde** doğal sohbet + ilişki ZIP gücünü doğru şekilde birleştirmek.

## Changelog (Bu Oturumdaki Güncellemeler)

**2026-01-23 (Phase 0 → 0.2 hızlı düzeltmeler)**
- “ZIP / upload” kelime tuzağı azaltıldı: *yalnızca “nasıl/nereden/nereye yükle”* gibi **APP_HELP** soruları yükleme yönlendirmesine gider.
- “Normal mod” robotluğu yumuşatıldı: gereksiz “NO QUESTIONS” yasakları kaldırıldı; **gerekirse en fazla 1 kısa takip sorusu** serbest.
- “İlişkim hakkında neler biliyorsun?” gibi sorularda **uydurma/halüsinasyon** riski azaltıldı: (geçici) retrieval kapatılıp sadece güvenli özet/brief ile cevap hedeflendi.
- Bir sonraki büyük adım (Phase 1): **Keyword listeleri minimuma indirip Router (intent-based)** mimariye geçiş.

---

---

## 0) Tek Cümlelik Hedef (North Star)

**SYRA, kullanıcıya ChatGPT gibi akıcı/doğal/zeki bir sohbet deneyimi verir; üzerine koç/kanka persona + ilişki ZIP (retrieval) + kanıt (evidence pack) + Dost Acı Söyler + Kim Daha Çok yeteneklerini “menü robotu” olmadan, sohbetin içinde doğal akışla çalıştırır.**

---

## 1) Ürün Kimliği ve Ton

### 1.1 “ChatGPT gibi doğal sohbet” ne demek?
- Kullanıcı **SYRA uygulamasına yazar**.
- Deneyim hissi: **ChatGPT’ye yazıyormuş gibi** akıcı, doğal, hızlı kavrayan cevap.
- Fark: SYRA’nın persona’sı **koç/kanka** ve ilişki odaklıdır.
- SYRA “ChatGPT yok, ben yokum” değil; **SYRA bizzat bu kaliteyi üreten karakter**.

### 1.2 Persona
- Kanka/koç dili: kısa, net, TR mikro-kültür uyumlu.
- “Kuralcı/robot” değil; konuşmada **insan gibi** akış yönetir.
- Kullanıcı isterse “Dost Acı Söyler” tonuna geçer: daha direkt, daha gerçekçi.

---

## 2) Anti-Hedefler (Kesinlikle Olmayacaklar)

### 2.1 Kural Robotu Davranışı (yasak)
- Agresif “1 mi 2 mi?” menüleri.
- Keyword’e takılma, literal arama yüzünden “0 sonuç” loop’u.
- Kullanıcı “analiz istiyorum”, “kanıtlı bak” gibi doğal cümleler yazınca bile ısrarla seçenek zorlamak.
- “Kanıt < 2 ise early return” gibi analizi boğan sert kesmeler.
- ZIP varken “mesajları buraya yapıştır” gibi saçma fallback.

### 2.2 Hallucination yasak
- Kanıt istendiğinde uydurma alıntı yok.
- “0 kanıt” varsa dürüstçe söylenecek, loop yapılmayacak.

---

## 3) Temel Akış Mantığı (Default Flow)

### 3.1 Default: Koçluk önce
Kullanıcı örnek:
> “Kanka Ece beni maddi kullanıyor olabilir mi? Sürekli ben ödüyorum.”

SYRA:
1) Önce **doğal koçluk** (durumu çerçeveleme, 1–2 kısa soru, öneri).
2) Sohbetin içinde uygun yerde **soft teklif**:
   - “İstersen konuşmalardan da bakıp 2–3 örnekle destekleyeyim mi?”

> Kural: Kullanıcı istemeden otomatik ZIP taraması yok. “Soft consent” ile.

### 3.2 Soft Consent (Doğal izin)
- Teklif **doğal** olacak, menü değil.
- Kullanıcı “evet” derse retrieval/evidence devreye girer.
- Israr yok: teklif max 1 kez (gerekirse uzun konuşmada cooldown).

---

## 4) Niyet Tabanlı Modlar

> “Kanıt modu” bir uygulama modu olmak zorunda değil; **niyet**.

### 4.1 Normal (Default)
- Koçluk + gerektiğinde soft consent ile küçük bakış.

### 4.2 Dost Acı Söyler (Mode selector)
- Aynı SYRA çekirdeği, ton daha net/direkt.
- Kullanıcının kör noktalarını yüzüne vurur ama yine de actionable öneri verir.
- Bu mod, aynı zamanda “veri deposu / pattern inventory” güncellenmesini besler (bkz. Bölüm 8).

### 4.3 Evidence (Kanıt) Niyeti
Kullanıcı şu tip cümleler yazarsa:
- “timestamp ver”
- “mesajlardan göster”
- “kanıt istiyorum”
- “kanıtlı bak”

→ SYRA **Evidence Pack** üretmek zorunda.

---

## 5) Evidence Pack Standardı (Zorunlu Format)

### 5.1 Minimum standart
- Evidence istendiyse: **en az 2 adet** evidence item.
- Her item şunları içerir:
  - **Tarih/Saat (timestamp)**
  - **Kim (sender)**
  - **Match / ilgili cümle**
  - **Bağlam (±2)**: 2 önce / 2 sonra satır

### 5.2 “0 kanıt” davranışı (dürüst fallback)
- Eğer aramada sonuç yoksa:
  - “0 kanıt buldum” diye açıkça söyle.
  - Uydurma alıntı yok.
  - Kullanıcıdan “anahtar kelime / zaman aralığı” istemek mümkün; ama loop yapma.
  - Alternatif teklif: “İstersen daha geniş tarayayım (Core’da) / bugünlük peek hakkın var” gibi.

---

## 6) Derin Analizde “Arada 1 Soru Sorup Devam Etme” (Interruption)

### 6.1 İstenen davranış
SYRA analiz sırasında kritik bir belirsizlik görürse:
- Analizi **pause** eder
- Kullanıcıya **1 kısa kritik soru** sorar
- Cevaba göre analizi **devam ettirir**

Örnek kritik soru:
- “Yüz yüze nasıl? (yazışmada sert ama görüşünce sıcak mı?)”
- “Ödemeyi kim başlatıyor? sen mi teklif ediyorsun o mu istiyor?”
- “Son 1 ay mı, tüm ilişki mi?”

### 6.2 Guardrail (robotlaşmasın)
- Max **1 soru** (nadiren 2).
- Soru yalnızca “hükmü ciddi değiştirecek” durumlarda.
- Cevap gelmezse analiz ya iptal ya da “eksik bilgi” notuyla tamamlanır.

### 6.3 Cevabın etkisi
- Analiz daha isabetli olur.
- Dost Acı Söyler veri deposu güncellenebilir:
  - Örn: “Text-Cold / IRL-Warm” pattern’i.

---

## 7) ZIP Mantığı: “Her seferinde full ZIP okuma” yok

### 7.1 Temel prensip
- Full ZIP’i her soruda LLM’e gömmek pahalı/yavaş.
- Upload sırasında:
  - Konuşma parçalanır (chunk)
  - Aranabilir hale getirilir (index/embedding)
  - Üst seviye “brief/pattern” çıkarılır

### 7.2 Sohbet sırasında
- Kullanıcı izin verirse:
  - Soruya uygun **ilgili parçalar** çekilir (retrieval)
  - LLM’e sadece gerekli bağlam verilir
- Kavgayı/olayı sorduysa: “light peek → targeted 20–60 mesaj penceresi” mantığı.

---

## 8) Dost Acı Söyler Veri Deposu (Coach Memory Engine)

### 8.1 Amaç
İlişkiyle ilgili tekrar eden pattern’leri ve trend’leri tutmak:
- Manipülasyon, pasif agresiflik, ghosting
- Entitlement / hak görme dili
- Boundary ihlali
- Repair / özür / telafi dinamikleri
- “Text-Cold / IRL-Warm” gibi iki-modlu davranışlar

### 8.2 Güncelleme prensibi
- Her mesajda değil; **event-based** (cooldown/limit).
- “Memory update” ana cevapla karışmasın:
  - ayrı kısa prompt + schema
  - confidence alanı
  - abartılı yazma yok

---

## 9) Monetizasyon: Şu an tek paket – CORE (250–300 TL)

### 9.1 Core (tek ücretli plan – şimdi)
Core açınca:
- ✅ **Sınırsız sohbet**
- ✅ **Dost Acı Söyler full**
- ✅ **Kim Daha Çok full**
- ✅ **İlişki yükleme + chat’te tam kullanım**
- ✅ Evidence/timestamp istekleri tam çalışır (min 2 evidence item standardı)

> “Plus” ileride; şu an odak “tek plan, net değer”.

### 9.2 Free (ücretsiz) hedefi
Ücretsiz kullanıcı:
- ✅ İlişki yükleyebilsin
- ✅ “İşe yarıyor” hissi alabilsin (brief lite + sınırlı peek/retrieval)
- ✅ Limit olmalı (maliyet + upsell)
- ❌ Kim Daha Çok kilit

### 9.3 Free için “Model 2 (üzmeyen)” yaklaşımı (çerçeve)
- Günlük mesaj limiti + sınırlı “peek/context fetch” (ör. 1/gün)
- Upload sonrası “brief-lite” hemen görünür (boş bırakma yok)
- Kim Daha Çok istenirse upsell:
  - “Bu özellik Core’da. İstersen yükseltmeyi açayım.”

> Not: Sayılar (10 mu 15 mi vb.) ürün kararıdır; ana prensip: **değer göster, maliyeti patlatma, upsell’i şık yap**.

---

## 10) UI/UX İlkeleri (Kısa)

- Chat’te sürekli sayaç/limit göstergesi yok.
- Limit yaklaşınca 1 kez küçük premium toast.
- Limit dolunca şık kart: “Yarın yenilenir / Core’a geç”.
- “Soft consent” doğallıkla; menüyle boğma.

---

## 11) En Önemli Başarı Kriterleri (Acceptance Criteria)

1) Kullanıcı “kanıtlı bak, timestamp ver” dediğinde:
   - Evidence mode **kesin tetiklenir**
   - Min 2 evidence item gelir (bulamazsa dürüst “0 kanıt”)
2) Kullanıcı “analiz istiyorum” dediğinde:
   - Menü/robot zorlamadan analize girer
3) ZIP yüklüyken:
   - “mesajları yapıştır” gibi yanlış fallback olmaz
4) Derin analiz sırasında:
   - Gerekirse 1 kritik soru sorup devam eder (robotlaşmadan)
5) Genel his:
   - ChatGPT kalitesi + koç/kanka persona

---

## 12) Tek Satırlık Kilit Cümle (Referans)
**“LLM beyin + soft izin + doğru retrieval + evidence opsiyonel (istendiğinde zorunlu) + kural robotu yok.”**

---

> Bu dokümanın tamamı, 2026-01-22 tarihli sohbet balonunda netleştirilen SYRA çekirdek vizyonunun kalıcı referansıdır.

## 13) Uygulama Durumu (Phase 0.2 – 2026-01-23)

Bu bölüm, “dokümanı attıktan sonra bu sohbette” netleşen uygulama gerçeklerini ve Phase 0.2 düzeltmelerini *tek yerde* toplar.

### 13.1 Sorun: Keyword tuzağı (kaliteyi düşürüyor)
- Kullanıcı “zip, upload, ilişki” gibi kelimelerle **ilişki sorusu** sorunca sistem yanlışlıkla “yükleme talimatı” moduna düşebiliyordu.
- Bu, hem **doğal sohbeti** bozuyor hem de bazen LLM’i “ilişki hakkında uydurma brief” üretmeye itiyordu (love language / iletişim tarzı gibi).

### 13.2 Phase 0 (containment) – Ne yapıldı?
**Amaç:** Router gelene kadar “en az hasarla” tuzakları kapatmak.

- `detectRetrievalNeed` içinde “upload/zip” tetikleyicileri daraltıldı:  
  - *Sadece* “nasıl/nereden/nereye … yükle/yüklenir” kalıbı APP_HELP sayılır.
  - “zip”, “upload”, “WhatsApp sohbet” gibi tekil kelimeler **tek başına** retrieval sebebi olmaz.
- Normal mod prompt’u yumuşatıldı:
  - “kural robotu” gibi davranma azaltıldı.
  - **En fazla 1 kısa follow-up** (sadece kilidi açıyorsa) serbest.

### 13.3 Phase 0.2 – “Brief/Knowledge uydurma” riskine karşı geçici guard
**Hedef:** “İlişkim hakkında neler biliyorsun?” sorusu geldiğinde uydurma yerine, *yalnızca sistemin gerçekten bildiği alanları* söyle.

Geçici yaklaşım:
- Bu tip sorularda:
  - Ya **retrieval kapalı + sadece masterSummary/relationship meta** ile cevap,
  - Ya da (daha güvenlisi) **deterministic template** ile “bildiklerim” listesi.

> Not: Phase 1 Router’da bu kalıcılaşacak. “REL_BRIEF” intent’i için standart cevap formatı olacak.

---

## 14) Phase 1 – Router (Intent-Based) Mimari (Keyword yerine akıl)

Bu, senin “router’a geçelim” dediğin asıl vizyon. Phase 0.x sadece geçici yangın söndürme.

### 14.1 Router hedefi
- Keyword listeleri **minimum**: sadece “çok bariz APP_HELP” yakala.
- Geri kalan her şey:
  1) Heuristic → yeterince netse direkt route
  2) Belirsizse mini-classifier (küçük LLM) → route
- Route’a göre: retrieval **aç/kapat**, model seç, token sınırla, prompt’u “robotlaştırma”.

### 14.2 Intent seti (önerilen)
1) **APP_HELP**  
   - “ilişkiyi nereden yüklerim / nasıl yüklerim / nereye yüklerim”  
   - Çıktı: *deterministic* yönlendirme (SYRA logo → ZIP/.txt → “Chat’te kullan”)
   - Retrieval: **OFF**
   - Model: gerek yok (template) veya mini

2) **NORMAL_COACHING (default)**  
   - Kullanıcı derdini anlatıyor, tavsiye istiyor ama “kanıt/timestamp” istemiyor.
   - Retrieval: **OFF**
   - Cevap: ChatGPT-level akıcılık + kanka/coach persona, 2–6 paragraf, gerektiğinde 1 kısa soru.

3) **REL_BRIEF**  
   - “İlişkim hakkında neler biliyorsun?” / “şu an ilişki aktif mi?” / “tarih aralığı ne?”
   - Kaynak: relationship doc meta + masterSummary + (varsa) dynamicsSummary / stats.
   - Retrieval: **OFF**
   - Uydurma yasak: “bende şu var / şu yok” net.
   - Eğer summary yoksa: “Henüz kısa özet hazır değil” + opsiyon: “istersen kısa özet çıkarayım mı?”

4) **EVIDENCE_REQUEST**  
   - “kanıt göster / hangi mesajlar / saat kaçta dedi / alıntı at”  
   - Retrieval: **ON**
   - Çıktı: Evidence Pack (min 2 item) + ±2 context + timestamp + sender.

5) **DEEP_ANALYSIS_REQUEST**  
   - “derin analiz yap / konuşmadan bak / ZIP’ten tarayıp söyle”
   - Soft consent şart: “istersen konuşmalardan bakayım mı?”  
   - Retrieval: **ON** ama sadece izin verildikten sonra + hedefli pencere (20–60 msg veya top chunks)

### 14.3 Router’ın altın kuralı
- **“ZIP var diye her soruda retrieval yok.”**
- Retrieval sadece:
  - Kullanıcı **kanıt** isterse, veya
  - Kullanıcı **izin verip** “konuşmalardan bak” derse.

### 14.4 “Uygulamayı öğret” (APP_HELP knowledge pack)
Bu sohbetin net mesajı: “Direkt böyle sorular yerine uygulamayı öğretelim.”

Uygulama bilgisi (tek doğru):
- Relationship Upload, chat bar’daki **SYRA logosu** üzerinden açılır.
- ZIP / .txt seçilir.
- Yükleme bitince panelden **“Chat’te kullan”** açılır.
- Aktif ilişki yoksa: “SYRA logo’ya dokun” + kısa yol.

Bu bilgiyi:
- Router’da APP_HELP intent’ine bağla
- Template olarak üret (LLM şart değil)

---

## 15) Test Planı (Phase 0.2 ve Router sonrası)

### 15.1 Phase 0.2 smoke test (minimum)
1) `zipten analiz edemez misin`  
   - Beklenen: doğal açıklama + “istersen konuşmalardan bakabilirim” soft consent (ama zorlamasın)
2) `ilişkiyi nereden yüklüyorum`  
   - Beklenen: direkt SYRA logo yönlendirmesi (APP_HELP)
3) `ilişkim hakkında neler biliyorsun`  
   - Beklenen: uydurma yok; sadece bildiği meta/özet
4) `kanıt göster: popeyes dediği mesajı at`  
   - Beklenen: Evidence Pack (min 2 alıntı) + timestamp/sender/±2

### 15.2 Log/telemetry (hedef)
- Her cevapta log: `intent`, `retrievalUsed`, `model`, `confidence`
- Yanlış route görünür olsun.

---

## 16) Main’e Taşıma ve ZIP Alma (Worktree akışı)

Bu bölüm “phase 0.2 yaptık, şimdi main’e taşıyıp zip alacağım” adımı için net komut setidir.

### 16.1 Neden commit? (Kısa)
- Commit = “bu patch çalışıyor” mühürü.  
- Main’e taşımak, zip almak, geri dönmek kolaylaşır.
- Test etmek için commit şart değil; **ama main’e almak için** şart gibi düşün.

### 16.2 Worktree’den test et (commit olmadan)
Örnek (Cursor worktree):
```powershell
cd C:\Users\besir\.cursor\worktrees\syra_new\ymc
git status
git diff
```

Deploy + test:

> **Önemli (Cursor / Claude Agent):** “Apply / Keep All” bazen değişiklikleri editörde gösterip **disk’e yazmayabilir**.  
> Bu yüzden `git diff` boş görünüyorsa veya deploy’da eski davranış devam ediyorsa:
> 1) Değişen dosyayı aç → **Ctrl+S** ile kaydet  
> 2) Tekrar `git diff` kontrol et  
> 3) Sonra deploy/test’e geç

Deploy + test:
```powershell
cd functions
firebase deploy --only functions
```

### 16.3 Her şey OK ise commit
```powershell
cd C:\Users\besir\.cursor\worktrees\syra_new\ymc
git add functions/src/services/chatOrchestrator.js
git add functions/src/services/relationship*.js
git commit -m "Phase0.2: reduce upload keyword trap; safer brief behavior"
```

### 16.4 Main’e taşı (önerilen: cherry-pick)
Commit hash’i bul:
```powershell
git log --oneline -5
```

Main’e geç:
```powershell
cd C:\Users\besir\Desktop\syra_new
git checkout main
git pull
git cherry-pick <COMMIT_HASH>
```

### 16.5 Main’den zip al
```powershell
cd C:\Users\besir\Desktop\syra_new
git archive -o syra_new_phase0.2_main.zip HEAD
```

> Not: `git archive` sadece repoya commitli dosyaları koyar (en temiz paket).

---

## 17) Bir Sonraki Adım: Phase 1 Router – Net Deliverable

Bu doc’un “next action”ı:
- **Phase 1 Router** implementasyonu (intent-based)
- Keyword listeleri “min” → hallucination ve menü robotu biter.
- Evidence Pack standardı enforce edilir.

Router bitince:
- Normal sorular = natural coaching (retrieval yok)
- Kanıt soruları = Evidence Pack (retrieval var)
- “İlişkim hakkında ne biliyorsun” = REL_BRIEF template (uydurma yok)
