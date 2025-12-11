import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import '../services/chat_service.dart';
import '../services/firestore_user.dart';
import '../services/chat_session_service.dart';
import '../services/image_upload_service.dart';
import '../services/relationship_analysis_service.dart';
import '../models/chat_session.dart';
import '../theme/syra_theme.dart';
import '../theme/design_system.dart';
import '../theme/syra_design_tokens.dart';
import '../widgets/glass_background.dart';
import '../widgets/blur_toast.dart';
import '../widgets/mode_switch_sheet.dart';
import '../widgets/chat_empty_state.dart';
import '../utils/message_adapter.dart';
import '../utils/animation_helpers.dart';
import 'premium_screen.dart';
import 'settings/settings_screen.dart';
import 'side_menu.dart';
import 'chat_sessions_sheet.dart';
import 'tarot_mode_screen.dart';
import 'chat/chat_app_bar.dart';

const bool forcePremiumForTesting = false;

/// ═══════════════════════════════════════════════════════════════
/// CHAT SCREEN v4.0 - Premium AI Chat with polish
/// ═══════════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  // Message storage in SYRA format (internal)
  final List<Map<String, dynamic>> _messages = [];
  
  // Premium & limits
  bool _isPremium = false;
  int _dailyLimit = 10;
  int _messageCount = 0;

  // UI states
  bool _isLoading = false;
  bool _isSending = false;
  bool _hasShownLimitWarning = false;

  // Reply state
  Map<String, dynamic>? _replyingTo;

  // Menu state
  bool _menuOpen = false;
  late AnimationController _menuController;
  late Animation<Offset> _menuOffset;

  // Session management
  List<ChatSession> _chatSessions = [];
  String? _currentSessionId;

  // Mode state
  bool _isTarotMode = false;
  String _selectedMode = "standard";

  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  File? _pendingImage;
  String? _pendingImageUrl;

  // Relationship upload
  bool _isUploadingRelationshipFile = false;

  // Mode selector anchor
  final LayerLink _modeAnchorLink = LayerLink();

  @override
  void initState() {
    super.initState();

    _initUser();
    _loadChatSessions();
    _createInitialSession();
    
    _speech = stt.SpeechToText();

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
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION METHODS
  // ═══════════════════════════════════════════════════════════════

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
    final result = await ChatSessionService.getUserSessions();
    if (!mounted) return;

    if (result.success && result.sessions != null) {
      setState(() {
        _chatSessions = result.sessions!;
      });
    } else {
      debugPrint("❌ Failed to load sessions: ${result.debugMessage}");
      if (result.errorMessage != null && mounted) {
        BlurToast.show(context, result.errorMessage!);
      }
    }
  }

  Future<void> _createInitialSession() async {
    final result = await ChatSessionService.createSession(
      title: "Yeni Sohbet",
    );

    if (result.success && result.sessionId != null) {
      setState(() {
        _currentSessionId = result.sessionId;
      });
      await _loadChatSessions();
    }
  }

  Future<void> _loadSelectedChat(String sessionId) async {
    final result = await ChatSessionService.getSessionMessages(sessionId);
    if (!mounted) return;

    if (result.success && result.messages != null) {
      setState(() {
        _currentSessionId = sessionId;
        _messages.clear();
        _messages.addAll(result.messages!);
        _isTarotMode = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UI ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _toggleMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
      if (_menuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _handleModeSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModeSwitchSheet(
        currentMode: _selectedMode,
        onModeSelected: (mode) {
          setState(() {
            _selectedMode = mode;
            _isTarotMode = mode == 'tarot';
          });
          Navigator.pop(context);

          if (mode == 'tarot') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TarotModeScreen()),
            );
          }
        },
      ),
    );
  }

  void _handleAttachment() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: SyraColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: SyraColors.accent),
              title: const Text('Resim Seç', style: TextStyle(color: SyraColors.textPrimary)),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: SyraColors.accent),
              title: const Text('İlişki Dosyası Yükle', style: TextStyle(color: SyraColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _handleDocumentUpload();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _pendingImage = File(image.path);
        _isLoading = true;
      });

      final result = await ImageUploadService.uploadImage(File(image.path));

      if (result.success && result.downloadUrl != null) {
        setState(() {
          _pendingImageUrl = result.downloadUrl!;
          _isLoading = false;
        });
        
        // Automatically send the image
        _handleSendPressed(types.PartialText(text: ''));
      } else {
        setState(() {
          _pendingImage = null;
          _isLoading = false;
        });
        BlurToast.show(context, result.userMessage ?? "Resim yüklenemedi.");
      }
    } catch (e) {
      setState(() {
        _pendingImage = null;
        _isLoading = false;
      });
      BlurToast.show(context, "Bir hata oluştu.");
    }
  }

  Future<void> _handleVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );

    if (available) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          // Note: We can't directly set text in flutter_chat_ui's input
          // User needs to use the input field
        },
        localeId: 'tr_TR',
      );
    } else {
      BlurToast.show(context, "Mikrofon izni verilmedi.");
    }
  }

  void _handleDocumentUpload() async {
    if (_isUploadingRelationshipFile) return;

    setState(() => _isUploadingRelationshipFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'docx', 'doc'],
      );

      if (result == null || result.files.single.path == null) {
        setState(() => _isUploadingRelationshipFile = false);
        return;
      }

      final file = File(result.files.single.path!);
      BlurToast.show(context, "Dosya yükleniyor...");

      final uploadResult = await RelationshipAnalysisService.uploadRelationshipFile(file);

      if (uploadResult.success) {
        BlurToast.show(context, "✅ Dosya yüklendi! Analizler aktif.");
        await _initUser();
      } else {
        BlurToast.show(
          context,
          uploadResult.userMessage ?? "Dosya yüklenemedi.",
        );
      }
    } catch (e) {
      BlurToast.show(context, "Bir hata oluştu: $e");
    } finally {
      if (mounted) {
        setState(() => _isUploadingRelationshipFile = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE SENDING (flutter_chat_ui callbacks)
  // ═══════════════════════════════════════════════════════════════

  void _handleSendPressed(types.PartialText message) async {
    final text = message.text.trim();

    // Allow empty text if we have pending image
    if (text.isEmpty && _pendingImageUrl == null) return;
    if (_isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      BlurToast.show(context, "Tekrar giriş yapman gerekiyor kanka.");
      return;
    }

    // Check premium & limits
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

    // 70% warning
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

    // Limit check
    if (!_isPremium && !forcePremiumForTesting && _messageCount >= _dailyLimit) {
      _showLimitReachedDialog();
      return;
    }

    final msgId = UniqueKey().toString();
    final now = DateTime.now();
    final String? replyBackup = _replyingTo?["text"];
    final String? imageUrlToSend = _pendingImageUrl;

    final userMessage = {
      "id": msgId,
      "role": "user",
      "sender": "user",
      "text": text,
      "replyTo": replyBackup,
      "time": now,
      "timestamp": now,
      "imageUrl": imageUrlToSend,
      "type": imageUrlToSend != null ? "image" : null,
    };

    setState(() {
      _messages.add(userMessage);
      _replyingTo = null;
      _isLoading = true;
      _isSending = true;
      _messageCount++;
      _pendingImage = null;
      _pendingImageUrl = null;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isSending = false);
      }
    });

    // Session management
    if (_currentSessionId == null) {
      final result = await ChatSessionService.createSession(
        title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
      );
      if (result.success && result.sessionId != null) {
        setState(() => _currentSessionId = result.sessionId);
      }
    } else {
      final userMessageCount = _messages.where((m) => m['sender'] == 'user').length;
      if (userMessageCount == 1) {
        await ChatSessionService.updateSession(
          sessionId: _currentSessionId!,
          title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
        );
      }
    }

    if (_currentSessionId != null) {
      await ChatSessionService.addMessageToSession(
        sessionId: _currentSessionId!,
        message: userMessage,
      );

      await ChatSessionService.updateSession(
        sessionId: _currentSessionId!,
        lastMessage: text,
        messageCount: _messages.where((m) => m['sender'] == 'user').length,
      );
    }

    // Increment count
    if (!forcePremiumForTesting) {
      try {
        await ChatService.incrementMessageCount();
      } catch (e) {
        debugPrint("incrementMessageCount ERROR: $e");
      }
    }

    // Send to AI
    final result = await ChatService.sendMessage(
      userMessage: text.isEmpty ? "Bu resimle ilgili ne düşünüyorsun?" : text,
      conversationHistory: _messages,
      replyingTo: _replyingTo,
      mode: _selectedMode,
      imageUrl: imageUrlToSend,
    );

    if (result.success && result.responseText != null) {
      final botText = result.responseText!;
      final flags = ChatService.detectManipulation(botText);

      final botMessage = {
        "id": UniqueKey().toString(),
        "role": "assistant",
        "sender": "bot",
        "text": botText,
        "replyTo": null,
        "time": DateTime.now(),
        "timestamp": DateTime.now(),
        "hasRedFlag": flags['hasRed'] ?? false,
        "hasGreenFlag": flags['hasGreen'] ?? false,
      };

      setState(() {
        _messages.add(botMessage);
        _isLoading = false;
        _isSending = false;
      });

      if (_currentSessionId != null) {
        await ChatSessionService.addMessageToSession(
          sessionId: _currentSessionId!,
          message: botMessage,
        );
        await ChatSessionService.updateSession(
          sessionId: _currentSessionId!,
          lastMessage: botText.length > 50 ? "${botText.substring(0, 50)}..." : botText,
          messageCount: _messages.length,
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _isSending = false;
      });

      if (result.userMessage != null) {
        BlurToast.show(context, result.userMessage!);
      }
    }
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => fadeIn(
        AlertDialog(
          backgroundColor: SyraColors.surface,
          shape: RoundedRectangleBorder(borderRadius: SyraRadius.radiusXL),
          contentPadding: EdgeInsets.all(SyraSpacing.xxl),
          title: Text(
            '💬 Günlük Limit Doldu',
            style: SyraTypography.titleLarge,
          ),
          content: Text(
            'Bugün için mesaj limitini doldurdun kanka!\n\n'
            'Premium\'a geçersen limitsiz mesaj atabilirsin.',
            style: SyraTypography.bodyMedium.copyWith(
              color: SyraColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tamam',
                style: SyraTypography.labelLarge.copyWith(
                  color: SyraColors.textSecondary,
                ),
              ),
            ),
            AnimatedPressButton(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SyraSpacing.lg,
                  vertical: SyraSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: SyraColors.accent,
                  borderRadius: SyraRadius.radiusMD,
                ),
                child: Text(
                  'Premium\'a Geç',
                  style: SyraTypography.labelLarge.copyWith(
                    color: SyraColors.background,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD METHOD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Convert SYRA messages to flutter_chat_ui format
    List<types.Message> chatMessages = MessageAdapter.toFlutterChatMessages(_messages);
    final currentUser = MessageAdapter.getCurrentUser();

    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: SyraTokens.background,
          body: Stack(
            children: [
              const SyraBackground(),

              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()
                      ..translate(_menuOpen ? 56.0 : 0.0, 0.0, 0.0)
                      ..scale(_menuOpen ? 0.95 : 1.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 720),
                      decoration: _menuOpen
                          ? BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 32,
                                  offset: const Offset(-8, 0),
                                ),
                              ],
                            )
                          : null,
                      child: Column(
                        children: [
                          // App Bar
                          ChatAppBar(
                            selectedMode: _selectedMode,
                            modeAnchorLink: _modeAnchorLink,
                            onMenuTap: _toggleMenu,
                            onModeTap: _handleModeSelection,
                            onDocumentUpload: _handleDocumentUpload,
                          ),

                          // Chat UI using flutter_chat_ui
                          Expanded(
                            child: _messages.isEmpty
                                ? ChatEmptyState(
                                    isTarotMode: _isTarotMode,
                                    onSuggestionTap: () {
                                      // Handle suggestion tap
                                    },
                                  )
                                : animateMessage(
                                    Chat(
                                      messages: chatMessages,
                                      onSendPressed: _handleSendPressed,
                                      user: currentUser,
                                      showUserAvatars: false,
                                      showUserNames: false,
                                      isLastPage: true,
                                      theme: DefaultChatTheme(
                                        backgroundColor: Colors.transparent,
                                        inputBackgroundColor: SyraColors.surface.withOpacity(0.6),
                                        inputTextColor: SyraColors.textPrimary,
                                        inputBorderRadius: SyraRadius.radiusXXL,
                                        primaryColor: SyraColors.accent,
                                        secondaryColor: SyraColors.surface,
                                        messageBorderRadius: SyraRadius.lg,
                                        userAvatarNameColors: [SyraColors.accent],
                                        receivedMessageBodyTextStyle: SyraTypography.bodyMedium,
                                        sentMessageBodyTextStyle: SyraTypography.bodyMedium,
                                        inputTextStyle: SyraTypography.bodyMedium,
                                        inputPadding: EdgeInsets.symmetric(
                                          horizontal: SyraSpacing.lg,
                                          vertical: SyraSpacing.md,
                                        ),
                                        messageInsetsHorizontal: SyraSpacing.lg,
                                        messageInsetsVertical: SyraSpacing.sm,
                                      ),
                                      customBottomWidget: _buildCustomInput(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Side Menu
              if (_menuOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleMenu,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),

              slideInFromLeft(
                SlideTransition(
                  position: _menuOffset,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 300,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: SyraColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(4, 0),
                          ),
                        ],
                      ),
                      child: SideMenu(
                        isPremium: _isPremium,
                        messageCount: _messageCount,
                        dailyLimit: _dailyLimit,
                        onClose: _toggleMenu,
                        onNewChat: () {
                          _toggleMenu();
                          setState(() {
                            _messages.clear();
                            _currentSessionId = null;
                          });
                          _createInitialSession();
                        },
                        onChatHistory: () {
                          _toggleMenu();
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => animateSheet(
                              ChatSessionsSheet(
                                sessions: _chatSessions,
                                currentSessionId: _currentSessionId,
                                onSessionSelected: (sessionId) {
                                  Navigator.pop(context);
                                  _loadSelectedChat(sessionId);
                                },
                              ),
                            ),
                          );
                        },
                        onSettings: () {
                          _toggleMenu();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                        onPremium: () {
                          _toggleMenu();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PremiumScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildCustomInput() {
    // Return null to use default input, or customize if needed
    // For now, we'll use the default flutter_chat_ui input
    return null;
  }
}
