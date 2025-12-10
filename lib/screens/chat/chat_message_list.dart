import 'package:flutter/material.dart';
import '../../theme/syra_theme.dart';
import '../../widgets/syra_message_bubble.dart';

/// Message list for ChatScreen
/// 
/// Displays:
/// - Empty state with suggestions when no messages
/// - Scrollable message list with typing indicator
/// - Swipe-to-reply gestures
class ChatMessageList extends StatelessWidget {
  // Empty state props
  final bool isEmpty;
  final bool isTarotMode;
  final Function(String) onSuggestionTap;

  // Message list props
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final bool isTyping;
  final String? swipedMessageId;
  final double swipeOffset;
  final Function(Map<String, dynamic>) onMessageLongPress;
  final Function(Map<String, dynamic>, double) onSwipeUpdate;
  final Function(Map<String, dynamic>, bool) onSwipeEnd;

  const ChatMessageList({
    super.key,
    required this.isEmpty,
    required this.isTarotMode,
    required this.onSuggestionTap,
    required this.messages,
    required this.scrollController,
    required this.isTyping,
    this.swipedMessageId,
    required this.swipeOffset,
    required this.onMessageLongPress,
    required this.onSwipeUpdate,
    required this.onSwipeEnd,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return _buildEmptyState();
    }
    return _buildMessageList();
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
              color: SyraColors.accent.withOpacity(0.3),
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        SyraColors.accent.withOpacity(0.2),
                        SyraColors.accent.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SyraColors.accent.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isTarotMode ? "🔮" : "S",
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        color: SyraColors.accent.withOpacity(0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Hero Title
            Text(
              isTarotMode ? "Kartlar hazır..." : "Bugün neyi çözüyoruz?",
              style: TextStyle(
                color:
                    isTarotMode ? SyraColors.accent : SyraColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              isTarotMode
                  ? "İstersen önce birkaç cümleyle durumu anlat."
                  : "Mesajını, ilişkinizi ya da aklındaki soruyu anlat.",
              style: const TextStyle(
                color: SyraColors.textMuted,
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
    final suggestions = isTarotMode
        ? [
            "Aşk hayatımla ilgili bir tarot açılımı yap",
            "Kariyer hedeflerim için ne diyor kartlar?",
          ]
        : [
            "Sevgilimin mesajını analiz et",
            "İlişkimde bir konu var, yardım eder misin?",
            "Bu durumda ne yapmalıyım?",
          ];

    return suggestions.map((text) {
      return GestureDetector(
        onTap: () => onSuggestionTap(text),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: SyraColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SyraColors.divider.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: SyraColors.textSecondary,
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
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: messages.length + (isTyping ? 1 : 0),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        if (isTyping && index == messages.length) {
          return _buildTypingIndicator();
        }

        final msg = messages[index];
        final isUser = msg["sender"] == "user";

        final bool isSwiped =
            swipedMessageId == msg["id"] && swipeOffset != 0.0;

        final double effectiveOffset = isSwiped
            ? Curves.easeOutCubic.transform(swipeOffset / 30).clamp(0.0, 1.0) *
                30
            : 0;

        return _AnimatedMessageItem(
          animationKey: ValueKey(msg["id"] ?? index),
          child: GestureDetector(
            onLongPress: () => onMessageLongPress(msg),
            onHorizontalDragUpdate: (details) {
              if (details.delta.dx > 0) {
                onSwipeUpdate(msg, details.delta.dx);
              }
            },
            onHorizontalDragEnd: (_) {
              onSwipeEnd(msg, swipeOffset > 18);
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
                onLongPress: () => onMessageLongPress(msg),
                imageUrl: msg["imageUrl"],
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
      padding: EdgeInsets.only(left: 4, top: 8, bottom: 8),
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
}

/// Animated message item wrapper for fade-in effect
class _AnimatedMessageItem extends StatefulWidget {
  final Widget child;
  final Key animationKey;

  const _AnimatedMessageItem({
    required this.animationKey,
    required this.child,
  });

  @override
  State<_AnimatedMessageItem> createState() => _AnimatedMessageItemState();
}

class _AnimatedMessageItemState extends State<_AnimatedMessageItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
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
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
