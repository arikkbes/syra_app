import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../services/purchase_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM SCREEN v2.0 - ChatGPT 2025 Style
/// ═══════════════════════════════════════════════════════════════
/// Clean, minimal premium upgrade screen
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
                SizedBox(width: 12),
                Text('Premium aktif edildi 🎉'),
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
    return Scaffold(
      backgroundColor: SyraColors.background,
      appBar: AppBar(
        backgroundColor: SyraColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.close_rounded,
            color: SyraColors.textSecondary,
          ),
        ),
        title: const Text(
          "Premium",
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  // Header card
                  _headerCard(),

                  const SizedBox(height: 24),

                  // Benefits
                  _benefitsCard(),

                  const SizedBox(height: 24),

                  // Info text
                  _infoText(),

                  const SizedBox(height: 24),

                  // CTA Buttons
                  _primaryButton(),

                  const SizedBox(height: 12),

                  _restoreButton(),

                  const SizedBox(height: 12),

                  _secondaryButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SyraColors.border, width: 0.5),
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
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SYRA Plus 💎",
                  style: TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Sınırsız mesaj ve derin analiz özellikleri ile ilişkilerinde avantaj sağla.",
                  style: TextStyle(
                    color: SyraColors.textSecondary,
                    fontSize: 13,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SyraColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Premium Avantajları",
            style: TextStyle(
              color: SyraColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _benefitRow(
            icon: Icons.all_inclusive_rounded,
            title: "Sınırsız sohbet",
            subtitle: "Günlük limit yok, istediğin kadar taktik ve analiz.",
          ),
          const SizedBox(height: 14),
          _benefitRow(
            icon: Icons.analytics_rounded,
            title: "Derin ilişki analizi",
            subtitle: "Mesajlarını yükleyip detaylı kırmızı bayrak analizi al.",
          ),
          const SizedBox(height: 14),
          _benefitRow(
            icon: Icons.bolt_rounded,
            title: "Taktik hatırlatma modu",
            subtitle: "Yanlış adım attığında kanka gibi uyarıp yönlendiren sistem.",
          ),
          const SizedBox(height: 14),
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
            color: SyraColors.accent.withOpacity(0.15),
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: SyraColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: SyraColors.textMuted,
                  fontSize: 12,
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
      style: TextStyle(
        color: SyraColors.textHint,
        fontSize: 12,
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
              ? SyraColors.textMuted.withOpacity(0.3)
              : SyraColors.textPrimary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SyraColors.background,
                    ),
                  ),
                )
              : Text(
                  "Premium'a Yükselt",
                  style: TextStyle(
                    color: SyraColors.background,
                    fontSize: 16,
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
          color: SyraColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SyraColors.border, width: 0.5),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SyraColors.textSecondary,
                    ),
                  ),
                )
              : const Text(
                  "Satın Alımları Geri Yükle",
                  style: TextStyle(
                    color: SyraColors.textSecondary,
                    fontSize: 14,
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
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            "Şimdilik Geç",
            style: TextStyle(
              color: SyraColors.textHint,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
