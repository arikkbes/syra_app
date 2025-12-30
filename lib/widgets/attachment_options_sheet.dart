// lib/widgets/attachment_options_sheet.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import '../theme/syra_theme.dart';
import '../theme/syra_glass.dart';
import '../theme/syra_animations.dart';

/// ═══════════════════════════════════════════════════════════════
/// MODERN ATTACHMENT OPTIONS SHEET
/// ═══════════════════════════════════════════════════════════════
/// ChatGPT/Claude-style attachment picker:
/// - Recent photos gallery preview
/// - Camera option
/// - File picker option
/// - Smooth animations
/// - Glass morphism design
/// ═══════════════════════════════════════════════════════════════

class AttachmentOptionsSheet extends StatefulWidget {
  final Function(File) onImageSelected;
  final VoidCallback? onFileTap;

  const AttachmentOptionsSheet({
    super.key,
    required this.onImageSelected,
    this.onFileTap,
  });

  @override
  State<AttachmentOptionsSheet> createState() => _AttachmentOptionsSheetState();
}

class _AttachmentOptionsSheetState extends State<AttachmentOptionsSheet>
    with SingleTickerProviderStateMixin {
  List<AssetEntity> _recentPhotos = [];
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: SyraAnimation.normal,
    );
    _animController.forward();
    _loadRecentPhotos();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentPhotos() async {
    try {
      final PermissionState permission =
          await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        setState(() => _isLoading = false);
        return;
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final List<AssetEntity> recent = await albums.first.getAssetListPaged(
        page: 0,
        size: 12, // Show 12 recent photos
      );

      if (mounted) {
        setState(() {
          _recentPhotos = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImageFromAsset(AssetEntity asset) async {
    HapticFeedback.mediumImpact();
    final file = await asset.file;
    if (file != null && mounted) {
      Navigator.pop(context);
      widget.onImageSelected(file);
    }
  }

  Future<void> _openCamera() async {
    HapticFeedback.mediumImpact();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null && mounted) {
      Navigator.pop(context);
      widget.onImageSelected(File(image.path));
    }
  }

  Future<void> _openGallery() async {
    HapticFeedback.mediumImpact();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      Navigator.pop(context);
      widget.onImageSelected(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animController,
            curve: SyraAnimation.spring,
          )),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: SyraColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SyraRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: SyraSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SyraColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: SyraSpacing.md),

            // Action buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SyraSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: _openCamera,
                    ),
                  ),
                  SizedBox(width: SyraSpacing.md),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: _openGallery,
                    ),
                  ),
                  if (widget.onFileTap != null) ...[
                    SizedBox(width: SyraSpacing.md),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.insert_drive_file_rounded,
                        label: 'Dosya',
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          widget.onFileTap?.call();
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: SyraSpacing.lg),

            // Recent photos section
            if (!_isLoading && _recentPhotos.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: SyraSpacing.lg),
                child: Row(
                  children: [
                    Text(
                      'Son Fotoğraflar',
                      style: SyraTextStyles.labelMedium.copyWith(
                        color: SyraColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _openGallery,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: SyraSpacing.sm,
                          vertical: SyraSpacing.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Tümünü Gör',
                        style: SyraTextStyles.caption.copyWith(
                          color: SyraColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SyraSpacing.sm),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: SyraSpacing.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentPhotos.length,
                  itemBuilder: (context, index) {
                    return _buildPhotoThumbnail(_recentPhotos[index], index);
                  },
                ),
              ),
              SizedBox(height: SyraSpacing.lg),
            ] else if (_isLoading) ...[
              Padding(
                padding: EdgeInsets.symmetric(vertical: SyraSpacing.lg),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(SyraColors.accent),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(height: SyraSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION BUTTON (Camera, Gallery, File)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SyraRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: SyraGlass.blurMedium,
            sigmaY: SyraGlass.blurMedium,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: SyraSpacing.md),
            decoration: BoxDecoration(
              color: SyraColors.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(SyraRadius.lg),
              border: Border.all(
                color: SyraColors.border.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(SyraSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        SyraColors.accent.withValues(alpha: 0.2),
                        SyraColors.accent.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: SyraColors.accent,
                    size: 24,
                  ),
                ),
                SizedBox(height: SyraSpacing.xs),
                Text(
                  label,
                  style: SyraTextStyles.labelSmall.copyWith(
                    color: SyraColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PHOTO THUMBNAIL
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPhotoThumbnail(AssetEntity asset, int index) {
    return Padding(
      padding: EdgeInsets.only(
        right: index < _recentPhotos.length - 1 ? SyraSpacing.sm : 0,
      ),
      child: _TapScale(
        onTap: () => _pickImageFromAsset(asset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(SyraRadius.md),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: SyraColors.border.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(SyraRadius.md),
            ),
            child: FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(
                const ThumbnailSize(200, 200),
                quality: 90,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for depth
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Container(
                    color: SyraColors.surface,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: SyraColors.textMuted,
                        size: 32,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// TAP SCALE ANIMATION
/// ═══════════════════════════════════════════════════════════════

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

class _TapScaleState extends State<_TapScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SyraAnimation.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: SyraAnimation.emphasize,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
