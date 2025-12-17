// lib/widgets/claude_sidebar.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_session.dart';
import '../theme/syra_theme.dart';

/// Claude-style sidebar overlay
class ClaudeSidebar extends StatefulWidget {
  final VoidCallback onClose;

  /// Top actions
  final VoidCallback? onNewChat;
  final VoidCallback? onTarotMode;
  final VoidCallback? onKimDahaCok;

  /// Sidebar içinde session listesi
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final void Function(String sessionId) onSelectSession;

  /// Session actions (long press)
  final void Function(ChatSession session)? onRenameSession;
  final void Function(ChatSession session)? onArchiveSession;
  final void Function(ChatSession session)? onDeleteSession;

  /// Çok sohbet varsa opsiyonel: "Tümünü gör"
  final VoidCallback? onOpenAllSessions;

  /// Profile/settings
  final VoidCallback? onSettingsTap;
  final String? userName;
  final String? userEmail;

  const ClaudeSidebar({
    super.key,
    required this.onClose,
    required this.sessions,
    required this.onSelectSession,
    this.currentSessionId,
    this.onRenameSession,
    this.onArchiveSession,
    this.onDeleteSession,
    this.onOpenAllSessions,
    this.onNewChat,
    this.onTarotMode,
    this.onKimDahaCok,
    this.onSettingsTap,
    this.userName,
    this.userEmail,
  });

  @override
  State<ClaudeSidebar> createState() => _ClaudeSidebarState();
}

class _ClaudeSidebarState extends State<ClaudeSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _dimAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _dimAnimation = Tween<double>(
      begin: 0.0,
      end: 0.10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    HapticFeedback.lightImpact();
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  String _subtitle(ChatSession s) {
    final last = (s.lastMessage ?? '').trim();
    if (last.isNotEmpty) return last;
    if (s.messageCount > 0) return '${s.messageCount} mesaj';
    return 'Henüz mesaj yok';
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    if (diff.inDays < 7) return '${diff.inDays} g';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  Future<void> _openSessionMenuAt(ChatSession s, Offset globalPos) async {
    HapticFeedback.mediumImpact();

    final hasAny = widget.onRenameSession != null ||
        widget.onArchiveSession != null ||
        widget.onDeleteSession != null;

    if (!hasAny) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final overlaySize = overlayBox.size;

    const double w = 320;
    const double padding = 12;

    // Popover’ı parmağın yanına koy, ekran dışına taşmasın
    double left = (globalPos.dx - w + 56).clamp(
      padding,
      overlaySize.width - w - padding,
    );

    // Çok yukarı/çok aşağı kaçmasın
    double top = (globalPos.dy - 110).clamp(
      80,
      overlaySize.height - 360,
    );

    Future<void> runAction(FutureOr<void> Function() fn) async {
      Navigator.of(context).pop(); // popover kapat
      await Future.delayed(const Duration(milliseconds: 80));
      await _close(); // sidebar kapat
      fn();
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'session_menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, a1, a2) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              left: left,
              top: top,
              width: w,
              child: _SessionPopoverCard(
                sessionId: s.id,
                title: s.title,
                fallbackSubtitle: _subtitle(s),
                trailing: _timeLabel(s.lastUpdatedAt),
                onRename: widget.onRenameSession == null
                    ? null
                    : () => runAction(() => widget.onRenameSession!(s)),
                onArchive: widget.onArchiveSession == null
                    ? null
                    : () => runAction(() => widget.onArchiveSession!(s)),
                onDelete: widget.onDeleteSession == null
                    ? null
                    : () => runAction(() => widget.onDeleteSession!(s)),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = (screenWidth * 0.82).clamp(280.0, 360.0);

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _dimAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withOpacity(_dimAnimation.value),
              ),
            );
          },
        ),
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: sidebarWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withOpacity(0.10),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 32,
                    offset: const Offset(8, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildMenuList()),
                    _buildProfileSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          const Text(
            'SYRA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _close,
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _MenuItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Yeni Sohbet',
          onTap: () {
            _close();
            widget.onNewChat?.call();
          },
        ),
        const SizedBox(height: 8),
        _MenuItem(
          icon: Icons.auto_fix_high_rounded,
          label: 'Tarot Modu',
          onTap: () {
            _close();
            widget.onTarotMode?.call();
          },
        ),
        _MenuItem(
          icon: Icons.favorite_border_rounded,
          label: 'Kim Daha Çok Seviyor?',
          onTap: () {
            _close();
            widget.onKimDahaCok?.call();
          },
        ),
        const SizedBox(height: 16),
        const _MenuDivider(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Geçmiş Sohbetler',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildSessionsInline(),
      ],
    );
  }

  Widget _buildSessionsInline() {
    if (widget.sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Text(
          'Henüz sohbet yok',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 12,
            height: 1.2,
          ),
        ),
      );
    }

    final items = widget.sessions.take(12).toList();

    return Column(
      children: [
        for (final s in items)
          _SessionItem(
            title: s.title,
            subtitle: _subtitle(s),
            trailing: _timeLabel(s.lastUpdatedAt),
            isSelected: s.id == widget.currentSessionId,
            onTap: () {
              _close();
              widget.onSelectSession(s.id);
            },
            onOpenMenuAt: (pos) => _openSessionMenuAt(s, pos),
          ),
        if (widget.sessions.length > 10 && widget.onOpenAllSessions != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 6),
              child: TextButton(
                onPressed: () {
                  _close();
                  widget.onOpenAllSessions?.call();
                },
                child: Text(
                  'Tümünü gör',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        _close();
        widget.onSettingsTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: SyraColors.divider.withOpacity(0.9),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: SyraColors.accent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (widget.userName != null && widget.userName!.isNotEmpty)
                      ? widget.userName!.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.userName ?? 'Kullanıcı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.userEmail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.userEmail!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final bool isSelected;
  final VoidCallback onTap;

  /// Menü açılması için anchor pozisyonu
  final void Function(Offset globalPos) onOpenMenuAt;

  const _SessionItem({
    required this.subtitle,
    required this.trailing,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.onOpenMenuAt,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : Colors.white.withOpacity(0.78);

    return GestureDetector(
      onLongPressStart: (d) {
        HapticFeedback.mediumImpact();
        onOpenMenuAt(d.globalPosition);
      },
      onSecondaryTapDown: (d) {
        HapticFeedback.selectionClick();
        onOpenMenuAt(d.globalPosition);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_rounded,
                  color: isSelected
                      ? SyraColors.accent
                      : Colors.white.withOpacity(0.55),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.52),
                          fontSize: 11.5,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  trailing,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPremium;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPremium
                  ? SyraColors.accent
                  : Colors.white.withOpacity(0.8),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (isPremium) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SyraColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: SyraColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: SyraColors.divider.withOpacity(0.9),
    );
  }
}

/// ===== Popover Card (Preview Card + Actions Card) =====

class _PreviewMsg {
  final bool isUser;
  final String text;

  const _PreviewMsg({required this.isUser, required this.text});
}

class _SessionPopoverCard extends StatefulWidget {
  /// Session id for fetching recent messages
  final String sessionId;
  final String title;

  /// Fallback text if messages cannot be fetched
  final String fallbackSubtitle;

  /// Right-side time label
  final String trailing;

  final VoidCallback? onRename;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const _SessionPopoverCard({
    required this.sessionId,
    required this.title,
    required this.fallbackSubtitle,
    required this.trailing,
    this.onRename,
    this.onArchive,
    this.onDelete,
  });

  @override
  State<_SessionPopoverCard> createState() => _SessionPopoverCardState();
}

class _SessionPopoverCardState extends State<_SessionPopoverCard> {
  late Future<List<_PreviewMsg>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadPreview();
  }

  Future<List<_PreviewMsg>> _loadPreview() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return const [];

      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(widget.sessionId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();

      // Snapshot is newest -> oldest. We want oldest -> newest for preview.
      final docs = snap.docs.toList().reversed;
      final out = <_PreviewMsg>[];
      for (final d in docs) {
        final data = d.data();
        final txt = (data['text'] ?? '').toString().trim();
        if (txt.isEmpty) continue;
        final sender = (data['sender'] ?? '').toString();
        out.add(_PreviewMsg(isUser: sender == 'user', text: txt));
      }
      return out;
    } catch (_) {
      // Silent fallback: if Firestore path differs / permission issue, show fallback.
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = 22.0;
    final bg = SyraColors.surfaceElevated.withOpacity(0.92);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: SyraColors.border.withOpacity(0.75),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: _buildPreviewSection(),
                ),
                _thinDivider(),
                _buildActionsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Preview kart: WhatsApp gibi mini sohbet kesiti
  Widget _buildPreviewSection() {
    // WhatsApp hissi: header + sabit yükseklikte mini chat alanı + footer
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 16, color: SyraColors.textSecondary.withOpacity(0.9)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SyraColors.textPrimary.withOpacity(0.95),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Mini chat alanı (tek çerçeve: içeride border yok)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: SyraColors.surfaceDark.withOpacity(0.35),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: SizedBox(
              height: 110,
              child: FutureBuilder<List<_PreviewMsg>>(
                future: _future,
                builder: (context, snap) {
                  final loading = snap.connectionState != ConnectionState.done;
                  if (loading) return _PreviewLoading();

                  final msgs = snap.data ?? const <_PreviewMsg>[];
                  if (msgs.isEmpty) {
                    return Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        widget.fallbackSubtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: SyraColors.textSecondary.withOpacity(0.95),
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // Mesajları aşağıda bitir (WhatsApp gibi)
                  final children = <Widget>[const Spacer()];
                  for (final m in msgs) {
                    children.add(
                      Align(
                        alignment: m.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _MiniBubble(text: m.text, isUser: m.isUser),
                      ),
                    );
                    children.add(const SizedBox(height: 8));
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: children,
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Önizleme',
              style: TextStyle(
                color: SyraColors.textMuted.withOpacity(0.95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              widget.trailing,
              style: TextStyle(
                color: SyraColors.textMuted.withOpacity(0.95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onRename != null)
            _PopoverActionRow(
              icon: Icons.edit_rounded,
              label: 'Yeniden Adlandır',
              onTap: widget.onRename!,
            ),
          if (widget.onRename != null &&
              (widget.onArchive != null || widget.onDelete != null))
            _thinDivider(),
          if (widget.onArchive != null)
            _PopoverActionRow(
              icon: Icons.archive_rounded,
              label: 'Arşivle',
              onTap: widget.onArchive!,
            ),
          if (widget.onArchive != null && widget.onDelete != null)
            _thinDivider(),
          if (widget.onDelete != null)
            _PopoverActionRow(
              icon: Icons.delete_rounded,
              label: 'Sil',
              isDestructive: true,
              onTap: widget.onDelete!,
            ),
        ],
      ),
    );
  }

  Widget _thinDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: SyraColors.divider.withOpacity(0.9),
    );
  }
}

class _MiniBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MiniBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final borderColor = isUser
        ? SyraColors.accent.withOpacity(0.22)
        : SyraColors.border.withOpacity(0.65);

    final gradient = isUser
        ? LinearGradient(
            colors: [
              SyraColors.accent.withOpacity(0.18),
              SyraColors.accent.withOpacity(0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              SyraColors.surfaceElevated.withOpacity(0.75),
              SyraColors.surfaceElevated.withOpacity(0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      constraints: const BoxConstraints(maxWidth: 290),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 5),
          bottomRight: Radius.circular(isUser ? 5 : 16),
        ),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: SyraColors.textPrimary.withOpacity(0.95),
          fontSize: 13.4,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewLoading extends StatelessWidget {
  const _PreviewLoading();

  @override
  Widget build(BuildContext context) {
    // Lightweight skeleton: two ghost bubbles, aligned like chat.
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: const [
        Spacer(),
        Align(
            alignment: Alignment.centerRight,
            child: _GhostBubble(isUser: true)),
        SizedBox(height: 8),
        Align(
            alignment: Alignment.centerLeft,
            child: _GhostBubble(isUser: false)),
      ],
    );
  }
}

class _GhostBubble extends StatelessWidget {
  final bool isUser;
  const _GhostBubble({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final borderColor = isUser
        ? SyraColors.accent.withOpacity(0.18)
        : SyraColors.border.withOpacity(0.55);

    final fill = isUser
        ? SyraColors.accent.withOpacity(0.10)
        : SyraColors.surfaceElevated.withOpacity(0.55);

    return Container(
      width: isUser ? 140 : 180,
      height: 34,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 5),
          bottomRight: Radius.circular(isUser ? 5 : 16),
        ),
        border: Border.all(color: borderColor, width: 1),
      ),
    );
  }
}

class _PopoverActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _PopoverActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = isDestructive ? const Color(0xFFFF5A5F) : Colors.white;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c.withOpacity(0.9), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.withOpacity(0.9),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
