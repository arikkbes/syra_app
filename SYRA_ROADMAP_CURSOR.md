# SYRA FIX ROADMAP — ChatGPT → Cursor Workflow

**Amaç:** Bu dosya audit raporundaki TÜM bulguları çözüm sırasına göre düzenler. Her madde için ChatGPT'ye "bunu Cursor'a nasıl yaptıracağım" diye sorduğunda, ChatGPT'nin sana doğru prompt'u üretebilmesi için gerekli bağlamı içerir.

**Kullanım Şekli:**
1. Bu dosyayı + repo ZIP'ini ChatGPT'ye gönder
2. "Madde X için Cursor prompt'u yaz" de
3. ChatGPT sana Cursor-ready prompt üretsin
4. Cursor'da prompt'u çalıştır → test et → bir sonraki maddeye geç

---

## AŞAMA 0: HAZIRLIK (Cursor'a girmeden önce — 15 dk)

### ✅ 0.1 — OpenAI API Key Revoke — TAMAMLANDI
- Key OpenAI Dashboard'dan revoke edildi
- `.runtimeconfig.json` repodan silindi
- `.gitignore`'a eklendi

### 0.2 — Git History Temizliği (Terminal — Cursor dışı)
- **Ne:** `.runtimeconfig.json` dosyasını silmek yetmez. Git eski commit'lerde bu dosyanın tüm geçmişini tutuyor. Birisi `git log` ile geçmişe bakıp key'i bulabilir. Bu yüzden git geçmişinden de temizlenmesi lazım.
- **Basit anlatım:**
  - Bu işlem "force push" gerektirir. Yani repo'nun geçmişi değişir.
  - Eğer ekipte başka biri varsa, force push'tan sonra herkesin repo'yu silip sıfırdan `git clone` yapması gerekir.
  - Tek başına çalışıyorsan sorun yok, sadece komutu çalıştır.
- **Nasıl yapılır:**
  - Google'a "BFG Repo Cleaner" yaz, indir
  - Terminalde şunu çalıştır:
  ```bash
  bfg --delete-files .runtimeconfig.json
  git reflog expire --expire=now --all
  git gc --prune=now --aggressive
  git push --force
  ```
  - Emin değilsen ChatGPT'ye "bfg ile git geçmişinden dosya silme" diye sor, işletim sistemine göre (Mac/Windows) adım adım anlatır
- **Cursor gerekli mi:** HAYIR — terminalde çalıştır

### ✅ 0.3 — .gitignore Güncelle — TAMAMLANDI
- Root `.gitignore`'a `.runtimeconfig.json`, `functions/.runtimeconfig.json`, `.env`, `.env.*` eklendi
- `functions/.gitignore`'a `.runtimeconfig.json` ve `.env` eklendi

**✅ Aşama 0 tamamlandı:** OpenAI key revoke edildi, dosya silindi, .gitignore eklendi. Git history temizliği P2'ye taşındı (acil değil ama yapılmalı).

---

## AŞAMA 1: P0 — RELEASE BLOCKER FIX'LER ✅ TAMAMLANDI (18 Şubat 2026)

> P0 kodlama + deploy + smoke testlerin tamamı bitti. Release blocker kalmadı.

---

### ✅ 1.1 — Hesap Silme Akışını Tamamla — TAMAMLANDI
- **Öncelik:** P0 🔴 → ✅ ÇÖZÜLDÜ (18 Şubat 2026)
- **Yapılanlar:**
  - **Backend:** `functions/src/http/deleteUserDataHandler.js` oluşturuldu
    - Firebase Auth token doğrulaması (Bearer)
    - Subcollection'ları batch+recursive siliyor: `chat_sessions`, `usage_daily`, `profile_memory`, `conversations`
    - Supabase `message_embeddings` tablosundan uid eşleşen kayıtları siliyor
    - `users/{uid}` ana doc siliyor
    - `admin.auth().deleteUser(uid)` ile Auth hesabı siliyor (re-auth gerekmez)
  - **Export:** `functions/index.js`'e `deleteUserData` onRequest eklendi
  - **Endpoint:** `https://deleteuserdata-qbipkdgczq-uc.a.run.app`
  - **Flutter:** `api_endpoints.dart`'a URL eklendi
  - **Flutter:** `settings_modal_sheet.dart` → `_deleteAccount()` artık backend'e POST atıyor
  - **Flutter:** `PurchaseService.logout()` (try/catch) eklendi
  - **UI fix:** Hesap silme/çıkış sonrası `pushNamedAndRemoveUntil('/login', ...)` ile login ekranına dönüyor
  - Deploy edildi, test edildi: login ekranına dönüyor ✅, Firestore + Auth temiz ✅
- **✅ Doğrulama tamamlandı:** Supabase `message_embeddings` 127→0 kayıt (18 Şubat smoke test)

---

### ✅ 1.2 — Webhook'a `plus` Entitlement Desteği — TAMAMLANDI
- **Öncelik:** P0 🔴 → ✅ ÇÖZÜLDÜ (18 Şubat 2026)
- **Dosya:** `functions/src/http/revenuecatWebhook.js`
- **Yapılanlar:**
  - `PLUS_ENTITLEMENT_KEY = "plus"` sabiti eklendi
  - `hasPlusEntitlement()` fonksiyonu eklendi
  - `determinePlan()` fonksiyonu eklendi (öncelik: plus > core > free)
  - `shouldActivatePremium()` artık core VEYA plus ile true dönüyor
  - Firestore yazımında `plan` artık `determinePlan(entitlementIds)` ile set ediliyor
  - Deploy edildi ✅
- **✅ Doğrulama tamamlandı:** Core satın alma → Firestore `plan:"core"`, `isPremium:true` doğrulandı (18 Şubat smoke test)

---

### ✅ 1.3 — Smoke Test — TAMAMLANDI (18 Şubat 2026)
- **Sonuçlar:**

| Test | Sonuç | Kanıt |
|------|-------|-------|
| Core satın alma senkronu | ✅ PASSED | Firestore: `plan:"core"`, `isPremium:true` |
| Supabase delete cleanup | ✅ PASSED | `message_embeddings` 127→0 kayıt |
| OpenAI key revoke + yeni key | ✅ PASSED | Eski key revoke, yeni key aktif |
| Chat + Tarot çalışıyor | ✅ PASSED | Mesaj gönder → AI cevap gelir |

**✅ Aşama 1 tamamlandı.** Release blocker'lar çözüldü.

---

## AŞAMA 2: P1 — İLK PATCH ✅ TAMAMLANDI (18 Şubat 2026)

> P1 maddeleri tamamlandı. Kod kalitesi ve güvenlik iyileştirmeleri yapıldı.

---

### ✅ 2.1 — Legacy `flortIQChat` Endpoint Kaldır — TAMAMLANDI
- **Yapılanlar:**
  - `functions/index.js`'ten `flortIQChat` export + `syraChatHandler` import kaldırıldı
  - `functions/src/http/syraChatHandler.js` silindi
  - Deploy ile us-central1 `flortIQChat` Cloud Function kaldırıldı
- **Doğrulama:** `grep "flortIQChat" functions/index.js` → 0 sonuç ✅
- **Dosya değişiklikleri:**
  - `functions/index.js` (düzenlendi — import+export silindi)
  - `functions/src/http/syraChatHandler.js` (SİLİNDİ)

---

### ✅ 2.2 — Ölü Kod Temizliği — BÜYÜK BÖLÜMÜ TAMAMLANDI
- **Silinen dosyalar:**
  - `functions/src/http/syraChatHandler.js` ✅
  - `functions/src/services/chatOrchestrator.js` ✅
  - `functions/src/services/relationshipContext.js` ✅
  - `functions/src/_legacy/*` (limitEngine.js HARİÇ) ✅
  - `functions/index_old_backup.js` ✅
  - `functions/debug-openai.js` ✅
- **Bırakılan:**
  - `functions/src/_legacy/limitEngine.js` — tarotReadingHandler tarafından import ediliyor
  - `functions/src/domain/tarotDeck.js` — tarotService tarafından import ediliyor
- **⚠️ Kalan ölü kod:** `functions/src/domain/` altında 8 dosya (tarotDeck hariç) hiçbiri import edilmiyor — ~49K, P2'de silinebilir
- **Dosya değişiklikleri:** 6 dosya SİLİNDİ

---

### ✅ 2.3 — `upgradeToPremium()` + `isPremium()` Sil — TAMAMLANDI
- **Yapılanlar:**
  - `lib/services/firestore_user.dart`'tan method'lar silindi
  - Unused import'lar temizlendi
  - `flutter analyze` → hata yok
- **Not:** `isPremium` kelimesi Firestore field adı olarak hâlâ geçiyor — backward compat için doğru
- **Dosya değişiklikleri:**
  - `lib/services/firestore_user.dart` (düzenlendi)

---

### ✅ 2.4 — RC Key Tekrarı → RevenueCatConfig SSoT — TAMAMLANDI
- **Yapılanlar:**
  - `lib/config/revenuecat_config.dart` oluşturuldu (YENİ) — tüm RC sabitleri tek dosyada
  - `lib/core/app_constants.dart`'tan RC satırları silindi
  - `lib/services/purchase_service.dart` → `RevenueCatConfig` import ediyor
  - `flutter analyze` → hata yok
- **Dosya değişiklikleri:**
  - `lib/config/revenuecat_config.dart` (YENİ)
  - `lib/core/app_constants.dart` (düzenlendi)
  - `lib/services/purchase_service.dart` (düzenlendi)

---

### ~~2.5 — Re-auth Akışı~~ — GEREKSİZ (Cloud Function çözüyor)
- **Durum:** 1.1'de Cloud Function uygulandı → `admin.auth().deleteUser(uid)` re-auth gerektirmez → bu madde iptal.

---

## AŞAMA 3: P2 — İYİLEŞTİRMELER (Release sonrası — 3-5 saat)

> Bunlar acil değil ama uzun vadede yapılmalı.

---

### 3.1 — Privacy Policy ve Terms URL'lerini Ayır
- **Öncelik:** P2 🟡
- **Dosya:** `lib/screens/settings/settings_modal_sheet.dart`
- **Mevcut sorun:** Kullanım Şartları ve Gizlilik Politikası aynı URL'ye gidiyor
- **Hedef:** İki ayrı URL tanımla, settings'teki linkleri güncelle
- **Gerekli:** İki ayrı web sayfası hazırla (Notion/web sitesi)

**ChatGPT'ye söyle:** "settings_modal_sheet.dart dosyasındaki Privacy Policy ve Terms of Service linklerini ayıran bir Cursor prompt'u yaz."

---

### ✅ 3.2 — Supabase Veri Temizliği Doğrulama — TAMAMLANDI
- **Durum:** Smoke test ile doğrulandı (18 Şubat 2026)
- **Sonuç:** `message_embeddings` tablosu 127→0 kayıt — Cloud Function Supabase temizliği çalışıyor ✅

---

### 3.3 — Webhook Replay Koruması
- **Öncelik:** P2 🟡
- **Dosya:** `functions/src/http/revenuecatWebhook.js`
- **Mevcut sorun:** Dedupe var ama replay koruması yok — eski event'ler yeniden gönderilebilir
- **Hedef:** Event timestamp'ı kontrol et, 24 saatten eski event'leri logla + reddet (veya sadece uyar)

**ChatGPT'ye söyle:** "revenuecatWebhook.js dosyasına event timestamp tabanlı replay koruması ekleyen bir Cursor prompt'u yaz."

---

### 3.4 — Production'da debugPrint Loglarını Azalt
- **Öncelik:** P2 🟡
- **Dosyalar:** Tüm Flutter dosyaları
- **Hedef:** `grep -rn "debugPrint\|print(" lib/` → production build'de gereksiz olanları kaldır veya `kDebugMode` ile sar
- **Pattern:**
```dart
if (kDebugMode) { debugPrint("..."); }
```

**ChatGPT'ye söyle:** "Repo'daki tüm debugPrint ve print çağrılarını bulan ve production build'de kapatılacak şekilde kDebugMode ile saran bir Cursor prompt'u yaz."

---

### 3.5 — Root'taki Tekrar Dosyaları Sil
- **Öncelik:** P2 🟡
- **Dosyalar:**
  - `lib/syra_animations.dart` → `lib/theme/syra_animations.dart` varsa sil
  - `lib/syra_theme.dart` → `lib/theme/syra_theme.dart` varsa sil
- **Doğrulama:** `grep -rn "import.*syra_animations\|import.*syra_theme" lib/` → hangi import kullanılıyor kontrol et
- **Test:** `flutter analyze`

**ChatGPT'ye söyle:** "lib/ root'taki syra_animations.dart ve syra_theme.dart dosyalarının lib/theme/ altındakilerle aynı olup olmadığını kontrol eden ve tekrarları temizleyen bir Cursor prompt'u yaz."

---

### ✅ 3.6 — `chatOrchestrator.js` Legacy Sistemi — TAMAMLANDI (P1-2'de silindi)
- **Durum:** `chatOrchestrator.js` ve `relationshipContext.js` P1-2 ölü kod temizliğinde silindi ✅

---

## KONTROL TABLOSU

Aşağıdaki tabloyu her maddeyi tamamladığında işaretle:

| # | Madde | Aşama | Durum |
|---|-------|-------|-------|
| 0.1 | OpenAI Key Revoke | Hazırlık | ✅ DONE |
| 0.2 | Git History Temizle | Hazırlık → P2 | ☐ (P2'ye taşındı) |
| 0.3 | .gitignore Güncelle | Hazırlık | ✅ DONE |
| 1.1 | Hesap Silme Tamamla | P0 | ✅ DONE |
| 1.2 | Webhook plus Desteği | P0 | ✅ DONE |
| 1.3 | Smoke Test | P0 | ✅ DONE |
| 2.1 | flortIQChat Kaldır | P1 | ✅ DONE |
| 2.2 | Ölü Kod Temizliği | P1 | ✅ DONE (domain/ P2'de) |
| 2.3 | upgradeToPremium Sil | P1 | ✅ DONE |
| 2.4 | RC Key Tekrarı Temizle | P1 | ✅ DONE |
| 2.5 | ~~Re-auth Akışı~~ | ~~P1~~ | ❌ GEREKSİZ |
| 3.1 | Privacy/Terms URL Ayır | P2 | ☐ |
| 3.2 | Supabase Veri Temizliği Doğrula | ~~P1~~ | ✅ DONE (127→0) |
| 3.3 | Webhook Replay Koruması | P2 | ☐ |
| 3.4 | debugPrint Temizliği | P2 | ☐ |
| 3.5 | Tekrar Dosyaları Sil | P2 | ☐ |
| 3.6 | chatOrchestrator Retire | ~~P2~~ | ✅ DONE (P1-2'de silindi) |

---

## CHATGPT'YE GÖNDERİRKEN ŞABLON

Aşağıdaki mesajı ChatGPT'ye ilk mesaj olarak gönder:

```
Bu dosya SYRA uygulamasının audit raporundan çıkan fix roadmap'idir. 
Repo'yu da ekliyorum.

İş akışımız şöyle:
1. Ben sana madde numarası söylüyorum (örn: "Madde 1.1")
2. Sen repo'daki ilgili dosyaları inceliyorsun
3. Bana Cursor IDE'de kullanabileceğim bir prompt yazıyorsun
4. Prompt şunları içermeli:
   - Hangi dosyada ne değişecek (dosya yolu + satır aralığı)
   - Tam kod değişikliği (mevcut → yeni)
   - Değişiklik sonrası test adımları

Cursor prompt'u yazarken:
- Türkçe yorum satırları kullan
- Mevcut kod stiline uy (mevcut import pattern, naming convention)
- Sadece değişen kısmı yaz, tüm dosyayı tekrar yazma
- Yan etki riski varsa uyar

Hazırsan "Madde 1.1" ile başlayalım.
```

---

## NOTLAR

- **Aşama sırası önemli:** 0 → 1 → 2 → 3 sırasıyla git. Aşama içinde sıra esnektir.
- **Bağımlılıklar:** ~~3.6 → 2.1'e bağımlı~~ (her ikisi de tamamlandı). Diğerleri bağımsız.
- **Her aşama sonunda:** `flutter analyze` + `cd functions && npm run lint` çalıştır.
- **Release için minimum:** Aşama 0 + Aşama 1 ✅ TAMAMLANDI. Aşama 2 ✅ TAMAMLANDI. Release'e hazır.

---

## CHANGELOG

### 18 Şubat 2026 (Akşam) — P1 + Smoke Test + UX Fix

**Smoke Testler (HEPSİ PASSED):**

| Test | Sonuç | Kanıt |
|------|-------|-------|
| Core satın alma senkronu | ✅ | Firestore: `plan:"core"`, `isPremium:true` |
| Supabase delete cleanup | ✅ | `message_embeddings` 127→0 kayıt |
| OpenAI key revoke + yeni key | ✅ | Eski key revoke, yeni key aktif |
| Chat + Tarot çalışıyor | ✅ | Mesaj gönder → AI cevap gelir |

**P1 Tamamlananlar:**

| Madde | Dosya Değişiklikleri |
|-------|---------------------|
| 2.1: flortIQChat kaldır | `functions/index.js` (export+import silindi), `functions/src/http/syraChatHandler.js` (SİLİNDİ) |
| 2.2: Ölü kod temizliği | `chatOrchestrator.js` (SİLİNDİ), `relationshipContext.js` (SİLİNDİ), `_legacy/*` (limitEngine hariç SİLİNDİ), `index_old_backup.js` (SİLİNDİ), `debug-openai.js` (SİLİNDİ) |
| 2.3: upgradeToPremium sil | `lib/services/firestore_user.dart` (method'lar + import silindi) |
| 2.4: RC key SSoT | `lib/config/revenuecat_config.dart` (YENİ), `lib/core/app_constants.dart` (RC silindi), `lib/services/purchase_service.dart` (import değişti) |

**UX İyileştirmesi:**

| Değişiklik | Dosya |
|-----------|-------|
| Delete Account UX | `lib/screens/settings/settings_modal_sheet.dart` — `_DataControlsContent` StatefulWidget, `_isDeleting` guard, spinner, buton disable, "Siliniyor…" text |

### 17-18 Şubat 2026 (Gece/Sabah) — P0 Tamamlama

| Madde | Dosya Değişiklikleri |
|-------|---------------------|
| P0-1: OpenAI key | `.runtimeconfig.json` (SİLİNDİ), `.gitignore` (güncellendi), Firebase secret set |
| P0-2: Hesap silme | `functions/src/http/deleteUserDataHandler.js` (YENİ), `functions/index.js` (export eklendi), `lib/services/api_endpoints.dart` (URL eklendi), `lib/screens/settings/settings_modal_sheet.dart` (backend'e bağlandı + login redirect) |
| P0-3: Webhook plus | `functions/src/http/revenuecatWebhook.js` (plus entitlement + determinePlan eklendi) |
