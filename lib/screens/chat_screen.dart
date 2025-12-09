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
import '../widgets/glass_background.dart';
import '../widgets/blur_toast.dart';
import '../widgets/syra_message_bubble.dart';
import '../widgets/mode_switch_sheet.dart';
import '../widgets/syra_bottom_panel.dart';
import 'premium_screen.dart';
import 'settings/settings_screen.dart';
import 'side_menu_new.dart';
import 'relationship_analysis_screen.dart';
import 'relationship_analysis_result_screen.dart';
import 'chat_sessions_sheet.dart';
import 'tactical_moves_screen.dart';
import 'premium_management_screen.dart';
import 'tarot_mode_screen.dart';

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
    try {
      final sessions = await ChatSessionService.getUserSessions();
      if (!mounted) return;
      setState(() {
        _chatSessions = sessions;
      });
    } catch (e) {
      debugPrint("_loadChatSessions error: $e");
    }
  }

  /// Load selected chat messages
  Future<void> _loadSelectedChat(String sessionId) async {
    try {
      final messages = await ChatSessionService.getSessionMessages(sessionId);
      if (!mounted) return;

      setState(() {
        _currentSessionId = sessionId;
        _messages.clear();
        _messages.addAll(messages);
        _isTarotMode = false;
      });

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      debugPrint("_loadSelectedChat error: $e");
      if (mounted) {
        BlurToast.show(context, "Chat yüklenirken hata oluştu");
      }
    }
  }

  Future<void> _createInitialSession() async {
    if (_currentSessionId == null) {
      final sessionId = await ChatSessionService.createSession(
        title: 'Yeni Sohbet',
      );
      if (sessionId != null && mounted) {
        setState(() {
          _currentSessionId = sessionId;
        });
        await _loadChatSessions();
      }
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
                    if (!isImageMessage) // Sadece text mesajlar için kopyala
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
  Future<void> _startNewChat() async {
    final sessionId = await ChatSessionService.createSession(
      title: 'Yeni Sohbet',
    );

    if (sessionId != null && mounted) {
      setState(() {
        _currentSessionId = sessionId;
        _messages.clear();
        _replyingTo = null;
        _isTarotMode = false;
      });
      await _loadChatSessions();
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
                      SyraColors.accent.withValues(alpha: 0.2),
                      SyraColors.accent.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: SyraColors.accent,
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
                        color: SyraColors.textPrimary,
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
              color: SyraColors.textSecondary.withValues(alpha: 0.9),
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
                  colors: [SyraColors.accent, SyraColors.accent],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: SyraColors.accent.withValues(alpha: 0.3),
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
      startDate: memory.startDate != null ? DateTime.tryParse(memory.startDate!) : null,
      endDate: memory.endDate != null ? DateTime.tryParse(memory.endDate!) : null,
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
      final analysisResult = await RelationshipAnalysisService.analyzeChat(file);

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
            leading: const Icon(Icons.image, color: SyraColors.textPrimary),
            title: const Text(
              'Fotoğraf Seç',
              style: TextStyle(color: SyraColors.textPrimary),
            ),
            onTap: () async {
              Navigator.pop(context);
              await _pickImageForPreview(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: SyraColors.textPrimary),
            title: const Text(
              'Kamera',
              style: TextStyle(color: SyraColors.textPrimary),
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
  void _handleModeSelection() {
    SyraBottomPanel.show(
      context: context,
      child: ModeSwitchSheet(
        selectedMode: _selectedMode,
        onModeSelected: (String mode) {
          setState(() {
            _selectedMode = mode;
          });
        },
      ),
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
    // ═══════════════════════════════════════════════════════════════
    if (_currentSessionId == null) {
      final sessionId = await ChatSessionService.createSession(
        title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
      );
      if (sessionId != null) {
        setState(() {
          _currentSessionId = sessionId;
        });
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

    if (_currentSessionId != null) {
      try {
        await ChatSessionService.addMessageToSession(
          sessionId: _currentSessionId!,
          message: userMessage,
        );

        await ChatSessionService.updateSession(
          sessionId: _currentSessionId!,
          lastMessage: text,
          messageCount: _messages.where((m) => m['sender'] == 'user').length,
        );
      } catch (e) {
        debugPrint("Error saving user message: $e");
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
    // ═══════════════════════════════════════════════════════════════
    try {
      final botText = await ChatService.sendMessage(
        userMessage: text.isEmpty ? "Bu resimle ilgili ne düşünüyorsun?" : text,
        conversationHistory: _messages,
        replyingTo: _replyingTo,
        mode: _selectedMode,
        imageUrl: imageUrlToSend, // Resim URL'ini backend'e gönder
      );

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
        _isSending = false; // Gönderim tamamlandı
      });

      // ═══════════════════════════════════════════════════════════════
      // ═══════════════════════════════════════════════════════════════
      if (_currentSessionId != null) {
        try {
          await ChatSessionService.addMessageToSession(
            sessionId: _currentSessionId!,
            message: botMessage,
          );

          await ChatSessionService.updateSession(
            sessionId: _currentSessionId!,
            lastMessage: botText.length > 50
                ? "${botText.substring(0, 50)}..."
                : botText,
          );

          await _loadChatSessions();
        } catch (e) {
          debugPrint("Error saving bot message: $e");
        }
      }

      // Bot mesajı geldiğinde de scroll yap (delay ile)
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      debugPrint("Network error: $e");
      setState(() {
        _isTyping = false;
        _isLoading = false;
        _isSending = false; // Hata durumunda da gönderimi serbest bırak
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
                  const Text(
                    "Günlük Limit Doldu",
                    style: TextStyle(
                      color: SyraColors.textPrimary,
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
                      color: SyraColors.textSecondary,
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
          backgroundColor: SyraColors.background,
          body: Stack(
            children: [
              const SyraBackground(),
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
                onSelectChat: (chat) async {
                  _toggleMenu();
                  await _loadSelectedChat(chat.id);
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
                onRenameChat: (chat, newTitle) async {
                  try {
                    await ChatSessionService.renameSession(
                      sessionId: chat.id,
                      newTitle: newTitle,
                    );
                    await _loadChatSessions();
                    if (mounted) {
                      BlurToast.show(context, "Chat adı güncellendi");
                    }
                  } catch (e) {
                    debugPrint("Rename chat error: $e");
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
                          color: SyraColors.accent,
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
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _handleModeSelection,
                child: SyraLogo(
                  fontSize: 18,
                  showModLabel: true,
                  selectedMode: _selectedMode,
                ),
              ),
            ),
          ),
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
          Image.asset(
            'assets/icon/syra.png',
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
                Text(
                  "SYRA düşünüyor",
                  style: TextStyle(
                    color: SyraColors.textMuted,
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
            color: SyraColors.textMuted.withOpacity(value),
          ),
        );
      },
    );
  }

  /// ChatGPT-style input bar
  Widget _buildInputBar() {
    // Text field içeriğini dinle
    final bool hasText = _controller.text.trim().isNotEmpty;
    final bool isUploadingImage = _pendingImage != null && _pendingImageUrl == null; // Resim yükleniyor
    final bool hasPendingImage = _pendingImage != null && _pendingImageUrl != null; // Resim hazır
    final bool canSend = (hasText || hasPendingImage) && !_isSending && !_isLoading && !isUploadingImage;

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
          if (_pendingImage != null) _buildImagePreview(), // Yeni: resim preview
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
                GestureDetector(
                  onTap: _handleAttachment,
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
                    enabled: !_isSending,
                    maxLines: 5,
                    minLines: 1,
                    onChanged: (_) =>
                        setState(() {}), // TextField değiştiğinde rebuild
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
                    onSubmitted: (_) => canSend ? _sendMessage() : null,
                  ),
                ),

                GestureDetector(
                  onTap: _handleVoiceInput,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        key: ValueKey(_isListening),
                        color: _isListening ? SyraColors.accent : SyraColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Send button with smooth animation
                GestureDetector(
                  onTap: canSend ? _sendMessage : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: canSend
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
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: canSend
                                ? SyraColors.background
                                : SyraColors.background.withOpacity(0.5),
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

  /// Pending image preview (ChatGPT/Claude style)
  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
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
                    color: SyraColors.textPrimary,
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
                          color: SyraColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Yükleniyor...",
                        style: TextStyle(
                          color: SyraColors.textMuted,
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
                color: SyraColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: SyraColors.textMuted,
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
  State<_RelationshipPanelSheet> createState() => _RelationshipPanelSheetState();
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
        backgroundColor: SyraColors.surface,
        title: const Text(
          'Bu ilişkiyi silmek istiyor musun?',
          style: TextStyle(color: SyraColors.textPrimary),
        ),
        content: const Text(
          'İlişkiye ait özet ve istatistikler silinecek. SYRA bu ilişkiyi chat\'te artık referans almayacak.',
          style: TextStyle(color: SyraColors.textSecondary),
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
                      SyraColors.accent.withValues(alpha: 0.2),
                      SyraColors.accent.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: SyraColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kayıtlı İlişki',
                  style: TextStyle(
                    color: SyraColors.textPrimary,
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
              color: SyraColors.textSecondary.withValues(alpha: 0.9),
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
                color: SyraColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 20),
          const Divider(color: SyraColors.border, height: 1),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: SyraColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SyraColors.border.withValues(alpha: 0.3)),
            ),
            child: SwitchListTile(
              title: const Text(
                'Chat\'te kullan',
                style: TextStyle(
                  color: SyraColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _isActive
                    ? 'SYRA bu ilişkiyi sohbetlerde arka plan bilgisi olarak kullanır'
                    : 'Veri saklanır ama chat\'te referans alınmaz',
                style: TextStyle(
                  color: SyraColors.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              value: _isActive,
              onChanged: _isUpdating ? null : _handleToggle,
              activeColor: SyraColors.accent,
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
                        colors: [SyraColors.accent, SyraColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
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
                      color: SyraColors.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SyraColors.border),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: SyraColors.textSecondary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Sohbeti Güncelle',
                          style: TextStyle(
                            color: SyraColors.textSecondary,
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
