// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════
import 'package:intl/intl.dart';

class DateFormatUtils {
  // ─────────────────────────────────────────────────────────────
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
      return _getTurkishWeekday(date.weekday);
    } else if (date.year == now.year) {
      return "${date.day} ${_getTurkishMonth(date.month)}";
    } else {
      return "${date.day} ${_getTurkishMonth(date.month)} ${date.year}";
    }
  }

  // ─────────────────────────────────────────────────────────────
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
