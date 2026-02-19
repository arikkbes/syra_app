// lib/screens/settings/settings_modal_sheet.dart
// ═══════════════════════════════════════════════════════════════
// SYRA SETTINGS MODAL SHEET - iOS STYLE (Simplified)
// ═══════════════════════════════════════════════════════════════

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../theme/syra_theme.dart';
import '../../theme/syra_glass.dart';
import '../../services/purchase_service.dart';
import '../../services/firestore_user.dart';
import '../../services/api_endpoints.dart';
import '../../models/chat_session.dart';
import '../../models/user_plan.dart';
import 'package:syra/core/syra_log.dart';

/// SYRA Settings Modal Sheet - iOS Style with grouped sections
class SyraSettingsModalSheet extends StatefulWidget {
  final BuildContext hostContext;
  final bool focusUpgradeSection;
  final Future<void> Function(BuildContext context, {bool initialPlusTab})
  openPaywallSheet;
  final Future<void> Function(BuildContext context) openManageSubscriptionSheet;

  const SyraSettingsModalSheet({
    super.key,
    required this.hostContext,
    required this.openPaywallSheet,
    required this.openManageSubscriptionSheet,
    this.focusUpgradeSection = false,
  });

  @override
  State<SyraSettingsModalSheet> createState() => _SyraSettingsModalSheetState();
}

class _SyraSettingsModalSheetState extends State<SyraSettingsModalSheet> {
  final GlobalKey _upgradeSectionKey = GlobalKey();
  UserPlan _userPlan = UserPlan.free;
  bool get _isPremium => _userPlan.isPaid;
  String? _userEmail;
  String _userName = 'Kullanıcı';
  String _userHandle = '@syra_user';

  final List<_SheetPage> _pageStack = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.focusUpgradeSection) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusUpgradeSection(),
      );
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final plan = await FirestoreUser.getPlan();
    final hasEntitlement = await PurchaseService.hasPremium();
    final resolvedPlan = (!plan.isPaid && hasEntitlement)
        ? UserPlan.core
        : plan;
    final email = user?.email;
    final fallbackName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (email != null && email.contains('@')
              ? email.split('@').first
              : 'Kullanıcı');
    final handleSource = fallbackName.replaceAll(' ', '').toLowerCase();
    final handle = '@$handleSource';

    if (mounted) {
      setState(() {
        _userPlan = resolvedPlan;
        _userEmail = email;
        _userName = fallbackName;
        _userHandle = handle;
      });
      if (widget.focusUpgradeSection) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusUpgradeSection(),
        );
      }
    }
  }

  void _focusUpgradeSection() {
    final upgradeContext = _upgradeSectionKey.currentContext;
    if (upgradeContext == null) return;
    Scrollable.ensureVisible(
      upgradeContext,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  }

  void _pushPage(_SheetPage page) {
    HapticFeedback.lightImpact();
    setState(() => _pageStack.add(page));
  }

  void _popPage() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_pageStack.isNotEmpty) _pageStack.removeLast();
    });
  }

  Future<void> _restorePurchases() async {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SyraColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: SyraColors.accent),
              const SizedBox(height: 16),
              Text(
                'Satın almalar geri yükleniyor...',
                style: TextStyle(color: SyraColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await PurchaseService.restorePurchases();
      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result
                  ? 'Satın almalar geri yüklendi!'
                  : 'Geri yüklenecek satın alma bulunamadı.',
            ),
            backgroundColor: result ? Colors.green : SyraColors.surface,
          ),
        );
        if (result) {
          final plan = await FirestoreUser.getPlan();
          setState(() => _userPlan = plan);
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _planLabel {
    switch (_userPlan) {
      case UserPlan.free:
        return 'Ücretsiz';
      case UserPlan.core:
        return 'SYRA Core';
      case UserPlan.plus:
        return 'SYRA Plus';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      snap: true,
      snapSizes: const [0.5, 0.88, 0.94],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: SyraColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: SyraGlass.white8, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [SyraGlass.white8, Colors.transparent],
                      ),
                    ),
                  ),
                ),
                _buildMainPage(scrollController),
                ..._pageStack.asMap().entries.map((entry) {
                  final index = entry.key;
                  final page = entry.value;
                  return _AnimatedSheetPage(
                    key: ValueKey('page_$index'),
                    page: page,
                    onBack: _popPage,
                    onClose: () => Navigator.of(context).pop(),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainPage(ScrollController scrollController) {
    return Column(
      children: [
        _buildHandleBar(),
        _buildCloseButton(),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              // ═══════════════════════════════════════════════════════════════
              // HESAP Section
              // ═══════════════════════════════════════════════════════════════
              _SectionHeader(title: 'Hesap'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'E-posta',
                    subtitle: _userEmail ?? 'Yükleniyor...',
                    showChevron: false,
                    onTap: () {},
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Abonelik',
                    trailing: _planLabel,
                    onTap: () {
                      if (_isPremium) {
                        widget.openManageSubscriptionSheet(context);
                        return;
                      }
                      widget.openPaywallSheet(context, initialPlusTab: false);
                    },
                  ),
                  if (_userPlan != UserPlan.plus) ...[
                    const _SettingsDivider(),
                    _SettingsRow(
                      key: _upgradeSectionKey,
                      icon: Icons.diamond_outlined,
                      label: 'SYRA Plus\'a yükselt',
                      iconColor: SyraColors.accent,
                      onTap: () {
                        widget.openPaywallSheet(
                          context,
                          initialPlusTab: _userPlan == UserPlan.core,
                        );
                      },
                    ),
                  ],
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.refresh_rounded,
                    label: 'Satın almaları geri yükle',
                    showChevron: false,
                    onTap: _restorePurchases,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════════════════════════
              // AYARLAR Section
              // ═══════════════════════════════════════════════════════════════
              _SectionHeader(title: 'Ayarlar'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.shield_outlined,
                    label: 'Veri kontrolleri',
                    onTap: () => _pushPage(
                      _SheetPage(
                        title: 'Veri Kontrolleri',
                        builder: () => _DataControlsContent(
                          userEmail: _userEmail,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.archive_outlined,
                    label: 'Arşivlenmiş sohbetler',
                    onTap: () => _pushPage(
                      _SheetPage(
                        title: 'Arşivlenmiş Sohbetler',
                        builder: () => _ArchivedChatsContent(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════════════════════════
              // YASAL Section
              // ═══════════════════════════════════════════════════════════════
              _SectionHeader(title: 'Yasal'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    label: 'Kullanım şartları',
                    onTap: () => _launchURL(
                      'https://ariksoftware.com.tr/privacy-policy.html',
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Gizlilik politikası',
                    onTap: () => _launchURL(
                      'https://ariksoftware.com.tr/privacy-policy.html',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ═══════════════════════════════════════════════════════════════
              // Çıkış yap
              // ═══════════════════════════════════════════════════════════════
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.logout_rounded,
                    label: 'Çıkış yap',
                    isDestructive: true,
                    showChevron: false,
                    onTap: () async {
                      HapticFeedback.mediumImpact();
                      syraLog(
                        '[Settings] Attempting RevenueCat logout before Firebase sign-out.',
                      );
                      try {
                        await PurchaseService.logout();
                        syraLog('[Settings] RevenueCat logout successful.');
                      } catch (e, st) {
                        syraLog(
                          '[Settings] RevenueCat logout failed, continuing sign-out: $e',
                        );
                        syraLog('$st');
                      }
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.of(context, rootNavigator: true)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'SYRA v1.0.0',
                  style: TextStyle(
                    color: SyraColors.textMuted.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHandleBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: SyraGlass.white20,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 8),
        child: _GlassButton(
          icon: Icons.close_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = _userName.trim().isEmpty
        ? 'U'
        : _userName
              .trim()
              .split(' ')
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SyraGlass.white8, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: SyraColors.surface,
            child: Text(
              initials,
              style: const TextStyle(
                color: SyraColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userHandle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SyraColors.textMuted.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil düzenleme yakinda eklenecek.'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: SyraColors.textPrimary,
              backgroundColor: SyraColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: SyraGlass.white8),
              ),
            ),
            child: const Text('Profili duzenle'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACCENT COLOR PICKER MODAL (Glass Style)
// ═══════════════════════════════════════════════════════════════

class _AccentColorPickerModal extends StatelessWidget {
  final String selectedColor;
  final Function(String) onColorSelected;

  const _AccentColorPickerModal({
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const Map<String, Color> _colors = {
    'gold': Color(0xFFD4A574),
    'blue': Color(0xFF5B9BD5),
    'green': Color(0xFF6BBF7A),
    'purple': Color(0xFFA78BFA),
    'pink': Color(0xFFF472B6),
    'orange': Color(0xFFFB923C),
  };

  static const Map<String, String> _names = {
    'gold': 'Altın',
    'blue': 'Mavi',
    'green': 'Yeşil',
    'purple': 'Mor',
    'pink': 'Pembe',
    'orange': 'Turuncu',
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SyraColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ana Renk',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _colors.entries.map((entry) {
                  final isSelected = entry.key == selectedColor;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onColorSelected(entry.key);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.2),
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: entry.value.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _names[entry.key] ?? '',
                          style: TextStyle(
                            color: isSelected
                                ? SyraColors.textPrimary
                                : SyraColors.textMuted,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHEET PAGE MODEL
// ═══════════════════════════════════════════════════════════════

class _SheetPage {
  final String title;
  final Widget Function() builder;

  _SheetPage({required this.title, required this.builder});
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED SHEET PAGE
// ═══════════════════════════════════════════════════════════════

class _AnimatedSheetPage extends StatefulWidget {
  final _SheetPage page;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const _AnimatedSheetPage({
    super.key,
    required this.page,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<_AnimatedSheetPage> createState() => _AnimatedSheetPageState();
}

class _AnimatedSheetPageState extends State<_AnimatedSheetPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: SyraColors.background,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    _GlassButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: widget.onBack,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.page.title,
                        style: const TextStyle(
                          color: SyraColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _GlassButton(
                      icon: Icons.close_rounded,
                      onTap: widget.onClose,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: widget.page.builder()),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTENT PAGES
// ═══════════════════════════════════════════════════════════════

class _DataControlsContent extends StatefulWidget {
  final String? userEmail;
  final VoidCallback onClose;

  const _DataControlsContent({this.userEmail, required this.onClose});

  @override
  State<_DataControlsContent> createState() => _DataControlsContentState();
}

class _DataControlsContentState extends State<_DataControlsContent> {
  bool _isDeleting = false;

  Future<void> _deleteAllChats(BuildContext context) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tüm sohbetleri sil'),
        content: const Text(
          'Bu işlem geri alınamaz. Tüm sohbet geçmişin silinecek.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.heavyImpact();
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final sessions = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('chat_sessions')
              .get();

          for (var doc in sessions.docs) {
            await doc.reference.delete();
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tüm sohbetler silindi'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    if (_isDeleting) return;

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hesabı sil'),
        content: const Text(
          'Bu işlem geri alınamaz. Hesabın ve tüm verilerin kalıcı olarak silinecek.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hesabı Sil'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    HapticFeedback.heavyImpact();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silme işlemi başarısız, tekrar dene.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final idToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse(ApiEndpoints.deleteUserData),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      Map<String, dynamic> payload = const {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        }
      } catch (_) {}

      final success = response.statusCode == 200 && payload['success'] == true;
      if (!success) {
        syraLog(
          '[Settings] deleteUserData failed: status=${response.statusCode}, code=${payload['code'] ?? 'unknown'}',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silme işlemi başarısız, tekrar dene.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        await PurchaseService.logout();
      } catch (_) {}

      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesabın silindi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      syraLog('[Settings] deleteUserData request error: ${e.runtimeType}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silme işlemi başarısız, tekrar dene.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _exportData(BuildContext context) async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veri dışa aktarma yakında eklenecek'),
        backgroundColor: SyraColors.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SettingsCard(
          children: [
            _SettingsRow(
              icon: Icons.delete_sweep_outlined,
              label: 'Tüm sohbetleri sil',
              isDestructive: true,
              showChevron: false,
              onTap: () => _deleteAllChats(context),
            ),
            const _SettingsDivider(),
            _SettingsRow(
              icon: Icons.download_outlined,
              label: 'Verilerimi dışa aktar',
              showChevron: false,
              onTap: () => _exportData(context),
            ),
            const _SettingsDivider(),
            _SettingsRow(
              icon: _isDeleting
                  ? Icons.hourglass_top_rounded
                  : Icons.person_remove_outlined,
              label: _isDeleting ? 'Siliniyor…' : 'Hesabı sil',
              isDestructive: true,
              showChevron: false,
              trailingWidget: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFFF6B6B),
                      ),
                    )
                  : null,
              onTap: _isDeleting ? null : () => _deleteAccount(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Hesabını sildiğinde tüm verilerin kalıcı olarak silinir ve bu işlem geri alınamaz.',
            style: TextStyle(
              color: SyraColors.textMuted.withOpacity(0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// Archived Chats Content - Shows real archived sessions
class _ArchivedChatsContent extends StatefulWidget {
  @override
  State<_ArchivedChatsContent> createState() => _ArchivedChatsContentState();
}

class _ArchivedChatsContentState extends State<_ArchivedChatsContent> {
  List<ChatSession> _archivedSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedSessions();
  }

  Future<void> _loadArchivedSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .where('isArchived', isEqualTo: true)
          .orderBy('archivedAt', descending: true)
          .get();

      final sessions = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatSession(
          id: doc.id,
          title: data['title'] ?? 'Adsız Sohbet',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastUpdatedAt:
              (data['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastMessage: data['lastMessage'],
          messageCount: data['messageCount'] ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _archivedSessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unarchiveSession(ChatSession session) async {
    HapticFeedback.mediumImpact();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(session.id)
          .update({'isArchived': false, 'archivedAt': FieldValue.delete()});

      setState(() {
        _archivedSessions.removeWhere((s) => s.id == session.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sohbet arşivden çıkarıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSession(ChatSession session) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sohbeti sil'),
        content: const Text('Bu sohbet kalıcı olarak silinecek.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.heavyImpact();
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chat_sessions')
            .doc(session.id)
            .delete();

        setState(() {
          _archivedSessions.removeWhere((s) => s.id == session.id);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: SyraColors.accent),
      );
    }

    if (_archivedSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: SyraColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.archive_outlined,
                color: SyraColors.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Arşivlenmiş sohbet yok',
              style: TextStyle(
                color: SyraColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arşivlediğin sohbetler\nburada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SyraColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _archivedSessions.length,
      itemBuilder: (context, index) {
        final session = _archivedSessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ArchivedSessionCard(
            session: session,
            onUnarchive: () => _unarchiveSession(session),
            onDelete: () => _deleteSession(session),
          ),
        );
      },
    );
  }
}

class _ArchivedSessionCard extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const _ArchivedSessionCard({
    required this.session,
    required this.onUnarchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SyraGlass.white8, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.title,
            style: const TextStyle(
              color: SyraColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (session.lastMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              session.lastMessage!,
              style: TextStyle(color: SyraColors.textMuted, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${session.messageCount} mesaj',
                style: TextStyle(
                  color: SyraColors.textMuted.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              _SmallButton(
                icon: Icons.unarchive_outlined,
                label: 'Çıkar',
                onTap: onUnarchive,
              ),
              const SizedBox(width: 8),
              _SmallButton(
                icon: Icons.delete_outline,
                label: 'Sil',
                isDestructive: true,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SmallButton({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFFF6B6B)
        : SyraColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// UI COMPONENTS
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: SyraColors.textMuted.withOpacity(0.6),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SyraColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SyraGlass.white8, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final Color? iconColor;
  final bool isDestructive;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.iconColor,
    this.isDestructive = false,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFFF6B6B)
        : (iconColor ?? SyraColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: SyraColors.accent.withOpacity(0.08),
        highlightColor: SyraColors.accent.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDestructive
                            ? const Color(0xFFFF6B6B)
                            : SyraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: SyraColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) trailingWidget!,
              if (trailing != null && trailingWidget == null)
                Text(
                  trailing!,
                  style: TextStyle(color: SyraColors.textMuted, fontSize: 15),
                ),
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SyraColors.textMuted.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Container(height: 0.5, color: SyraGlass.white8),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: SyraColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: SyraGlass.white8, width: 0.5),
        ),
        child: Icon(icon, color: SyraColors.textSecondary, size: 18),
      ),
    );
  }
}
