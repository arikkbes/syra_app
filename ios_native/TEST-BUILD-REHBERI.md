# 🚀 SYRA Test Build - Dosya Konumları ve Kurulum

## 📁 Dosya Yapısı (MUTLAKA BU ŞEKİLDE OLMALI)

```
syra-ios-repo/                           # ← Repo root
│
├── codemagic.yaml                       # ← BURAYA (repo root)
│
└── ios_native/                          # ← iOS proje klasörü
    ├── SyraNative.xcodeproj
    ├── SyraNative/
    │   ├── SyraNativeApp.swift
    │   ├── ChatComposer.swift
    │   └── ... (diğer Swift dosyaları)
    │
    ├── ExportOptions_Development.plist  # ← BURAYA (ios_native içine)
    └── ExportOptions_AppStore.plist     # ← BURAYA (ios_native içine)
```

---

## ✅ İndirdiğin Dosyalar ve Konumları

| Dosya | Konum | Açıklama |
|-------|-------|----------|
| **codemagic.yaml** | Repo root | Codemagic build config |
| **ExportOptions_Development.plist** | ios_native/ | Development build export ayarları |
| **ExportOptions_AppStore.plist** | ios_native/ | TestFlight/App Store export ayarları |

---

## 🔧 Adım Adım Kurulum

### 1️⃣ Dosyaları Kopyala

```bash
# Repo klasörüne git
cd /path/to/syra-ios-repo

# codemagic.yaml'ı root'a kopyala
cp ~/Downloads/codemagic.yaml .

# ExportOptions dosyalarını ios_native'e kopyala
cp ~/Downloads/ExportOptions_Development.plist ios_native/
cp ~/Downloads/ExportOptions_AppStore.plist ios_native/
```

### 2️⃣ Dosya Yapısını Doğrula

```bash
# Şu dosyalar olmalı:
ls codemagic.yaml                                  # ✅ Olmalı
ls ios_native/ExportOptions_Development.plist      # ✅ Olmalı
ls ios_native/ExportOptions_AppStore.plist         # ✅ Olmalı
ls ios_native/SyraNative.xcodeproj                 # ✅ Olmalı
```

### 3️⃣ Git'e Commit + Push

```bash
# Dosyaları git'e ekle
git add codemagic.yaml
git add ios_native/ExportOptions_*.plist

# Commit
git commit -m "Add Codemagic config and export options for test builds"

# Push
git push origin main
```

---

## 🚀 Test Build Başlatma (Codemagic)

### Option 1: Development Build (HIZLI TEST)

Bu yöntem telefonuna direkt kurulum için. **En hızlı yöntem!**

#### Codemagic'te:
1. **Projects** → **SYRA** seç
2. **Start new build** tıkla
3. **Workflow seç:** `ios-syra-development`
4. **Branch:** `main`
5. **Start build** tıkla

#### Build bitince (10-15dk):
1. **Artifacts** sekmesine git
2. **SyraNative.ipa** dosyasını indir
3. **Diawi'ye upload et:** https://www.diawi.com
4. Link'i al → iPhone'dan aç → Install

---

### Option 2: TestFlight (ÖNERİLEN - PROFESYONEL)

Bu yöntem App Store Connect üzerinden TestFlight'a upload eder.

#### Önce App Store Connect Hazırlığı:

1. **App Store Connect'e git:** https://appstoreconnect.apple.com
2. **My Apps** → **+** → **New App**
3. Bilgileri doldur:
   - **Name:** SYRA
   - **Bundle ID:** com.ariksoftware.syra
   - **SKU:** SYRA-001

4. **App Store Connect API Key** oluştur:
   - **Users and Access** → **Keys** → **+**
   - **Key Name:** Codemagic
   - **Access:** App Manager
   - **Generate** → **.p8 dosyasını indir**

5. **Codemagic'e API Key ekle:**
   - Codemagic → **Teams** → **Integrations** → **App Store Connect**
   - Issuer ID, Key ID, .p8 dosyasını ekle

#### Codemagic'te Build:
1. **Projects** → **SYRA**
2. **Start new build**
3. **Workflow:** `ios-syra-testflight`
4. **Start build**

#### Build bitince (15-20dk):
1. iPhone'da **TestFlight** app'i aç
2. **SYRA** görünecek
3. **Install** tıkla
4. Test et! 🎉

---

### Option 3: Simulator (SADECE COMPILE TEST)

Telefon gerektirmez, sadece compile test için.

#### Codemagic'te:
1. **Workflow:** `ios-syra-simulator`
2. **Start build**
3. 5 dakikada biter
4. Compile başarılı mı kontrol et

---

## 📋 codemagic.yaml İçeriği (Önemli Noktalar)

### ✅ Senin İçin Güncellenmiş:

```yaml
# Team ID otomatik eklendi
DEVELOPMENT_TEAM=4NK7SA2722  # ✅

# Email adresi eklendi
recipients:
  - besirarik@gmail.com  # ✅

# Export options doğru konumda
exportOptionsPlist ios_native/ExportOptions_Development.plist  # ✅
exportOptionsPlist ios_native/ExportOptions_AppStore.plist     # ✅
```

### ⚠️ Sadece Bunu Düzenlemelisin:

```yaml
# Satır 75 (TestFlight için):
APP_STORE_ID: "YOUR_APP_STORE_ID"  # ← App Store Connect'ten App ID'yi buraya yaz
```

App Store ID'yi nereden bulursun:
- App Store Connect → My Apps → SYRA → App Information → Apple ID

---

## 🔍 Sık Karşılaşılan Sorunlar

### ❌ "Provisioning profile not found"
**Çözüm:**
```yaml
# codemagic.yaml'da zaten var:
CODE_SIGN_STYLE=Automatic
-allowProvisioningUpdates
```
Codemagic otomatik halleder!

### ❌ "No such file: ExportOptions_Development.plist"
**Çözüm:** Dosya konumunu kontrol et
```bash
# Doğru konum:
ls ios_native/ExportOptions_Development.plist  # ✅ Olmalı
```

### ❌ "Team ID not found"
**Çözüm:** codemagic.yaml'da zaten var:
```yaml
DEVELOPMENT_TEAM=4NK7SA2722  # ✅
```

### ❌ Scheme bulunamadı
**Çözüm:** Xcode'da scheme'i "Shared" yap:
```
Xcode → Product → Scheme → Manage Schemes
→ "SyraNative" → "Shared" checkbox işaretle
→ Commit + push
```

---

## ✅ Build Başarı Kontrol

### Build loglarında görmeli:
```
✅ Archive succeeded
✅ Export succeeded  
✅ Created IPA: SyraNative.ipa
```

### Artifacts'te olmalı:
```
✅ SyraNative.ipa (Development build için ~50MB)
✅ SyraNative.xcarchive
```

---

## 🎯 Hangi Workflow'u Seçmeliyim?

| Durum | Workflow | Süre | Kurulum |
|-------|----------|------|---------|
| **Hızlı test (telefon)** | `ios-syra-development` | 10dk | Diawi link |
| **Profesyonel test** | `ios-syra-testflight` | 15dk | TestFlight app |
| **Sadece compile** | `ios-syra-simulator` | 5dk | Kurulum yok |

---

## 💡 Pro Tips

1. **İlk build uzun sürer** (~20-30dk)
   - Certificate/profile oluşturuluyor
   - Sonraki build'ler hızlı (~10dk)

2. **Development build için UDID gerek**
   - iPhone UDID'ini Apple Developer Portal'a ekle
   - Settings → General → About → UDID

3. **TestFlight automatic**
   - Build başarılı olunca otomatik TestFlight'a gider
   - Email notification gelir

4. **Simulator build en hızlı**
   - Sadece compile test için kullan
   - Telefona kurulmaz

---

## 📞 Yardım

Takıldığın yer olursa:
1. Codemagic build logs'a bak
2. Error mesajını kopyala
3. Bana gönder, çözelim! 🚀

---

## ✅ Final Checklist

- [ ] codemagic.yaml → repo root'a kopyalandı
- [ ] ExportOptions_Development.plist → ios_native/ kopyalandı
- [ ] ExportOptions_AppStore.plist → ios_native/ kopyalandı
- [ ] Git commit + push yapıldı
- [ ] Codemagic'te workflow seçildi
- [ ] Build başlatıldı
- [ ] Build başarılı (10-15dk)
- [ ] IPA indirildi / TestFlight'tan kuruldu
- [ ] Telefonunda test edildi ✅

---

**Beşir**, dosyaları doğru konumlara koy ve push et! Sonra Codemagic'ten `ios-syra-development` workflow'u ile build başlat! 🚀📱
