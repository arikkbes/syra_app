import 'dart:ui';
import 'dart:io';
import 'dart:math'; // max fonksiyonu için
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/chat_service.dart';
import '../services/firestore_user.dart';
import '../services/chat_session_service.dart';
import '../services/image_upload_service.dart';
import '../services/relationship_analysis_service.dart';
import '../services/relationship_memory_service.dart';
import '../models/chat_session.dart';
import '../models/relationship_analysis_result.dart';
import '../models/relationship_memory.dart';
import '../theme/syra_theme.dart';
import '../theme/design_system.dart';
import '../widgets/glass_background.dart';
import '../widgets/blur_toast.dart';
import '../widgets/mode_switch_sheet.dart';
import '../widgets/syra_bottom_panel.dart';
import 'premium_screen.dart';
import 'settings/settings_screen.dart';
import 'side_menu.dart';
import 'relationship_analysis_screen.dart';
import 'relationship_analysis_result_screen.dart';
import 'chat_sessions_sheet.dart';
import 'tactical_moves_screen.dart';
import 'premium_management_screen.dart';
import 'tarot_mode_screen.dart';
// New extracted widgets
import 'chat/chat_app_bar.dart';
import 'chat/chat_message_list.dart';
import 'chat/chat_input_bar.dart';

const bool forcePremiumForTesting = false;

// ═══════════════════════════════════════════════════════════════
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
  final FocusNode _inputFocusNode = FocusNode();

  bool _isPremium = false;
  int _dailyLimit = 10;
  int _messageCount = 0;

  bool _isLoading = false;
  bool _isTyping = false;
  bool _isSending = false; // Anti-spam flag
  bool _userScrolledUp = false; // Track if user manually scrolled

  Map<String, dynamic>? _replyingTo;

  bool _menuOpen = false;
  late AnimationController _menuController;
  late Animation<Offset> _menuOffset;

  double _swipeOffset = 0.0;
  String? _swipedMessageId;

  // Limit warning (show only once per session)
  bool _hasShownLimitWarning = false;

  List<ChatSession> _chatSessions = [];
  String? _currentSessionId; // CRITICAL FIX - Bu eksikti!

  bool _isTarotMode = false;

  String _selectedMode = "standard";

  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Pending image (resim seçilmiş ama henüz gönderilmemiş)
  File? _pendingImage;
  String? _pendingImageUrl; // Upload edilmiş URL (gönderilmeyi bekliyor)

  // Relationship upload
  bool _isUploadingRelationshipFile = false;

  // LayerLink for anchored mode selector popover
  // This anchors the mode selector popover to the mode label in the app bar
  final LayerLink _modeAnchorLink = LayerLink();

  @override
  void initState() {
    super.initState();

    _initUser();
    _loadChatSessions();
    _createInitialSession(); // İlk oturumu oluştur

    // Speech-to-text başlat
    _speech = stt.SpeechToText();

    // Scroll listener - Kullanıcı manuel scroll yapıyor mu?
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        // Eğer kullanıcı en altta değilse, manuel scroll yapmış demektir
        if (maxScroll - currentScroll > 100) {
          if (!_userScrolledUp) {
            setState(() => _userScrolledUp = true);
          }
        } else {
          if (_userScrolledUp) {
            setState(() => _userScrolledUp = false);
          }
        }
      }
    });

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

  /// Load all chat sessions from Firestore
  Future<void> _loadChatSessions() async {
    final result = await ChatSessionService.getUserSessions();
    if (!mounted) return;

    if (result.success && result.sessions != null) {
      setState(() {
        _chatSessions = result.sessions!;
      });
    } else {
      debugPrint("❌ Failed to load sessions: ${result.debugMessage}");
      // Optionally show error to user
      if (result.errorMessage != null && mounted) {
        BlurToast.show(context, result.errorMessage!);
      }
    }
  }

  /// Load selected chat messages
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

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      debugPrint("❌ Failed to load messages: ${result.debugMessage}");
      if (result.errorMessage != null && mounted) {
        BlurToast.show(context, result.errorMessage!);
      }
    }
  }

  Future<void> _createInitialSession() async {
    if (_currentSessionId == null) {
      final result = await ChatSessionService.createSession(
        title: 'Yeni Sohbet',
      );
      if (result.success && result.sessionId != null && mounted) {
        setState(() {
          _currentSessionId = result.sessionId;
        });
        await _loadChatSessions();
      } else {
        debugPrint(
            "❌ Failed to create initial session: ${result.debugMessage}");
      }
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
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
    // Sadece kullanıcı manuel scroll yapmamışsa otomatik scroll yap
    if (!_userScrolledUp && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showMessageMenu(BuildContext ctx, Map<String, dynamic> msg) async {
    HapticFeedback.selectionClick();

    final isImageMessage = msg["imageUrl"] != null;

    final actions = <SyraContextAction>[
      SyraContextAction(
        icon: Icons.reply_rounded,
        label: 'Yanıtla',
        onTap: () {
          setState(() => _replyingTo = msg);
        },
      ),
    ];

    // Sadece text mesajlar için kopyala
    if (!isImageMessage) {
      actions.add(
        SyraContextAction(
          icon: Icons.copy_rounded,
          label: 'Kopyala',
          onTap: () {
            final text = msg["text"];
            if (text != null) {
              Clipboard.setData(ClipboardData(text: text));
              BlurToast.show(ctx, "Metin kopyalandı");
            }
          },
        ),
      );
    }

    actions.addAll([
      SyraContextAction(
        icon: Icons.share_rounded,
        label: 'Paylaş',
        onTap: () {
          // TODO: Implement share functionality
        },
      ),
      SyraContextAction(
        icon: Icons.delete_rounded,
        label: 'Sil',
        isDestructive: true,
        onTap: () {
          setState(() => _messages.remove(msg));
        },
      ),
    ]);

    await showSyraContextMenu(
      context: ctx,
      actions: actions,
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
  Future<void> _startNewChat() async {
    final result = await ChatSessionService.createSession(
      title: 'Yeni Sohbet',
    );

    if (result.success && result.sessionId != null && mounted) {
      setState(() {
        _currentSessionId = result.sessionId;
        _messages.clear();
        _replyingTo = null;
        _isTarotMode = false;
      });
      await _loadChatSessions();
    } else {
      debugPrint("❌ Failed to create new chat: ${result.debugMessage}");
      if (result.errorMessage != null && mounted) {
        BlurToast.show(context, result.errorMessage!);
      }
    }
  }

  /// Start tarot mode - Navigate to dedicated tarot screen
  void _startTarotMode() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const TarotModeScreen(),
      ),
    );
  }

  /// Handle document upload - Relationship Upload (Beta)
  /// Shows either empty state (upload) or filled state (panel with controls)
  void _handleDocumentUpload() async {
    // Close keyboard before starting relationship upload
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Load relationship memory to determine which state to show
    final memory = await RelationshipMemoryService.getMemory();

    if (!mounted) return;

    if (memory == null) {
      // EMPTY STATE: Show upload dialog
      _showUploadDialog();
    } else {
      // FILLED STATE: Show relationship panel
      _showRelationshipPanel(memory);
    }
  }

  /// Show empty state upload dialog
  void _showUploadDialog() {
    SyraBottomPanel.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraTokens.accent.withValues(alpha: 0.2),
                      SyraTokens.accent.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: SyraTokens.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Relationship Upload (Beta)',
                      style: TextStyle(
                        color: SyraTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'WhatsApp sohbetini dışa aktar, buraya yükle.\nSYRA ilişki dinamiğini senin yerine analiz etsin.',
            style: TextStyle(
              color: SyraTokens.textSecondary.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _pickAndUploadRelationshipFile();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SyraTokens.accent, SyraTokens.accent],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: SyraTokens.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'WhatsApp Chat Yükle (.txt / .zip)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show filled state relationship panel
  void _showRelationshipPanel(RelationshipMemory memory) {
    SyraBottomPanel.show(
      context: context,
      padding: EdgeInsets.zero,
      child: _RelationshipPanelSheet(
        memory: memory,
        onUpdate: () {
          Navigator.pop(context);
          _handleDocumentUpload();
        },
        onUpload: () {
          Navigator.pop(context);
          _pickAndUploadRelationshipFile();
        },
        onViewAnalysis: () {
          Navigator.pop(context);
          _openAnalysisFromMemory(memory);
        },
      ),
    );
  }

  /// Open analysis screen with stored memory data
  void _openAnalysisFromMemory(RelationshipMemory memory) {
    // Convert memory to analysis result format
    final analysisResult = RelationshipAnalysisResult(
      totalMessages: memory.totalMessages ?? 0,
      startDate: memory.startDate != null
          ? DateTime.tryParse(memory.startDate!)
          : null,
      endDate:
          memory.endDate != null ? DateTime.tryParse(memory.endDate!) : null,
      shortSummary: memory.shortSummary ?? '',
      energyTimeline: (memory.energyTimeline ?? [])
          .map((e) => EnergyPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      keyMoments: (memory.keyMoments ?? [])
          .map((e) => KeyMoment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => RelationshipAnalysisResultScreen(
          analysisResult: analysisResult,
        ),
      ),
    );
  }

  /// Pick and upload relationship file
  Future<void> _pickAndUploadRelationshipFile() async {
    // Close keyboard before file picker (additional safeguard)
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'zip'],
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled
        return;
      }

      final file = File(result.files.single.path!);

      if (!mounted) return;

      // Show loading state
      setState(() {
        _isUploadingRelationshipFile = true;
      });

      // Upload and analyze
      final analysisResult =
          await RelationshipAnalysisService.analyzeChat(file);

      if (!mounted) return;

      setState(() {
        _isUploadingRelationshipFile = false;
      });

      // Show confirmation
      BlurToast.show(context, "✅ Sohbetin alındı, analiz hazır!");

      // Navigate to analysis screen
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => RelationshipAnalysisResultScreen(
            analysisResult: analysisResult,
          ),
        ),
      );
    } catch (e) {
      debugPrint('_pickAndUploadRelationshipFile error: $e');

      if (!mounted) return;

      setState(() {
        _isUploadingRelationshipFile = false;
      });

      BlurToast.show(
        context,
        "❌ Analiz sırasında bir hata oluştu: ${e.toString()}",
      );
    }
  }

  /// Handle attachment menu - resim gönderme özelliği
  void _handleAttachment() {
    SyraBottomPanel.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image, color: SyraTokens.textPrimary),
            title: const Text(
              'Fotoğraf Seç',
              style: TextStyle(color: SyraTokens.textPrimary),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _pickImageForPreview(ImageSource.gallery);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.camera_alt, color: SyraTokens.textPrimary),
            title: const Text(
              'Kamera',
              style: TextStyle(color: SyraTokens.textPrimary),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _pickImageForPreview(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  /// Resim seç ve preview göster (henüz gönderme)
  Future<void> _pickImageForPreview(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      // Önce dosyayı state'e kaydet (preview için)
      setState(() {
        _pendingImage = File(pickedFile.path);
        _pendingImageUrl = null; // Henüz upload edilmedi
      });

      // Arka planda Firebase'e upload et
      _uploadPendingImage();
    } catch (e) {
      debugPrint("_pickImageForPreview error: $e");
      if (mounted) {
        BlurToast.show(context, "Resim seçilirken hata oluştu.");
      }
    }
  }

  /// Pending image'ı Firebase Storage'a yükle
  Future<void> _uploadPendingImage() async {
    if (_pendingImage == null) return;

    try {
      final imageUrl = await ImageUploadService.uploadImage(_pendingImage!);

      if (imageUrl != null && mounted) {
        setState(() {
          _pendingImageUrl = imageUrl;
        });
        debugPrint("Pending image uploaded: $imageUrl");
      }
    } catch (e) {
      debugPrint("_uploadPendingImage error: $e");
      if (mounted) {
        BlurToast.show(context, "Resim yüklenirken hata oluştu.");
        setState(() {
          _pendingImage = null;
          _pendingImageUrl = null;
        });
      }
    }
  }

  /// Pending image'ı temizle
  void _clearPendingImage() {
    setState(() {
      _pendingImage = null;
      _pendingImageUrl = null;
    });
  }

  /// Handle voice input - ses ile mesaj gönderme
  Future<void> _handleVoiceInput() async {
    if (_isListening) {
      // Dinleme aktifse durdur
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    // Speech-to-text izni al ve başlat
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        setState(() => _isListening = false);
        if (mounted) {
          BlurToast.show(context, "🎤 Ses tanıma hatası: ${error.errorMsg}");
        }
      },
    );

    if (!available) {
      if (mounted) {
        BlurToast.show(context, "🎤 Ses tanıma özelliği kullanılamıyor");
      }
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
      },
      localeId: 'tr_TR', // Türkçe dil desteği
      listenMode: stt.ListenMode.confirmation,
    );
  }

  /// Handle mode selection - mod değiştirme overlay
  /// Uses anchored popover positioned below the mode label in app bar
  void _handleModeSelection() {
    showSyraPopover<String>(
      context: context,
      // Use anchored positioning instead of alignment
      anchorLink: _modeAnchorLink,
      anchorOffset: 8.0, // 8px below the mode label
      title: 'KONUŞMA MODU',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeItem(
            mode: 'standard',
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Normal',
            description: 'Dengeli, her konuda akıcı sohbet',
          ),
          const SyraPopoverDivider(),
          _buildModeItem(
            mode: 'deep',
            icon: Icons.psychology_rounded,
            label: 'Derin Analiz',
            description: 'Detaylı psikolojik analiz ve içgörü',
          ),
          const SyraPopoverDivider(),
          _buildModeItem(
            mode: 'mentor',
            icon: Icons.psychology_alt_rounded,
            label: 'Dost Acı Söyler',
            description: 'Direkt, açık ve samimi geri bildirim',
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem({
    required String mode,
    required IconData icon,
    required String label,
    required String description,
  }) {
    return SyraPopoverItem(
      icon: icon,
      label: label,
      description: description,
      isSelected: _selectedMode == mode,
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    // Boş mesaj kontrolü
    if (text.isEmpty) return;

    // Anti-spam: Eğer zaten mesaj gönderiliyorsa, çık
    if (_isSending) return;

    // ═══════════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      BlurToast.show(context, "Tekrar giriş yapman gerekiyor kanka.");
      return;
    }
    final uid = user.uid;

    // ═══════════════════════════════════════════════════════════════
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

    // Pending image'ı backup'la ve temizle
    final String? imageUrlToSend = _pendingImageUrl;

    final userMessage = {
      "id": msgId,
      "sender": "user",
      "text": text, // Text'i her zaman kaydet (boş bile olsa)
      "replyTo": replyBackup,
      "time": now,
      "timestamp": now,
      "imageUrl": imageUrlToSend, // Resim varsa ekle
      "type": imageUrlToSend != null ? "image" : null,
    };

    setState(() {
      _messages.add(userMessage);

      _controller.clear();
      _replyingTo = null;
      _isTyping = true;
      _isLoading = true;
      _isSending = true; // Gönderme başladı
      _messageCount++;

      // Pending image'ı temizle
      _pendingImage = null;
      _pendingImageUrl = null;
    });

    // Scroll to bottom after user message
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

    // 1 saniye sonra buton tekrar aktif olacak (anti-spam timeout)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isSending = false);
      }
    });

    // ═══════════════════════════════════════════════════════════════
    // CREATE OR UPDATE SESSION
    // ═══════════════════════════════════════════════════════════════
    if (_currentSessionId == null) {
      final result = await ChatSessionService.createSession(
        title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
      );
      if (result.success && result.sessionId != null) {
        setState(() {
          _currentSessionId = result.sessionId;
        });
      } else {
        debugPrint("❌ Failed to create session: ${result.debugMessage}");
      }
    } else {
      // Eğer session zaten varsa ama messageCount = 1 ise (ilk mesaj)
      // başlığı güncelle
      final userMessageCount =
          _messages.where((m) => m['sender'] == 'user').length;
      if (userMessageCount == 1) {
        await ChatSessionService.updateSession(
          sessionId: _currentSessionId!,
          title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
        );
      }
    }

    // Save user message to session
    if (_currentSessionId != null) {
      final saveResult = await ChatSessionService.addMessageToSession(
        sessionId: _currentSessionId!,
        message: userMessage,
      );

      if (saveResult.success) {
        await ChatSessionService.updateSession(
          sessionId: _currentSessionId!,
          lastMessage: text,
          messageCount: _messages.where((m) => m['sender'] == 'user').length,
        );
      } else {
        debugPrint("❌ Failed to save user message: ${saveResult.debugMessage}");
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // ═══════════════════════════════════════════════════════════════
    if (!forcePremiumForTesting) {
      try {
        await ChatService.incrementMessageCount();
      } catch (e) {
        debugPrint("incrementMessageCount ERROR: $e");
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // SEND MESSAGE TO AI - With new ChatSendResult
    // ═══════════════════════════════════════════════════════════════
    final result = await ChatService.sendMessage(
      userMessage: text.isEmpty ? "Bu resimle ilgili ne düşünüyorsun?" : text,
      conversationHistory: _messages,
      replyingTo: _replyingTo,
      mode: _selectedMode,
      imageUrl: imageUrlToSend,
    );

    // Handle result
    if (result.success && result.responseText != null) {
      // Success - add bot message
      final botText = result.responseText!;
      final flags = ChatService.detectManipulation(botText);

      final botMessage = {
        "id": UniqueKey().toString(),
        "sender": "bot",
        "text": botText,
        "replyTo": null,
        "time": DateTime.now(),
        "timestamp": DateTime.now(),
        "hasRed": flags['hasRed'] ?? false,
        "hasGreen": flags['hasGreen'] ?? false,
      };

      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
        _isLoading = false;
        _isSending = false;
      });

      // Save bot message to session
      if (_currentSessionId != null) {
        final saveResult = await ChatSessionService.addMessageToSession(
          sessionId: _currentSessionId!,
          message: botMessage,
        );

        if (saveResult.success) {
          await ChatSessionService.updateSession(
            sessionId: _currentSessionId!,
            lastMessage: botText.length > 50
                ? "${botText.substring(0, 50)}..."
                : botText,
          );
          await _loadChatSessions();
        } else {
          debugPrint(
              "❌ Failed to save bot message: ${saveResult.debugMessage}");
        }
      }

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } else {
      // Error - show user-friendly message
      setState(() {
        _isTyping = false;
        _isLoading = false;
        _isSending = false;
      });

      if (mounted) {
        final errorMessage = result.userMessage ?? "Bağlantı kurulamadı kanka";
        BlurToast.show(context, errorMessage);
      }

      debugPrint("❌ Chat send error: ${result.debugMessage}");
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
                color: SyraTokens.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SyraTokens.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SyraTokens.accent.withOpacity(0.2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: SyraTokens.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Günlük Limit Doldu",
                    style: TextStyle(
                      color: SyraTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Bugünlük mesaj hakkın bitti kanka.\n"
                    "Premium ile sınırsız devam edebilirsin!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SyraTokens.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: SyraTokens.glassBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: SyraTokens.border),
                            ),
                            child: const Center(
                              child: Text(
                                "Tamam",
                                style: TextStyle(
                                  color: SyraTokens.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _navigateToPremium();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: SyraTokens.accent,
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
    SyraBottomPanel.show(
      context: context,
      child: const ChatSessionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: SyraTokens.background,
          body: Stack(
            children: [
              const SyraBackground(),

              // ═══════════════════════════════════════════════════════════════
              // MAIN CHAT CONTENT - Centered with max width + sliding animation
              // ═══════════════════════════════════════════════════════════════
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
                          ChatAppBar(
                            selectedMode: _selectedMode,
                            modeAnchorLink: _modeAnchorLink,
                            onMenuTap: _toggleMenu,
                            onModeTap: _handleModeSelection,
                            onDocumentUpload: _handleDocumentUpload,
                          ),
                          Expanded(
                            child: ChatMessageList(
                              isEmpty: _messages.isEmpty,
                              isTarotMode: _isTarotMode,
                              onSuggestionTap: (text) {
                                setState(() {
                                  _controller.text = text;
                                });
                                _inputFocusNode.requestFocus();
                                _controller.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: _controller.text.length),
                                );
                              },
                              messages: _messages,
                              scrollController: _scrollController,
                              isTyping: _isTyping,
                              swipedMessageId: _swipedMessageId,
                              swipeOffset: _swipeOffset,
                              onMessageLongPress: (msg) =>
                                  _showMessageMenu(context, msg),
                              onSwipeUpdate: (msg, delta) {
                                setState(() {
                                  _swipedMessageId = msg["id"];
                                  _swipeOffset =
                                      (_swipeOffset + delta).clamp(0, 30);
                                });
                              },
                              onSwipeEnd: (msg, shouldReply) {
                                if (shouldReply) {
                                  setState(() => _replyingTo = msg);
                                }
                                setState(() {
                                  _swipeOffset = 0;
                                  _swipedMessageId = null;
                                });
                              },
                            ),
                          ),
                          ChatInputBar(
                            controller: _controller,
                            focusNode: _inputFocusNode,
                            isSending: _isSending,
                            isLoading: _isLoading,
                            isListening: _isListening,
                            replyingTo: _replyingTo,
                            pendingImage: _pendingImage,
                            pendingImageUrl: _pendingImageUrl,
                            onAttachmentTap: _handleAttachment,
                            onVoiceInputTap: _handleVoiceInput,
                            onSendMessage: _sendMessage,
                            onCancelReply: () =>
                                setState(() => _replyingTo = null),
                            onClearImage: _clearPendingImage,
                            onTextChanged: () => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════════════════════
              // DARK OVERLAY - Tap to close menu
              // ═══════════════════════════════════════════════════════════════
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
              SideMenu(
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
                onSelectChat: (chat) async {
                  _toggleMenu();
                  await _loadSelectedChat(chat.id);
                },
                onDeleteChat: (chat) async {
                  final result =
                      await ChatSessionService.deleteSession(chat.id);
                  if (result.success) {
                    await _loadChatSessions();
                    if (mounted) {
                      BlurToast.show(context, "Chat silindi");
                    }
                  } else {
                    debugPrint("❌ Delete chat error: ${result.debugMessage}");
                    if (result.errorMessage != null && mounted) {
                      BlurToast.show(context, result.errorMessage!);
                    }
                  }
                },
                onRenameChat: (chat, newTitle) async {
                  final result = await ChatSessionService.renameSession(
                    sessionId: chat.id,
                    newTitle: newTitle,
                  );
                  if (result.success) {
                    await _loadChatSessions();
                    if (mounted) {
                      BlurToast.show(context, "Chat adı güncellendi");
                    }
                  } else {
                    debugPrint("❌ Rename chat error: ${result.debugMessage}");
                    if (result.errorMessage != null && mounted) {
                      BlurToast.show(context, result.errorMessage!);
                    }
                  }
                },
                onOpenSettings: () {
                  _toggleMenu();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                onClose: _toggleMenu,
              ),

              // Loading overlay for relationship upload
              if (_isUploadingRelationshipFile)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: SyraTokens.accent,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Sohbet analiz ediliyor...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bu işlem 10-30 saniye sürebilir',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// ChatGPT-style App Bar
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SyraTokens.background,
        border: Border(
          bottom: BorderSide(
            color: SyraTokens.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _TapScale(
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
                color: SyraTokens.textSecondary,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _buildModeTrigger(),
            ),
          ),
          _TapScale(
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
                color: SyraTokens.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mode selector trigger in the top bar
  /// Wrapped with CompositedTransformTarget to anchor the mode popover
  Widget _buildModeTrigger() {
    String modeLabel;
    switch (_selectedMode) {
      case 'deep':
        modeLabel = 'Derin';
        break;
      case 'mentor':
        modeLabel = 'Mentor';
        break;
      default:
        modeLabel = 'Normal';
    }

    // Wrap with CompositedTransformTarget to anchor the popover
    return CompositedTransformTarget(
      link: _modeAnchorLink,
      child: GestureDetector(
        onTap: _handleModeSelection,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SyraTokens.paddingSm,
            vertical: SyraTokens.paddingXs - 2,
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(SyraTokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SYRA',
                style: SyraTokens.titleSm.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: SyraTokens.textSecondary.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                modeLabel,
                style: SyraTokens.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: SyraTokens.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: SyraTokens.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state with centered logo
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo - Daha belirgin ve premium
            Image.asset(
              'assets/icon/syra.png',
              width: 120,
              height: 120,
              color: SyraTokens.accent.withOpacity(0.3),
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        SyraTokens.accent.withOpacity(0.2),
                        SyraTokens.accent.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SyraTokens.accent.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _isTarotMode ? "🔮" : "S",
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        color: SyraTokens.accent.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Hero Title
            Text(
              _isTarotMode ? "Kartlar hazır..." : "Bugün neyi çözüyoruz?",
              style: TextStyle(
                color:
                    _isTarotMode ? SyraTokens.accent : SyraTokens.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              _isTarotMode
                  ? "İstersen önce birkaç cümleyle durumu anlat."
                  : "Mesajını, ilişkinizi ya da aklındaki soruyu anlat.",
              style: const TextStyle(
                color: SyraTokens.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Suggestion Chips
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: _buildSuggestionChips(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSuggestionChips() {
    final List<String> suggestions = _isTarotMode
        ? [
            "Son konuşmamı kartlarla yorumla",
            "İlişkim için genel tarot açılımı yap",
            "Bugün için kart çek",
          ]
        : [
            "İlişki mesajımı analiz et",
            "İlk mesaj taktiği ver",
            "Konuşmamın enerjisini değerlendir",
          ];

    return suggestions.map((text) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _controller.text = text;
          });
          _inputFocusNode.requestFocus();
          // Cursor'u sonuna götür
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: SyraTokens.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SyraTokens.divider.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: SyraTokens.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }).toList();
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

        return _AnimatedMessageItem(
          animationKey: ValueKey(msg["id"] ?? index),
          child: GestureDetector(
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
                text: msg["text"],
                isUser: isUser,
                time: msg["time"] is DateTime ? msg["time"] : null,
                replyToText: msg["replyTo"],
                hasRedFlag: !isUser && (msg['hasRed'] == true),
                hasGreenFlag: !isUser && (msg['hasGreen'] == true),
                onLongPress: () => _showMessageMenu(context, msg),
                imageUrl: msg["imageUrl"], // Yeni: resim URL'i
              ),
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
              color: SyraTokens.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SYRA düşünüyor",
                  style: TextStyle(
                    color: SyraTokens.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
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
            color: SyraTokens.textMuted.withOpacity(value),
          ),
        );
      },
    );
  }

  /// ChatGPT-style input bar
  Widget _buildInputBar() {
    // Text field içeriğini dinle
    final bool hasText = _controller.text.trim().isNotEmpty;
    final bool isUploadingImage =
        _pendingImage != null && _pendingImageUrl == null; // Resim yükleniyor
    final bool hasPendingImage =
        _pendingImage != null && _pendingImageUrl != null; // Resim hazır
    final bool canSend = (hasText || hasPendingImage) &&
        !_isSending &&
        !_isLoading &&
        !isUploadingImage;

    // Focus/active state
    final bool isFocused = _inputFocusNode.hasFocus;
    final bool isActive = isFocused || hasText || hasPendingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        max(
            8.0,
            MediaQuery.of(context).padding.bottom -
                20), // Safe area'dan 8 çıkar, min 8
      ),
      decoration: BoxDecoration(
        color: SyraTokens.background,
        border: Border(
          top: BorderSide(
            color: SyraTokens.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null) _buildReplyPreview(),
          if (_pendingImage != null)
            _buildImagePreview(), // Yeni: resim preview
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isActive ? SyraTokens.surfaceLight : SyraTokens.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive
                    ? SyraTokens.accent.withOpacity(0.8)
                    : SyraTokens.border,
                width: isActive ? 1.2 : 0.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TapScale(
                  onTap: _handleAttachment,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(left: 4, bottom: 4),
                    child: const Icon(
                      Icons.add_rounded,
                      color: SyraTokens.textMuted,
                      size: 24,
                    ),
                  ),
                ),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _inputFocusNode,
                    enabled: !_isSending,
                    maxLines: 5,
                    minLines: 1,
                    onChanged: (_) =>
                        setState(() {}), // TextField değiştiğinde rebuild
                    style: const TextStyle(
                      color: SyraTokens.textPrimary,
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
                        color: SyraTokens.textHint,
                        fontSize: 15,
                      ),
                    ),
                    onSubmitted: (_) => canSend ? _sendMessage() : null,
                  ),
                ),

                _TapScale(
                  onTap: _handleVoiceInput,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        key: ValueKey(_isListening),
                        color: _isListening
                            ? SyraTokens.accent
                            : SyraTokens.textMuted,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Send button with smooth animation
                _TapScale(
                  onTap: canSend ? _sendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: canSend
                          ? SyraTokens.textPrimary
                          : SyraTokens.textMuted.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                SyraTokens.background,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: canSend
                                ? SyraTokens.background
                                : SyraTokens.background.withOpacity(0.5),
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
        color: SyraTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraTokens.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: SyraTokens.accent,
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
                    color: SyraTokens.accent,
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
                    color: SyraTokens.textMuted,
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
                color: SyraTokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pending image preview (ChatGPT/Claude style)
  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SyraTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraTokens.border,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Resim thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _pendingImage!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // Upload durumu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Fotoğraf",
                  style: TextStyle(
                    color: SyraTokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (_pendingImageUrl == null)
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SyraTokens.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Yükleniyor...",
                        style: TextStyle(
                          color: SyraTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Hazır",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Kapat butonu
          GestureDetector(
            onTap: _clearPendingImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SyraTokens.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: SyraTokens.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// RELATIONSHIP PANEL SHEET (Filled State)
// ═══════════════════════════════════════════════════════════════
class _RelationshipPanelSheet extends StatefulWidget {
  final RelationshipMemory memory;
  final VoidCallback onUpdate;
  final VoidCallback onUpload;
  final VoidCallback onViewAnalysis;

  const _RelationshipPanelSheet({
    required this.memory,
    required this.onUpdate,
    required this.onUpload,
    required this.onViewAnalysis,
  });

  @override
  State<_RelationshipPanelSheet> createState() =>
      _RelationshipPanelSheetState();
}

class _RelationshipPanelSheetState extends State<_RelationshipPanelSheet> {
  bool _isActive = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isActive = widget.memory.isActive;
  }

  Future<void> _handleToggle(bool value) async {
    setState(() {
      _isUpdating = true;
    });

    final success = await RelationshipMemoryService.updateIsActive(value);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isActive = value;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'İlişki chat\'te kullanılacak'
                : 'İlişki chat\'te kullanılmayacak',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir hata oluştu, lütfen tekrar deneyin'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SyraTokens.surface,
        title: const Text(
          'Bu ilişkiyi silmek istiyor musun?',
          style: TextStyle(color: SyraTokens.textPrimary),
        ),
        content: const Text(
          'İlişkiye ait özet ve istatistikler silinecek. SYRA bu ilişkiyi chat\'te artık referans almayacak.',
          style: TextStyle(color: SyraTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    final success = await RelationshipMemoryService.deleteMemory();

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlişki bilgileri silindi'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silme işlemi başarısız oldu'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mem = widget.memory;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SyraTokens.accent.withValues(alpha: 0.2),
                      SyraTokens.accent.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: SyraTokens.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kayıtlı İlişki',
                  style: TextStyle(
                    color: SyraTokens.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            mem.shortSummary ?? 'Özet mevcut değil',
            style: TextStyle(
              color: SyraTokens.textSecondary.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (mem.startDate != null && mem.endDate != null)
            Text(
              '${_formatDate(mem.startDate!)} — ${_formatDate(mem.endDate!)}',
              style: TextStyle(
                color: SyraTokens.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 20),
          const Divider(color: SyraTokens.border, height: 1),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: SyraTokens.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: SyraTokens.border.withValues(alpha: 0.3)),
            ),
            child: SwitchListTile(
              title: const Text(
                'Chat\'te kullan',
                style: TextStyle(
                  color: SyraTokens.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _isActive
                    ? 'SYRA bu ilişkiyi sohbetlerde arka plan bilgisi olarak kullanır'
                    : 'Veri saklanır ama chat\'te referans alınmaz',
                style: TextStyle(
                  color: SyraTokens.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              value: _isActive,
              onChanged: _isUpdating ? null : _handleToggle,
              activeColor: SyraTokens.accent,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onViewAnalysis,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [SyraTokens.accent, SyraTokens.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Detaylı Analiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onUpload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: SyraTokens.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SyraTokens.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh,
                            color: SyraTokens.textSecondary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Sohbeti Güncelle',
                          style: TextStyle(
                            color: SyraTokens.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _isUpdating ? null : _handleDelete,
              child: Text(
                'Bu ilişkiyi unut',
                style: TextStyle(
                  color: Colors.red.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Tap Scale Widget - Micro-interaction for tap feedback
// ═══════════════════════════════════════════════════════════════
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() {
      _scale = pressed ? 0.94 : 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) {
        _setPressed(false);
        if (widget.onTap != null) {
          HapticFeedback.selectionClick();
          widget.onTap!();
        }
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Animated Message Item - Entrance animation for messages
// ═══════════════════════════════════════════════════════════════
class _AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  final Key? animationKey;

  const _AnimatedMessageItem({
    required this.child,
    this.animationKey,
  });

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// SYRA MESSAGE BUBBLE - Chat Message Widget
/// ═══════════════════════════════════════════════════════════════

class SyraMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime? time;
  final String? replyToText;
  final bool hasRedFlag;
  final bool hasGreenFlag;
  final VoidCallback? onLongPress;
  final String? imageUrl;

  const SyraMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.time,
    this.replyToText,
    this.hasRedFlag = false,
    this.hasGreenFlag = false,
    this.onLongPress,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          left: isUser ? 60 : 16,
          right: isUser ? 16 : 60,
          bottom: 8,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isUser ? SyraTokens.accent.withOpacity(0.15) : SyraTokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? SyraTokens.accent.withOpacity(0.3)
                : SyraTokens.border.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply indicator
            if (replyToText != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '↩ $replyToText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SyraTokens.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Image if present
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: SyraTokens.surface,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: SyraTokens.textMuted),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Message text
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isUser ? SyraTokens.textPrimary : SyraTokens.textPrimary,
                height: 1.4,
              ),
            ),

            // Flags and time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flags
                Row(
                  children: [
                    if (hasRedFlag)
                      Container(
                        margin: const EdgeInsets.only(right: 4, top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SyraTokens.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🚩 Dikkat',
                          style: TextStyle(
                            fontSize: 11,
                            color: SyraTokens.error,
                          ),
                        ),
                      ),
                    if (hasGreenFlag)
                      Container(
                        margin: const EdgeInsets.only(right: 4, top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SyraTokens.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✓ İyi',
                          style: TextStyle(
                            fontSize: 11,
                            color: SyraTokens.success,
                          ),
                        ),
                      ),
                  ],
                ),

                // Time
                if (time != null)
                  Text(
                    _formatTime(time!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: SyraTokens.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
