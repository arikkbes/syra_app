import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/chat_service.dart';
import '../services/firestore_user.dart';
import '../services/chat_session_service.dart';
import '../models/chat_session.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/blur_toast.dart';
import '../widgets/syra_message_bubble.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'side_menu_new.dart';
import 'settings_sheet.dart';
import 'relationship_analysis_screen.dart';
import 'chat_sessions_sheet.dart';
import 'tactical_moves_screen.dart';
import 'daily_tip_screen.dart';
import 'chat_archive_screen.dart';
import 'premium_management_screen.dart';

const bool forcePremiumForTesting = false;

// ═══════════════════════════════════════════════════════════════
// CHAT SCREEN - ChatGPT 2025 Style
// ═══════════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isPremium = false;
  int _dailyLimit = 10;
  int _messageCount = 0;

  bool _isLoading = false;
  bool _isTyping = false;

  Map<String, dynamic>? _replyingTo;

  // Side menu
  bool _menuOpen = false;
  late AnimationController _menuController;
  late Animation<Offset> _menuOffset;

  // Swipe reply
  double _swipeOffset = 0.0;
  String? _swipedMessageId;

  // Limit warning (show only once per session)
  bool _hasShownLimitWarning = false;

  // Chat sessions for sidebar
  List<ChatSession> _chatSessions = [];

  // Tarot mode
  bool _isTarotMode = false;

  @override
  void initState() {
    super.initState();

    _initUser();
    _loadChatSessions();

    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuOffset = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _menuController,
        curve: Curves.easeOutCubic,
      ),
    );

    // No welcome message by default - show logo instead
  }

  Future<void> _initUser() async {
    try {
      final status = await ChatService.getUserStatus();

      if (!mounted) return;
      setState(() {
        _isPremium = status['isPremium'] as bool;
        _dailyLimit = status['limit'] as int;
        _messageCount = status['count'] as int;
      });
    } catch (e) {
      debugPrint("initUser error: $e");
      if (!mounted) return;
      setState(() {
        _dailyLimit = 10;
        _messageCount = 0;
      });
    }
  }

  Future<void> _loadChatSessions() async {
    try {
      final sessions = await ChatSessionService.getUserSessions();
      if (!mounted) return;
      setState(() {
        _chatSessions = sessions;
      });
    } catch (e) {
      debugPrint("loadChatSessions error: $e");
      // Fail silently, empty list is fine
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    if (_menuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageMenu(BuildContext ctx, Map<String, dynamic> msg) async {
    HapticFeedback.selectionClick();

    await showDialog(
      context: ctx,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: SyraColors.surface.withOpacity(0.95),
                  border: Border.all(
                    color: SyraColors.border,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuButton("Yanıtla", Icons.reply_rounded, () {
                      Navigator.pop(ctx);
                      setState(() => _replyingTo = msg);
                    }),
                    _menuButton("Kopyala", Icons.copy_rounded, () {
                      final text = msg["text"];
                      if (text != null) {
                        Clipboard.setData(ClipboardData(text: text));
                      }
                      Navigator.pop(ctx);
                      BlurToast.show(ctx, "Metin kopyalandı");
                    }),
                    _menuButton("Paylaş", Icons.share_rounded, () {
                      Navigator.pop(ctx);
                    }),
                    _menuButton("Sil", Icons.delete_rounded, () {
                      Navigator.pop(ctx);
                      setState(() => _messages.remove(msg));
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _menuButton(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        child: Row(
          children: [
            Icon(icon, color: SyraColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: SyraColors.textPrimary.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to premium screen based on premium status
  void _navigateToPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isPremium
            ? const PremiumManagementScreen()
            : const PremiumScreen(),
      ),
    );
  }

  /// Start a new chat
  void _startNewChat() {
    setState(() {
      _messages.clear();
      _replyingTo = null;
      _isTarotMode = false;
    });
  }

  /// Start tarot mode
  void _startTarotMode() {
    setState(() {
      _messages.clear();
      _replyingTo = null;
      _isTarotMode = true;
      _messages.add({
        "id": UniqueKey().toString(),
        "sender": "bot",
        "text": "🔮 Tarot modu aktif. Kartlar seni bekliyor...\n\n"
            "İlişkinde bir sorun mu var? Bir karar mı vermelisin? "
            "Sormak istediğin bir şey varsa, kartlar sana yol gösterecek.",
        "time": DateTime.now(),
      });
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  /// Handle document upload (placeholder for future feature)
  void _handleDocumentUpload() {
    BlurToast.show(
      context,
      "📄 Doküman analizi özelliği çok yakında gelecek!",
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // ═══════════════════════════════════════════════════════════════
    // AUTH CHECK - Don't crash if user is null
    // ═══════════════════════════════════════════════════════════════
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      BlurToast.show(context, "Tekrar giriş yapman gerekiyor kanka.");
      return;
    }
    final uid = user.uid;

    // ═══════════════════════════════════════════════════════════════
    // MESSAGE LIMIT CHECK
    // ═══════════════════════════════════════════════════════════════
    if (!forcePremiumForTesting) {
      try {
        final status = await ChatService.getUserStatus();

        if (mounted) {
          setState(() {
            _isPremium = status['isPremium'] as bool;
            _dailyLimit = status['limit'] as int;
            _messageCount = status['count'] as int;
          });
        }
      } catch (e) {
        debugPrint("getUserStatus error: $e");
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // 70% WARNING - Show once per session
    // ═══════════════════════════════════════════════════════════════
    if (!_isPremium &&
        !forcePremiumForTesting &&
        !_hasShownLimitWarning &&
        _dailyLimit > 0 &&
        _messageCount >= (_dailyLimit * 0.7).floor() &&
        _messageCount < _dailyLimit) {
      _hasShownLimitWarning = true;
      BlurToast.show(
        context,
        "Bugün mesajlarının çoğunu kullandın kanka.\n"
        "Kısa ve net yaz, istersen Premium'a da göz at 😉",
      );
    }

    // ═══════════════════════════════════════════════════════════════
    // LIMIT REACHED - Block and show premium prompt
    // ═══════════════════════════════════════════════════════════════
    if (!_isPremium &&
        !forcePremiumForTesting &&
        _messageCount >= _dailyLimit) {
      _showLimitReachedDialog();
      return;
    }

    final msgId = UniqueKey().toString();
    final now = DateTime.now();
    final String? replyBackup = _replyingTo?["text"];

    setState(() {
      _messages.add({
        "id": msgId,
        "sender": "user",
        "text": text,
        "replyTo": replyBackup,
        "time": now,
      });

      _controller.clear();
      _replyingTo = null;
      _isTyping = true;
      _isLoading = true;
      _messageCount++;
    });

    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    // ═══════════════════════════════════════════════════════════════
    // INCREMENT MESSAGE COUNT
    // ═══════════════════════════════════════════════════════════════
    if (!forcePremiumForTesting) {
      try {
        await ChatService.incrementMessageCount();
      } catch (e) {
        debugPrint("incrementMessageCount ERROR: $e");
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // SEND TO AI SERVICE
    // ═══════════════════════════════════════════════════════════════
    try {
      final botText = await ChatService.sendMessage(
        userMessage: text,
        conversationHistory: _messages,
        replyingTo: _replyingTo,
      );

      // Detect manipulation patterns
      final flags = ChatService.detectManipulation(botText);

      setState(() {
        _messages.add({
          "id": UniqueKey().toString(),
          "sender": "bot",
          "text": botText,
          "replyTo": null,
          "time": DateTime.now(),
          "hasRed": flags['hasRed'] ?? false,
          "hasGreen": flags['hasGreen'] ?? false,
        });

        _isTyping = false;
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      debugPrint("Network error: $e");
      setState(() {
        _isTyping = false;
        _isLoading = false;
      });
      if (mounted) {
        BlurToast.show(context, "Bağlantı kurulamadı kanka");
      }
    }
  }

  /// Show dialog when daily limit is reached
  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SyraColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SyraColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SyraColors.accent.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: SyraColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    "Günlük Limit Doldu",
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    "Bugünlük mesaj hakkın bitti kanka.\n"
                    "Premium ile sınırsız devam edebilirsin!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: SyraColors.glassBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SyraColors.border),
                            ),
                            child: const Center(
                              child: Text(
                                "Tamam",
                                style: TextStyle(
                                  color: SyraColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Premium
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _navigateToPremium();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: SyraColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "Premium'a Geç",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openChatSessions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ChatSessionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SyraColors.background,
        body: Stack(
          children: [
            // Solid Background
            const SyraBackground(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(),
                  ),
                  _buildInputBar(),
                ],
              ),
            ),

            // Menu overlay
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_menuOpen,
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _menuOpen
                        ? Colors.black.withOpacity(0.5)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),

            // Side menu - NEW VERSION
            SideMenuNew(
              slideAnimation: _menuOffset,
              isPremium: _isPremium,
              chatSessions: _chatSessions,
              onNewChat: () {
                _toggleMenu();
                _startNewChat();
              },
              onTarotMode: () {
                _toggleMenu();
                _startTarotMode();
              },
              onSelectChat: (chat) {
                _toggleMenu();
                // TODO: Load selected chat messages
                BlurToast.show(context, "Chat yükleme özelliği yakında!");
              },
              onDeleteChat: (chat) async {
                try {
                  await ChatSessionService.deleteSession(chat.id);
                  await _loadChatSessions();
                  if (mounted) {
                    BlurToast.show(context, "Chat silindi");
                  }
                } catch (e) {
                  debugPrint("Delete chat error: $e");
                }
              },
              onOpenSettings: () {
                _toggleMenu();
                SettingsSheet.show(context);
              },
              onClose: _toggleMenu,
            ),
          ],
        ),
      ),
    );
  }

  /// ChatGPT-style App Bar
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SyraColors.background,
        border: Border(
          bottom: BorderSide(
            color: SyraColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Menu button
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: SyraColors.textSecondary,
                size: 24,
              ),
            ),
          ),

          // Logo with mod label
          Expanded(
            child: Center(
              child: const SyraLogo(fontSize: 18, showModLabel: true),
            ),
          ),

          // Upload/Analysis button
          GestureDetector(
            onTap: _handleDocumentUpload,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.upload_file_outlined,
                color: SyraColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state with centered logo
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SYRA Logo - large, centered
          Image.asset(
            'assets/icon/syra.png',
            width: 100,
            height: 100,
            color: SyraColors.textPrimary.withOpacity(0.15),
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image not found
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SyraColors.textPrimary.withOpacity(0.15),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _isTarotMode ? "🔮" : "S",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: SyraColors.textPrimary.withOpacity(0.15),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            _isTarotMode ? "Kartlar hazır..." : "Bugün neyi çözüyoruz?",
            style: TextStyle(
              color: _isTarotMode ? SyraColors.accent : SyraColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        // Show typing indicator
        if (_isTyping && index == _messages.length) {
          return _buildTypingIndicator();
        }

        final msg = _messages[index];
        final isUser = msg["sender"] == "user";

        final bool isSwiped =
            _swipedMessageId == msg["id"] && _swipeOffset != 0.0;

        final double effectiveOffset = isSwiped
            ? Curves.easeOutCubic.transform(_swipeOffset / 30).clamp(0.0, 1.0) *
                30
            : 0;

        return GestureDetector(
          onLongPress: () => _showMessageMenu(context, msg),
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              setState(() {
                _swipedMessageId = msg["id"];
                _swipeOffset = (_swipeOffset + details.delta.dx).clamp(0, 30);
              });
            }
          },
          onHorizontalDragEnd: (_) {
            if (_swipeOffset > 18) {
              setState(() => _replyingTo = msg);
            }
            setState(() {
              _swipeOffset = 0;
              _swipedMessageId = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            transform: Matrix4.translationValues(effectiveOffset, 0, 0),
            child: SyraMessageBubble(
              text: msg["text"] ?? '',
              isUser: isUser,
              time: msg["time"] is DateTime ? msg["time"] : null,
              replyToText: msg["replyTo"],
              hasRedFlag: !isUser && (msg['hasRed'] == true),
              hasGreenFlag: !isUser && (msg['hasGreen'] == true),
              onLongPress: () => _showMessageMenu(context, msg),
            ),
          ),
        );
      },
    );
  }

  /// Typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SyraColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SyraColors.textMuted.withOpacity(value),
          ),
        );
      },
    );
  }

  /// ChatGPT-style input bar
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: SyraColors.background,
        border: Border(
          top: BorderSide(
            color: SyraColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          if (_replyingTo != null) _buildReplyPreview(),

          // Input field
          Container(
            decoration: BoxDecoration(
              color: SyraColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: SyraColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Plus button
                GestureDetector(
                  onTap: () {
                    // Future: attachment menu
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(left: 4, bottom: 4),
                    child: const Icon(
                      Icons.add_rounded,
                      color: SyraColors.textMuted,
                      size: 24,
                    ),
                  ),
                ),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    maxLines: 5,
                    minLines: 1,
                    style: const TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      hintText: "Message",
                      hintStyle: TextStyle(
                        color: SyraColors.textHint,
                        fontSize: 15,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                // Mic button
                GestureDetector(
                  onTap: () {
                    // Future: voice input
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      color: SyraColors.textMuted,
                      size: 24,
                    ),
                  ),
                ),

                // Send button
                GestureDetector(
                  onTap: _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: _controller.text.trim().isNotEmpty && !_isLoading
                          ? SyraColors.textPrimary
                          : SyraColors.textMuted.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SyraColors.background,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: SyraColors.background,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraColors.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: SyraColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Yanıtlanıyor",
                  style: TextStyle(
                    color: SyraColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!["text"] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SyraColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: SyraColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
