// lib/screens/settings/settings_modal_sheet.dart
// ═══════════════════════════════════════════════════════════════
// SYRA PREMIUM SETTINGS MODAL SHEET
// In-sheet navigation with real glass effects
// ═══════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/syra_theme.dart';
import '../../theme/syra_glass.dart';
import '../../utils/syra_prefs.dart';
import '../premium_screen.dart';

/// SYRA Premium Settings Modal Sheet
class SyraSettingsModalSheet extends StatefulWidget {
  final BuildContext hostContext;

  const SyraSettingsModalSheet({
    super.key,
    required this.hostContext,
  });

  @override
  State<SyraSettingsModalSheet> createState() => _SyraSettingsModalSheetState();
}

class _SyraSettingsModalSheetState extends State<SyraSettingsModalSheet> {
  bool _isPremium = false;
  String? _userEmail;
  String? _userName;

  final List<_SheetPage> _pageStack = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    final isPremium = SyraPrefs.getBool('isPremium', defaultValue: false);

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _userEmail = user?.email;
        _userName = user?.displayName;
      });
    }
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
            border: Border.all(
              color: SyraGlass.white8,
              width: 0.5,
            ),
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
                // Subtle top gradient
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
                        colors: [
                          SyraGlass.white8,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main content
                _buildMainPage(scrollController),

                // Overlay pages
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
        // Handle bar
        _buildHandleBar(),

        // Close button
        _buildCloseButton(),

        // Content
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: [
              // HESAP
              _SectionHeader(title: 'Hesap'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'E-posta',
                    subtitle: _userEmail ?? 'Yükleniyor...',
                    showChevron: false,
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Abonelik',
                    trailing: _isPremium ? 'SYRA Plus' : 'Ücretsiz',
                    showChevron: false, // Tıklanamaz
                  ),
                  if (!_isPremium) ...[
                    const _SettingsDivider(),
                    _SettingsRow(
                      icon: Icons.auto_awesome_rounded,
                      label: 'SYRA Plus\'a yükselt',
                      iconColor: SyraColors.accent,
                      onTap: () => _pushPage(_SheetPage(
                        title: 'SYRA Plus',
                        builder: () => _SubscriptionContent(
                          isPremium: _isPremium,
                          hostContext: widget.hostContext,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      )),
                    ),
                  ],
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.refresh_rounded,
                    label: 'Satın almaları geri yükle',
                    showChevron: false,
                    onTap: () => HapticFeedback.mediumImpact(),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // AYARLAR
              _SectionHeader(title: 'Ayarlar'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.tune_rounded,
                    label: 'Kişiselleştirme',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Kişiselleştirme',
                      builder: () => _PersonalizationContent(onPush: _pushPage),
                    )),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.notifications_outlined,
                    label: 'Bildirimler',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Bildirimler',
                      builder: () => _NotificationsContent(),
                    )),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.shield_outlined,
                    label: 'Gizlilik & Veri',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Gizlilik & Veri',
                      builder: () => _PrivacyContent(),
                    )),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.archive_outlined,
                    label: 'Arşivlenmiş sohbetler',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Arşivlenmiş sohbetler',
                      builder: () => _ArchivedChatsContent(),
                    )),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // UYGULAMA
              _SectionHeader(title: 'Uygulama'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.language_rounded,
                    label: 'Dil',
                    trailing: 'Türkçe',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Dil',
                      builder: () => _LanguageContent(),
                    )),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.palette_outlined,
                    label: 'Görünüm',
                    trailing: 'Koyu',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Görünüm',
                      builder: () => _AppearanceContent(),
                    )),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.vibration_rounded,
                    label: 'Dokunsal geri bildirim',
                    trailing: 'Açık',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Dokunsal geri bildirim',
                      builder: () => _HapticsContent(),
                    )),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // HESAP YÖNETİMİ
              _SectionHeader(title: 'Hesap Yönetimi'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Hesap bilgileri',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Hesap bilgileri',
                      builder: () => _AccountContent(),
                    )),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Yardım & Destek',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Yardım & Destek',
                      builder: () => _HelpContent(),
                    )),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Hakkında',
                    onTap: () => _pushPage(_SheetPage(
                      title: 'Hakkında',
                      builder: () => _AboutContent(),
                    )),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Çıkış yap
              _SettingsCard(
                children: [
                  _SettingsRow(
                    icon: Icons.logout_rounded,
                    label: 'Çıkış yap',
                    isDestructive: true,
                    showChevron: false,
                    onTap: () => HapticFeedback.mediumImpact(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Version
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
        child: _RealGlassButton(
          icon: Icons.close_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBack() async {
    await _controller.reverse();
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: SyraColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(-8, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSubPageHeader(),
            Expanded(child: widget.page.builder()),
          ],
        ),
      ),
    );
  }

  Widget _buildSubPageHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Back button - same position as X on main page (left)
          _RealGlassButton(
            icon: Icons.arrow_back_ios_rounded,
            onTap: _handleBack,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REAL GLASS BUTTON (Circular) - Clean glass effect
// ═══════════════════════════════════════════════════════════════
class _RealGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _RealGlassButton({
    required this.icon,
    required this.onTap,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SyraGlass.white8,
              border: Border.all(
                color: SyraGlass.white12,
                width: 0.5,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: SyraColors.textSecondary,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: SyraColors.textMuted.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS CARD
// ═══════════════════════════════════════════════════════════════
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SyraColors.surfaceElevated.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SyraGlass.white8,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS DIVIDER
// ═══════════════════════════════════════════════════════════════
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      height: 0.5,
      color: SyraGlass.white8,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS ROW
// ═══════════════════════════════════════════════════════════════
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailing;
  final Color? iconColor;
  final bool showChevron;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.iconColor,
    this.showChevron = true,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? SyraColors.error : SyraColors.textPrimary;
    final effectiveIconColor = iconColor ?? 
        (isDestructive ? SyraColors.error : SyraColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                HapticFeedback.lightImpact();
                onTap!();
              }
            : null,
        splashColor: SyraColors.accent.withOpacity(0.08),
        highlightColor: SyraColors.accent.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: effectiveIconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                Text(
                  trailing!,
                  style: TextStyle(
                    color: SyraColors.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (showChevron && !isDestructive && onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: SyraColors.textMuted.withOpacity(0.4),
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUB-PAGE CONTENT WIDGETS
// ═══════════════════════════════════════════════════════════════

class _SubscriptionContent extends StatelessWidget {
  final bool isPremium;
  final BuildContext hostContext;
  final VoidCallback onClose;

  const _SubscriptionContent({
    required this.isPremium,
    required this.hostContext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SyraColors.accent.withOpacity(0.15),
                SyraColors.accent.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SyraColors.accent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SyraColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: SyraColors.accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'SYRA Plus',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sınırsız mesaj ve özel özellikler.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SyraColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  onClose();
                  Future.microtask(() {
                    Navigator.of(hostContext, rootNavigator: true).push(
                      CupertinoPageRoute(builder: (_) => const PremiumScreen()),
                    );
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: SyraColors.accent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Planları Gör',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SettingsCard(
          children: [
            _FeatureRow(icon: Icons.all_inclusive_rounded, label: 'Sınırsız mesaj', isEnabled: isPremium),
            const _SettingsDivider(),
            _FeatureRow(icon: Icons.speed_rounded, label: 'Öncelikli yanıt', isEnabled: isPremium),
            const _SettingsDivider(),
            _FeatureRow(icon: Icons.auto_fix_high_rounded, label: 'Gelişmiş özellikler', isEnabled: isPremium),
          ],
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;

  const _FeatureRow({required this.icon, required this.label, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: SyraColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: SyraColors.textPrimary, fontSize: 16))),
          Icon(
            isEnabled ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: isEnabled ? SyraColors.success : SyraColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PersonalizationContent extends StatelessWidget {
  final void Function(_SheetPage) onPush;
  const _PersonalizationContent({required this.onPush});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SettingsCard(
          children: [
            _SettingsRow(icon: Icons.record_voice_over_outlined, label: 'Ton ayarları', subtitle: 'SYRA\'nın konuşma tarzı', onTap: () => onPush(_SheetPage(title: 'Ton ayarları', builder: () => _ToneContent()))),
            const _SettingsDivider(),
            _SettingsRow(icon: Icons.short_text_rounded, label: 'Mesaj uzunluğu', trailing: 'Orta', onTap: () => onPush(_SheetPage(title: 'Mesaj uzunluğu', builder: () => _MessageLengthContent()))),
            const _SettingsDivider(),
            _SettingsRow(icon: Icons.lightbulb_outline_rounded, label: 'Günlük ipuçları', trailing: 'Açık', showChevron: false),
          ],
        ),
      ],
    );
  }
}

class _NotificationsContent extends StatefulWidget {
  @override
  State<_NotificationsContent> createState() => _NotificationsContentState();
}

class _NotificationsContentState extends State<_NotificationsContent> {
  bool _pushEnabled = true;
  bool _tipsEnabled = true;
  bool _reminderEnabled = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SettingsCard(
          children: [
            _SwitchRow(icon: Icons.notifications_active_outlined, label: 'Push bildirimleri', subtitle: 'Önemli güncellemeler', value: _pushEnabled, onChanged: (v) => setState(() => _pushEnabled = v)),
            const _SettingsDivider(),
            _SwitchRow(icon: Icons.tips_and_updates_outlined, label: 'Günlük ipuçları', subtitle: 'İlişki tavsiyeleri', value: _tipsEnabled, onChanged: (v) => setState(() => _tipsEnabled = v)),
            const _SettingsDivider(),
            _SwitchRow(icon: Icons.schedule_outlined, label: 'Hatırlatıcılar', subtitle: 'Sohbet hatırlatmaları', value: _reminderEnabled, onChanged: (v) => setState(() => _reminderEnabled = v)),
          ],
        ),
      ],
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SettingsCard(
          children: [
            _SettingsRow(icon: Icons.delete_outline_rounded, label: 'Sohbet geçmişini sil', subtitle: 'Tüm mesajları kalıcı olarak sil', isDestructive: true, showChevron: false),
            const _SettingsDivider(),
            _SettingsRow(icon: Icons.download_outlined, label: 'Verilerimi indir', showChevron: false),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Verilerini sildiğinde tüm sohbet geçmişin kalıcı olarak silinir. Bu işlem geri alınamaz.', style: TextStyle(color: SyraColors.textMuted.withOpacity(0.6), fontSize: 13, height: 1.5)),
        ),
      ],
    );
  }
}

class _ArchivedChatsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: SyraColors.surfaceElevated, shape: BoxShape.circle), child: Icon(Icons.archive_outlined, color: SyraColors.textMuted, size: 36)),
          const SizedBox(height: 20),
          const Text('Arşivlenmiş sohbet yok', style: TextStyle(color: SyraColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Arşivlediğin sohbetler\nburada görünecek.', textAlign: TextAlign.center, style: TextStyle(color: SyraColors.textMuted, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

class _LanguageContent extends StatefulWidget {
  @override
  State<_LanguageContent> createState() => _LanguageContentState();
}

class _LanguageContentState extends State<_LanguageContent> {
  String _selected = 'tr';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_SettingsCard(children: [_RadioRow(label: 'Türkçe', value: 'tr', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'English', value: 'en', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!))])]);
  }
}

class _AppearanceContent extends StatefulWidget {
  @override
  State<_AppearanceContent> createState() => _AppearanceContentState();
}

class _AppearanceContentState extends State<_AppearanceContent> {
  String _selected = 'dark';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_SettingsCard(children: [_RadioRow(label: 'Sistem', subtitle: 'Cihaz ayarlarını takip et', value: 'system', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'Açık', value: 'light', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'Koyu', value: 'dark', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!))])]);
  }
}

class _HapticsContent extends StatefulWidget {
  @override
  State<_HapticsContent> createState() => _HapticsContentState();
}

class _HapticsContentState extends State<_HapticsContent> {
  String _selected = 'on';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_SettingsCard(children: [_RadioRow(label: 'Açık', subtitle: 'Dokunuşlarda titreşim', value: 'on', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'Kapalı', value: 'off', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!))])]);
  }
}

class _AccountContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_SettingsCard(children: [_SettingsRow(icon: Icons.lock_outline_rounded, label: 'Şifre değiştir'), const _SettingsDivider(), _SettingsRow(icon: Icons.fingerprint_rounded, label: 'Biyometrik kilit', trailing: 'Kapalı')]), const SizedBox(height: 28), _SettingsCard(children: [_SettingsRow(icon: Icons.delete_forever_outlined, label: 'Hesabı sil', isDestructive: true, showChevron: false)])]);
  }
}

class _HelpContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_SettingsCard(children: [_SettingsRow(icon: Icons.chat_bubble_outline_rounded, label: 'Bize ulaşın'), const _SettingsDivider(), _SettingsRow(icon: Icons.help_outline_rounded, label: 'SSS'), const _SettingsDivider(), _SettingsRow(icon: Icons.bug_report_outlined, label: 'Hata bildir')])]);
  }
}

class _AboutContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [Center(child: Column(children: [Container(width: 80, height: 80, decoration: BoxDecoration(color: SyraColors.surfaceElevated, borderRadius: BorderRadius.circular(20), border: Border.all(color: SyraColors.accent.withOpacity(0.3))), child: const Center(child: Text('S', style: TextStyle(fontFamily: 'Literata', color: SyraColors.accent, fontSize: 36, fontWeight: FontWeight.w700)))), const SizedBox(height: 16), const Text('SYRA', style: TextStyle(fontFamily: 'Literata', color: SyraColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 2)), const SizedBox(height: 4), Text('Versiyon 1.0.0', style: TextStyle(color: SyraColors.textMuted, fontSize: 14))])), const SizedBox(height: 32), _SettingsCard(children: [_SettingsRow(icon: Icons.description_outlined, label: 'Kullanım Şartları'), const _SettingsDivider(), _SettingsRow(icon: Icons.privacy_tip_outlined, label: 'Gizlilik Politikası'), const _SettingsDivider(), _SettingsRow(icon: Icons.star_outline_rounded, label: 'Uygulamayı değerlendir', showChevron: false)])]);
  }
}

class _ToneContent extends StatefulWidget {
  @override
  State<_ToneContent> createState() => _ToneContentState();
}

class _ToneContentState extends State<_ToneContent> {
  String _selected = 'balanced';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_SettingsCard(children: [_RadioRow(label: 'Samimi', subtitle: 'Sıcak ve arkadaşça', value: 'friendly', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'Dengeli', subtitle: 'Doğal ve akıcı', value: 'balanced', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'Profesyonel', subtitle: 'Resmi ve ciddi', value: 'professional', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!))])]);
  }
}

class _MessageLengthContent extends StatefulWidget {
  @override
  State<_MessageLengthContent> createState() => _MessageLengthContentState();
}

class _MessageLengthContentState extends State<_MessageLengthContent> {
  String _selected = 'medium';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [_SettingsCard(children: [_RadioRow(label: 'Kısa', subtitle: 'Öz ve net yanıtlar', value: 'short', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'Orta', subtitle: 'Dengeli uzunluk', value: 'medium', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!)), const _SettingsDivider(), _RadioRow(label: 'Uzun', subtitle: 'Detaylı açıklamalar', value: 'long', groupValue: _selected, onChanged: (v) => setState(() => _selected = v!))])]);
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.icon, required this.label, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: SyraColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: SyraColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)), if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(color: SyraColors.textMuted, fontSize: 13))]])),
          CupertinoSwitch(value: value, onChanged: (v) { HapticFeedback.lightImpact(); onChanged(v); }, activeColor: SyraColors.accent),
        ],
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioRow({required this.label, this.subtitle, required this.value, required this.groupValue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.lightImpact(); onChanged(value); },
        splashColor: SyraColors.accent.withOpacity(0.08),
        highlightColor: SyraColors.accent.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: SyraColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)), if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(color: SyraColors.textMuted, fontSize: 13))]])),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? SyraColors.accent : Colors.transparent, border: Border.all(color: isSelected ? SyraColors.accent : SyraColors.textMuted.withOpacity(0.4), width: 2)),
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
