import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/user_plan.dart';
import '../screens/settings/settings_modal_sheet.dart';
import '../services/firestore_user.dart';
import '../services/purchase_service.dart';
import '../theme/syra_theme.dart';

enum SubscriptionTab { core, plus }

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
          initialTab: initialPlusTab
              ? SubscriptionTab.plus
              : SubscriptionTab.core,
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

Future<UserPlan> _resolveCurrentPlan() async {
  final firestorePlan = await FirestoreUser.getPlan();
  final hasEntitlement = await PurchaseService.hasPremium();
  if (hasEntitlement && !firestorePlan.isPaid) return UserPlan.core;
  return firestorePlan;
}

class _SyraPaywallSheet extends StatefulWidget {
  final SubscriptionTab initialTab;

  const _SyraPaywallSheet({required this.initialTab});

  @override
  State<_SyraPaywallSheet> createState() => _SyraPaywallSheetState();
}

class _SyraPaywallSheetState extends State<_SyraPaywallSheet> {
  late SubscriptionTab _selectedTab;
  UserPlan _plan = UserPlan.free;
  StoreProduct? _coreProduct;
  bool _loading = true;
  bool _purchaseLoading = false;
  bool _restoreLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        _resolveCurrentPlan(),
        PurchaseService.getPremiumProduct(),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = results[0] as UserPlan;
        _coreProduct = results[1] as StoreProduct?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _buyCore() async {
    if (_purchaseLoading) return;
    setState(() => _purchaseLoading = true);
    try {
      final ok = await PurchaseService.buyPremium();
      if (!mounted) return;
      if (ok) {
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SYRA Core aktif edildi.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satin alma tamamlanmadi.')),
        );
      }
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
                ? 'Satin almalar geri yuklendi.'
                : 'Geri yuklenecek aktif satin alma bulunamadi.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _restoreLoading = false);
    }
  }

  String get _corePriceLabel => _coreProduct?.priceString ?? 'Fiyati gorecek';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.6,
        maxChildSize: 0.94,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: SyraColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: SyraColors.glassBorder),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SyraColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'SYRA planina katil',
                  style: TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _plan.isPaid
                      ? 'Zaten uyesin. Planini buradan yonetebilirsin.'
                      : 'Core ile sinirsiz sohbet ve gelismis analiz ozelliklerini ac.',
                  style: TextStyle(
                    color: SyraColors.textSecondary.withOpacity(0.95),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSegment(),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _buildComparisonTable(),
                  const SizedBox(height: 16),
                  _buildPrimaryAction(),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _restoreLoading ? null : _restore,
                    child: Text(
                      _restoreLoading
                          ? 'Geri yukleniyor...'
                          : 'Satin almalari geri yukle',
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Abonelikler App Store / Google Play uzerinden otomatik yenilenir ve istedigin zaman yonetilebilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SyraColors.textMuted.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSegment() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SyraColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _segmentChip(SubscriptionTab.core, 'Core')),
          Expanded(child: _segmentChip(SubscriptionTab.plus, 'Plus')),
        ],
      ),
    );
  }

  Widget _segmentChip(SubscriptionTab tab, String label) {
    final selected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? SyraColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? SyraColors.textPrimary
                  : SyraColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final coreSelected = _selectedTab == SubscriptionTab.core;
    final rows = <Map<String, String>>[
      {'name': 'Gunluk mesaj limiti', 'core': 'Sinirsiz', 'plus': 'Sinirsiz'},
      {'name': 'Kim Daha Cok tam erisim', 'core': 'Var', 'plus': 'Var'},
      {'name': 'Oncelikli yeni ozellikler', 'core': '-', 'plus': 'Var'},
      {'name': 'Model kalitesi', 'core': 'Gelismis', 'plus': 'En yuksek'},
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SyraColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SyraColors.glassBorder),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row['name']!,
                        style: const TextStyle(
                          color: SyraColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      coreSelected ? row['core']! : row['plus']!,
                      style: const TextStyle(
                        color: SyraColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPrimaryAction() {
    if (_plan.isPaid) {
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await openManageSubscriptionSheet(context);
          },
          child: const Text('Aboneligi yonet'),
        ),
      );
    }

    if (_selectedTab == SubscriptionTab.plus) {
      return SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: null,
          child: const Text('SYRA Plus yakinda'),
        ),
      );
    }

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: SyraColors.textPrimary,
          foregroundColor: SyraColors.background,
        ),
        onPressed: _purchaseLoading ? null : _buyCore,
        child: Text(
          _purchaseLoading
              ? 'Isleniyor...'
              : 'SYRA Core - $_corePriceLabel / ay',
        ),
      ),
    );
  }
}

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
  StoreProduct? _product;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        _resolveCurrentPlan(),
        PurchaseService.getPremiumProduct(),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = results[0] as UserPlan;
        _product = results[1] as StoreProduct?;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openManage() async {
    HapticFeedback.lightImpact();
    final ok = await PurchaseService.openSubscriptionManagement();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Abonelikler magazadan yonetilir. App Store/Google Play > Abonelikler.',
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
                ? 'Satin almalar geri yuklendi.'
                : 'Aktif satin alma bulunamadi.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _restoreLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.45,
        maxChildSize: 0.85,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: SyraColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: SyraColors.glassBorder),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SyraColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aboneligi duzenle',
                  style: TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SyraColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SyraColors.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: SyraColors.surface,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _plan == UserPlan.plus
                                    ? 'SYRA Plus'
                                    : (_plan == UserPlan.core
                                          ? 'SYRA Core'
                                          : 'Ucretsiz Plan'),
                                style: const TextStyle(
                                  color: SyraColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _product?.priceString != null
                                    ? '${_product!.priceString} / ay'
                                    : 'Magaza uzerinden yonetilir',
                                style: const TextStyle(
                                  color: SyraColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A1F1F),
                        foregroundColor: Colors.redAccent.shade100,
                      ),
                      onPressed: _openManage,
                      child: const Text('Aboneligi iptal et / yonet'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _restoreLoading ? null : _restore,
                    child: Text(
                      _restoreLoading
                          ? 'Geri yukleniyor...'
                          : 'Satin almalari geri yukle',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
