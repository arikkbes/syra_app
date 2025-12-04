import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/firestore_user.dart';
import '../services/purchase_service.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import 'premium_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// PREMIUM MANAGEMENT SCREEN v1.0
/// ═══════════════════════════════════════════════════════════════
/// Shows premium status and allows purchase/restore.
/// ═══════════════════════════════════════════════════════════════

class PremiumManagementScreen extends StatefulWidget {
  const PremiumManagementScreen({super.key});

  @override
  State<PremiumManagementScreen> createState() =>
      _PremiumManagementScreenState();
}

class _PremiumManagementScreenState extends State<PremiumManagementScreen> {
  bool _loading = true;
  bool _actionLoading = false;
  bool _isPremium = false;
  int _dailyLimit = 10;
  int _usedToday = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      setState(() => _loading = true);

      final status = await FirestoreUser.getMessageStatus();

      setState(() {
        _isPremium = status['isPremium'] ?? false;

        final dynamic rawLimit = status['limit'];
        final dynamic rawCount = status['count'];

        _dailyLimit = rawLimit is int
            ? rawLimit
            : rawLimit is num
                ? rawLimit.toInt()
                : 10;

        _usedToday = rawCount is int
            ? rawCount
            : rawCount is num
                ? rawCount.toInt()
                : 0;
      });
    } catch (e) {
      debugPrint('Premium status load error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum yüklenirken hata oluştu: $e'),
          backgroundColor: SyraColors.surface,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _buyPremium() async {
    if (_actionLoading) return;

    try {
      setState(() => _actionLoading = true);

      final ok = await PurchaseService.buyPremium();

      if (!mounted) return;

      if (ok) {
        await _loadStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium aktif edildi 🎉'),
            backgroundColor: SyraColors.surface,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Satın alma iptal edildi veya tamamlanamadı.'),
            backgroundColor: SyraColors.surface,
          ),
        );
      }
    } catch (e) {
      debugPrint('Buy premium error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satın alma sırasında hata oluştu: $e'),
          backgroundColor: SyraColors.surface,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_actionLoading) return;

    try {
      setState(() => _actionLoading = true);

      final success = await PurchaseService.restorePurchases();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçmiş satın alımlar kontrol ediliyor...'),
            backgroundColor: SyraColors.surface,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        await _loadStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mağaza şu anda kullanılamıyor veya geçmiş satın alım bulunamadı.'),
            backgroundColor: SyraColors.surface,
          ),
        );
      }
    } catch (e) {
      debugPrint('Restore purchases error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geri yükleme sırasında bir hata oluştu. Lütfen tekrar deneyin.'),
          backgroundColor: SyraColors.surface,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  void _openStoreInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Abonelik yönetimi mağaza hesabın üzerinden yapılır.\n'
          'Google Play / App Store → Abonelikler bölümünden kontrol edebilirsin.',
        ),
        duration: Duration(seconds: 4),
        backgroundColor: SyraColors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          const SyraBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: SyraColors.neonCyan,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _header(),
                          const SizedBox(height: 22),
                          _statusCard(),
                          const SizedBox(height: 22),
                          _usageCard(),
                          const SizedBox(height: 22),
                          _actionsCard(),
                          const SizedBox(height: 32),
                          _footer(),
                        ],
                      ),
                    ),
            ),
          ),

          if (_actionLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: SyraColors.neonCyan),
              ),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: SyraColors.textPrimary,
          size: 18,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
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
        shaderCallback: (bounds) => SyraColors.accentGradient.createShader(bounds),
        child: const Text(
          'Premium Yönetimi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isPremium ? SyraColors.accentGradient : null,
            color: _isPremium ? null : SyraColors.surface,
            border: _isPremium ? null : Border.all(color: SyraColors.glassBorder),
          ),
          child: Icon(
            _isPremium ? Icons.workspace_premium_rounded : Icons.lock_clock_rounded,
            color: _isPremium ? Colors.white : SyraColors.textSecondary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPremium ? 'Premium Aktif ✨' : 'Free Plan',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: SyraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isPremium
                    ? 'Sınırsız mesaj ve analiz aktif'
                    : 'Premium ile sınırsız deneyim',
                style: const TextStyle(
                  fontSize: 14,
                  color: SyraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glass(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: SyraColors.glassBg,
            border: Border.all(color: SyraColors.glassBorder),
            boxShadow: SyraColors.cardGlow(),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _statusCard() {
    return _glass(
      Row(
        children: [
          Icon(
            _isPremium ? Icons.verified_rounded : Icons.lock_clock_rounded,
            color: _isPremium ? SyraColors.neonCyan : SyraColors.textSecondary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPremium ? 'Aboneliğin aktif' : 'Premium aktif değil',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SyraColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPremium
                      ? 'Aylık aboneliğin mağaza üzerinden yenilenir.'
                      : 'Sınırsız mesaj + Analiz Yükle için Premium\'a geç.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: SyraColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageCard() {
    final used = _usedToday.clamp(0, _dailyLimit);
    final ratio = _dailyLimit == 0 ? 0.0 : used / _dailyLimit.toDouble();

    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bugünkü kullanımın',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SyraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: SyraColors.glassBorder,
                  valueColor: AlwaysStoppedAnimation(
                    _isPremium ? SyraColors.neonCyan : SyraColors.neonPink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isPremium ? 'Sınırsız' : '$used / $_dailyLimit',
                style: const TextStyle(
                  fontSize: 12,
                  color: SyraColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    return _glass(
      Column(
        children: [
          _tile(
            Icons.info_outline_rounded,
            'Premium avantajlarını gör',
            'Tüm özellikleri Premium ekranında incele.',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            ),
          ),
          Divider(height: 18, color: SyraColors.glassBorder),
          _tile(
            Icons.manage_accounts_rounded,
            'Aboneliği yönet',
            'Google Play / App Store abonelik ayarlarını aç.',
            _openStoreInfo,
          ),
          const SizedBox(height: 4),
          _tile(
            Icons.refresh_rounded,
            'Satın alımları geri yükle',
            'Premium aldıysan ama görünmüyorsa geri yüklemeyi dene.',
            _restorePurchases,
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _actionLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: SyraColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SyraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: SyraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SyraColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Column(
      children: [
        // ═══════════════════════════════════════════════════════════════
        // ═══════════════════════════════════════════════════════════════
        if (!_isPremium)
          GestureDetector(
            onTap: _actionLoading ? null : _buyPremium,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: SyraColors.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SyraColors.neonPink.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _actionLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Premium'a Yükselt",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

        if (!_isPremium) const SizedBox(height: 16),

        Text(
          _isPremium
              ? 'Premium aktif ✨ Aboneliğini mağaza abonelik ayarlarından yönetebilirsin.'
              : 'Aylık abonelik, mağaza hesabın üzerinden güvenli şekilde yönetilir.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: SyraColors.textHint,
          ),
        ),
      ],
    );
  }
}
