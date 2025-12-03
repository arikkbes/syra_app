import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
// CHAT SCREEN - FIXED VERSION
// ═══════════════════════════════════════════════════════════════
// ✅ Mod button opens mode selection
// ✅ + button opens image picker
// ✅ Microphone button activates speech-to-text
// ✅ Keyboard dismisses on tap
// ✅ Chats are saved to Firestore
// ✅ Multiple chats support
// ✅ Tarot mode is an extension, not separate chat
// ═══════════════════════════════════════════════════════════════

class ChatScreen extends StatefulWidget {
  final String? sessionId;

  const ChatScreen({super.key, this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isPremium = false;
  int _dailyLimit = 10;
  int _messageCount = 0;

  bool _isLoading = false;
  bool _isTyping = false;
  bool _isListening = false;

  Map<String, dynamic>? _replyingTo;

  // Side menu
  bool _menuOpen = false;
  late AnimationController _menuController;
  late Animation<Offset> _menuOffset;

  // Swipe reply
  double _swipeOffset = 0.0;
  String? _swipedMessageId;

  // Limit warning
  bool _hasShownLimitWarning = false;

  // Chat sessions
  List<ChatSession> _chatSessions = [];
  String? _currentSessionId;

  // Modes
  String _currentMode = 'default'; // default, strategic, empathy, direct, tarot
  bool _isTarotMode = false;

  @override
  void initState() {
    super.initState();

    _currentSessionId = widget.sessionId;

    _initUser();
    _loadChatSessions();
    _initSpeech();

    if (_currentSessionId != null) {
      _loadSessionMessages();
    }

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
  }

  @override
  void dispose() {
    _menuController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
      debugPrint('initUser error: $e');
    }
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          setState(() => _isListening = false);
        },
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _loadChatSessions() async {
    final sessions = await ChatSessionService.getUserSessions();
    if (!mounted) return;
    setState(() => _chatSessions = sessions);
  }

  Future<void> _loadSessionMessages() async {
    if (_currentSessionId == null) return;

    final messages =
        await ChatSessionService.getSessionMessages(_currentSessionId!);
    if (!mounted) return;

    setState(() {
      _messages.clear();
      _messages.addAll(messages);
    });

    _scrollToBottom();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE NEW CHAT
  // ═══════════════════════════════════════════════════════════════
  Future<void> _createNewChat() async {
    final sessionId =
        await ChatSessionService.createSession(title: 'Yeni Sohbet');
    if (sessionId == null) return;

    setState(() {
      _currentSessionId = sessionId;
      _messages.clear();
      _replyingTo = null;
      _isTarotMode = false;
      _currentMode = 'default';
    });

    await _loadChatSessions();

    _showToast('Yeni sohbet başlatıldı');
  }

  // ═══════════════════════════════════════════════════════════════
  // SWITCH CHAT
  // ═══════════════════════════════════════════════════════════════
  Future<void> _switchToChat(String sessionId) async {
    setState(() {
      _currentSessionId = sessionId;
      _messages.clear();
    });

    await _loadSessionMessages();
    _closeMenu();
  }

  // ═══════════════════════════════════════════════════════════════
  // MODE SELECTION OVERLAY
  // ═══════════════════════════════════════════════════════════════
  void _showModeSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: SyraColors.border, width: 0.5),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SyraColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Mod Seç',
                  style: TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Modes
              _buildModeOption(
                  'default', '💬', 'Varsayılan', 'Dengeli ve profesyonel'),
              _buildModeOption('strategic', '🎯', 'Stratejik',
                  'Taktiksel analiz ve öneriler'),
              _buildModeOption(
                  'empathy', '💙', 'Empatik', 'Duygusal destek odaklı'),
              _buildModeOption('direct', '⚡', 'Net', 'Kısa ve direkt cevaplar'),
              _buildModeOption('tarot', '🔮', 'Tarot', 'Mistik rehberlik'),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(
      String mode, String emoji, String title, String description) {
    final isSelected = _currentMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMode = mode;
          _isTarotMode = mode == 'tarot';
        });
        Navigator.pop(context);
        _showToast('$emoji $title modu seçildi');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? SyraColors.accent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SyraColors.accent : SyraColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: SyraColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE PICKER
  // ═══════════════════════════════════════════════════════════════
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_camera,
                    color: SyraColors.textPrimary),
                title: const Text('Fotoğraf Çek',
                    style: TextStyle(color: SyraColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(context);
                  final image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    _showToast('Fotoğraf analizi yakında eklenecek');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: SyraColors.textPrimary),
                title: const Text('Galeriden Seç',
                    style: TextStyle(color: SyraColors.textPrimary)),
                onTap: () async {
                  Navigator.pop(context);
                  final image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    _showToast('Fotoğraf analizi yakında eklenecek');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SPEECH TO TEXT
  // ═══════════════════════════════════════════════════════════════
  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      _showToast('Mikrofon kullanılamıyor');
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEND MESSAGE
  // ═══════════════════════════════════════════════════════════════
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Limit check for free users
    if (!_isPremium) {
      final canSend = await ChatService.canSendMessage(
        isPremium: _isPremium,
        messageCount: _messageCount,
        dailyLimit: _dailyLimit,
      );

      if (!canSend) {
        if (!_hasShownLimitWarning) {
          _hasShownLimitWarning = true;
          _showLimitDialog();
        }
        return;
      }
    }

    // Create session if needed
    if (_currentSessionId == null) {
      _currentSessionId = await ChatSessionService.createSession();
      if (_currentSessionId == null) {
        _showToast('Chat oluşturulamadı');
        return;
      }
    }

    final userMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender': 'user',
      'text': text,
      'time': DateTime.now(),
      'replyTo': _replyingTo?['text'],
    };

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Save user message to Firestore
    await ChatSessionService.addMessageToSession(
      sessionId: _currentSessionId!,
      message: {
        'sender': 'user',
        'text': text,
        'timestamp': DateTime.now(),
        'replyTo': _replyingTo?['text'],
      },
    );

    // Get settings for backend
    final settings = await FirestoreUser.getSettings();
    final tone = settings['botCharacter'] ?? 'default';
    final messageLength = settings['replyLength'] ?? 'default';

    // Call AI
    final aiResponse = await ChatService.sendMessage(
      userMessage: text,
      conversationHistory: _messages,
      replyingTo: _replyingTo,
      mode: _currentMode,
      tone: tone,
      messageLength: messageLength,
    );

    // Manipulation detection
    final flags = ChatService.detectManipulation(aiResponse);

    final aiMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender': 'ai',
      'text': aiResponse,
      'time': DateTime.now(),
      'hasRed': flags['hasRed'],
      'hasGreen': flags['hasGreen'],
    };

    setState(() {
      _messages.add(aiMessage);
      _isLoading = false;
      _isTyping = false;
      _replyingTo = null;
      _messageCount++;
    });

    // Save AI message to Firestore
    await ChatSessionService.addMessageToSession(
      sessionId: _currentSessionId!,
      message: {
        'sender': 'ai',
        'text': aiResponse,
        'timestamp': DateTime.now(),
      },
    );

    // Update session
    await ChatSessionService.updateSession(
      sessionId: _currentSessionId!,
      lastMessage: text,
      messageCount: _messages.length,
    );

    // Increment message count
    await ChatService.incrementMessageCount();

    _scrollToBottom();
    await _loadChatSessions();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU CONTROLS
  // ═══════════════════════════════════════════════════════════════
  void _openMenu() {
    setState(() => _menuOpen = true);
    _menuController.forward();
  }

  void _closeMenu() {
    _menuController.reverse();
    setState(() => _menuOpen = false);
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS & TOASTS
  // ═══════════════════════════════════════════════════════════════
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: SyraColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SyraColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Günlük Limit Doldu',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bugün için mesaj limitine ulaştın. Premium\'a geç ve sınırsız kullan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SyraColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tamam'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PremiumScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SyraColors.accent,
                      ),
                      child: const Text('Premium'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageMenu(BuildContext context, Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: SyraColors.textPrimary),
                title: const Text('Yanıtla',
                    style: TextStyle(color: SyraColors.textPrimary)),
                onTap: () {
                  setState(() => _replyingTo = message);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: SyraColors.textPrimary),
                title: const Text('Kopyala',
                    style: TextStyle(color: SyraColors.textPrimary)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message['text'] ?? ''));
                  Navigator.pop(context);
                  _showToast('Kopyalandı');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ FIX: Dismiss keyboard on tap
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: SyraColors.background,
        body: Stack(
          children: [
            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(),
                  ),
                  _buildInputBar(),
                ],
              ),
            ),

            // Side menu
            if (_menuOpen)
              GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),

            SlideTransition(
              position: _menuOffset,
              child: SideMenuNew(
                slideAnimation: _menuOffset,
                isPremium: _isPremium,
                chatSessions: _chatSessions,
                onNewChat: _createNewChat,
                onTarotMode: () {
                  setState(() {
                    _currentMode = 'tarot';
                    _isTarotMode = true;
                  });
                  _closeMenu();
                  _showToast('🔮 Tarot modu aktif');
                },
                onSelectChat: (session) => _switchToChat(session.id),
                onDeleteChat: (session) async {
                  await ChatSessionService.deleteSession(session.id);
                  await _loadChatSessions();
                  _showToast('Sohbet silindi');
                },
                onOpenSettings: () {
                  _closeMenu();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                onClose: _closeMenu,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            onTap: _openMenu,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SyraColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: SyraColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SYRA',
                  style: TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isTarotMode)
                  Text(
                    '🔮 Tarot Modu',
                    style: TextStyle(
                      color: SyraColors.accent,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // ✅ FIX: Mode button now opens overlay
          GestureDetector(
            onTap: _showModeSelection,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SyraColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SyraColors.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getModeEmoji(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: SyraColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getModeEmoji() {
    switch (_currentMode) {
      case 'strategic':
        return '🎯';
      case 'empathy':
        return '💙';
      case 'direct':
        return '⚡';
      case 'tarot':
        return '🔮';
      default:
        return '💬';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _isTarotMode
                ? 'assets/images/syra_logo_tarot.png'
                : 'assets/images/syra_logo.png',
            width: 100,
            height: 100,
            color: SyraColors.textPrimary.withOpacity(0.15),
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) {
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
      onEnd: () {
        // Loop animation
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8, // ✅ FIX: Adjusted padding
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
          if (_replyingTo != null) _buildReplyPreview(),
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
                // ✅ FIX: + button now opens image picker
                GestureDetector(
                  onTap: _pickImage,
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

                // ✅ FIX: Mic button now activates speech-to-text
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening
                          ? SyraColors.accent
                          : SyraColors.textMuted,
                      size: 24,
                    ),
                  ),
                ),

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
