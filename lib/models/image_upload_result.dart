/// ═══════════════════════════════════════════════════════════════
/// IMAGE UPLOAD RESULT MODEL
/// ═══════════════════════════════════════════════════════════════
/// Result wrapper for image upload operations
/// ═══════════════════════════════════════════════════════════════

class ImageUploadResult {
  final bool success;
  final String? downloadUrl;
  final String? userMessage;

  ImageUploadResult({
    required this.success,
    this.downloadUrl,
    this.userMessage,
  });

  factory ImageUploadResult.success(String downloadUrl) {
    return ImageUploadResult(
      success: true,
      downloadUrl: downloadUrl,
    );
  }

  factory ImageUploadResult.failure(String message) {
    return ImageUploadResult(
      success: false,
      userMessage: message,
    );
  }
}
