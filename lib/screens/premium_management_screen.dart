import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/firestore_user.dart';
import '../services/purchase_service.dart';
import 'premium_screen.dart';

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
        _dailyLimit = status['dailyMessageLimit'] ?? 10;
        _usedToday = status['dailyMessageCount'] ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum yüklenirken hata oluştu: $e'),
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
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Satın alma iptal edildi veya tamamlanamadı.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satın alma sırasında hata oluştu: $e'),
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

      final available = await InAppPurchase.instance.isAvailable();

      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mağaza şu anda kullanılamıyor.')),
        );
        return;
      }

      InAppPurchase.instance.restorePurchases();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Geçmiş satın alımlar kontrol ediliyor...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geri yükleme hatası: $e')),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gradientCyan = Color(0xFF66E0FF);
    const gradientPink = Color(0xFFFF7AB8);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [gradientCyan, gradientPink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Premium Yönetimi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF050509),
                  Color(0xFF0C0F18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _header(),
                        const SizedBox(height: 22),
                        _statusCard(),
                        const SizedBox(height: 22),
                        _usageCard(),
                        const SizedBox(height: 22),
                        _actionsCard(),
                        const Spacer(),
                        _footer(),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF7AB8),
                Color(0xFF66E0FF),
              ],
            ),
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYRA Premium',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Aylık abonelik ile sınırsız sohbet ve derin analiz.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
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
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
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
            color: _isPremium ? const Color(0xFF66E0FF) : Colors.white70,
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
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPremium
                      ? 'Aylık aboneliğin mağaza üzerinden yenilenir.'
                      : 'Sınırsız mesaj + Analiz Yükle için Premium’a geç.',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageCard() {
    return _glass(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bugünkü kullanımın',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_dailyLimit == 0)
                      ? 0
                      : (_usedToday / _dailyLimit).clamp(0.0, 1.0),
                  minHeight: 5, // 🔥 İnceltilmiş premium bar
                  backgroundColor: Colors.white.withOpacity(0.10),
                  valueColor: AlwaysStoppedAnimation(
                    _isPremium
                        ? const Color(0xFF66E0FF)
                        : const Color(0xFFFF7AB8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isPremium ? 'Sınırsız' : '$_usedToday / $_dailyLimit',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
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
          const Divider(height: 18, color: Colors.white24),
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

  Widget _tile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _actionLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Column(
      children: [
        if (!_isPremium)
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _actionLoading ? null : _buyPremium,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
              ).copyWith(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF7AB8), Color(0xFF66E0FF)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _actionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Aylık Premium’a Geç',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ),
        if (!_isPremium) const SizedBox(height: 10),
        Text(
          _isPremium
              ? 'Premium aktif ✨ Aboneliğini mağaza abonelik ayarlarından yönetebilirsin.'
              : 'Aylık abonelik, mağaza hesabın üzerinden güvenli şekilde yönetilir.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.55), // 🔥 Daha soft footer
          ),
        ),
      ],
    );
  }
}
