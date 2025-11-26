import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════
// DATE FORMAT UTILITIES
// ═══════════════════════════════════════════════════════════════
// Tarih formatlama yardımcı fonksiyonları
// ═══════════════════════════════════════════════════════════════

class DateFormatUtils {
  // ─────────────────────────────────────────────────────────────
  // Chat session listesi için "Bugün", "Dün", "5 Şubat" formatı
  // ─────────────────────────────────────────────────────────────
  static String formatChatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return "Bugün";
    } else if (dateOnly == yesterday) {
      return "Dün";
    } else if (now.difference(date).inDays < 7) {
      // Son 7 gün için gün ismi
      return _getTurkishWeekday(date.weekday);
    } else if (date.year == now.year) {
      // Bu yıl ise sadece gün + ay
      return "${date.day} ${_getTurkishMonth(date.month)}";
    } else {
      // Eski tarih ise tam tarih
      return "${date.day} ${_getTurkishMonth(date.month)} ${date.year}";
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Detaylı zaman formatı: "14:35" veya "Dün 14:35"
  // ─────────────────────────────────────────────────────────────
  static String formatMessageTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final timeStr = DateFormat('HH:mm').format(date);

    if (dateOnly == today) {
      return timeStr;
    } else if (dateOnly == yesterday) {
      return "Dün $timeStr";
    } else {
      return "${formatChatDate(date)} $timeStr";
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Relative time: "2 dakika önce", "5 saat önce"
  // ─────────────────────────────────────────────────────────────
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return "Şimdi";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} dakika önce";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} saat önce";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} gün önce";
    } else {
      return formatChatDate(date);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Türkçe ay isimleri
  // ─────────────────────────────────────────────────────────────
  static String _getTurkishMonth(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return months[month - 1];
  }

  // ─────────────────────────────────────────────────────────────
  // Türkçe gün isimleri
  // ─────────────────────────────────────────────────────────────
  static String _getTurkishWeekday(int weekday) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    return days[weekday - 1];
  }
}
