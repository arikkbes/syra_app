import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_user.dart';
import '../theme/syra_theme.dart';
import '../widgets/syra_orb.dart';
import '../widgets/glass_input.dart';
import '../widgets/syra_message_bubble.dart';
import '../widgets/glass_background.dart';
import '../widgets/blur_toast.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'side_menu.dart';
import 'relationship_analysis_screen.dart';
import 'chat_sessions_sheet.dart';
import 'tactical_moves_screen.dart';
import 'daily_tip_screen.dart';
import 'chat_archive_screen.dart';
import 'premium_management_screen.dart';

const bool forcePremiumForTesting = false;

// ═══════════════════════════════════════════════════════════════
// CHAT SCREEN
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

  @override
  void initState() {
    super.initState();

    _initUser();

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

    // Welcome message
    _messages.add({
      'id': UniqueKey().toString(),
      'sender': 'bot',
      'text': 'Selam kanka 👋 Hazırım. Bugün neyi çözüyoruz?',
      'replyTo': null,
      'time': DateTime.now(),
      'hasRed': false,
      'hasGreen': false,
    });
  }

  Future<void> _initUser() async {
    try {
      final status = await FirestoreUser.getMessageStatus();

      // Safe type casting with defaults
      final bool isPremium = status["isPremium"] == true;

      int limit = 10;
      if (status["limit"] is int) {
        limit = status["limit"];
      } else if (status["limit"] is num) {
        limit = (status["limit"] as num).toInt();
      }

      int count = 0;
      if (status["count"] is int) {
        count = status["count"];
      } else if (status["count"] is num) {
        count = (status["count"] as num).toInt();
      }

      if (!mounted) return;
      setState(() {
        _isPremium = isPremium;
        _dailyLimit = limit <= 0 ? 10 : limit;
        _messageCount = count.clamp(0, _dailyLimit);
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
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: SyraColors.surface.withValues(alpha: 0.9),
                  border: Border.all(
                    color: SyraColors.glassBorder,
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
                color: SyraColors.textPrimary.withValues(alpha: 0.9),
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
        final status = await FirestoreUser.getMessageStatus();
        final bool isPremium = status["isPremium"] == true;

        int limit = 10;
        if (status["limit"] is int) {
          limit = status["limit"];
        } else if (status["limit"] is num) {
          limit = (status["limit"] as num).toInt();
        }

        int count = 0;
        if (status["count"] is int) {
          count = status["count"];
        } else if (status["count"] is num) {
          count = (status["count"] as num).toInt();
        }

        if (mounted) {
          setState(() {
            _isPremium = isPremium;
            _dailyLimit = limit <= 0 ? 10 : limit;
            _messageCount = count.clamp(0, _dailyLimit);
          });
        }
      } catch (e) {
        debugPrint("getMessageStatus error: $e");
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
        await FirestoreUser.incrementMessageCount();
      } catch (e) {
        debugPrint("incrementMessageCount ERROR: $e");
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // SEND TO BACKEND
    // ═══════════════════════════════════════════════════════════════
    try {
      final res = await http.post(
        Uri.parse(
          "https://us-central1-flortiq-v2.cloudfunctions.net/flortIQChat",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": text,
          "replyTo": replyBackup,
          "uid": uid,
        }),
      );

      if (res.statusCode != 200) {
        debugPrint("Backend ERROR ${res.statusCode}: ${res.body}");
        if (mounted) {
          BlurToast.show(context, "Şu an cevap veremiyorum kanka.");
        }
        setState(() {
          _isTyping = false;
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(res.body);
      final botText = data["reply"] ?? "Şu an cevap üretemedim kanka.";

      // Extract flags safely
      final traits = data["extractedTraits"];
      bool hasRed = false;
      bool hasGreen = false;

      if (traits is Map && traits["flags"] is Map) {
        final flags = traits["flags"];
        if (flags["red"] is List && (flags["red"] as List).isNotEmpty) {
          hasRed = true;
        }
        if (flags["green"] is List && (flags["green"] as List).isNotEmpty) {
          hasGreen = true;
        }
      }

      setState(() {
        _messages.add({
          "id": UniqueKey().toString(),
          "sender": "bot",
          "text": botText,
          "replyTo": null,
          "time": DateTime.now(),
          "hasRed": hasRed,
          "hasGreen": hasGreen,
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
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SyraColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SyraColors.glassBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SyraColors.accentGradient,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    "Günlük Limit Doldu",
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
                              border: Border.all(color: SyraColors.glassBorder),
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
                              gradient: SyraColors.accentGradient,
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
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Premium Background
            const SyraBackground(
              enableParticles: true,
              enableGrain: true,
              particleOpacity: 0.025,
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildOrbSection(),
                  Expanded(child: _buildMessageList()),
                  GlassInputBar(
                    controller: _controller,
                    onSend: _sendMessage,
                    isLoading: _isLoading,
                    replyingToText: _replyingTo?["text"],
                    onCancelReply: () => setState(() => _replyingTo = null),
                    hintText: "Mesajını yaz...",
                  ),
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
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),

            // Side menu
            SideMenu(
              slideAnimation: _menuOffset,
              isPremium: _isPremium,
              onTapPremium: () {
                _navigateToPremium();
                _toggleMenu();
              },
              onTapChatSessions: () {
                _openChatSessions();
                _toggleMenu();
              },
              onTapTactical: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TacticalMovesScreen(),
                  ),
                );
                _toggleMenu();
              },
              onTapAnalysis: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RelationshipAnalysisScreen(),
                  ),
                );
                _toggleMenu();
              },
              onTapArchive: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatArchiveScreen(),
                  ),
                );
                _toggleMenu();
              },
              onTapDailyTip: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DailyTipScreen(),
                  ),
                );
                _toggleMenu();
              },
              onTapSettings: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                _toggleMenu();
              },
              onTapLogout: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Menu button
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SyraColors.glassBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.menu_rounded,
                color: SyraColors.textSecondary,
                size: 18,
              ),
            ),
          ),

          // Logo
          const Expanded(
            child: Center(
              child: SyraLogo(fontSize: 20, withGlow: true),
            ),
          ),

          // Right side: premium button only (for free users)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPremium && !forcePremiumForTesting)
                GestureDetector(
                  onTap: _navigateToPremium,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SyraColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: const Color(0xFFFFD54F),
                      size: 18,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrbSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Center(
        child: SyraOrb(
          state: _isTyping ? OrbState.thinking : OrbState.idle,
          size: 140,
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      itemCount: _messages.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
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
}
