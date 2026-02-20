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
import 'syra_markdown.dart';

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

    Future<void> runAction(FutureOr<void> Function() fn) async {
      Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 80));
      widget.onClose();
      fn();
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'session_menu',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) {
        return _ClaudeStyleSessionMenu(
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
          onClose: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Claude-style: narrower sidebar to prevent clipping
    final sidebarWidth = (screenWidth * 0.72).clamp(260.0, 320.0);

    // Claude-style: Sidebar is always static, no animation
    // Chat screen slides over it
    return GestureDetector(
      // Allow swipe to close from sidebar
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -300) {
          HapticFeedback.lightImpact();
          widget.onClose();
        }
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: SyraTokens.background,
          ),
          child: SafeArea(
            bottom: false, // Don't add bottom padding, we handle it manually
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
          isPremium: true,
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
              color: Colors.white.withOpacity(0.45),
              fontSize: 14, // Increased from 13
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
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

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Claude-style: minimal glass pill button with transparent background
    // NOTE: onClose() removed so sidebar stays open when settings modal appears
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          // Sidebar stays open - modal sheet will appear over it
          widget.onSettingsTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar circle - dark background like Claude
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    getInitials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Name
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    widget.userName ?? 'Kullanıcı',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Material(
          color:
              isSelected ? Colors.black.withOpacity(0.50) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.white.withOpacity(0.08),
            highlightColor: Colors.white.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
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
                  : Colors.white.withOpacity(0.75),
              size: 24, // Increased from 22
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Geist',
                color: Colors.white.withOpacity(0.88),
                fontSize: 17, // Increased from 16
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

/// ===== Claude-Style Session Menu (Two Cards: Preview + Actions) =====

class _ClaudeStyleSessionMenu extends StatefulWidget {
  final String sessionId;
  final String title;
  final String fallbackSubtitle;
  final String trailing;
  final VoidCallback? onRename;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback onClose;

  const _ClaudeStyleSessionMenu({
    required this.sessionId,
    required this.title,
    required this.fallbackSubtitle,
    required this.trailing,
    required this.onClose,
    this.onRename,
    this.onArchive,
    this.onDelete,
  });

  @override
  State<_ClaudeStyleSessionMenu> createState() =>
      _ClaudeStyleSessionMenuState();
}

class _ClaudeStyleSessionMenuState extends State<_ClaudeStyleSessionMenu> {
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
          .limit(8)
          .get();

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
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                // Large Preview Card - mimics actual chat screen
                Expanded(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing
                    child: _buildPreviewCard(),
                  ),
                ),
                const SizedBox(height: 16),
                // Actions Card (glass - same as mode selector)
                GestureDetector(
                  onTap: () {}, // Prevent closing
                  child: _buildActionsCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SyraTokens.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        // Messages - exactly like real chat screen (no header)
        child: Container(
          color: SyraTokens.background,
          child: FutureBuilder<List<_PreviewMsg>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white24,
                  ),
                );
              }

              final msgs = snap.data ?? [];
              if (msgs.isEmpty) {
                return Center(
                  child: Text(
                    widget.fallbackSubtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final msg = msgs[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: msg.isUser ? 20 : 24),
                    child: _RealChatBubble(
                      text: msg.text,
                      isUser: msg.isUser,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    // Exact same glass values as MinimalModeSelector
    return ClipRRect(
      borderRadius: BorderRadius.circular(23),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 250,
          decoration: ib.BoxDecoration(
            color: Colors.white.withOpacity(0.003),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              // CSS: 0 -2px 4px inset black 20%
              ib.BoxShadow(
                inset: true,
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.15),
              ),
              // CSS: 0 2px 4px inset white 40%
              ib.BoxShadow(
                inset: true,
                offset: const Offset(0, 2),
                blurRadius: 4,
                color: Colors.white.withOpacity(0.20),
              ),
              // Drop shadow
              ib.BoxShadow(
                offset: const Offset(0, 8),
                blurRadius: 24,
                color: Colors.black.withOpacity(0.2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onRename != null)
                _GlassActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Yeniden Adlandir',
                  onTap: widget.onRename!,
                ),
              if (widget.onRename != null &&
                  (widget.onArchive != null || widget.onDelete != null))
                _glassDivider(),
              if (widget.onArchive != null)
                _GlassActionButton(
                  icon: Icons.archive_outlined,
                  label: 'Arsivle',
                  onTap: widget.onArchive!,
                ),
              if (widget.onArchive != null && widget.onDelete != null)
                _glassDivider(),
              if (widget.onDelete != null)
                _GlassActionButton(
                  icon: Icons.delete_outline,
                  label: 'Sil',
                  onTap: widget.onDelete!,
                  isDestructive: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withOpacity(0.06),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFFF453A) : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color.withOpacity(0.85)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real chat bubble style for preview - uses SyraMarkdown like actual chat
class _RealChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _RealChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (isUser) {
      // User bubble - right aligned, accent color, same as SyraMessageBubble
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SyraColors.accent.withOpacity(0.22),
                SyraColors.accent.withOpacity(0.12),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
            border: Border.all(
              color: SyraColors.accent.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Geist',
              color: Colors.white.withOpacity(0.95),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      );
    } else {
      // Assistant message - left aligned, no bubble, uses SyraMarkdown for proper rendering
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SyraMarkdown(
            data: text,
            selectable: false,
          ),
        ),
      );
    }
  }
}

class _PreviewMsg {
  final bool isUser;
  final String text;

  const _PreviewMsg({required this.isUser, required this.text});
}
