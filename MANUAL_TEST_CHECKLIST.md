# SYRA - Manual Test Checklist for ChatGPT-Style Subscription Flow

## Overview
This checklist covers the new unified subscription flow with ChatGPT-style UX:
- Settings bottom sheet with subscription status
- Paywall sheet (Core/Plus toggle)
- Manage subscription sheet (for subscribed users)
- All upgrade CTAs unified to use the same flow

---

## 1. Settings Sheet (Free User)

### Test Steps:
1. ✅ Login as a **free user**
2. ✅ Tap the user icon in the side menu to open Settings sheet
3. ✅ Verify Settings sheet layout:
   - Handle bar at top
   - Close button
   - "Hesap" section with:
     - E-posta row (showing your email)
     - **Abonelik row** showing "Ücretsiz" with chevron
     - "SYRA Core'a yükselt" row with gold accent icon
     - "Satın almaları geri yükle" row
   - Other sections (Ayarlar, Yasal, Çıkış yap)

### Expected Behavior:
- ✅ Settings sheet opens smoothly from bottom
- ✅ "Abonelik" row shows "Ücretsiz" as trailing text
- ✅ "SYRA Core'a yükselt" row is visible
- ✅ Tapping "Abonelik" opens **Paywall Sheet**
- ✅ Tapping "SYRA Core'a yükselt" opens **Paywall Sheet** with Core tab preselected

---

## 2. Paywall Sheet (Free User)

### Test Steps:
1. ✅ From Settings, tap "Abonelik" or "SYRA Core'a yükselt"
2. ✅ Verify Paywall Sheet layout:
   - Title: "SYRA planına katıl"
   - Subtitle with description
   - Close button (X)
   - **Segmented control**: Core | Plus (with "Yakında" badge on Plus)
   - Feature list showing Core or Plus features based on selected tab
   - Large CTA button at bottom
   - Disclaimer text

### Expected Behavior:
- ✅ Paywall sheet opens smoothly
- ✅ Core tab is preselected by default (unless opened from "Plus'a yükselt")
- ✅ Tapping Core/Plus tabs switches features instantly
- ✅ Core CTA button shows: **"Core ile Başla - Aylık"** (gold gradient)
- ✅ Plus CTA button shows: **"Yakında Kullanıma Açılacak"** (gray, disabled)
- ✅ Tapping Core CTA initiates purchase flow
- ✅ Tapping Plus CTA shows toast: "SYRA Plus yakında kullanıma açılacak 🚀"
- ✅ Close button dismisses sheet and returns to Settings

---

## 3. Purchase Flow (Free User → Core)

### Test Steps:
1. ✅ From Paywall Sheet, tap **"Core ile Başla - Aylık"**
2. ✅ Verify platform purchase dialog appears (App Store / Play Store)
3. ✅ Complete purchase (use sandbox account if testing)
4. ✅ Verify success toast: "SYRA Core aktif edildi 🎉"
5. ✅ Verify Paywall sheet closes automatically
6. ✅ Reopen Settings sheet

### Expected Behavior:
- ✅ Purchase dialog matches platform (iOS/Android)
- ✅ On success, toast appears
- ✅ Sheet closes and returns to previous screen
- ✅ Settings "Abonelik" row now shows **"SYRA Core"** instead of "Ücretsiz"
- ✅ "SYRA Core'a yükselt" row is now **hidden**
- ✅ New row appears: **"SYRA Plus'a yükselt"** (to upgrade from Core to Plus)

---

## 4. Settings Sheet (Core User)

### Test Steps:
1. ✅ Login as a **Core subscriber**
2. ✅ Tap user icon to open Settings
3. ✅ Verify Settings sheet layout:
   - "Abonelik" row shows **"SYRA Core"** with chevron
   - "SYRA Plus'a yükselt" row is visible
   - "SYRA Core'a yükselt" row is **hidden**

### Expected Behavior:
- ✅ "Abonelik" row displays correct plan name
- ✅ Tapping "Abonelik" opens **Manage Subscription Sheet**
- ✅ Tapping "SYRA Plus'a yükselt" opens **Paywall Sheet** with Plus tab preselected

---

## 5. Manage Subscription Sheet (Core User)

### Test Steps:
1. ✅ From Settings (as Core user), tap "Abonelik" row
2. ✅ Verify Manage Subscription Sheet layout:
   - Title: "Abonelik Yönetimi"
   - Subtitle: "SYRA Core"
   - Close button (X)
   - **Gold card** showing plan icon, "SYRA Core", "Aktif abonelik ✨"
   - Info card with:
     - Plan: SYRA Core
     - Yenileme: Aylık (Mağaza üzerinden yönetilir)
     - Durum: Aktif
   - Actions card with:
     - "Aboneliği iptal et / Yönet" (red text)
     - "Satın almaları geri yükle"
   - Footer disclaimer text

### Expected Behavior:
- ✅ Manage sheet opens smoothly
- ✅ Gold card prominently displays active subscription
- ✅ Tapping "Aboneliği iptal et / Yönet" shows toast with instructions
- ✅ On iOS: shows App Store subscription management link
- ✅ On Android: shows Play Store subscription management link
- ✅ Tapping "Satın almaları geri yükle" initiates restore flow
- ✅ Close button dismisses sheet

---

## 6. Paywall Sheet (Core User → Plus Upgrade)

### Test Steps:
1. ✅ From Settings (as Core user), tap "SYRA Plus'a yükselt"
2. ✅ Verify Paywall Sheet opens with **Plus tab preselected**
3. ✅ Verify banner at top: "Zaten Core üyesisin ✨" (if already subscribed)
4. ✅ Verify Plus features are shown
5. ✅ Verify CTA button shows **"Yakında Kullanıma Açılacak"** (gray, disabled)

### Expected Behavior:
- ✅ Plus tab is automatically selected
- ✅ Banner indicates current Core subscription
- ✅ Plus features are listed
- ✅ CTA is disabled with "Yakında" message
- ✅ Tapping CTA shows toast: "SYRA Plus yakında kullanıma açılacak 🚀"

---

## 7. Chat Screen Upgrade CTAs (Free User)

### Test Steps:
1. ✅ Login as **free user**
2. ✅ Send messages until daily limit is reached
3. ✅ Verify limit warning dialog appears with:
   - Message: "Günlük mesaj limitine ulaştın"
   - Button: **"Premium'a Geç"**
4. ✅ Tap "Premium'a Geç"

### Expected Behavior:
- ✅ Paywall Sheet opens directly (NOT legacy PremiumScreen page)
- ✅ Core tab is preselected
- ✅ After closing sheet, user returns to chat screen (NOT stuck on empty PremiumScreen)

---

## 8. Chat Screen Upgrade CTAs (Core User)

### Test Steps:
1. ✅ Login as **Core user**
2. ✅ Trigger upgrade CTA (if any)

### Expected Behavior:
- ✅ If user taps any upgrade button, Manage Subscription Sheet opens
- ✅ No daily limit dialogs appear (unlimited for Core users)

---

## 9. Restore Purchases

### Test Steps:
1. ✅ Login as a user who previously purchased Core
2. ✅ Delete and reinstall app (or clear app data)
3. ✅ Login again
4. ✅ Open Settings → tap "Satın almaları geri yükle"
5. ✅ Wait for restore process

### Expected Behavior:
- ✅ Loading indicator appears
- ✅ If purchase found: Toast shows "Satın almalar geri yüklendi 🎉"
- ✅ Settings "Abonelik" row updates to show "SYRA Core"
- ✅ If no purchase found: Toast shows "Geri yüklenecek satın alma bulunamadı"

---

## 10. Legacy Premium Screens (Wrapper Behavior)

### Test Steps:
1. ✅ Programmatically navigate to `/premium` route (if accessible)
2. ✅ Programmatically navigate to `/premium-management` route (if accessible)

### Expected Behavior:
- ✅ Both routes should **immediately open** the appropriate sheet (Paywall or Manage)
- ✅ After sheet closes, the wrapper route should **auto-pop** without showing empty page
- ✅ User should NOT see a blank screen or stuck state

---

## 11. Close Behavior & Navigation

### Test Steps:
1. ✅ Open Settings → Abonelik → Paywall Sheet
2. ✅ Close Paywall Sheet (X button or swipe down)
3. ✅ Verify you return to Settings Sheet (NOT main screen)
4. ✅ Close Settings Sheet
5. ✅ Verify you return to Chat Screen

### Expected Behavior:
- ✅ All sheets close smoothly with correct navigation stack
- ✅ No "double pop" or unexpected navigation jumps
- ✅ Handle bar drag-to-close works on all sheets
- ✅ X button works on all sheets

---

## 12. Subscription Status Sync

### Test Steps:
1. ✅ Purchase Core subscription
2. ✅ Close and reopen app
3. ✅ Open Settings immediately

### Expected Behavior:
- ✅ "Abonelik" row shows **"SYRA Core"** (not stale "Ücretsiz")
- ✅ Plan status is loaded from Firestore on app launch
- ✅ No race conditions or flickering between Free/Core states

---

## 13. Settings Sheet Profile Header (Future Enhancement)

### Test Steps:
1. ✅ Open Settings sheet
2. ✅ Look for profile section at top (avatar, name, username, "Profili düzenle")

### Expected Behavior:
- ⚠️ **Not yet implemented** - this is a future enhancement
- ✅ Current version shows sections directly without profile header
- 📝 TODO: Add ChatGPT-style profile header in future iteration

---

## 14. Overflow Bug in Relationship Radar (Kim Daha Çok)

### Test Steps:
1. ✅ Upload a relationship analysis
2. ✅ Navigate to "İlişki Radarı" tab
3. ✅ Scroll through the screen
4. ✅ Check near locked stat cards or warning stripes

### Expected Behavior:
- ✅ No "Bottom overflowed by X pixels" error
- ✅ All cards and widgets render without overflow warnings
- ✅ Smooth scrolling throughout the screen

---

## 15. Accessibility & Haptics

### Test Steps:
1. ✅ Tap various buttons and rows in Settings
2. ✅ Tap segmented control tabs in Paywall
3. ✅ Tap CTAs and action buttons

### Expected Behavior:
- ✅ Light haptic feedback on row taps
- ✅ Medium haptic feedback on important actions (purchase, restore)
- ✅ Selection click haptic on tab switches
- ✅ All interactive elements respond to touch

---

## 16. Edge Cases & Error Handling

### Test Steps:
1. ✅ Attempt purchase with no internet connection
2. ✅ Cancel purchase mid-flow
3. ✅ Attempt restore with no previous purchases

### Expected Behavior:
- ✅ No internet: Toast shows "Ödeme sistemi başlatılamadı" or network error
- ✅ Purchase canceled: Toast shows "Satın alma iptal edildi"
- ✅ Restore fails: Toast shows "Geri yüklenecek satın alma bulunamadı"
- ✅ All errors are gracefully handled without crashes

---

## Summary Checklist

- [ ] Settings sheet opens and displays correct subscription status
- [ ] Paywall sheet Core/Plus toggle works smoothly
- [ ] Purchase flow completes successfully
- [ ] Manage subscription sheet shows for subscribed users
- [ ] All upgrade CTAs open Paywall sheet (not legacy pages)
- [ ] Legacy premium routes are thin wrappers (no blank screens)
- [ ] Navigation stack is correct after closing sheets
- [ ] Restore purchases works as expected
- [ ] No "bottom overflowed" errors in Relationship Radar
- [ ] Haptic feedback works throughout
- [ ] Error states are handled gracefully

---

## Known Limitations / Future Work

1. **Client Firestore Writes**: `FirestoreUser.upgradeToPremium()` is deprecated and will fail if Firestore rules block client writes. TODO: Implement server-side sync via Cloud Functions + RevenueCat webhooks.

2. **Plus Plan**: Currently "coming soon" - CTA is disabled. Implement when Plus tier is ready.

3. **Profile Header**: ChatGPT-style avatar/name/username header in Settings is not yet implemented. Current Settings sheet shows sections directly.

4. **Subscription Details**: Renewal date, price, next billing info not yet shown in Manage sheet (requires RevenueCat subscription info fetching).

5. **Platform Links**: Direct links to App Store/Play Store subscription management could be improved with native `url_launcher` implementations.

---

**End of Checklist**
