// lib/widgets/claude_sidebar.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as ib;

import '../models/chat_session.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_tokens.dart';

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

class _ClaudeSidebarState extends State<ClaudeSidebar> {
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
      widget.onClose(); // sidebar kapat
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

    // Claude-style: Sidebar is always static, no animation
    // Chat screen slides over it
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: SyraTokens.background,
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
              fontFamily: 'Literata',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    // Filter sessions with messages
    final filteredSessions =
        widget.sessions.where((s) => s.messageCount > 0).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        _MenuItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Yeni Sohbet',
          onTap: () {
            widget.onClose();
            widget.onNewChat?.call();
          },
        ),
        const SizedBox(height: 8),
        _MenuItem(
          icon: Icons.auto_fix_high_rounded,
          label: 'Tarot Modu',
          onTap: () {
            widget.onClose();
            widget.onTarotMode?.call();
          },
        ),
        _MenuItem(
          icon: Icons.favorite_border_rounded,
          label: 'Kim Daha Çok Seviyor?',
          onTap: () {
            widget.onClose();
            widget.onKimDahaCok?.call();
          },
        ),
        const SizedBox(height: 16),
        const _MenuDivider(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            'Recents',
            style: TextStyle(
              fontFamily: 'Geist',
              color: Colors.white.withOpacity(0.42),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
            ),
          ),
        ),
        // Session items directly in ListView
        ...filteredSessions.map((s) => _SessionItem(
              title: s.title,
              subtitle: _subtitle(s),
              trailing: _timeLabel(s.lastUpdatedAt),
              isSelected: s.id == widget.currentSessionId,
              onTap: () {
                widget.onClose();
                widget.onSelectSession(s.id);
              },
              onOpenMenuAt: (pos) => _openSessionMenuAt(s, pos),
            )),
        if (widget.sessions.length > 10 && widget.onOpenAllSessions != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 6),
              child: TextButton(
                onPressed: () {
                  widget.onClose();
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
    // Get user initials
    String getInitials() {
      if (widget.userName == null || widget.userName!.isEmpty) return 'U';
      final parts = widget.userName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return widget.userName!.substring(0, 1).toUpperCase();
    }

    return Container(
      color: SyraTokens.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: ib.BoxDecoration(
                color: SyraTokens.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
                boxShadow: [
                  // CSS: 0 -2px 4px inset black 20%
                  ib.BoxShadow(
                    inset: true,
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.15),
                  ),
                  // CSS: 0 2px 4px inset white 40%
                  ib.BoxShadow(
                    inset: true,
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onClose();
                  widget.onSettingsTap?.call();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD6B35A).withOpacity(0.9),
                              const Color(0xFFD6B35A).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            getInitials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.userName ?? 'Kullanıcı',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: isSelected
                      ? Colors.white.withOpacity(0.95)
                      : Colors.white.withOpacity(0.70),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.15,
                ),
              ),
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
              color:
                  isPremium ? SyraColors.accent : Colors.white.withOpacity(0.8),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Geist',
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
      color: Colors.white.withOpacity(0.05),
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
