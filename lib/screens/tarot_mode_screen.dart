import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../services/tarot_service.dart';
import '../widgets/blur_toast.dart';
import '../widgets/tarot_card_choice.dart';

/// ═══════════════════════════════════════════════════════════════
/// TAROT MODE SCREEN - CONVERSATIONAL EXPERIENCE
/// Chat-like interface for tarot readings and follow-up conversations
/// ═══════════════════════════════════════════════════════════════

enum TarotMessageType {
  systemWelcome,
  cardSelection,
  reading,
  userMessage,
  assistantMessage,
}

class TarotMessage {
  final TarotMessageType type;
  final String? text;
  final List<int>? selectedCards;
  final List<Map<String, dynamic>>? cardMeta;
  final DateTime timestamp;
  final String? selectionId; // Unique ID for card selections

  TarotMessage({
    required this.type,
    this.text,
    this.selectedCards,
    this.cardMeta,
    DateTime? timestamp,
    this.selectionId,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TarotModeScreen extends StatefulWidget {
  const TarotModeScreen({super.key});

  @override
  State<TarotModeScreen> createState() => _TarotModeScreenState();
}

class _TarotModeScreenState extends State<TarotModeScreen> {
  final List<TarotMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Current card selection state
  final Set<int> _selectedCards = {};
  bool _isCardSelectionActive = false;
  String? _currentSelectionId; // Track active card selection
  
  // Loading states
  bool _isLoadingReading = false;
  bool _isLoadingResponse = false;
  
  // Current reading context (for follow-up questions)
  String? _currentReadingText;
  List<Map<String, dynamic>>? _currentCardMeta;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeConversation() {
    // Welcome message from SYRA
    _messages.add(TarotMessage(
      type: TarotMessageType.systemWelcome,
      text: "Tarot moduna hoş geldin.\n\nAklındaki soruya odaklan – bir ilişki, bir kararsızlık, ya da içinde dönüp duran bir his. Hazır olduğunda kartlarını seç.",
    ));
    
    // Show card selection
    _showCardSelection();
  }

  void _showCardSelection() {
    final newSelectionId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _isCardSelectionActive = true;
      _selectedCards.clear();
      _currentSelectionId = newSelectionId;
      _messages.add(TarotMessage(
        type: TarotMessageType.cardSelection,
        selectionId: newSelectionId,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      appBar: AppBar(
        backgroundColor: SyraColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: SyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🔮 Tarot Mode',
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_currentReadingText != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: SyraColors.accent),
              onPressed: _startNewReading,
              tooltip: 'Yeni açılım',
            ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoadingReading || _isLoadingResponse ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildLoadingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          
          // Input area (only show after reading is done)
          if (_currentReadingText != null && !_isCardSelectionActive)
            _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(TarotMessage message) {
    switch (message.type) {
      case TarotMessageType.systemWelcome:
        return _buildSystemMessage(message.text!);
      case TarotMessageType.cardSelection:
        // Only render interactive if this is the current active selection
        final isActive = message.selectionId == _currentSelectionId;
        return _buildCardSelectionBubble(isActive: isActive);
      case TarotMessageType.reading:
        return _buildReadingMessage(message);
      case TarotMessageType.userMessage:
        return _buildUserMessage(message.text!);
      case TarotMessageType.assistantMessage:
        return _buildAssistantMessage(message.text!);
    }
  }

  Widget _buildSystemMessage(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: SyraColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SyraColors.border.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: SyraColors.accent, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: SyraColors.textSecondary.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSelectionBubble({bool isActive = true}) {
    final displayedSelectedCards = isActive ? _selectedCards : <int>{};
    
    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !isActive,
        child: Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TarotCardChoice(
                    cardId: 0,
                    label: 'The Fool',
                    isSelected: displayedSelectedCards.contains(0),
                    isActive: isActive && _isCardSelectionActive,
                    onTap: () => _handleCardTap(0),
                  ),
                  TarotCardChoice(
                    cardId: 6,
                    label: 'The Lovers',
                    isSelected: displayedSelectedCards.contains(6),
                    isActive: isActive && _isCardSelectionActive,
                    onTap: () => _handleCardTap(6),
                  ),
                  TarotCardChoice(
                    cardId: 16,
                    label: 'The Tower',
                    isSelected: displayedSelectedCards.contains(16),
                    isActive: isActive && _isCardSelectionActive,
                    onTap: () => _handleCardTap(16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Kartlarını seç (1-3 kart)',
                  style: TextStyle(
                    color: SyraColors.textMuted.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (isActive && displayedSelectedCards.isNotEmpty && _isCardSelectionActive)
                GestureDetector(
                  onTap: _handleStartReading,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [SyraColors.accent, SyraColors.accentLight],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: SyraColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Okumayı Başlat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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

  void _handleCardTap(int cardId) {
    if (!_isCardSelectionActive) return;
    setState(() {
      if (_selectedCards.contains(cardId)) {
        _selectedCards.remove(cardId);
      } else {
        _selectedCards.add(cardId);
      }
    });
  }

  Widget _buildReadingMessage(TarotMessage message) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card info chip
          if (message.cardMeta != null && message.cardMeta!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 6,
                children: message.cardMeta!.map((card) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: SyraColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: SyraColors.accent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      card['name']?.toString() ?? '',
                      style: const TextStyle(
                        color: SyraColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Reading bubble
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SyraColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SyraColors.accent.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: SyraColors.accent.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.text!,
              style: TextStyle(
                color: SyraColors.textPrimary.withOpacity(0.95),
                fontSize: 15,
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: 40),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SyraColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SyraColors.accent.withOpacity(0.3),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: SyraColors.textPrimary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, right: 40),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SyraColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SyraColors.border),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: SyraColors.textPrimary.withOpacity(0.95),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, right: 40),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SyraColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SyraColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(SyraColors.accent.withOpacity(0.6)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Yazıyor...',
                style: TextStyle(
                  color: SyraColors.textMuted.withOpacity(0.8),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyraColors.surface,
        border: Border(
          top: BorderSide(color: SyraColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: SyraColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: SyraColors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(
                    color: SyraColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Bu okuma hakkında bir şey sor...',
                    hintStyle: TextStyle(
                      color: SyraColors.textMuted.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _handleSendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SyraColors.accent, SyraColors.accentLight],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartReading() async {
    if (_selectedCards.isEmpty || _isLoadingReading) return;

    setState(() {
      _isCardSelectionActive = false;
      _isLoadingReading = true;
    });
    
    _scrollToBottom();

    try {
      final sortedCards = _selectedCards.toList()..sort();
      final response = await TarotService.getTarotReading(selectedCards: sortedCards);
      
      // Parse response
      Map<String, dynamic>? parsedResponse;
      String? readingText;
      List<Map<String, dynamic>>? cardMeta;
      
      try {
        parsedResponse = jsonDecode(response);
        
        // Check for errors
        if (parsedResponse != null) {
          if (parsedResponse['success'] == false || parsedResponse['reading'] == null) {
            throw Exception(parsedResponse['message'] ?? 'Okuma alınamadı');
          }
          
          readingText = parsedResponse['reading'];
          if (parsedResponse['cards'] is List) {
            cardMeta = List<Map<String, dynamic>>.from(parsedResponse['cards']);
          }
        }
      } catch (e) {
        // If not JSON or parsing failed, treat whole response as reading
        if (response.contains('{') && response.contains('reading')) {
          rethrow; // Re-throw if it was a structured error
        }
        readingText = response;
      }

      if (!mounted) return;

      setState(() {
        _isLoadingReading = false;
        _currentReadingText = readingText;
        _currentCardMeta = cardMeta;
        
        _messages.add(TarotMessage(
          type: TarotMessageType.reading,
          text: readingText!,
          selectedCards: sortedCards,
          cardMeta: cardMeta,
        ));
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Tarot reading error: $e');
      
      if (!mounted) return;

      setState(() {
        _isLoadingReading = false;
        _isCardSelectionActive = true; // Re-enable card selection on error
      });

      if (mounted) {
        BlurToast.show(context, e.toString().contains('Exception:') 
            ? e.toString().replaceAll('Exception: ', '')
            : "Okuma yapılırken bir hata oluştu. Tekrar dene.");
      }
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoadingResponse) return;

    // Add user message
    setState(() {
      _messages.add(TarotMessage(
        type: TarotMessageType.userMessage,
        text: text,
      ));
      _isLoadingResponse = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Call backend with tarot context
      final response = await TarotService.followUpQuestion(
        question: text,
        readingContext: _currentReadingText!,
        cardMeta: _currentCardMeta,
      );

      if (!mounted) return;

      setState(() {
        _isLoadingResponse = false;
        _messages.add(TarotMessage(
          type: TarotMessageType.assistantMessage,
          text: response,
        ));
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('Follow-up question error: $e');
      
      if (!mounted) return;

      setState(() {
        _isLoadingResponse = false;
        _messages.add(TarotMessage(
          type: TarotMessageType.assistantMessage,
          text: "Bir hata oluştu. Tekrar dene.",
        ));
      });

      _scrollToBottom();
    }
  }

  void _startNewReading() {
    setState(() {
      _currentReadingText = null;
      _currentCardMeta = null;
      _messages.add(TarotMessage(
        type: TarotMessageType.systemWelcome,
        text: "Yeni bir açılım için kartlarını seç.",
      ));
    });
    _showCardSelection();
  }
}
