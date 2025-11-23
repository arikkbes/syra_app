import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_user.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';
import 'side_menu.dart';

// ---------------------------------------------------------
// TEST CONFIG
// ---------------------------------------------------------
// Premium'u test için ZORLA açmak istersen:
// true yap → premium UI aktif olur (Windows'ta bile)
// false yap → gerçek premium sistemi çalışır (Android/iOS)
const bool forcePremiumForTesting = false;

// ---------------------------------------------------------
// BLUR TOAST
// ---------------------------------------------------------
class BlurToast {
  static OverlayEntry? _entry;

  static void show(BuildContext context, String msg) {
    _entry?.remove();
    final overlay = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.black.withOpacity(0.7),
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    Future.delayed(const Duration(seconds: 2), () {
      _entry?.remove();
    });
  }
}

// ---------------------------------------------------------
// CHAT SCREEN
// ---------------------------------------------------------
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();

  bool _isPremium = false;
  int _dailyLimit = 10;
  int _messageCount = 0;

  bool _isLoading = false;
  bool _isTyping = false;

  Map<String, dynamic>? _replyingTo;

  // typing dots
  late AnimationController _dotsController;
  late Animation<int> _dotAnim;

  double _swipeOffset = 0.0;
  String? _swipedMessageId;

  // side menu
  bool _menuOpen = false;
  late AnimationController _menuController;
  late Animation<Offset> _menuOffset;

  @override
  void initState() {
    super.initState();

    // TEST MODE → Premium'u zorla aç
    if (forcePremiumForTesting == true) {
      _isPremium = true;
      _dailyLimit = 99999;
    }

    _initUser(); // 🔥 limit sistemi buradan başlıyor

    // typing dots anim
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _dotAnim = IntTween(begin: 0, end: 3).animate(_dotsController);

    // side menu anim
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
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

    // first bot message
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

  // ---------------------------------------------------------
  // USER INIT (LIMIT FIX)
  // ---------------------------------------------------------
  Future<void> _initUser() async {
    if (forcePremiumForTesting) {
      if (!mounted) return;
      setState(() {
        _isPremium = true;
        _dailyLimit = 99999;
        _messageCount = 0;
      });
      return;
    }

    try {
      final status = await FirestoreUser.getMessageStatus();

      final bool isPremium = status["isPremium"] == true;

      int limit = (status["limit"] is int)
          ? status["limit"]
          : (status["limit"] is num)
              ? (status["limit"] as num).toInt()
              : 10;

      int count = (status["count"] is int)
          ? status["count"]
          : (status["count"] is num)
              ? (status["count"] as num).toInt()
              : 0;

      if (!mounted) return;
      setState(() {
        _isPremium = isPremium;
        _dailyLimit = limit <= 0 ? 10 : limit;
        _messageCount = count.clamp(0, _dailyLimit);
      });
    } catch (e) {
      print("initUser error: $e");
      if (!mounted) return;
      setState(() {
        _dailyLimit = 10;
        _messageCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _dotsController.dispose();
    _menuController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // SUPER MENU TOGGLE
  // ---------------------------------------------------------
  void _toggleMenu() {
    setState(() => _menuOpen = !_menuOpen);
    if (_menuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  // ---------------------------------------------------------
  // BASILI TUT MENÜSÜ
  // ---------------------------------------------------------
  void _showMessageMenu(BuildContext ctx, Map<String, dynamic> msg) async {
    HapticFeedback.selectionClick();

    await showDialog(
      context: ctx,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.05),
          insetPadding: const EdgeInsets.all(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withOpacity(0.45),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuButton("Yanıtla", Icons.reply_rounded, () {
                    Navigator.pop(ctx);
                    setState(() => _replyingTo = msg);
                  }),
                  _menuButton("Kopyala", Icons.copy_rounded, () {
                    Clipboard.setData(ClipboardData(text: msg["text"]));
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
        );
      },
    );
  }

  Widget _menuButton(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // MESAJ GÖNDERME (FINAL LIMIT FIX)
  // ---------------------------------------------------------
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      BlurToast.show(context, "Tekrar giriş yapman gerekiyor kanka.");
      return;
    }
    final uid = user.uid;

    // 🔥 Mesajdan hemen önce Firestore'dan en güncel limitleri çek (gerçek limit)
    if (!forcePremiumForTesting) {
      try {
        final status = await FirestoreUser.getMessageStatus();

        final bool isPremium = status["isPremium"] == true;

        int limit = (status["limit"] is int)
            ? status["limit"]
            : (status["limit"] is num)
                ? (status["limit"] as num).toInt()
                : 10;

        int count = (status["count"] is int)
            ? status["count"]
            : (status["count"] is num)
                ? (status["count"] as num).toInt()
                : 0;

        setState(() {
          _isPremium = isPremium;
          _dailyLimit = limit <= 0 ? 10 : limit;
          _messageCount = count.clamp(0, _dailyLimit);
        });
      } catch (e) {
        print("getMessageStatus error: $e");
      }
    }

    // LIMIT KONTROLÜ
    if (!_isPremium &&
        !forcePremiumForTesting &&
        _messageCount >= _dailyLimit) {
      BlurToast.show(
        context,
        "Bugünlük mesaj limitin doldu kanka.\nPremium ile sınırsız devam edebilirsin.",
      );
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

    // 🔥 Firestore tarafında günlük sayacı artır (gerçek limit sistemi)
    if (!forcePremiumForTesting) {
      try {
        await FirestoreUser.incrementMessageCount();
      } catch (e) {
        print("incrementMessageCount ERROR: $e");
      }
    }

    // -------------------------------------------------------
    // BACKEND API CALL
    // -------------------------------------------------------
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
        print("Backend ERROR ${res.statusCode}: ${res.body}");
        BlurToast.show(context, "Şu an cevap veremiyorum kanka.");
        setState(() {
          _isTyping = false;
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(res.body);
      final botText = data["reply"] ?? "Şu an cevap üretemedim kanka.";

      final traits = data["extractedTraits"] ?? {};
      bool hasRed = false;
      bool hasGreen = false;

      if (traits is Map && traits["flags"] is Map) {
        final flags = traits["flags"];
        if (flags["red"] is List && flags["red"].isNotEmpty) hasRed = true;
        if (flags["green"] is List && flags["green"].isNotEmpty)
          hasGreen = true;
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
    } catch (e) {
      setState(() {
        _isTyping = false;
        _isLoading = false;
      });
      BlurToast.show(context, "Bağlantı kurulamadı kanka");
    }
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBackground(),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildTopCard(),

                  if (!_isPremium && !forcePremiumForTesting) ...[
                    const SizedBox(height: 6),
                    _buildLimitBar(),
                  ],

                  const SizedBox(height: 6),

                  // MESSAGE LIST
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (_isTyping && index == _messages.length) {
                          return _buildTypingBubble();
                        }

                        final msg = _messages[index];
                        final isUser = msg["sender"] == "user";

                        final bool isSwiped = _swipedMessageId == msg["id"] &&
                            _swipeOffset != 0.0;

                        final double effectiveOffset = isSwiped
                            ? Curves.easeOutCubic
                                    .transform(_swipeOffset / 30)
                                    .clamp(0.0, 1.0) *
                                30
                            : 0;

                        return GestureDetector(
                          onLongPress: () => _showMessageMenu(context, msg),
                          onHorizontalDragUpdate: (details) {
                            if (details.delta.dx > 0) {
                              setState(() {
                                _swipedMessageId = msg["id"];
                                _swipeOffset = (_swipeOffset + details.delta.dx)
                                    .clamp(0, 30);
                              });
                            }
                          },
                          onHorizontalDragEnd: (_) {
                            if (_swipeOffset > 18) {
                              setState(() {
                                _replyingTo = msg;
                              });
                            }
                            setState(() {
                              _swipeOffset = 0;
                              _swipedMessageId = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 90),
                            transform: Matrix4.translationValues(
                                effectiveOffset, 0, 0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: _buildMessageBubble(msg, isUser),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (_replyingTo != null) _buildReplyPreview(),
                  _buildInputArea(),
                ],
              ),
            ),

            // MENU OVERLAY
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_menuOpen,
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _menuOpen
                        ? Colors.black.withOpacity(0.4)
                        : Colors.transparent,
                  ),
                ),
              ),
            ),

            // SIDE MENU
            SideMenu(
              slideAnimation: _menuOffset,
              isPremium: _isPremium || forcePremiumForTesting,
              onTapPremium: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                );
                _toggleMenu();
              },
              onTapTactical: () {
                BlurToast.show(
                  context,
                  "Tactical Moves v2.0 ile gelecek kanka 🔥",
                );
                _toggleMenu();
              },
              onTapAnalysis: () {
                BlurToast.show(
                  context,
                  "Deep Analysis ekranı yakında.",
                );
                _toggleMenu();
              },
              onTapArchive: () {
                BlurToast.show(
                  context,
                  "Arşiv sistemi v2’de eklenecek.",
                );
                _toggleMenu();
              },
              onTapDailyTip: () {
                BlurToast.show(
                  context,
                  "Bugünün tavsiyesi: Daha kısa, daha net yaz 😉",
                );
                _toggleMenu();
              },
              onTapSettings: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
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

  // ---------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.06),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        "SYRA",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
        onPressed: _toggleMenu,
      ),
      actions: [
        if (!_isPremium && !forcePremiumForTesting)
          IconButton(
            icon: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD54F),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PremiumScreen(),
                ),
              );
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Background
  // ---------------------------------------------------------
  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0B0B0B),
                Color(0xFF111111),
                Color(0xFF131313),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x33FF7AB8),
                  Color(0x00000000),
                ],
                radius: 0.9,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x3366E0FF),
                  Color(0x00000000),
                ],
                radius: 0.9,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              color: Colors.black.withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Top Card
  // ---------------------------------------------------------
  Widget _buildTopCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF66E0FF).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7AB8), Color(0xFF66E0FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7AB8).withOpacity(0.35),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_isPremium || forcePremiumForTesting)
                            ? "Premium mod açık 🔥"
                            : "Günlük rehberin hazır",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (_isPremium || forcePremiumForTesting)
                            ? "Sınırsız soru, derin analiz."
                            : "Bugünlük $_dailyLimit mesaja kadar buradayım.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.26)),
                    color: Colors.white.withOpacity(0.06),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (_isPremium || forcePremiumForTesting)
                            ? Icons.flash_on_rounded
                            : Icons.lock_open_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (_isPremium || forcePremiumForTesting)
                            ? "PREMIUM"
                            : "FREE",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Limit Bar
  // ---------------------------------------------------------
  Widget _buildLimitBar() {
    final used = _messageCount.clamp(0, _dailyLimit);
    final ratio = used / _dailyLimit.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              AnimatedFractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio.clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF3B6F), Color(0xFFFF7AB8)],
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Limit: $used / $_dailyLimit",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Reply Preview
  // ---------------------------------------------------------
  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7AB8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _replyingTo!["text"],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 18,
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // BUBBLE + FLAGS
  // ---------------------------------------------------------
  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser) {
    final String text = msg["text"] ?? '';
    final String? replyText = msg["replyTo"];
    final DateTime? time = msg["time"] is DateTime ? msg["time"] : null;

    final gradient = isUser
        ? [
            const Color(0xFFFF7AB8).withOpacity(0.92),
            const Color(0xFF66E0FF).withOpacity(0.92),
          ]
        : [
            Colors.white.withOpacity(0.13),
            Colors.white.withOpacity(0.08),
          ];

    final timeStr = time == null
        ? ""
        : "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    final bool hasRed = !isUser && (msg['hasRed'] == true);
    final bool hasGreen = !isUser && (msg['hasGreen'] == true);

    Widget? flagIcon;
    if (hasRed) {
      flagIcon = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.warning_rounded,
          color: Colors.orangeAccent,
          size: 14,
        ),
      );
    } else if (hasGreen) {
      flagIcon = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.pinkAccent,
          size: 14,
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (replyText != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                  width: 0.7,
                ),
              ),
              constraints: const BoxConstraints(maxWidth: 220),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFFF7AB8)
                          : const Color(0xFF66E0FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      replyText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isUser ? 22 : 10),
                    bottomRight: Radius.circular(isUser ? 10 : 22),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 0.3,
                  ),
                  boxShadow: isUser
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF7AB8).withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isUser ? Colors.black : Colors.white,
                    fontSize: 13.5,
                    height: 1.33,
                  ),
                ),
              ),
              if (flagIcon != null)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Opacity(
                    opacity: 0.95,
                    child: flagIcon,
                  ),
                ),
            ],
          ),
          if (timeStr.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 6, right: 6),
              child: Text(
                timeStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // Typing Bubble
  // ---------------------------------------------------------
  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
                width: 0.6,
              ),
            ),
            child: AnimatedBuilder(
              animation: _dotsController,
              builder: (_, __) {
                final active = _dotAnim.value % 3;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final isOn = i == active;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 260),
                      opacity: isOn ? 1 : 0.18,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.2),
                        child: Icon(
                          Icons.circle,
                          size: 6.5,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Input Area
  // ---------------------------------------------------------
  Widget _buildInputArea() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF66E0FF).withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: _replyingTo != null
                            ? "Yanıt yaz..."
                            : "Bugün neyi çözelim kanka?",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF7AB8), Color(0xFF66E0FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF7AB8).withOpacity(0.40),
                            blurRadius: 18,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
