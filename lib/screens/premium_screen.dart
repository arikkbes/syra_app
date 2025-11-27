import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../services/purchase_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM SCREEN v2.0 - LAZY INITIALIZATION
/// ═══════════════════════════════════════════════════════════════
/// Shows premium benefits and allows purchase.
/// RevenueCat is initialized ONLY when user taps "Go Premium"
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
    // Do NOT initialize RevenueCat here!
    // We'll initialize it when user taps "Go Premium"
    debugPrint("💎 [PremiumScreen] Opened");
  }

  /// ═══════════════════════════════════════════════════════════════
  /// LOAD PRICE - Initialize RevenueCat first, then load price
  /// ═══════════════════════════════════════════════════════════════
  Future<void> _loadPrice() async {
    if (_isLoadingPrice) return;

    setState(() {
      _isLoadingPrice = true;
      _errorMessage = null;
    });

    try {
      debugPrint("💰 [PremiumScreen] Loading price...");

      // Initialize RevenueCat first
      final initialized = await PurchaseService.ensureInitialized();
      if (!initialized) {
        throw Exception("RevenueCat başlatılamadı");
      }

      // Now load the price
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

  /// ═══════════════════════════════════════════════════════════════
  /// HANDLE PURCHASE - Initialize RevenueCat, then purchase
  /// ═══════════════════════════════════════════════════════════════
  Future<void> _handlePurchase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("🛒 [PremiumScreen] Starting purchase flow...");

      // STEP 1: Initialize RevenueCat (if not already)
      final initialized = await PurchaseService.ensureInitialized();
      if (!initialized) {
        throw Exception("Ödeme sistemi başlatılamadı. Lütfen tekrar dene.");
      }

      // STEP 2: Make the purchase
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
            backgroundColor: SyraColors.neonCyan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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

  /// ═══════════════════════════════════════════════════════════════
  /// HANDLE RESTORE - Initialize RevenueCat, then restore
  /// ═══════════════════════════════════════════════════════════════
  Future<void> _handleRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint("🔄 [PremiumScreen] Starting restore flow...");

      // Initialize RevenueCat first
      final initialized = await PurchaseService.ensureInitialized();
      if (!initialized) {
        throw Exception("Ödeme sistemi başlatılamadı");
      }

      // Restore purchases
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
            backgroundColor: SyraColors.neonCyan,
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: SyraColors.background.withValues(alpha: 0.5),
                border: Border(
                  bottom: BorderSide(
                    color: SyraColors.glassBorder,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              SyraColors.accentGradient.createShader(bounds),
          child: const Text(
            "SYRA Plus",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: SyraColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerCard(),
                  const SizedBox(height: 20),
                  _benefitsCard(),
                  const SizedBox(height: 24),
                  _infoText(),
                  const SizedBox(height: 32),
                  _primaryButton(),
                  const SizedBox(height: 16),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: SyraColors.glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SyraColors.glassBorder),
            boxShadow: SyraColors.cardGlow(),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SyraColors.accentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: SyraColors.neonPink.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 30,
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
        ),
      ),
    );
  }

  Widget _benefitsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: SyraColors.glassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SyraColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Premium Avantajları",
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _benefitRow(
                icon: Icons.all_inclusive_rounded,
                title: "Sınırsız sohbet",
                subtitle: "Günlük limit yok, istediğin kadar taktik ve analiz.",
              ),
              const SizedBox(height: 10),
              _benefitRow(
                icon: Icons.analytics_rounded,
                title: "Derin ilişki analizi",
                subtitle:
                    "Mesajlarını yükleyip detaylı kırmızı bayrak analizi al.",
              ),
              const SizedBox(height: 10),
              _benefitRow(
                icon: Icons.bolt_rounded,
                title: "Taktik hatırlatma modu",
                subtitle:
                    "Yanlış adım attığında kanka gibi uyarıp yönlendiren sistem.",
              ),
              const SizedBox(height: 10),
              _benefitRow(
                icon: Icons.shield_rounded,
                title: "Öncelikli erişim",
                subtitle:
                    "Yeni özellikler ve deneysel modlara erken erişim hakkı.",
              ),
            ],
          ),
        ),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SyraColors.accentGradient,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 18,
            color: Colors.white,
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
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: SyraColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoText() {
    return const Text(
      "Premium abonelik aylık olarak yenilenir.\n"
      "İstediğin zaman mağaza ayarlarından iptal edebilirsin.",
      style: TextStyle(
        color: SyraColors.textMuted,
        fontSize: 12.5,
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
          gradient: _isLoading
              ? LinearGradient(
                  colors: [
                    SyraColors.neonPink.withValues(alpha: 0.5),
                    SyraColors.neonCyan.withValues(alpha: 0.5),
                  ],
                )
              : SyraColors.accentGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: SyraColors.neonPink.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  "Premium'a Yükselt",
                  style: TextStyle(
                    color: Colors.white,
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
          color: SyraColors.glassBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SyraColors.glassBorder),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(SyraColors.textSecondary),
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
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Center(
          child: Text(
            "Şimdilik Geç",
            style: TextStyle(
              color: SyraColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
