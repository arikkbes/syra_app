import 'package:flutter/material.dart';
import '../services/firestore_user.dart';
import '../theme/syra_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// CHAT BEHAVIOR SCREEN - FIXED
/// ═══════════════════════════════════════════════════════════════
/// ✅ Now saves settings to Firestore
/// ✅ Settings are applied in ChatService and backend
/// ═══════════════════════════════════════════════════════════════

class ChatBehaviorScreen extends StatefulWidget {
  const ChatBehaviorScreen({super.key});

  @override
  State<ChatBehaviorScreen> createState() => _ChatBehaviorScreenState();
}

class _ChatBehaviorScreenState extends State<ChatBehaviorScreen> {
  String _tone = "default";
  String _replyLength = "default";
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await FirestoreUser.getSettings();
      
      if (!mounted) return;
      
      setState(() {
        _tone = settings['botCharacter'] ?? 'default';
        _replyLength = settings['replyLength'] ?? 'default';
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);

    try {
      await FirestoreUser.saveSettings(
        botCharacter: _tone,
        replyLength: _replyLength,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyraColors.background,
      appBar: AppBar(
        backgroundColor: SyraColors.background,
        elevation: 0,
        title: const Text(
          "Sohbet Davranışı",
          style: TextStyle(
            color: SyraColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: SyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: SyraColors.accent,
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          "SYRA'nın sana nasıl konuşacağını özelleştir. Bu ayarlar tüm cihazlarda geçerli olur.",
                          style: TextStyle(
                            fontSize: 13,
                            color: SyraColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // TONE SELECTION
                        _buildSectionTitle("Konuşma Tonu"),
                        const SizedBox(height: 12),
                        _buildToneOption(
                          'default',
                          'Varsayılan',
                          'Duruma göre otomatik ton',
                        ),
                        _buildToneOption(
                          'professional',
                          'Profesyonel',
                          'Ölçülü ve saygılı dil',
                        ),
                        _buildToneOption(
                          'friendly',
                          'Samimi',
                          'Arkadaşça ve rahat ton',
                        ),
                        _buildToneOption(
                          'direct',
                          'Direkt',
                          'Açık sözlü ve filtresiz',
                        ),

                        const SizedBox(height: 24),

                        // MESSAGE LENGTH
                        _buildSectionTitle("Mesaj Uzunluğu"),
                        const SizedBox(height: 12),
                        _buildLengthOption(
                          'short',
                          'Kısa & Net',
                          'Maximum 2-3 cümle',
                        ),
                        _buildLengthOption(
                          'default',
                          'Dengeli',
                          'Orta uzunlukta cevaplar',
                        ),
                        _buildLengthOption(
                          'detailed',
                          'Detaylı',
                          'Kapsamlı açıklamalar',
                        ),

                        const SizedBox(height: 32),

                        // INFO
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: SyraColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SyraColors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: SyraColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Bu ayarlar bir sonraki mesajından itibaren geçerli olacak.',
                                  style: TextStyle(
                                    color: SyraColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SAVE BUTTON
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SyraColors.background,
                      border: Border(
                        top: BorderSide(
                          color: SyraColors.divider,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SyraColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Kaydet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: SyraColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildToneOption(String value, String title, String subtitle) {
    final isSelected = _tone == value;

    return GestureDetector(
      onTap: () => setState(() => _tone = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? SyraColors.accent.withOpacity(0.1)
              : SyraColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SyraColors.accent : SyraColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: SyraColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLengthOption(String value, String title, String subtitle) {
    final isSelected = _replyLength == value;

    return GestureDetector(
      onTap: () => setState(() => _replyLength = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? SyraColors.accent.withOpacity(0.1)
              : SyraColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SyraColors.accent : SyraColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: SyraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: SyraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: SyraColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
