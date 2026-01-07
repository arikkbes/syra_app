import 'dart:ui';
import 'dart:io';
// max fonksiyonu için
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../widgets/syra_top_haze.dart';
import '../widgets/syra_top_haze_with_holes.dart';
import '../widgets/syra_bottom_haze.dart';
import '../widgets/syra_glass_sheet.dart'; // For bottom input bar glass
import '../widgets/attachment_options_sheet.dart'; // NEW: Modern attachment picker

import 'premium_screen.dart';
import 'settings/settings_modal_sheet.dart';
import 'chat_sessions_sheet.dart';
import 'premium_management_screen.dart';
import 'tarot_mode_screen.dart';

// RelationshipRadarBody - unified analysis + scoreboard screen
import 'relationship_radar_body.dart';

// New extracted widgets
import 'chat/chat_app_bar.dart';
import 'chat/chat_message_list.dart';
import 'chat/chat_input_bar.dart';
import '../widgets/minimal_mode_selector.dart';
import '../widgets/claude_sidebar.dart';
import '../widgets/measure_size.dart';

const bool forcePremiumForTesting = false;

/// Body mode enum for ChatScreen - controls which body is displayed
enum ChatBodyMode { chat, relationshipRadar }

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

  double _inputBarHeight = 0.0; // Measured height of ChatInputBar

  // ═══════════════════════════════════════════════════════════════
  // BUG FIX #1: Stream subscription management
  // ═══════════════════════════════════════════════════════════════
  String? _activeRequestId; // Current active request ID for guard
  String? _lockedSessionId; // Session locked at send time

  Map<String, dynamic>? _replyingTo;

  bool _sidebarOpen = false;
  double _dragOffset =
      0.0; // Claude-style: track drag position for smooth panel sliding

  double _swipeOffset = 0.0;
  String? _swipedMessageId;

  // Limit warning (show only once per session)
  bool _hasShownLimitWarning = false;

  List<ChatSession> _chatSessions = [];
  String? _currentSessionId; // CRITICAL FIX - Bu eksikti!

  bool _isTarotMode = false;
  bool _isPrivateMode = false; // NEW: Gizli sohbet modu

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

  // Relationship panel state
  bool _isRelationshipPanelOpen = false; // Anti-spam flag
  void Function(VoidCallback)? _sheetSetState; // Reference to sheet's setState
  int _panelRefreshTrigger = 0; // Increment to force panel refresh

  // Background upload state (persists when sheet is closed)
  bool _isUploadingInBackground = false;
  String _uploadStatus = '';
  double? _uploadProgress; // null = indeterminate
  File? _pendingUploadFile;
  bool _showMismatchCard = false;
  String _mismatchReason = '';
  String? _mismatchExistingRelationshipId;

  // LayerLink for anchored mode selector popover
  // This anchors the mode selector popover to the mode label in the app bar
  final LayerLink _modeAnchorLink = LayerLink();

  // GlobalKey for RepaintBoundary (Liquid Glass background capture)
  final GlobalKey _chatBackgroundKey = GlobalKey();

  // Body mode control - chat vs relationship radar
  ChatBodyMode _bodyMode = ChatBodyMode.chat;
  RelationshipMemory? _radarMemory; // Active memory for radar view

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

        // Show scroll-to-bottom button when user scrolls up > 250px from bottom
        if (maxScroll - currentScroll > 250) {
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
    // Exit radar mode if active
    if (_bodyMode == ChatBodyMode.relationshipRadar) {
      setState(() {
        _bodyMode = ChatBodyMode.chat;
        _radarMemory = null;
      });
    }

    final result = await ChatSessionService.getSessionMessages(sessionId);
    if (!mounted) return;

    if (result.success && result.messages != null) {
      // Inject local feedback from SharedPreferences
      await ChatSessionService.injectLocalFeedback(result.messages!);

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
    final screenWidth = MediaQuery.of(context).size.width;
    final maxDragOffset = (screenWidth * 0.72).clamp(260.0, 320.0);

    setState(() {
      _sidebarOpen = !_sidebarOpen;
      _dragOffset = _sidebarOpen ? maxDragOffset : 0.0;
    });
    HapticFeedback.lightImpact();
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

  /// Handle copy message action (silent - no toast)
  void _handleCopyMessage(Map<String, dynamic> msg) {
    final text = msg["text"];
    if (text != null) {
      Clipboard.setData(ClipboardData(text: text));
      // NO TOAST - checkmark animation in button provides feedback
    }
  }

  /// Handle feedback change (like/dislike)
  Future<void> _handleFeedbackChanged(
      Map<String, dynamic> msg, String? newFeedback) async {
    final messageId = msg['id'] as String?;
    if (messageId == null || _currentSessionId == null) return;

    // Optimistic update
    setState(() {
      msg['feedback'] = newFeedback;
    });

    // Show feedback toast when like/dislike is given (not when removing)
    if (newFeedback != null && mounted) {
      BlurToast.showTop(
        context,
        "Geri bildirimin için teşekkürler!",
        duration: const Duration(milliseconds: 1500),
      );
    }

    // Persist to Firestore + SharedPreferences
    final result = await ChatSessionService.setMessageFeedback(
      sessionId: _currentSessionId!,
      messageId: messageId,
      feedback: newFeedback,
    );

    if (!result.success && mounted) {
      // Revert on failure
      setState(() {
        msg['feedback'] = null;
      });
      BlurToast.show(
          context, result.errorMessage ?? 'Geri bildirim kaydedilemedi');
    }
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
    // ═══════════════════════════════════════════════════════════════
    // BUG FIX #1: Cancel any in-flight stream before starting new chat
    // ═══════════════════════════════════════════════════════════════
    // Invalidate active request so late chunks are ignored
    _activeRequestId = null;
    _lockedSessionId = null;

    // Reset sending state immediately
    setState(() {
      _isSending = false;
      _isTyping = false;
      _isLoading = false;
    });

    // Exit radar mode if active
    if (_bodyMode == ChatBodyMode.relationshipRadar) {
      setState(() {
        _bodyMode = ChatBodyMode.chat;
        _radarMemory = null;
      });
    }

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

    // ═══════════════════════════════════════════════════════════════
    // MODULE 2: Cancel in-flight request if deleting current session
    // ═══════════════════════════════════════════════════════════════
    if (_currentSessionId == session.id) {
      // Cancel any in-flight streaming response
      if (_activeRequestId != null) {
        debugPrint(
            "⚠️ [ChatScreen] Cancelling in-flight request due to session deletion");
        setState(() {
          _activeRequestId =
              null; // This will cause streaming chunks to be ignored
          _lockedSessionId = null;
          _isTyping = false;
        });
      }
    }

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

  /// MODULE 3: Show mismatch detection dialog
  /// Returns: true = create new, false = force update, null = cancel
  // DEPRECATED: Mismatch handling now done inside _RelationshipPanelSheet
  /*
  Future<bool?> _showMismatchDialog(String reason) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: SyraTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Farklı İlişki Tespit Edildi',
          style: TextStyle(
            color: SyraTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: TextStyle(
                color: SyraTokens.textSecondary.withValues(alpha: 0.92),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Yeni ilişki olarak kaydedilsin mi, yoksa mevcut ilişkiyi güncelleyelim mi?',
              style: TextStyle(
                color: SyraTokens.textSecondary.withValues(alpha: 0.92),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Vazgeç',
              style: TextStyle(color: SyraTokens.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Yine de Güncelle',
              style: TextStyle(color: SyraTokens.accent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: SyraTokens.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Yeni İlişki',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  */

  void _archiveSessionFromSidebar(ChatSession session) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update session in Firestore to mark as archived
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(session.id)
          .update(
              {'isArchived': true, 'archivedAt': FieldValue.serverTimestamp()});

      // Remove from local list
      setState(() {
        _chatSessions.removeWhere((s) => s.id == session.id);
      });
    } catch (e) {
      debugPrint('Arşivleme hatası: $e');
    }
  }

  /// Toggle private chat mode - messages won't be saved
  void _togglePrivateChat() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_isPrivateMode) {
        // Exit private mode - start fresh normal chat
        _isPrivateMode = false;
        _messages.clear();
        _currentSessionId = null;
      } else {
        // Enter private mode
        _isPrivateMode = true;
        _messages.clear();
        _currentSessionId = null;
      }
    });
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
    // Anti-spam: Prevent multiple opens
    if (_isRelationshipPanelOpen) return;

    // Close keyboard before starting relationship upload
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Set flag to prevent spam
    _isRelationshipPanelOpen = true;

    // Load relationship memory - include inactive ones for panel UI
    final memory =
        await RelationshipMemoryService.getMemory(forceIncludeInactive: true);

    if (!mounted) {
      _isRelationshipPanelOpen = false;
      return;
    }

    // Always show the relationship panel sheet
    // It will handle both empty state (no memory) and filled state (has memory)
    _showRelationshipPanel(memory);
  }

  // ═══════════════════════════════════════════════════════════════
  // BACKGROUND UPLOAD METHODS (persist when sheet is closed)
  // ═══════════════════════════════════════════════════════════════

  /// Handle upload button tap - start file picker
  Future<void> _handleUploadTap() async {
    // Close keyboard before file picker
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'zip'],
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = File(result.files.single.path!);

      // Start upload with progress tracking
      await _uploadFile(file);
    } catch (e) {
      debugPrint('_handleUploadTap error: $e');
      if (mounted) {
        setState(() {
          _isUploadingInBackground = false;
        });
        BlurToast.show(
          context,
          "❌ Dosya seçimi başarısız: ${e.toString()}",
        );
      }
    }
  }

  /// Upload file with background support
  Future<void> _uploadFile(File file, {bool forceUpdate = false}) async {
    if (!mounted) return;

    setState(() {
      _isUploadingInBackground = true;
      _uploadStatus = 'Dosya seçildi...';
      _uploadProgress = null;
      _showMismatchCard = false;
      _pendingUploadFile = file;
      _panelRefreshTrigger++; // Increment for didUpdateWidget
    });

    // Update sheet StatefulBuilder to rebuild with new props
    _sheetSetState?.call(() {});

    try {
      // Determine if this is an update or new upload
      String? existingRelationshipId;
      final currentMemory =
          await RelationshipMemoryService.getMemory(forceIncludeInactive: true);
      if (currentMemory != null && !forceUpdate) {
        existingRelationshipId = currentMemory.id;
      }

      if (mounted) {
        setState(() {
          _uploadStatus = 'Yükleniyor...';
        });
      }

      // Upload and analyze
      final analysisResult = await RelationshipAnalysisService.analyzeChat(
        file,
        existingRelationshipId: existingRelationshipId,
        forceUpdate: forceUpdate,
        updateMode: "smart", // Smart delta update by default
      );

      if (!mounted) return;

      setState(() {
        _uploadStatus = 'Analiz ediliyor...';
      });

      // Handle mismatch detection
      if (analysisResult.isMismatch && !forceUpdate) {
        setState(() {
          _isUploadingInBackground = false;
          _showMismatchCard = true;
          _mismatchReason = analysisResult.mismatchReason ??
              'Farklı bir ilişki tespit edildi';
          _mismatchExistingRelationshipId = existingRelationshipId;
          _panelRefreshTrigger++; // Increment for didUpdateWidget
        });

        // Update sheet StatefulBuilder to rebuild with new props
        _sheetSetState?.call(() {});
        return;
      }

      // Success - fetch the updated/new memory WITHOUT activating it
      if (analysisResult.relationshipId != null) {
        // If this is a NEW upload (not update), auto-activate the relationship
        final isNewUpload = existingRelationshipId == null;

        if (isNewUpload) {
          // New relationship - activate it
          await RelationshipMemoryService.setActiveRelationship(
            analysisResult.relationshipId!,
          );
          await RelationshipMemoryService.updateIsActive(
            true,
            relationshipId: analysisResult.relationshipId!,
          );
        } else {
          // Existing relationship updated - ensure activeRelationshipId is still this one
          // (in case backend changed the ID during force rebuild)
          await RelationshipMemoryService.setActiveRelationship(
            analysisResult.relationshipId!,
          );
        }

        // Force refresh memory from Firestore (no cache)
        final memory = await RelationshipMemoryService.getMemory(
          forceIncludeInactive: true,
        );

        if (!mounted) return;

        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
          _pendingUploadFile = null;
          _panelRefreshTrigger++; // Trigger sheet refresh
        });

        // Update sheet StatefulBuilder to rebuild with new props
        _sheetSetState?.call(() {});

        // Show success message
        if (mounted) {
          BlurToast.show(
            context,
            isNewUpload
                ? "✅ İlişki yüklendi ve aktif edildi"
                : "✅ İlişki güncellendi",
          );
        }
      } else {
        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
          _pendingUploadFile = null;
        });
      }
    } catch (e) {
      debugPrint('_uploadFile error: $e');
      if (mounted) {
        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
          _pendingUploadFile = null;
        });
        BlurToast.show(
          context,
          "❌ Analiz sırasında bir hata oluştu: ${e.toString()}",
        );
      }
    }
  }

  /// Handle mismatch - new relationship
  Future<void> _handleMismatchNewRelationship() async {
    debugPrint('🔵 _handleMismatchNewRelationship called');
    debugPrint('🔵 _pendingUploadFile: $_pendingUploadFile');

    if (_pendingUploadFile == null) {
      debugPrint('❌ _pendingUploadFile is NULL - returning early');
      return;
    }

    debugPrint('✅ Starting new relationship creation');
    setState(() {
      _showMismatchCard = false;
      _isUploadingInBackground = true;
      _uploadStatus = 'Yeni ilişki oluşturuluyor...';
    });

    // ✅ Update sheet immediately to show loading
    _sheetSetState?.call(() {});

    try {
      // Create NEW relationship - explicitly pass null for relationshipId
      final analysisResult = await RelationshipAnalysisService.analyzeChat(
        _pendingUploadFile!,
        existingRelationshipId: null, // IMPORTANT: null for new relationship
        updateMode: "smart",
      );

      if (!mounted) return;

      // Check if somehow still got mismatch (shouldn't happen)
      if (analysisResult.isMismatch) {
        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
        });

        // ✅ Update sheet to hide loading
        _sheetSetState?.call(() {});

        if (mounted) {
          BlurToast.show(
            context,
            "❌ Yeni ilişki oluşturulamadı: ${analysisResult.mismatchReason}",
          );
        }
        return;
      }

      // Success - activate new relationship
      if (analysisResult.relationshipId != null) {
        await RelationshipMemoryService.setActiveRelationship(
          analysisResult.relationshipId!,
        );
        await RelationshipMemoryService.updateIsActive(
          true,
          relationshipId: analysisResult.relationshipId,
        );

        // Force refresh memory from Firestore (no cache)
        final memory = await RelationshipMemoryService.getMemory(
          forceIncludeInactive: true,
        );

        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
          _pendingUploadFile = null;
          _panelRefreshTrigger++;
        });

        _sheetSetState?.call(() {});

        if (mounted && memory != null) {
          BlurToast.show(context, "✅ Yeni ilişki oluşturuldu ve aktif edildi");
        }
      }
    } catch (e) {
      debugPrint('_handleMismatchNewRelationship error: $e');
      if (mounted) {
        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
        });

        // ✅ Update sheet to hide loading
        _sheetSetState?.call(() {});

        BlurToast.show(
          context,
          "❌ Yeni ilişki oluşturulamadı: ${e.toString()}",
        );
      }
    }
  }

  /// Handle mismatch - force update
  Future<void> _handleMismatchForceUpdate() async {
    if (_pendingUploadFile == null || _mismatchExistingRelationshipId == null)
      return;

    setState(() {
      _showMismatchCard = false;
      _isUploadingInBackground = true;
      _uploadStatus = 'İlişki güncelleniyor...';
    });

    // ✅ Update sheet immediately to show loading
    _sheetSetState?.call(() {});

    try {
      // Force rebuild existing relationship
      final analysisResult = await RelationshipAnalysisService.analyzeChat(
        _pendingUploadFile!,
        existingRelationshipId: _mismatchExistingRelationshipId,
        forceUpdate: true,
        updateMode: "force_rebuild", // Clear all data and rebuild
      );

      if (!mounted) return;

      // Check if somehow still got mismatch (shouldn't happen with forceUpdate)
      if (analysisResult.isMismatch) {
        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
        });

        // ✅ Update sheet to hide loading
        _sheetSetState?.call(() {});

        if (mounted) {
          BlurToast.show(
            context,
            "❌ Güncelleme başarısız: ${analysisResult.mismatchReason}",
          );
        }
        return;
      }

      // Success - activate updated relationship
      if (analysisResult.relationshipId != null) {
        await RelationshipMemoryService.setActiveRelationship(
          analysisResult.relationshipId!,
        );
        await RelationshipMemoryService.updateIsActive(
          true,
          relationshipId: analysisResult.relationshipId,
        );

        // Force refresh memory from Firestore (no cache)
        final memory = await RelationshipMemoryService.getMemory(
          forceIncludeInactive: true,
        );

        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
          _pendingUploadFile = null;
          _mismatchExistingRelationshipId = null;
          _panelRefreshTrigger++;
        });

        _sheetSetState?.call(() {});

        if (mounted && memory != null) {
          BlurToast.show(context, "✅ İlişki güncellendi");
        }
      }
    } catch (e) {
      debugPrint('_handleMismatchForceUpdate error: $e');
      if (mounted) {
        setState(() {
          _isUploadingInBackground = false;
          _uploadStatus = '';
        });

        // ✅ Update sheet to hide loading
        _sheetSetState?.call(() {});

        BlurToast.show(
          context,
          "❌ Güncelleme başarısız: ${e.toString()}",
        );
      }
    }
  }

  /// Handle mismatch - cancel
  void _handleMismatchCancel() {
    setState(() {
      _showMismatchCard = false;
      _pendingUploadFile = null;
      _mismatchExistingRelationshipId = null;
      _mismatchReason = '';
      _isUploadingInBackground = false;
      _uploadStatus = '';
      _panelRefreshTrigger++; // Increment for didUpdateWidget
    });

    // Update sheet StatefulBuilder to rebuild with new props
    _sheetSetState?.call(() {});
  }

  /// Show empty state upload dialog
  // DEPRECATED: Upload dialog now integrated into _RelationshipPanelSheet
  /*
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
    ).then((_) {
      // Reset anti-spam flag when panel closes
      _isRelationshipPanelOpen = false;
    });
  }
  */

  /// Show filled state relationship panel
  void _showRelationshipPanel(RelationshipMemory? memory) {
    SyraBottomPanel.show(
      context: context,
      padding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          // Save reference for updates
          _sheetSetState = setSheetState;

          return _RelationshipPanelSheet(
            memory: memory,
            onDelete: () {
              // Force new chat session after forget
              setState(() {
                // Clear current session to force fresh start
                _currentSessionId = null;
                _messages.clear();
                _replyingTo = null;
              });

              // Reset panel open flag so it can be opened again
              _isRelationshipPanelOpen = false;

              // Create new session for next message
              _createInitialSession();
            },
            onMemoryUpdated: (updatedMemory) {
              // Callback when memory is updated (after upload/update)
              setState(() {
                // Update local state if needed
              });
            },
            // Background upload state
            isUploadingInBackground: _isUploadingInBackground,
            uploadStatus: _uploadStatus,
            uploadProgress: _uploadProgress,
            showMismatchCard: _showMismatchCard,
            mismatchReason: _mismatchReason,
            onUploadTap: _handleUploadTap,
            onMismatchNew: _handleMismatchNewRelationship,
            onMismatchForceUpdate: _handleMismatchForceUpdate,
            onMismatchCancel: _handleMismatchCancel,
            refreshTrigger: _panelRefreshTrigger,
          );
        },
      ),
    ).then((_) {
      // Reset anti-spam flag when panel closes
      _isRelationshipPanelOpen = false;
      _sheetSetState = null; // Clear reference
    });
  }

  /// Open relationship radar (unified analysis + scoreboard) as body swap
  void _openRelationshipRadar(RelationshipMemory memory) {
    setState(() {
      _radarMemory = memory;
      _bodyMode = ChatBodyMode.relationshipRadar;
      _sidebarOpen = false;
      _dragOffset = 0.0;
    });
  }

  /// Return to chat mode from radar
  void _closeRelationshipRadar() {
    setState(() {
      _bodyMode = ChatBodyMode.chat;
      _radarMemory = null;
    });
  }

  /// Radar loading state (while memory is being fetched)
  Widget _buildRadarLoadingState() {
    return Container(
      color: SyraTokens.background,
      child: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header with menu button
                _buildRadarLoadingHeader(),
                // Loading content
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              SyraTokens.accent.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'İlişki verileri yükleniyor...',
                          style: TextStyle(
                            color: SyraTokens.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
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

  Widget _buildRadarLoadingHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: SyraTokens.background.withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: SyraTokens.divider,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _toggleSidebar();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  color: SyraTokens.textSecondary,
                  size: 24,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        color: SyraTokens.accent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "İlişki Radarı",
                        style: TextStyle(
                          color: SyraTokens.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Legacy method - kept for potential direct navigation if needed
  void _openAnalysisFromMemory(RelationshipMemory memory) {
    // Now redirects to unified radar view
    _openRelationshipRadar(memory);
  }

  // DEPRECATED: Upload logic now integrated into _RelationshipPanelSheet
  /*
  /// Pick and upload relationship file
  Future<void> _pickAndUploadRelationshipFile(
      {String? existingRelationshipId}) async {
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

      // Upload and analyze - pass existingRelationshipId if updating
      final analysisResult = await RelationshipAnalysisService.analyzeChat(
        file,
        existingRelationshipId: existingRelationshipId,
        updateMode: "smart", // Smart delta update
      );

      if (!mounted) return;

      setState(() {
        _isUploadingRelationshipFile = false;
      });

      // Handle mismatch detection
      if (analysisResult.isMismatch) {
        final shouldCreateNew = await _showMismatchDialog(
          analysisResult.mismatchReason ?? 'Farklı bir ilişki tespit edildi',
        );

        if (!mounted) return;

        if (shouldCreateNew == null) {
          // User cancelled
          return;
        } else if (shouldCreateNew) {
          // Create new relationship - retry without relationshipId
          setState(() {
            _isUploadingRelationshipFile = true;
          });

          try {
            final newResult = await RelationshipAnalysisService.analyzeChat(
              file,
              existingRelationshipId: null, // Create new
              updateMode: "smart", // New relationship
            );

            if (!mounted) return;

            setState(() {
              _isUploadingRelationshipFile = false;
            });

            // Check if new upload also has mismatch (shouldn't happen for new relationship)
            if (newResult.isMismatch) {
              // This shouldn't happen, but if it does, show error and stop
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Yeni ilişki oluşturulamadı: ${newResult.mismatchReason ?? "Bilinmeyen hata"}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              return;
            }

            // Activate new relationship
            if (newResult.relationshipId != null) {
              await RelationshipMemoryService.setActiveRelationship(
                  newResult.relationshipId!);
              await RelationshipMemoryService.updateIsActive(true,
                  relationshipId: newResult.relationshipId);
              // Force refresh memory from Firestore (no cache)
              final memory = await RelationshipMemoryService.getMemory(
                forceIncludeInactive: true,
              );
              if (mounted && memory != null) {
                _showRelationshipPanel(memory);
              }
            }
          } catch (e) {
            if (!mounted) return;
            
            setState(() {
              _isUploadingRelationshipFile = false;
            });
            
            // Show error to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Yeni ilişki oluşturulamadı: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        } else {
          // Force update existing relationship
          setState(() {
            _isUploadingRelationshipFile = true;
          });

          try {
            final forceResult = await RelationshipAnalysisService.analyzeChat(
              file,
              existingRelationshipId: existingRelationshipId,
              forceUpdate: true, // Force overwrite
              updateMode: "force_rebuild", // Clear and rebuild
            );

            if (!mounted) return;

            setState(() {
              _isUploadingRelationshipFile = false;
            });

            // Check if force update also has mismatch (shouldn't happen with forceUpdate=true)
            if (forceResult.isMismatch) {
              // This shouldn't happen with forceUpdate, but if it does, show error
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Güncelleme başarısız: ${forceResult.mismatchReason ?? "Bilinmeyen hata"}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
              return;
            }

            // Activate updated relationship
            if (forceResult.relationshipId != null) {
              await RelationshipMemoryService.setActiveRelationship(
                  forceResult.relationshipId!);
              await RelationshipMemoryService.updateIsActive(true,
                  relationshipId: forceResult.relationshipId);
              // Force refresh memory from Firestore (no cache)
              final memory = await RelationshipMemoryService.getMemory(
                forceIncludeInactive: true,
              );
              if (mounted && memory != null) {
                _showRelationshipPanel(memory);
              }
            }
          } catch (e) {
            if (!mounted) return;
            
            setState(() {
              _isUploadingRelationshipFile = false;
            });
            
            // Show error to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Güncelleme başarısız: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      // After upload, activate relationship and open panel (stay in chat)
      if (analysisResult.relationshipId != null) {
        // Set user activeRelationshipId
        await RelationshipMemoryService.setActiveRelationship(
            analysisResult.relationshipId!);

        // Set relation isActive=true
        await RelationshipMemoryService.updateIsActive(true,
            relationshipId: analysisResult.relationshipId);

        // Fetch fresh memory and open panel
        final memory = await RelationshipMemoryService.getMemory();
        if (mounted && memory != null) {
          _showRelationshipPanel(memory);
        }
      }
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
  */

  /// Handle attachment menu - Modern ChatGPT/Claude-style picker
  void _handleAttachment() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.40),
      isScrollControlled: true,
      builder: (context) => AttachmentOptionsSheet(
        onImageSelected: (File imageFile) async {
          // Seçilen resmi preview'e ekle ve upload et
          setState(() {
            _pendingImage = imageFile;
            _pendingImageUrl = null; // Henüz upload edilmedi
          });
          // Arka planda Firebase'e upload et
          _uploadPendingImage();
        },
        onFileTap: () {
          // İleride dosya yükleme özelliği için
          BlurToast.show(context, "Dosya yükleme yakında eklenecek");
        },
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
    // BUG FIX #1: Generate request ID at send time
    // ═══════════════════════════════════════════════════════════════
    final requestId = UniqueKey().toString(); // Generate unique request ID

    // Set active request ID
    _activeRequestId = requestId;

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

    // ═══════════════════════════════════════════════════════════════
    // PATCH C: Auto-detect selfParticipant from "ben X'yim" patterns
    // ═══════════════════════════════════════════════════════════════
    _tryAutoSelectSelfParticipant(text);

    // 1 saniye sonra buton tekrar aktif olacak (anti-spam timeout)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isSending = false);
      }
    });

    // ═══════════════════════════════════════════════════════════════
    // MICRO FIX: Ensure session exists and appears in sidebar IMMEDIATELY
    // ═══════════════════════════════════════════════════════════════
    if (_currentSessionId == null) {
      // Create session with temporary title
      final result = await ChatSessionService.createSession(
        title: 'New chat',
      );
      if (result.success && result.sessionId != null) {
        setState(() {
          _currentSessionId = result.sessionId;
        });
        // Immediately load sessions to show in sidebar
        await _loadChatSessions();
      } else {
        debugPrint("❌ Failed to create session: ${result.debugMessage}");
      }
    } else {
      // Session exists - update title if this is first message
      final userMessageCount =
          _messages.where((m) => m['sender'] == 'user').length;
      if (userMessageCount == 1) {
        await ChatSessionService.updateSession(
          sessionId: _currentSessionId!,
          title: text.length > 30 ? '${text.substring(0, 30)}...' : text,
        );
        // Refresh sidebar
        await _loadChatSessions();
      }
    }

    // ═══════════════════════════════════════════════════════════════
    // MICRO FIX: Lock session ID AFTER ensuring it exists
    // ═══════════════════════════════════════════════════════════════
    final lockedSessionId =
        _currentSessionId!; // Lock current session (now guaranteed non-null)
    _lockedSessionId = lockedSessionId; // Update state variable

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

    // Show compact status chip (ChatGPT-style)
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
        sessionId: lockedSessionId, // MODULE 1: Pass locked session ID
        conversationHistory: _messages,
        replyingTo: _replyingTo,
        mode: _selectedMode,
        imageUrl: imageUrlToSend,
      )) {
        // Error handling
        if (chunk.error != null) {
          // ═════════════════════════════════════════════════════════
          // BUG FIX #1: Guard - ignore if request is stale
          // ═════════════════════════════════════════════════════════
          if (_activeRequestId != requestId ||
              _lockedSessionId != lockedSessionId) {
            debugPrint("⚠️ Ignoring error chunk for stale request");
            return; // Ignore stale error
          }

          // Hide status chip on error

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
          // ═════════════════════════════════════════════════════════
          // BUG FIX #1: Guard - ignore if request is stale
          // ═════════════════════════════════════════════════════════
          if (_activeRequestId != requestId ||
              _lockedSessionId != lockedSessionId) {
            debugPrint("⚠️ Ignoring isDone chunk for stale request");
            return; // Ignore stale completion
          }

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

            // Save bot message to session (use lockedSessionId!)
            if (lockedSessionId != null) {
              final saveResult = await ChatSessionService.addMessageToSession(
                sessionId: lockedSessionId,
                message: _messages[index],
              );

              if (saveResult.success) {
                await ChatSessionService.updateSession(
                  sessionId: lockedSessionId,
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
          // ═════════════════════════════════════════════════════════
          // BUG FIX #1: Guard - ignore if request is stale
          // ═════════════════════════════════════════════════════════
          if (_activeRequestId != requestId ||
              _lockedSessionId != lockedSessionId) {
            debugPrint("⚠️ Ignoring first chunk for stale request");
            return; // Ignore stale chunk
          }

          // MICRO FIX: Only add message if still in the same session
          if (_currentSessionId != lockedSessionId) {
            debugPrint(
                "⚠️ Ignoring first chunk - session changed (current: $_currentSessionId, locked: $lockedSessionId)");
            return;
          }

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
          // ═════════════════════════════════════════════════════════
          // BUG FIX #1: Guard - ignore if request is stale
          // ═════════════════════════════════════════════════════════
          if (_activeRequestId != requestId ||
              _lockedSessionId != lockedSessionId) {
            debugPrint("⚠️ Ignoring subsequent chunk for stale request");
            return; // Ignore stale chunk
          }

          // MICRO FIX: Only append if still in the same session
          if (_currentSessionId != lockedSessionId) {
            debugPrint(
                "⚠️ Ignoring subsequent chunk - session changed (current: $_currentSessionId, locked: $lockedSessionId)");
            return;
          }

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
                // Layer 0: Background (always visible)
                const SyraBackground(),

                // Layer 1: Sidebar - ALWAYS present, sits behind the chat panel
                ClaudeSidebar(
                  onClose: () => setState(() {
                    _sidebarOpen = false;
                    _dragOffset = 0.0;
                  }),
                  userName: FirebaseAuth.instance.currentUser?.displayName ??
                      'Kullanıcı',
                  userEmail: FirebaseAuth.instance.currentUser?.email,
                  sessions: _chatSessions,
                  currentSessionId: _currentSessionId,
                  onSelectSession: (id) async {
                    await _loadSelectedChat(id);
                    setState(() {
                      _sidebarOpen = false;
                      _dragOffset = 0.0;
                    });
                  },
                  onRenameSession: _renameSessionFromSidebar,
                  onArchiveSession: _archiveSessionFromSidebar,
                  onDeleteSession: _deleteSessionFromSidebar,
                  onNewChat: () {
                    _startNewChat();
                    setState(() {
                      _sidebarOpen = false;
                      _dragOffset = 0.0;
                    });
                  },
                  onTarotMode: () {
                    _startTarotMode();
                    setState(() {
                      _sidebarOpen = false;
                      _dragOffset = 0.0;
                    });
                  },
                  onKimDahaCok: () async {
                    // ═════════════════════════════════════════════════════════
                    // BUG FIX #3: Use top toast instead of popup when no relationship
                    // ═════════════════════════════════════════════════════════
                    // Load memory to check if relationship exists
                    final memory = await RelationshipMemoryService.getMemory();

                    if (memory != null) {
                      // Has relationship - instantly switch to radar mode
                      setState(() {
                        _bodyMode = ChatBodyMode.relationshipRadar;
                        _sidebarOpen = false;
                        _dragOffset = 0.0;
                        _radarMemory = memory;
                      });
                    } else {
                      // No relationship - show top toast and stay in chat
                      BlurToast.showTop(
                        context,
                        'İlişki yüklemek için SYRA logosuna dokun.',
                        duration: const Duration(seconds: 3),
                      );
                    }
                  },
                  onSettingsTap: () {
                    // DO NOT close sidebar - sheet will appear over it
                    // Show Claude-style modal settings sheet
                    showModalBottomSheet(
                      context: context,
                      useRootNavigator: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withOpacity(0.40),
                      builder: (_) =>
                          SyraSettingsModalSheet(hostContext: context),
                    );
                  },
                ),

                // Layer 2: Chat panel - slides over sidebar like a card (Claude-style)
                Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    // Match sidebar width (72% clamped to 260-320)
                    final maxDragOffset =
                        (screenWidth * 0.72).clamp(260.0, 320.0);

                    // Calculate current offset based on state
                    final targetOffset = _sidebarOpen ? maxDragOffset : 0.0;
                    final currentOffset = _dragOffset.clamp(0.0, maxDragOffset);

                    // Use drag offset during drag, animated offset otherwise
                    final displayOffset = _dragOffset != 0.0 || _sidebarOpen
                        ? currentOffset
                        : targetOffset;

                    return GestureDetector(
                      onHorizontalDragStart: (details) {
                        // Only allow drag from left edge when closed, or anywhere when open
                        if (!_sidebarOpen && details.localPosition.dx > 30) {
                          return;
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _dragOffset = (_dragOffset + details.delta.dx)
                              .clamp(0.0, maxDragOffset);
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        final threshold = maxDragOffset * 0.4;

                        // Determine final state based on velocity and position
                        bool shouldOpen;
                        if (velocity.abs() > 500) {
                          shouldOpen = velocity > 0;
                        } else {
                          shouldOpen = _dragOffset > threshold;
                        }

                        setState(() {
                          _sidebarOpen = shouldOpen;
                          _dragOffset = shouldOpen ? maxDragOffset : 0.0;
                        });

                        if (shouldOpen || !shouldOpen) {
                          HapticFeedback.lightImpact();
                        }
                      },
                      child: AnimatedContainer(
                        duration:
                            _dragOffset == 0.0 || _dragOffset == maxDragOffset
                                ? const Duration(milliseconds: 300)
                                : Duration.zero,
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(
                          _sidebarOpen ? maxDragOffset : _dragOffset,
                          0,
                          0,
                        ),
                        // Reduced shadow for lighter look
                        decoration: (_sidebarOpen || _dragOffset > 0)
                            ? BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  bottomLeft: Radius.circular(28),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 30,
                                    offset: const Offset(-12, 0),
                                  ),
                                ],
                              )
                            : null,
                        child: ClipRRect(
                          borderRadius: (_sidebarOpen || _dragOffset > 0)
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  bottomLeft: Radius.circular(28),
                                )
                              : BorderRadius.zero,
                          child: Container(
                            color: SyraTokens.background,
                            // Conditional body: Chat vs Radar mode
                            child: _bodyMode == ChatBodyMode.relationshipRadar
                                ? _radarMemory != null
                                    ? RelationshipRadarBody(
                                        memory: _radarMemory!,
                                        onMenuTap: _toggleSidebar,
                                      )
                                    : _buildRadarLoadingState()
                                : Stack(
                                    children: [
                                      // Layer 1: SyraBackground (visible texture for blur)
                                      const Positioned.fill(
                                        child: SyraBackground(),
                                      ),

                                      // Layer 2: ChatMessageList (full screen with top padding)
                                      Positioned.fill(
                                        top: 0,
                                        child: ChatMessageList(
                                          isEmpty: _messages.isEmpty,
                                          isTarotMode: _isTarotMode,
                                          isPrivateMode: _isPrivateMode,
                                          headerHeight:
                                              topInset + ChatAppBar.baseHeight,
                                          bottomOverlayHeight: _inputBarHeight,
                                          onSuggestionTap: (text) {
                                            setState(() {
                                              _controller.text = text;
                                            });
                                            _inputFocusNode.requestFocus();
                                            _controller.selection =
                                                TextSelection.fromPosition(
                                              TextPosition(
                                                  offset:
                                                      _controller.text.length),
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
                                                  (_swipeOffset + delta)
                                                      .clamp(0, 30);
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
                                          onCopyMessage: _handleCopyMessage,
                                          onFeedbackChanged:
                                              _handleFeedbackChanged,
                                        ),
                                      ),

                                      // Layer 4: Bottom Haze (micro-blur + scrim with feather fade)
                                      // Subtle foggy/haze effect at bottom, fades smoothly into content
                                      // No horizontal padding - full width
                                      // Settings: blur 0.9, scrim 0.55-0.18, feather 22px at top
                                      Builder(
                                        builder: (context) {
                                          final bottomInset =
                                              MediaQuery.of(context)
                                                  .padding
                                                  .bottom;
                                          final hazeHeight = bottomInset + 60.0;

                                          return Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: SyraBottomHaze(
                                              height: hazeHeight,
                                              blurSigma: 0.5,
                                              featherHeight: 28.0,
                                              scrimBottomAlpha: 0.35,
                                              scrimMidAlpha: 0.10,
                                              scrimMidStop: 0.65,
                                              whiteLiftAlpha: 0.02,
                                            ),
                                          );
                                        },
                                      ),

                                      // Layer 5: Input bar overlay at bottom
                                      Positioned(
                                        bottom: 12,
                                        left: 0,
                                        right: 0,
                                        child: MeasureSize(
                                          onChange: (size) {
                                            setState(() {
                                              _inputBarHeight = size.height;
                                            });
                                          },
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
                                            onCancelReply: () => setState(
                                                () => _replyingTo = null),
                                            onClearImage: _clearPendingImage,
                                            onTextChanged: () =>
                                                setState(() {}),
                                            onCameraTap: () =>
                                                _pickImageForPreview(
                                                    ImageSource.camera),
                                            onGalleryTap: () =>
                                                _pickImageForPreview(
                                                    ImageSource.gallery),
                                            onModeTap: _handleModeSelection,
                                            onRelationshipTap:
                                                _handleDocumentUpload,
                                            currentMode: _getModeDisplayName(),
                                            chatBackgroundKey:
                                                _chatBackgroundKey,
                                          ),
                                        ),
                                      ),

                                      // Layer 5.5: Scroll-to-bottom button (ChatGPT-style centered)
                                      if (_userScrolledUp)
                                        Positioned(
                                          bottom: _inputBarHeight +
                                              20, // 20px above input bar
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: _buildScrollToBottomButton(),
                                          ),
                                        ),

                                      // Layer 6: Top Haze (micro-blur + scrim + feather fade)
                                      // Claude/Sonnet style: subtle foggy/haze effect
                                      // - Small blur for haze (not heavy glass)
                                      // - Soft scrim dimming
                                      // - Feather fade at bottom (no hard line)
                                      // NOTE: Uses ClipPath with circular holes to EXCLUDE icon button zones
                                      // This prevents vertical seams while keeping buttons' glass tone clean
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: SyraTopHazeWithHoles(
                                          height: topInset + 60.0,
                                          blurSigma: 8.0, // Subtle blur
                                          featherHeight: 35.0, // Soft fade
                                          scrimTopAlpha:
                                              0.08, // Very subtle darkening (Claude has almost none)
                                          scrimMidAlpha:
                                              0.02, // Almost transparent
                                          scrimMidStop:
                                              0.50, // Transition point
                                          whiteLiftAlpha:
                                              0.0, // No white lift (causes muddy look on dark bg)
                                          // Button hole positions
                                          leftButtonCenterX:
                                              36.0, // 16 padding + 20 radius
                                          rightButtonCenterX:
                                              36.0, // same from right
                                          buttonCenterY: topInset +
                                              28.0, // center of 56px bar
                                          holeRadius:
                                              20.0, // INCREASED: 20 button + 10 margin
                                        ),
                                      ),

                                      // Layer 7: ChatAppBar (transparent, sits on top of scrim)
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: ChatAppBar(
                                          selectedMode: _selectedMode,
                                          modeAnchorLink: _modeAnchorLink,
                                          onMenuTap: _toggleSidebar,
                                          onModeTap: _handleModeSelection,
                                          onPrivateChatTap: _togglePrivateChat,
                                          isPrivateMode: _isPrivateMode,
                                          isModeSelectorOpen:
                                              _isModeSelectorOpen,
                                          topPadding: topInset,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Removed: Full-screen loading overlay for relationship upload
                // Upload progress is now shown inside the sheet itself
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

  /// ═══════════════════════════════════════════════════════════════
  /// SCROLL-TO-BOTTOM BUTTON (ChatGPT-style centered glass button)
  /// ═══════════════════════════════════════════════════════════════
  Widget _buildScrollToBottomButton() {
    return GestureDetector(
      onTap: () {
        // Smooth scroll to bottom when tapped
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 24,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  /// ═══════════════════════════════════════════════════════════════
  /// PATCH C: Auto-select selfParticipant from "ben X'yim" patterns
  /// ═══════════════════════════════════════════════════════════════
  Future<void> _tryAutoSelectSelfParticipant(String message) async {
    // Only if active relationship exists
    final memory = await RelationshipMemoryService.getMemory();
    if (memory == null || memory.speakers.isEmpty) return;

    final messageLower = message.toLowerCase().trim();

    // GOAL 7: Auto-select A/B support
    // Check if user says "Ben A'yım" or "Ben B'yim"
    if (memory.speakers.length >= 2) {
      // Simple contains check for A/B
      if (messageLower.contains('ben a') &&
          (messageLower.contains('yim') || messageLower.contains('yım'))) {
        // User says A => selfParticipant = speakers[0]
        final success = await RelationshipMemoryService.updateParticipants(
          selfParticipant: memory.speakers[0],
          partnerParticipant: memory.speakers[1],
          relationshipId: memory.id,
        );
        if (success && mounted) {
          // GOAL 8: Remove toast
        }
        return;
      } else if (messageLower.contains('ben b') &&
          (messageLower.contains('yim') || messageLower.contains('yım'))) {
        // User says B => selfParticipant = speakers[1]
        final success = await RelationshipMemoryService.updateParticipants(
          selfParticipant: memory.speakers[1],
          partnerParticipant: memory.speakers[0],
          relationshipId: memory.id,
        );
        if (success && mounted) {
          // GOAL 8: Remove toast
        }
        return;
      }
    }

    // GOAL 7: Keep existing name-based matching
    // Simple string parsing instead of complex regex
    String? candidateName;

    // Try to extract name after "ben", "burda", or "ben burada"
    if (messageLower.contains('ben ')) {
      final benIndex = messageLower.indexOf('ben ');
      final afterBen = messageLower.substring(benIndex + 4).trim();

      // Extract first word
      final words = afterBen.split(RegExp(r'\s+'));
      if (words.isNotEmpty) {
        // Remove common suffixes
        candidateName = words[0]
            .replaceAll('\'yim', '')
            .replaceAll('\'ım', '')
            .replaceAll('\'im', '')
            .replaceAll('\'um', '')
            .replaceAll('\'üm', '')
            .replaceAll('yim', '')
            .replaceAll('ım', '')
            .replaceAll('im', '')
            .replaceAll('um', '')
            .replaceAll('üm', '')
            .trim();
      }
    } else if (messageLower.contains('burda ')) {
      final burdaIndex = messageLower.indexOf('burda ');
      final afterBurda = messageLower.substring(burdaIndex + 6).trim();
      final words = afterBurda.split(RegExp(r'\s+'));
      if (words.isNotEmpty) {
        candidateName = words[0]
            .replaceAll('\'yim', '')
            .replaceAll('\'ım', '')
            .replaceAll('\'im', '')
            .replaceAll('\'um', '')
            .replaceAll('\'üm', '')
            .replaceAll('yim', '')
            .replaceAll('ım', '')
            .replaceAll('im', '')
            .replaceAll('um', '')
            .replaceAll('üm', '')
            .trim();
      }
    }

    if (candidateName == null || candidateName.isEmpty) return;

    // Match against participant speakers (case-insensitive)
    String? matchedParticipant;
    for (final speaker in memory.speakers) {
      if (speaker.toLowerCase() == candidateName.toLowerCase() ||
          speaker.toLowerCase().contains(candidateName.toLowerCase())) {
        matchedParticipant = speaker;
        break;
      }
    }

    if (matchedParticipant == null) return;

    // Save selection and update Firestore
    final success = await RelationshipMemoryService.updateParticipants(
      selfParticipant: matchedParticipant,
      partnerParticipant: memory.speakers.firstWhere(
        (s) => s != matchedParticipant,
        orElse: () => '',
      ),
      relationshipId: memory.id,
    );

    if (success && mounted) {
      // GOAL 8: Remove toast for auto-select confirmation
    }
  }
}

// RELATIONSHIP PANEL SHEET (Filled State)
// ═══════════════════════════════════════════════════════════════
class _RelationshipPanelSheet extends StatefulWidget {
  final RelationshipMemory? memory; // Nullable - can be null initially
  final VoidCallback? onDelete;
  final Function(RelationshipMemory)? onMemoryUpdated;

  // Background upload state (from parent)
  final bool isUploadingInBackground;
  final String uploadStatus;
  final double? uploadProgress;
  final bool showMismatchCard;
  final String mismatchReason;
  final VoidCallback onUploadTap;
  final VoidCallback onMismatchNew;
  final VoidCallback onMismatchForceUpdate;
  final VoidCallback onMismatchCancel;
  final int refreshTrigger; // Increment to force refresh

  const _RelationshipPanelSheet({
    this.memory,
    this.onDelete,
    this.onMemoryUpdated,
    required this.isUploadingInBackground,
    required this.uploadStatus,
    this.uploadProgress,
    required this.showMismatchCard,
    required this.mismatchReason,
    required this.onUploadTap,
    required this.onMismatchNew,
    required this.onMismatchForceUpdate,
    required this.onMismatchCancel,
    required this.refreshTrigger,
  });

  @override
  State<_RelationshipPanelSheet> createState() =>
      _RelationshipPanelSheetState();
}

class _RelationshipPanelSheetState extends State<_RelationshipPanelSheet>
    with SingleTickerProviderStateMixin {
  RelationshipMemory? _displayMemory; // Current memory being displayed
  bool _isActive = false;
  bool _isUpdating = false;

  // Self participant selection
  String? _selectedSelfParticipant;

  // Typewriter animation
  String _animatedSummary = '';
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _displayMemory = widget.memory;
    _isActive = widget.memory?.isActive ?? false;
    _loadSelectedSelfParticipant();
    _loadLatestMemory();
  }

  @override
  void didUpdateWidget(_RelationshipPanelSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Refresh when trigger changes (indicates state update from parent)
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _loadLatestMemory();
    }
  }

  Future<void> _loadLatestMemory() async {
    final memory =
        await RelationshipMemoryService.getMemory(forceIncludeInactive: true);
    if (mounted && memory != null) {
      final isNewMemory = _displayMemory == null ||
          _displayMemory!.id != memory.id ||
          _displayMemory!.shortSummary != memory.shortSummary;

      setState(() {
        _displayMemory = memory;
        _isActive = memory.isActive;

        // Start typewriter animation for new/updated memory
        if (isNewMemory && memory.shortSummary != null) {
          _animatedSummary = '';
          _isAnimating = true;
          _startTypewriterAnimation(memory.shortSummary!);
        } else {
          _animatedSummary = memory.shortSummary ?? '';
          _isAnimating = false;
        }
      });
    }
  }

  Future<void> _startTypewriterAnimation(String fullText) async {
    _isAnimating = true;
    final chars = fullText.split('');

    for (int i = 0; i < chars.length; i++) {
      if (!mounted || !_isAnimating) break;

      await Future.delayed(const Duration(milliseconds: 20));

      if (mounted) {
        setState(() {
          _animatedSummary = fullText.substring(0, i + 1);
        });
      }
    }

    if (mounted) {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  @override
  void dispose() {
    _isAnimating = false; // Stop animation
    super.dispose();
  }

  Future<void> _loadSelectedSelfParticipant() async {
    final selected =
        await RelationshipMemoryService.getSelectedSelfParticipant();
    if (mounted) {
      setState(() {
        _selectedSelfParticipant = selected;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE HANDLER (Chat'te kullan)
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleToggle(bool value) async {
    if (_displayMemory == null || _displayMemory!.id == null) {
      BlurToast.show(context, 'İlişki ID bulunamadı');
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    bool success = false;

    if (value) {
      // Turning ON: Set activeRelationshipId and isActive=true
      await RelationshipMemoryService.setActiveRelationship(
          _displayMemory!.id!);
      success = await RelationshipMemoryService.updateIsActive(value,
          relationshipId: _displayMemory!.id!);
    } else {
      // Turning OFF: Clear activeRelationshipId and set isActive=false
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'activeRelationshipId': null});
      }
      success = await RelationshipMemoryService.updateIsActive(value,
          relationshipId: _displayMemory!.id!);
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _isActive = value;
        _isUpdating = false;
      });

      // Update display memory
      final updatedMemory =
          await RelationshipMemoryService.getMemoryById(_displayMemory!.id!);
      if (mounted && updatedMemory != null) {
        setState(() {
          _displayMemory = updatedMemory;
        });
        widget.onMemoryUpdated?.call(updatedMemory);
      }
    } else {
      setState(() {
        _isUpdating = false;
      });
      BlurToast.show(context, 'Bir hata oluştu, lütfen tekrar deneyin');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE/FORGET HANDLER
  // ═══════════════════════════════════════════════════════════════

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

    final success = await RelationshipMemoryService.deleteMemory(
      relationshipId: _displayMemory?.id,
      permanentDelete: true,
    );

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      widget.onDelete?.call();
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context);
        BlurToast.show(context, 'İlişki bilgileri silindi');
      }
    } else {
      BlurToast.show(context, 'Silme işlemi başarısız oldu');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SELF PARTICIPANT SELECTION
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleSelfParticipantSelection(String participantName) async {
    if (_displayMemory == null) return;

    setState(() {
      _selectedSelfParticipant = participantName;
    });

    // Save to SharedPreferences (single source of truth)
    await RelationshipMemoryService.setSelectedSelfParticipant(participantName);

    // Best-effort: persist to Firestore
    if (_displayMemory!.id != null && _displayMemory!.speakers.length == 2) {
      final partnerParticipant = _displayMemory!.speakers.firstWhere(
        (s) => s != participantName,
        orElse: () => '',
      );

      if (partnerParticipant.isNotEmpty) {
        await RelationshipMemoryService.persistParticipantMapping(
          relationshipId: _displayMemory!.id!,
          selfParticipant: participantName,
          partnerParticipant: partnerParticipant,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Upload Progress (if uploading - from parent)
            if (widget.isUploadingInBackground) ...[
              _buildUploadProgress(),
              const SizedBox(height: 16),
            ],

            // Mismatch Decision Card (if mismatch detected - from parent)
            if (widget.showMismatchCard) ...[
              _buildMismatchCard(),
              const SizedBox(height: 16),
            ],

            // Active Toggle (always show, but disabled if no memory)
            _buildActiveToggleRow(),
            const SizedBox(height: 12),

            // ZIP Upload / Update Row
            _buildUploadRow(),
            const SizedBox(height: 12),

            // Self Participant Picker (always show, but disabled if no memory)
            _buildSelfParticipantSection(),
            const SizedBox(height: 12),

            // Memory Summary (if exists) - with typewriter animation
            if (_displayMemory != null) ...[
              _buildMemorySummary(),
              const SizedBox(height: 16),
            ],

            // Forget Button (if memory exists)
            if (_displayMemory != null) ...[
              _buildForgetButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SyraTokens.accent.withValues(alpha: 0.15),
                SyraTokens.accent.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SyraTokens.accent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.favorite_outline_rounded,
            color: SyraTokens.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'İlişki Ayarları',
            style: TextStyle(
              color: SyraTokens.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraTokens.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SyraTokens.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.uploadStatus,
                  style: const TextStyle(
                    color: SyraTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (widget.uploadProgress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: widget.uploadProgress,
              backgroundColor: SyraTokens.border,
              valueColor: const AlwaysStoppedAnimation(SyraTokens.accent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMismatchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Farklı İlişki Tespit Edildi',
                  style: TextStyle(
                    color: SyraTokens.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.mismatchReason,
            style: const TextStyle(
              color: SyraTokens.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMismatchButton(
                  'Yeni ilişki',
                  Icons.add_circle_outline,
                  widget.onMismatchNew,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMismatchButton(
                  'Yine de güncelle',
                  Icons.sync_rounded,
                  widget.onMismatchForceUpdate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: widget.onMismatchCancel,
              style: TextButton.styleFrom(
                foregroundColor: SyraTokens.textMuted,
              ),
              child: const Text('İptal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMismatchButton(String text, IconData icon, VoidCallback onTap) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: SyraTokens.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: SyraTokens.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: SyraTokens.accent, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: SyraTokens.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadRow() {
    final hasMemory = _displayMemory != null;
    final title = hasMemory ? 'Sohbeti Güncelle (Yeni ZIP)' : 'ZIP Yükle';

    return _TapScale(
      onTap: widget.isUploadingInBackground ? null : widget.onUploadTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SyraTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SyraTokens.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasMemory ? Icons.sync_rounded : Icons.upload_file_rounded,
                  color: SyraTokens.accent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: SyraTokens.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SyraTokens.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'WhatsApp → Kişi → Profil → Sohbeti dışa aktar → Medya ekleme — SYRA\n(ZIP Dosyalar\'da kalır; buradan seçip yükle.)',
              style: TextStyle(
                color: SyraTokens.textMuted,
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveToggleRow() {
    final hasMemory = _displayMemory != null;
    final isDisabled = !hasMemory || _isUpdating;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SyraTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraTokens.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat\'te kullan',
                  style: TextStyle(
                    color: isDisabled
                        ? SyraTokens.textMuted
                        : SyraTokens.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasMemory
                      ? 'SYRA bu ilişkiyi sohbetlerde arka plan bilgisi olarak kullanır'
                      : 'Henüz ilişki yüklenmedi. ZIP yükleyince aktif edilecek.',
                  style: TextStyle(
                    color: SyraTokens.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Opacity(
            opacity: isDisabled ? 0.4 : 1.0,
            child: GestureDetector(
              onTap: isDisabled ? null : () => _handleToggle(!_isActive),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _isActive && hasMemory
                      ? SyraTokens.accent
                      : SyraTokens.surface,
                  border: Border.all(
                    color: _isActive && hasMemory
                        ? SyraTokens.accent
                        : SyraTokens.border,
                    width: 1.5,
                  ),
                  boxShadow: _isActive && hasMemory
                      ? [
                          BoxShadow(
                            color: SyraTokens.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment:
                      _isActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isUpdating
                        ? const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SyraTokens.accent,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfParticipantSection() {
    final hasMemory =
        _displayMemory != null && _displayMemory!.speakers.length >= 2;
    final speakers = hasMemory ? _displayMemory!.speakers : <String>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SyraTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SyraTokens.border.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu sohbette sen hangisisin?',
            style: TextStyle(
              color: hasMemory ? SyraTokens.textPrimary : SyraTokens.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasMemory
                ? 'İsmini seçerek SYRA\'ya kim olduğunu göster'
                : 'İlişki yüklenince participant seçimi buradan yapılabilecek',
            style: TextStyle(
              color: SyraTokens.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          if (hasMemory) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: speakers.map((speaker) {
                final isSelected = _selectedSelfParticipant == speaker;
                return _TapScale(
                  onTap: () => _handleSelfParticipantSelection(speaker),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SyraTokens.accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? SyraTokens.accent : SyraTokens.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.check_circle,
                              color: SyraTokens.accent,
                              size: 16,
                            ),
                          ),
                        Text(
                          speaker,
                          style: TextStyle(
                            color: isSelected
                                ? SyraTokens.accent
                                : SyraTokens.textPrimary,
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemorySummary() {
    return AnimatedOpacity(
      opacity: _displayMemory != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SyraTokens.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SyraTokens.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typewriter animated text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _animatedSummary.isEmpty
                        ? (_displayMemory?.shortSummary ?? 'Özet mevcut değil')
                        : _animatedSummary,
                    style: const TextStyle(
                      color: SyraTokens.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Blinking cursor while animating
                if (_isAnimating)
                  Padding(
                    padding: const EdgeInsets.only(left: 2, top: 2),
                    child: _BlinkingCursor(),
                  ),
              ],
            ),
            if (_displayMemory!.dateRangeFormatted.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _displayMemory!.dateRangeFormatted,
                style: TextStyle(
                  color: SyraTokens.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForgetButton() {
    return Center(
      child: TextButton(
        onPressed: _isUpdating ? null : _handleDelete,
        child: Text(
          'Bu ilişkiyi unut',
          style: TextStyle(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
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

// Blinking cursor for typewriter animation
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 16,
        decoration: BoxDecoration(
          color: SyraTokens.accent,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
