import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  
  // Feedback callbacks
  final Function(Map<String, dynamic>)? onCopyMessage;
  final Function(Map<String, dynamic>, String?)? onFeedbackChanged;

  // Layout props
  final double headerHeight;
  final double bottomOverlayHeight;

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
    this.onCopyMessage,
    this.onFeedbackChanged,
    this.headerHeight = 56.0,
    this.bottomOverlayHeight = 0.0,
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
              color: SyraColors.accent.withValues(alpha: 0.3),
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        SyraColors.accent.withValues(alpha: 0.2),
                        SyraColors.accent.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SyraColors.accent.withValues(alpha: 0.2),
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
                        color: SyraColors.accent.withValues(alpha: 0.5),
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
              style: SyraTextStyles.displayMedium.copyWith(
                fontSize: 24,
                color: isTarotMode ? SyraColors.accent : SyraColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              isTarotMode
                  ? "İstersen önce birkaç cümleyle durumu anlat."
                  : "Mesajını, ilişkinizi ya da aklındaki soruyu anlat.",
              style: SyraTextStyles.bodySmall.copyWith(
                color: SyraColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),

            // NOTE: Claude-style empty state should not show example prompts.
            // (User asked to remove the old placeholder suggestion texts.)
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    // Calculate dynamic bottom padding
    final bottomPadding = bottomOverlayHeight + 16;
    
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(12, headerHeight + 8, 12, bottomPadding),
      itemCount: messages.length + (isTyping ? 1 : 0),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        // Show logo pulse (waiting for assistant)
        if (isTyping && index == messages.length) {
          return _buildTypingIndicator();
        }

        final msg = messages[index];
        final isUser = msg["sender"] == "user";

        // Sender-aware spacing (ChatGPT style)
        // For first message (index 0), use minimal top margin
        final bool isSameSender =
            index > 0 && messages[index - 1]["sender"] == msg["sender"];
        final double topMargin = index == 0 
            ? 0.0  // First message: no extra top margin
            : (isSameSender ? 8.0 : 16.0);

        final bool isSwiped =
            swipedMessageId == msg["id"] && swipeOffset != 0.0;

        final double effectiveOffset = isSwiped
            ? Curves.easeOutCubic.transform(swipeOffset / 30).clamp(0.0, 1.0) *
                30
            : 0;

        return Padding(
          padding: EdgeInsets.only(top: topMargin),
          child: _AnimatedMessageItem(
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
                  // Feedback params (assistant only)
                  feedback: !isUser ? msg['feedback'] as String? : null,
                  onCopy: !isUser && onCopyMessage != null 
                      ? () => onCopyMessage!(msg) 
                      : null,
                  onFeedbackChanged: !isUser && onFeedbackChanged != null
                      ? (newFeedback) => onFeedbackChanged!(msg, newFeedback)
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Typing indicator - Logo pulse animation
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 16, bottom: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/syra_logo.png',
            width: 48,
            height: 48,
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(0.85, 0.85),
                duration: 1200.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
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
