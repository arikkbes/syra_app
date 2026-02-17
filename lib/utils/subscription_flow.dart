import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/user_plan.dart';
import '../screens/settings/settings_modal_sheet.dart';
import '../services/firestore_user.dart';
import '../services/purchase_service.dart';
import '../theme/syra_theme.dart';

// ═══════════════════════════════════════════════════════════════
// SYRA Paywall Sheet — v2.0  (Obsidian + Champagne Gold)
// Matches ChatGPT-Go-style information architecture with
// SYRA brand identity. Purchase logic is UNTOUCHED.
// ═══════════════════════════════════════════════════════════════

enum SubscriptionTab { core, plus }

// ─── Public openers (API unchanged) ───────────────────────────

Future<void> openSettingsSheet(
  BuildContext context, {
  BuildContext? hostContext,
  bool focusUpgradeSection = false,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => SyraSettingsModalSheet(
      hostContext: hostContext ?? context,
      focusUpgradeSection: focusUpgradeSection,
      openPaywallSheet: (ctx, {bool initialPlusTab = false}) {
        return openPaywallSheet(
          ctx,
          initialTab:
              initialPlusTab ? SubscriptionTab.plus : SubscriptionTab.core,
        );
      },
      openManageSubscriptionSheet: (ctx) => openManageSubscriptionSheet(ctx),
    ),
  );
}

Future<void> openPaywallSheet(
  BuildContext context, {
  SubscriptionTab initialTab = SubscriptionTab.core,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => _SyraPaywallSheet(initialTab: initialTab),
  );
}

Future<void> openManageSubscriptionSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => const _SyraManageSubscriptionSheet(),
  );
}

// ─── Shared helpers ───────────────────────────────────────────

Future<UserPlan> _resolveCurrentPlan() async {
  final firestorePlan = await FirestoreUser.getPlan();
  final hasEntitlement = await PurchaseService.hasPremium();
  if (hasEntitlement && !firestorePlan.isPaid) return UserPlan.core;
  return firestorePlan;
}

// ─── Design constants (SYRA Obsidian + Champagne Gold) ────────

class _PaywallStyle {
  _PaywallStyle._();

  // Colors
  static const Color bg = Color(0xFF11131A);
  static const Color cardBg = Color(0xFF1B202C);
  static const Color segmentBg = Color(0xFF1B202C);
  static const Color segmentActive = Color(0xFF262B38);
  static const Color gold = Color(0xFFD6B35A);
  static const Color goldLight = Color(0xFFEAD7A5);
  static const Color goldMuted = Color(0x33D6B35A);
  static const Color textPrimary = Color(0xFFE7E9EE);
  static const Color textSecondary = Color(0xFF9AA3B2);
  static const Color textMuted = Color(0xFF778090);
  static const Color textDisabled = Color(0xFF4A5060);
  static const Color hairline = Color(0x1AFFFFFF); // ~10% white
  static const Color closeBg = Color(0xFF1F2330);

  // Radii
  static const double sheetRadius = 24.0;
  static const double cardRadius = 20.0;
  static const double segmentRadius = 16.0;
  static const double segmentChipRadius = 12.0;
  static const double buttonRadius = 16.0;

  // Sizes
  static const double buttonHeight = 56.0;
  static const double grabberWidth = 36.0;
  static const double grabberHeight = 4.0;
  static const double closeSize = 32.0;

  // Typography
  static const TextStyle titleStyle = TextStyle(
    color: textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle segmentLabelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle featureLabelStyle = TextStyle(
    color: textSecondary,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle featureValueStyle = TextStyle(
    color: textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle ctaLabelStyle = TextStyle(
    color: Color(0xFF11131A),
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const TextStyle restoreStyle = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle footerStyle = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
}

// ═══════════════════════════════════════════════════════════════
//  PAYWALL SHEET
// ═══════════════════════════════════════════════════════════════

class _SyraPaywallSheet extends StatefulWidget {
  final SubscriptionTab initialTab;
  const _SyraPaywallSheet({required this.initialTab});

  @override
  State<_SyraPaywallSheet> createState() => _SyraPaywallSheetState();
}

class _SyraPaywallSheetState extends State<_SyraPaywallSheet> {
  late SubscriptionTab _selectedTab;
  UserPlan _plan = UserPlan.free;
  List<StoreProduct> _products = const [];
  bool _loading = true;
  bool _purchaseLoading = false;
  bool _restoreLoading = false;
  final bool _purchasesSupported = PurchaseService.isPlatformSupported();

  // ─── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await PurchaseService.identifyUser(uid);
      }
      final results = await Future.wait<dynamic>([
        _resolveCurrentPlan(),
        PurchaseService.getProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = results[0] as UserPlan;
        _products = results[1] as List<StoreProduct>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ─── Purchase actions (UNTOUCHED LOGIC) ─────────────────────

  Future<void> _buyCore() async {
    if (_purchaseLoading) return;
    if (!_purchasesSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satın alma bu platformda desteklenmiyor.')),
      );
      return;
    }
    setState(() => _purchaseLoading = true);
    try {
      final result = await PurchaseService.buyPremium();
      if (!mounted) return;
      if (result.isSuccess) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SYRA Core aktif edildi.')),
        );
        Navigator.of(context).pop();
      } else if (result.isCancelled) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Satın alma başarısız: ${result.message ?? "Bilinmeyen hata"}',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satın alma başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _purchaseLoading = false);
    }
  }

  Future<void> _restore() async {
    if (_restoreLoading) return;
    setState(() => _restoreLoading = true);
    try {
      final ok = await PurchaseService.restorePurchases();
      if (!mounted) return;
      if (ok) await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Satın almalar geri yüklendi.'
                : 'Geri yüklenecek aktif satın alma bulunamadı.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _restoreLoading = false);
    }
  }

  StoreProduct? _resolveProductForTab(SubscriptionTab tab) {
    if (_products.isEmpty) return null;
    final needle = tab == SubscriptionTab.core ? 'core' : 'plus';
    final byIdentifier = _products
        .where((p) => p.identifier.toLowerCase().contains(needle))
        .firstOrNull;
    if (byIdentifier != null) return byIdentifier;

    // Fallback: first product for Core, second (if any) for Plus.
    if (tab == SubscriptionTab.core) return _products.first;
    if (_products.length > 1) return _products[1];
    return null;
  }

  String _priceLabelForTab(SubscriptionTab tab) {
    final product = _resolveProductForTab(tab);
    if (product != null) return product.priceString;
    return _loading ? 'Loading…' : '—';
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: _PaywallStyle.bg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_PaywallStyle.sheetRadius),
              ),
            ),
            child: Column(
              children: [
                // ── Grabber + Close ──
                _buildHeader(),

                // ── Scrollable content ──
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 16),
                    children: [
                      const SizedBox(height: 8),

                      // Title
                      const Text(
                        'SYRA planına katıl',
                        textAlign: TextAlign.center,
                        style: _PaywallStyle.titleStyle,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        _plan.isPaid
                            ? 'Planını buradan yönetebilirsin.'
                            : 'Sohbetini ve analizlerini bir üst seviyeye taşı.',
                        textAlign: TextAlign.center,
                        style: _PaywallStyle.subtitleStyle,
                      ),
                      const SizedBox(height: 24),

                      // ── Segmented control ──
                      _SyraPlanSegmentedControl(
                        selected: _selectedTab,
                        onChanged: (tab) =>
                            setState(() => _selectedTab = tab),
                        corePriceLabel: _priceLabelForTab(SubscriptionTab.core),
                        plusPriceLabel: _priceLabelForTab(SubscriptionTab.plus),
                        plusDisabled: true,
                      ),
                      const SizedBox(height: 16),

                      // ── Feature card ──
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _PaywallStyle.gold,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        _SyraFeatureComparisonCard(
                          selectedTab: _selectedTab,
                        ),
                        const SizedBox(height: 24),

                        // ── Primary CTA ──
                        _SyraPrimaryCTAButton(
                          plan: _plan,
                          selectedTab: _selectedTab,
                          priceLabel: _priceLabelForTab(SubscriptionTab.core),
                          purchaseLoading: _purchaseLoading,
                          purchasesSupported: _purchasesSupported,
                          onBuyCore: _buyCore,
                          onManage: () async {
                            Navigator.of(context).pop();
                            await openManageSubscriptionSheet(context);
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Restore purchases ──
                        Center(
                          child: GestureDetector(
                            onTap: (_restoreLoading || !_purchasesSupported)
                                ? null
                                : _restore,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _restoreLoading
                                    ? 'Geri yükleniyor…'
                                    : 'Satın alımı geri yükle',
                                style: _PaywallStyle.restoreStyle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Footer ──
                        const Text(
                          'Aylık olarak yenilenir. İstediğin zaman iptal edebilirsin.',
                          textAlign: TextAlign.center,
                          style: _PaywallStyle.footerStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header: grabber bar + close button ──

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered grabber
          Container(
            width: _PaywallStyle.grabberWidth,
            height: _PaywallStyle.grabberHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          // Close button (top-right)
          Positioned(
            right: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Container(
                width: _PaywallStyle.closeSize,
                height: _PaywallStyle.closeSize,
                decoration: const BoxDecoration(
                  color: _PaywallStyle.closeBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _PaywallStyle.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEGMENTED CONTROL
// ═══════════════════════════════════════════════════════════════

class _SyraPlanSegmentedControl extends StatelessWidget {
  final SubscriptionTab selected;
  final ValueChanged<SubscriptionTab> onChanged;
  final String corePriceLabel;
  final String plusPriceLabel;
  final bool plusDisabled;

  const _SyraPlanSegmentedControl({
    required this.selected,
    required this.onChanged,
    required this.corePriceLabel,
    required this.plusPriceLabel,
    this.plusDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _PaywallStyle.segmentBg,
        borderRadius: BorderRadius.circular(_PaywallStyle.segmentRadius),
      ),
      child: Row(
        children: [
          _chip(SubscriptionTab.core, 'Core', corePriceLabel),
          const SizedBox(width: 4),
          _chip(SubscriptionTab.plus, 'Plus', plusPriceLabel),
        ],
      ),
    );
  }

  Widget _chip(SubscriptionTab tab, String label, String priceLabel) {
    final isSelected = selected == tab;
    final isDisabled = tab == SubscriptionTab.plus && plusDisabled;

    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? _PaywallStyle.segmentActive
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(_PaywallStyle.segmentChipRadius),
            border: isSelected
                ? Border.all(color: _PaywallStyle.hairline, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Text(
                  '$label · $priceLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _PaywallStyle.segmentLabelStyle.copyWith(
                    color: isDisabled
                        ? _PaywallStyle.textDisabled
                        : isSelected
                            ? _PaywallStyle.textPrimary
                            : _PaywallStyle.textSecondary,
                  ),
                ),
              ),
              if (isDisabled) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _PaywallStyle.textDisabled.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Yakında',
                    style: TextStyle(
                      color: _PaywallStyle.textDisabled,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FEATURE COMPARISON CARD
// ═══════════════════════════════════════════════════════════════

class _SyraFeatureComparisonCard extends StatelessWidget {
  final SubscriptionTab selectedTab;

  const _SyraFeatureComparisonCard({required this.selectedTab});

  static const _features = [
    _FeatureRow('Sohbet', 'Sınırsız', 'Sınırsız'),
    _FeatureRow('Ayna', '✓', '✓'),
    _FeatureRow('Dost Acı Söyler', '✓', '✓'),
    _FeatureRow('Model seviyesi', 'Gelişmiş', 'En yüksek'),
  ];

  @override
  Widget build(BuildContext context) {
    final isPlus = selectedTab == SubscriptionTab.plus;

    return Container(
      decoration: BoxDecoration(
        color: _PaywallStyle.cardBg,
        borderRadius: BorderRadius.circular(_PaywallStyle.cardRadius),
        border: Border.all(color: _PaywallStyle.hairline, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _features.length; i++) ...[
            _buildRow(_features[i], isPlus),
            if (i < _features.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: _PaywallStyle.hairline,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(_FeatureRow feature, bool showPlus) {
    final value = showPlus ? feature.plusValue : feature.coreValue;
    final isCheckOnly = value == '✓';
    final isPositive = value == 'Sınırsız';
    final isDash = value == '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature.label,
              style: _PaywallStyle.featureLabelStyle,
            ),
          ),
          const SizedBox(width: 12),
          if (isDash)
            Text(
              '—',
              style: _PaywallStyle.featureValueStyle.copyWith(
                color: _PaywallStyle.textDisabled,
              ),
            )
          else if (isCheckOnly)
            const Icon(
              Icons.check_rounded,
              size: 20,
              color: _PaywallStyle.gold,
            )
          else if (isPositive)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: _PaywallStyle.gold,
                ),
                const SizedBox(width: 4),
                Text(value, style: _PaywallStyle.featureValueStyle),
              ],
            )
          else
            Text(value, style: _PaywallStyle.featureValueStyle),
        ],
      ),
    );
  }
}

class _FeatureRow {
  final String label;
  final String coreValue;
  final String plusValue;
  const _FeatureRow(this.label, this.coreValue, this.plusValue);
}

// ═══════════════════════════════════════════════════════════════
//  PRIMARY CTA BUTTON
// ═══════════════════════════════════════════════════════════════

class _SyraPrimaryCTAButton extends StatelessWidget {
  final UserPlan plan;
  final SubscriptionTab selectedTab;
  final String priceLabel;
  final bool purchaseLoading;
  final bool purchasesSupported;
  final VoidCallback onBuyCore;
  final VoidCallback onManage;

  const _SyraPrimaryCTAButton({
    required this.plan,
    required this.selectedTab,
    required this.priceLabel,
    required this.purchaseLoading,
    required this.purchasesSupported,
    required this.onBuyCore,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    // Determine label + action
    String label;
    VoidCallback? onTap;
    bool isDisabled = false;

    if (!purchasesSupported) {
      label = 'Bu platformda desteklenmiyor';
      onTap = null;
      isDisabled = true;
    } else if (plan.isPaid) {
      label = 'Aboneliği yönet';
      onTap = onManage;
    } else if (selectedTab == SubscriptionTab.plus) {
      label = 'Plus yakında';
      onTap = null;
      isDisabled = true;
    } else if (purchaseLoading) {
      label = 'İşleniyor…';
      onTap = null;
    } else {
      label = 'Core\'a geç · $priceLabel/ay';
      onTap = onBuyCore;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: _PaywallStyle.buttonHeight,
        decoration: BoxDecoration(
          color: isDisabled
              ? _PaywallStyle.textDisabled.withOpacity(0.2)
              : _PaywallStyle.gold,
          borderRadius: BorderRadius.circular(_PaywallStyle.buttonRadius),
        ),
        alignment: Alignment.center,
        child: purchaseLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF11131A),
                ),
              )
            : Text(
                label,
                style: _PaywallStyle.ctaLabelStyle.copyWith(
                  color: isDisabled
                      ? _PaywallStyle.textDisabled
                      : const Color(0xFF11131A),
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MANAGE SUBSCRIPTION SHEET (polish pass, logic UNTOUCHED)
// ═══════════════════════════════════════════════════════════════

class _SyraManageSubscriptionSheet extends StatefulWidget {
  const _SyraManageSubscriptionSheet();

  @override
  State<_SyraManageSubscriptionSheet> createState() =>
      _SyraManageSubscriptionSheetState();
}

class _SyraManageSubscriptionSheetState
    extends State<_SyraManageSubscriptionSheet> {
  bool _loading = true;
  bool _restoreLoading = false;
  UserPlan _plan = UserPlan.free;
  List<StoreProduct> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        _resolveCurrentPlan(),
        PurchaseService.getProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = results[0] as UserPlan;
        _products = results[1] as List<StoreProduct>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  StoreProduct? _productForCurrentPlan() {
    if (_products.isEmpty) return null;
    final planNeedle = _plan == UserPlan.plus ? 'plus' : 'core';
    final byIdentifier = _products
        .where((p) => p.identifier.toLowerCase().contains(planNeedle))
        .firstOrNull;
    if (byIdentifier != null) return byIdentifier;
    return _products.first;
  }

  Future<void> _openManage() async {
    HapticFeedback.lightImpact();
    final ok = await PurchaseService.openSubscriptionManagement();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Abonelikler mağazadan yönetilir. App Store / Google Play → Abonelikler.',
          ),
        ),
      );
    }
  }

  Future<void> _restore() async {
    if (_restoreLoading) return;
    setState(() => _restoreLoading = true);
    try {
      final ok = await PurchaseService.restorePurchases();
      if (!mounted) return;
      if (ok) await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Satın almalar geri yüklendi.'
                : 'Aktif satın alma bulunamadı.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _restoreLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: _PaywallStyle.bg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(_PaywallStyle.sheetRadius),
              ),
            ),
            child: Column(
              children: [
                // ── Grabber + Close ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: _PaywallStyle.grabberWidth,
                        height: _PaywallStyle.grabberHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: _PaywallStyle.closeSize,
                            height: _PaywallStyle.closeSize,
                            decoration: const BoxDecoration(
                              color: _PaywallStyle.closeBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: _PaywallStyle.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    controller: controller,
                    padding:
                        EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 16),
                    children: [
                      const Text(
                        'Aboneliği düzenle',
                        style: TextStyle(
                          color: _PaywallStyle.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _PaywallStyle.gold,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        // Plan info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _PaywallStyle.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _PaywallStyle.hairline,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _PaywallStyle.goldMuted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 22,
                                  color: _PaywallStyle.gold,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _plan == UserPlan.plus
                                          ? 'SYRA Plus'
                                          : (_plan == UserPlan.core
                                              ? 'SYRA Core'
                                              : 'Ücretsiz Plan'),
                                      style: const TextStyle(
                                        color: _PaywallStyle.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _productForCurrentPlan() != null
                                          ? '${_productForCurrentPlan()!.priceString} / ay'
                                          : (_loading
                                                ? 'Loading…'
                                                : '—'),
                                      style: const TextStyle(
                                        color: _PaywallStyle.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Cancel / manage button
                        GestureDetector(
                          onTap: _openManage,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1518),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x33FF4D6D),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Aboneliği iptal et / yönet',
                              style: TextStyle(
                                color: Color(0xFFFF7A8A),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Restore
                        Center(
                          child: GestureDetector(
                            onTap: _restoreLoading ? null : _restore,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _restoreLoading
                                    ? 'Geri yükleniyor…'
                                    : 'Satın alımı geri yükle',
                                style: _PaywallStyle.restoreStyle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}