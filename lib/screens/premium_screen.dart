import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../theme/design_system.dart';
import '../widgets/glass_background.dart';
import '../services/purchase_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM SCREEN v3.0 - ChatGPT 2025 Style + Design System
/// ═══════════════════════════════════════════════════════════════
/// Clean, minimal premium upgrade screen with SyraPage
/// ═══════════════════════════════════════════════════════════════

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = false;
  bool _isLoadingPrice = false;
  String? _priceText;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint("💎 [PremiumScreen] Opened");
  }

  /// Load price from RevenueCat
  Future<void> _loadPrice() async {
    if (_isLoadingPrice) return;

    setState(() {
      _isLoadingPrice = true;
      _errorMessage = null;
    });

    try {
      debugPrint("💰 [PremiumScreen] Loading price...");

      final initialized = await PurchaseService.ensureInitialized();
      if (!initialized) {
        throw Exception("RevenueCat başlatılamadı");
      }

      final product = await PurchaseService.getPremiumProduct();
      if (product != null && mounted) {
        setState(() {
          _priceText = product.priceString;
          _isLoadingPrice = false;
        });
        debugPrint("✅ [PremiumScreen] Price loaded: $_priceText");
      } else {
        throw Exception("Ürün bilgisi alınamadı");
      }
    } catch (e) {
      debugPrint("❌ [PremiumScreen] Price load error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingPrice = false;
        });
      }
    }
  }

  /// Handle purchase
  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("🛒 [PremiumScreen] Starting purchase flow...");

      final initialized = await PurchaseService.ensureInitialized();
      if (!initialized) {
        throw Exception("Ödeme sistemi başlatılamadı. Lütfen tekrar dene.");
      }

      final success = await PurchaseService.buyPremium();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: SyraTokens.paddingSm),
                Text('Premium aktif edildi 🎉'),
              ],
            ),
            backgroundColor: SyraTokens.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SyraTokens.radiusSm),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Satın alma tamamlanamadı");
      }
    } catch (e) {
      debugPrint("❌ [PremiumScreen] Purchase error: $e");
      if (!mounted) return;

      String errorMsg = e.toString();
      if (errorMsg.contains("cancelled") || errorMsg.contains("canceled")) {
        errorMsg = "Satın alma iptal edildi";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: SyraColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle restore
  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("🔄 [PremiumScreen] Starting restore flow...");

      final initialized = await PurchaseService.ensureInitialized();
      if (!initialized) {
        throw Exception("Ödeme sistemi başlatılamadı");
      }

      final success = await PurchaseService.restorePurchases();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Premium abonelik geri yüklendi 🎉'),
              ],
            ),
            backgroundColor: SyraColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Geri yüklenecek abonelik bulunamadı'),
              ],
            ),
            backgroundColor: SyraColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ [PremiumScreen] Restore error: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Hata: ${e.toString()}')),
            ],
          ),
          backgroundColor: SyraColors.surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SyraPage(
      title: 'Premium',
      showBackButton: true,
      onBack: () => Navigator.pop(context),
      body: Column(
        children: [
          _headerCard(),

          const SizedBox(height: SyraTokens.paddingLg),

          _benefitsCard(),

          const SizedBox(height: SyraTokens.paddingLg),

          _infoText(),

          const SizedBox(height: SyraTokens.paddingLg),

          _primaryButton(),

          const SizedBox(height: SyraTokens.paddingSm),

          _restoreButton(),

          const SizedBox(height: SyraTokens.paddingSm),

          _secondaryButton(),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: EdgeInsets.all(SyraTokens.paddingLg),
      decoration: BoxDecoration(
        color: SyraTokens.card,
        borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
        border: Border.all(color: SyraTokens.borderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD54F).withOpacity(0.15),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD54F),
              size: 26,
            ),
          ),
          const SizedBox(width: SyraTokens.paddingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SYRA Plus 💎",
                  style: SyraTokens.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: SyraTokens.paddingXxs),
                Text(
                  "Sınırsız mesaj ve derin analiz özellikleri ile ilişkilerinde avantaj sağla.",
                  style: SyraTokens.bodySm.copyWith(
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitsCard() {
    return Container(
      padding: EdgeInsets.all(SyraTokens.paddingLg),
      decoration: BoxDecoration(
        color: SyraTokens.card,
        borderRadius: BorderRadius.circular(SyraTokens.radiusLg),
        border: Border.all(color: SyraTokens.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Premium Avantajları",
            style: SyraTokens.titleSm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: SyraTokens.paddingMd),
          _benefitRow(
            icon: Icons.all_inclusive_rounded,
            title: "Sınırsız sohbet",
            subtitle: "Günlük limit yok, istediğin kadar taktik ve analiz.",
          ),
          const SizedBox(height: SyraTokens.paddingSm),
          _benefitRow(
            icon: Icons.analytics_rounded,
            title: "Derin ilişki analizi",
            subtitle: "Mesajlarını yükleyip detaylı kırmızı bayrak analizi al.",
          ),
          const SizedBox(height: SyraTokens.paddingSm),
          _benefitRow(
            icon: Icons.bolt_rounded,
            title: "Taktik hatırlatma modu",
            subtitle: "Yanlış adım attığında kanka gibi uyarıp yönlendiren sistem.",
          ),
          const SizedBox(height: SyraTokens.paddingSm),
          _benefitRow(
            icon: Icons.shield_rounded,
            title: "Öncelikli erişim",
            subtitle: "Yeni özellikler ve deneysel modlara erken erişim hakkı.",
          ),
        ],
      ),
    );
  }

  Widget _benefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SyraTokens.accent.withOpacity(0.15),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: SyraTokens.accent,
          ),
        ),
        const SizedBox(width: SyraTokens.paddingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: SyraTokens.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: SyraTokens.paddingXxs),
              Text(
                subtitle,
                style: SyraTokens.caption.copyWith(
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoText() {
    return Text(
      "Premium abonelik aylık olarak yenilenir.\n"
      "İstediğin zaman mağaza ayarlarından iptal edebilirsin.",
      style: SyraTokens.caption.copyWith(
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _primaryButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handlePurchase,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _isLoading
              ? SyraTokens.textTertiary.withOpacity(0.3)
              : SyraTokens.textPrimary,
          borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SyraTokens.bg,
                    ),
                  ),
                )
              : Text(
                  "Premium'a Yükselt",
                  style: SyraTokens.titleSm.copyWith(
                    color: SyraTokens.bg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _restoreButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRestore,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: SyraTokens.card,
          borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
          border: Border.all(color: SyraTokens.borderSubtle, width: 0.5),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SyraTokens.textSecondary,
                    ),
                  ),
                )
              : Text(
                  "Satın Alımları Geri Yükle",
                  style: SyraTokens.bodyMd.copyWith(
                    color: SyraTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _secondaryButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(SyraTokens.radiusMd),
        ),
        child: Center(
          child: Text(
            "Şimdilik Geç",
            style: SyraTokens.bodyMd.copyWith(
              color: SyraTokens.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
