import 'dart:ui';
import 'dart:io';
// max fonksiyonu için
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../services/chat_service.dart';
import '../services/chat_service_streaming.dart'; // ← STREAMING SUPPORT
import '../services/chat_session_service.dart';
import '../services/image_upload_service.dart';
import '../services/relationship_analysis_service.dart';
import '../services/relationship_memory_service.dart';

import '../models/chat_session.dart';
import '../models/relationship_analysis_result.dart';
import '../models/relationship_memory.dart';

import '../theme/design_system.dart';
import '../widgets/glass_background.dart';
import '../widgets/blur_toast.dart';
import '../widgets/syra_bottom_panel.dart';

import 'premium_screen.dart';
import 'settings/settings_screen.dart';
import 'relationship_analysis_result_screen.dart';
import 'chat_sessions_sheet.dart';
import 'premium_management_screen.dart';
import 'tarot_mode_screen.dart';

// ✅ Kim Daha Çok screen import (PATH’i sende farklıysa burayı düzelt)
import 'kim_daha_cok_screen.dart';

// New extracted widgets
import 'chat/chat_app_bar.dart';
import 'chat/chat_message_list.dart';
import 'chat/chat_input_bar.dart';
import '../widgets/minimal_mode_selector.dart';
import '../widgets/claude_sidebar.dart';

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
  int _scrollCallCount = 0; // Debounce scroll during streaming

  Map<String, dynamic>? _replyingTo;

  bool _sidebarOpen = false;

  double _swipeOffset = 0.0;
  String? _swipedMessageId;

  // Limit warning (show only once per session)
  bool _hasShownLimitWarning = false;

  List<ChatSession> _chatSessions = [];
  String? _currentSessionId; // CRITICAL FIX - Bu eksikti!

  bool _isTarotMode = false;

  String _selectedMode = "standard";
  bool _isModeSelectorOpen = false;

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

  // GlobalKey for RepaintBoundary (Liquid Glass background capture)
  final GlobalKey _chatBackgroundKey = GlobalKey();

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
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
  }

  void _scrollToBottom({bool smooth = true}) {
    // Sadece kullanıcı manuel scroll yapmamışsa otomatik scroll yap
    if (!_userScrolledUp && _scrollController.hasClients) {
      if (smooth) {
        // Debounce: Only scroll every 3rd call during streaming to reduce jank
        _scrollCallCount++;
        if (_scrollCallCount % 3 == 0) {
          // Use jumpTo for instant scroll without animation during streaming
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      } else {
        // Animated scroll for user actions (sending message)
        _scrollCallCount = 0; // Reset debounce counter
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
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

  Future<void> _renameSessionFromSidebar(ChatSession session) async {
    final controller = TextEditingController(text: session.title);

    final newTitle = await SyraBottomPanel.show<String>(
      context: context,
      maxHeight: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeniden Adlandır',
            style: TextStyle(
              color: SyraTokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sohbet ismini düzenle.',
            style: TextStyle(
              color: SyraTokens.textSecondary.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              color: SyraTokens.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Örn: İlk buluşma planı',
              hintStyle: TextStyle(
                color: SyraTokens.textMuted.withValues(alpha: 0.8),
              ),
              filled: true,
              fillColor: SyraTokens.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: SyraTokens.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: SyraTokens.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: SyraTokens.accent.withOpacity(0.6)),
              ),
            ),
            onSubmitted: (v) {
              final t = v.trim();
              Navigator.pop(context, t.isEmpty ? null : t);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SyraTokens.textSecondary,
                    side: BorderSide(color: SyraTokens.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final t = controller.text.trim();
                    Navigator.pop(context, t.isEmpty ? null : t);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SyraTokens.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!mounted) return;
    final title = (newTitle ?? '').trim();
    if (title.isEmpty || title == session.title) return;

    final result = await ChatSessionService.renameSession(
      sessionId: session.id,
      newTitle: title,
    );

    if (!mounted) return;
    if (result.success) {
      await _loadChatSessions();
      BlurToast.show(context, 'Sohbet adı güncellendi');
    } else {
      BlurToast.show(
          context, result.errorMessage ?? 'Sohbet adı değiştirilemedi');
    }
  }

  Future<void> _deleteSessionFromSidebar(ChatSession session) async {
    final confirmed = await SyraBottomPanel.show<bool>(
      context: context,
      maxHeight: 260,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sohbet silinsin mi?',
            style: TextStyle(
              color: SyraTokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '"${session.title}" sohbeti kalıcı olarak silinecek.',
            style: TextStyle(
              color: SyraTokens.textSecondary.withValues(alpha: 0.92),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SyraTokens.textSecondary,
                    side: BorderSide(color: SyraTokens.borderSubtle),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Vazgeç'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SyraTokens.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Sil',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ChatSessionService.deleteSession(session.id);
    if (!mounted) return;

    if (result.success) {
      // If we deleted the currently open chat, create/select a new one
      if (_currentSessionId == session.id) {
        setState(() {
          _currentSessionId = null;
          _messages.clear();
          _replyingTo = null;
          _isTarotMode = false;
        });
        await _createInitialSession();
      }

      await _loadChatSessions();
      BlurToast.show(context, 'Sohbet silindi');
    } else {
      BlurToast.show(context, result.errorMessage ?? 'Sohbet silinemedi');
    }
  }

  void _archiveSessionFromSidebar(ChatSession session) {
    // NOTE: Archive is currently a placeholder in the app.
    // We still expose the UI for the sidebar context menu.
    BlurToast.show(context, 'Arşiv özelliği yakında');
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

  /// Handle mode selection - Minimal glass style popup
  void _handleModeSelection() {
    // Get screen width to center the card under SYRA title
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = 250.0;
    final centerX = (screenWidth - cardWidth) / 2;

    showMinimalModeSelector(
      context: context,
      selectedMode: _selectedMode,
      onModeSelected: (mode) {
        setState(() {
          _selectedMode = mode;
        });
      },
      anchorPosition: Offset(
          centerX, 72), // Below Dynamic Island (56px header + 16px padding)
      onShow: () {
        setState(() {
          _isModeSelectorOpen = true;
        });
      },
      onHide: () {
        setState(() {
          _isModeSelectorOpen = false;
        });
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

    // Scroll to bottom after user message (with animation)
    Future.delayed(const Duration(milliseconds: 100),
        () => _scrollToBottom(smooth: false));

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
    // 🚀 STREAMING AI RESPONSE
    // ═══════════════════════════════════════════════════════════════

    // Show typing indicator (logo pulse)
    setState(() {
      _isTyping = true;
    });

    // Small delay (AI "thinking")
    await Future.delayed(const Duration(milliseconds: 500));

    // Create bot message ID (but don't add to list yet)
    final botMessageId = UniqueKey().toString();
    bool messageAdded = false; // Track if message was added to list

    // Stream AI response word-by-word
    try {
      await for (final chunk in ChatServiceStreaming.sendMessageStream(
        userMessage: text.isEmpty ? "Bu resimle ilgili ne düşünüyorsun?" : text,
        conversationHistory: _messages,
        replyingTo: _replyingTo,
        mode: _selectedMode,
        imageUrl: imageUrlToSend,
      )) {
        // Error handling
        if (chunk.error != null) {
          setState(() {
            _isTyping = false;
            _isTyping = false;
            _isLoading = false;
            _isSending = false;
          });

          if (mounted) {
            BlurToast.show(context, chunk.error!);
          }

          // Remove message if it was added
          if (messageAdded) {
            setState(() {
              _messages.removeWhere((m) => m['id'] == botMessageId);
            });
          }

          return;
        }

        // Stream completed
        if (chunk.isDone) {
          setState(() {
            _isTyping = false;
          });

          // Detect manipulation flags
          final index = _messages.indexWhere((m) => m['id'] == botMessageId);
          if (index != -1) {
            final finalText = _messages[index]['text'] as String;
            final flags = ChatService.detectManipulation(finalText);

            setState(() {
              _messages[index]['hasRed'] = flags['hasRed'] ?? false;
              _messages[index]['hasGreen'] = flags['hasGreen'] ?? false;
              _isTyping = false;
              _isLoading = false;
            });

            // Save bot message to session
            if (_currentSessionId != null) {
              final saveResult = await ChatSessionService.addMessageToSession(
                sessionId: _currentSessionId!,
                message: _messages[index],
              );

              if (saveResult.success) {
                await ChatSessionService.updateSession(
                  sessionId: _currentSessionId!,
                  lastMessage: finalText.length > 50
                      ? "${finalText.substring(0, 50)}..."
                      : finalText,
                );
                await _loadChatSessions();
              }
            }
          }

          debugPrint("✅ Streaming completed!");
          break;
        }

        // First chunk: hide logo, add message to list
        if (!messageAdded) {
          setState(() {
            _isTyping = false; // Hide logo pulse
            _messages.add({
              "id": botMessageId,
              "sender": "bot",
              "text": chunk.text, // First chunk
              "replyTo": null,
              "time": DateTime.now(),
              "timestamp": DateTime.now(),
              "hasRed": false,
              "hasGreen": false,
            });
          });
          messageAdded = true;
        } else {
          // Subsequent chunks: append to existing message
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == botMessageId);
            if (index != -1) {
              _messages[index]['text'] =
                  (_messages[index]['text'] as String) + chunk.text;
            }
          });
        }

        // Auto-scroll to bottom
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("❌ Streaming error: $e");

      setState(() {
        _isTyping = false;
        _isLoading = false;
        _isSending = false;
      });

      if (mounted) {
        BlurToast.show(context, "Bir hata oluştu. Tekrar dene kanka.");
      }

      // Remove empty bot message on error
      setState(() {
        _messages.removeWhere((m) => m['id'] == botMessageId);
      });
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
                    "Bugünlük mesaj hakkın bitti kanka.\nPremium ile sınırsız devam edebilirsin!",
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
      child: ChatSessionsSheet(
        sessions: _chatSessions,
        currentSessionId: _currentSessionId,
        onNewChat: _startNewChat,
        onSelectSession: (id) async => _loadSelectedChat(id),
        onRefresh: _loadChatSessions,
      ),
    );
  }

  // ✅ FIX: build() BLOĞU BAŞTAN TEMİZ (parantez dengesi düzgün)
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: SyraTokens.background,
            body: Stack(
              children: [
                const SyraBackground(),

                // Sidebar - Behind the chat screen
                if (_sidebarOpen)
                  ClaudeSidebar(
                    onClose: () => setState(() => _sidebarOpen = false),
                    userName: FirebaseAuth.instance.currentUser?.displayName ??
                        'Kullanıcı',
                    userEmail: FirebaseAuth.instance.currentUser?.email,
                    sessions: _chatSessions,
                    currentSessionId: _currentSessionId,
                    onSelectSession: (id) async => _loadSelectedChat(id),
                    onRenameSession: _renameSessionFromSidebar,
                    onArchiveSession: _archiveSessionFromSidebar,
                    onDeleteSession: _deleteSessionFromSidebar,
                    onNewChat: _startNewChat,
                    onTarotMode: _startTarotMode,
                    onKimDahaCok: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const KimDahaCokScreen(),
                        ),
                      );
                    },
                    onSettingsTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                // Chat screen - slides to the right
                GestureDetector(
                  // Swipe only works on chat screen area (not sidebar)
                  onHorizontalDragEnd: (details) {
                    if (_sidebarOpen &&
                        details.primaryVelocity != null &&
                        details.primaryVelocity! < -300) {
                      setState(() {
                        _sidebarOpen = false;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                      _sidebarOpen
                          ? MediaQuery.of(context).size.width * 0.70
                          : 0,
                      0,
                      0,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(_sidebarOpen ? 24 : 0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Stack(
                            children: [
                              // Layer 1: SyraBackground (visible texture for blur)
                              const Positioned.fill(
                                child: SyraBackground(),
                              ),

                              // Layer 2: Optional light overlay for better contrast
                              Positioned.fill(
                                child: Container(
                                  color:
                                      SyraTokens.background.withOpacity(0.90),
                                ),
                              ),

                              // Layer 3: ChatMessageList (full screen with top padding)
                              Positioned.fill(
                                top: 0,
                                child: ChatMessageList(
                                  isEmpty: _messages.isEmpty,
                                  isTarotMode: _isTarotMode,
                                  headerHeight:
                                      topInset + ChatAppBar.baseHeight,
                                  onSuggestionTap: (text) {
                                    setState(() {
                                      _controller.text = text;
                                    });
                                    _inputFocusNode.requestFocus();
                                    _controller.selection =
                                        TextSelection.fromPosition(
                                      TextPosition(
                                          offset: _controller.text.length),
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

                              // Layer 4: Input bar overlay at bottom
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: ChatInputBar(
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
                                  onCameraTap: () =>
                                      _pickImageForPreview(ImageSource.camera),
                                  onGalleryTap: () =>
                                      _pickImageForPreview(ImageSource.gallery),
                                  onModeTap: _handleModeSelection,
                                  currentMode: _getModeDisplayName(),
                                  chatBackgroundKey: _chatBackgroundKey,
                                ),
                              ),

                              // Layer 5: ChatAppBar overlay at top (blurs content behind it)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: ChatAppBar(
                                  selectedMode: _selectedMode,
                                  modeAnchorLink: _modeAnchorLink,
                                  onMenuTap: _toggleSidebar,
                                  onModeTap: _handleModeSelection,
                                  onDocumentUpload: _handleDocumentUpload,
                                  isModeSelectorOpen: _isModeSelectorOpen,
                                  topPadding: topInset,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
            ), // Stack
          ), // Scaffold
        ), // GestureDetector
      ), // PopScope
    ); // AnnotatedRegion
  }

  String _getModeDisplayName() {
    switch (_selectedMode) {
      case 'tarot':
        return 'Tarot';
      case 'flirt':
        return 'Flört';
      case 'deep':
        return 'Derin';
      case 'tactical':
        return 'Taktik';
      default:
        return 'Pro';
    }
  }

  // ----------------------------------------------------------------
  // Aşağıdaki eski helper widgetlar sende zaten vardı; kalsın diye bıraktım.
  // (Şu an yeni ChatAppBar/ChatMessageList/ChatInputBar kullanıyorsun.)
  // ----------------------------------------------------------------

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
            onTap: _toggleSidebar,
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
              activeThumbColor: SyraTokens.accent,
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
