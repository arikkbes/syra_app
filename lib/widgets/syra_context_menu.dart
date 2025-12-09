import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';

class SyraContextMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const SyraContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

class SyraContextMenu extends StatefulWidget {
  final List<SyraContextMenuItem> items;

  const SyraContextMenu({
    super.key,
    required this.items,
  });

  @override
  State<SyraContextMenu> createState() => _SyraContextMenuState();

  static Future<T?> show<T>({
    required BuildContext context,
    required List<SyraContextMenuItem> items,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => SyraContextMenu(items: items),
    );
  }
}

class _SyraContextMenuState extends State<SyraContextMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleClose,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(_scaleAnimation),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 320),
                decoration: BoxDecoration(
                  color: SyraColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: SyraColors.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < widget.items.length; i++) ...[
                      _buildMenuItem(widget.items[i]),
                      if (i < widget.items.length - 1)
                        Divider(
                          height: 1,
                          color: SyraColors.border.withValues(alpha: 0.2),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(SyraContextMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          item.onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: item.isDestructive
                    ? Colors.red.withValues(alpha: 0.9)
                    : SyraColors.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: item.isDestructive
                        ? Colors.red.withValues(alpha: 0.9)
                        : SyraColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
