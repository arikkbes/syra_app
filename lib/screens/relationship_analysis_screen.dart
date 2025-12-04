import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// RELATIONSHIP ANALYSIS SCREEN
/// ═══════════════════════════════════════════════════════════════
/// İlişki analizi ekranı - Durum özeti girişi ve analiz.
/// ═══════════════════════════════════════════════════════════════

class RelationshipAnalysisScreen extends StatefulWidget {
  const RelationshipAnalysisScreen({super.key});

  @override
  State<RelationshipAnalysisScreen> createState() =>
      _RelationshipAnalysisScreenState();
}

class _RelationshipAnalysisScreenState
    extends State<RelationshipAnalysisScreen> {
  final TextEditingController _inputController = TextEditingController();
  String? _analysisResult;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleAnalyze() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisResult = _generateDummyAnalysis(text);
      });
    });
  }

  String _generateDummyAnalysis(String input) {
    return """📊 SYRA İlişki Analizi

🔍 Durum Özeti:
Anlattığın durumda karşı tarafın davranışları belirli bir örüntü gösteriyor. 

💡 Önemli Noktalar:
• İletişim stilinde tutarsızlıklar mevcut
• Duygusal mesafe alma eğilimi görülüyor
• Belirsizlik yaratma davranışı dikkat çekici

⚠️ Dikkat Edilmesi Gerekenler:
• Karşı tarafın sözleri ile eylemleri arasındaki tutarlılığı gözlemle
• Kendi sınırlarını net bir şekilde koy
• Duygusal yatırımını dengeli tut

🎯 Öneriler:
1. Doğrudan ve açık iletişim kur
2. Beklentilerini net ifade et
3. Karşı tarafın tepkilerini dikkatle izle

---
Not: Bu analiz genel bir değerlendirmedir. Gerçek ilişki analizi için SYRA 1.1'de gelecek olan AI destekli derin analiz özelliğini bekle.""";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const SyraBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(),
                        const SizedBox(height: 20),
                        _buildInputSection(),
                        const SizedBox(height: 16),
                        _buildAnalyzeButton(),
                        if (_analysisResult != null) ...[
                          const SizedBox(height: 24),
                          _buildAnalysisResult(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF00D4FF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "SYRA analiz ediyor...",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: Color(0xFFB388FF),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "İlişki Analizi",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFB388FF).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFB388FF),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Konuşmayı veya durumu özetle",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "SYRA durumu analiz etsin ve sana içgörüler sunsun.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Durum Özeti",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            maxLines: 8,
            minLines: 5,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  "Karşı tarafla olan konuşmanı veya durumu buraya özetle...\n\nÖrneğin:\n- Son konuşmanızda neler oldu?\n- Seni rahatsız eden ne?\n- Karşı taraf nasıl davranıyor?",
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
                height: 1.5,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFB388FF),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    final hasText = _inputController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasText ? _handleAnalyze : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: hasText
              ? const LinearGradient(
                  colors: [Color(0xFFB388FF), Color(0xFF00D4FF)],
                )
              : null,
          color: hasText ? null : Colors.white.withValues(alpha: 0.1),
          boxShadow: hasText
              ? [
                  BoxShadow(
                    color: const Color(0xFFB388FF).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_rounded,
              color: hasText ? Colors.white : Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              "Analiz Et",
              style: TextStyle(
                color: hasText ? Colors.white : Colors.white.withValues(alpha: 0.4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFB388FF).withValues(alpha: 0.3),
                      const Color(0xFF00D4FF).withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF00D4FF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "SYRA Analizi",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _analysisResult!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
