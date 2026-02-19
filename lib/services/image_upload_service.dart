import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:syra/core/syra_log.dart';

/// ═══════════════════════════════════════════════════════════════
/// IMAGE UPLOAD SERVICE — Firebase Storage'a resim yükleme
/// ═══════════════════════════════════════════════════════════════
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Resmi Firebase Storage'a yükle ve URL'ini döndür
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        syraLog('ImageUploadService: User not logged in');
        return null;
      }

      // Unique dosya adı oluştur: user_uid/timestamp_random.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${user.uid}.jpg';
      final storageRef = _storage.ref().child('chat_images/${user.uid}/$fileName');

      // Dosyayı yükle
      final uploadTask = storageRef.putFile(imageFile);
      
      // Upload progress (opsiyonel - ileride progress bar için kullanılabilir)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        syraLog('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Upload tamamlanana kadar bekle
      final snapshot = await uploadTask;
      
      // Download URL'ini al
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      syraLog('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      syraLog('ImageUploadService error: $e');
      return null;
    }
  }

  /// Resmi sil (opsiyonel - kullanıcı mesajı silerse kullanılabilir)
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      syraLog('Image deleted successfully: $imageUrl');
    } catch (e) {
      syraLog('ImageUploadService deleteImage error: $e');
    }
  }
}
