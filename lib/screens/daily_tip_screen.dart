import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/syra_theme.dart';
import '../widgets/glass_background.dart';

/// ═══════════════════════════════════════════════════════════════
/// DAILY TIP SCREEN
/// ═══════════════════════════════════════════════════════════════
/// Günlük tavsiye ekranı - Her gün yeni bir tavsiye.
/// ═══════════════════════════════════════════════════════════════

class DailyTipScreen extends StatefulWidget {
  const DailyTipScreen({super.key});

  @override
  State<DailyTipScreen> createState() => _DailyTipScreenState();
}

class _DailyTipScreenState extends State<DailyTipScreen> {
  final List<Map<String, dynamic>> _tips = [
    {
      "title": "Gizemini Koru",
      "tip": "Her şeyi anlatma. Biraz gizem bırak ki karşı taraf seni merak etsin. Sıradan olmak ilgiyi öldürür.",
      "icon": Icons.visibility_off_rounded,
      "color": const Color(0xFFB388FF),
    },
    {
      "title": "Enerji Yansıması",
      "tip": "İnsanlar sana verdiğin enerjiyi yansıtır. Pozitif ve enerjik ol, aynısını geri alırsın.",
      "icon": Icons.bolt_rounded,
      "color": const Color(0xFFFFD54F),
    },
    {
      "title": "Dinleme Sanatı",
      "tip": "Konuşmaktan çok dinle. İnsanlar kendilerini dinleyenleri sever. Gerçekten ilgilen.",
      "icon": Icons.hearing_rounded,
      "color": const Color(0xFF64B5F6),
    },
    {
      "title": "Kendi Değerin",
      "tip": "Kimseyi peşinden koşturma. Kendi değerini bil ve ona göre davran. Değerini bilmeyene değer verme.",
      "icon": Icons.diamond_rounded,
      "color": const Color(0xFFFF6B9D),
    },
    {
      "title": "Sabırlı Ol",
      "tip": "Aceleci davranma. İyi şeyler zaman alır. Sabırsızlık seni zayıf gösterir.",
      "icon": Icons.hourglass_bottom_rounded,
      "color": const Color(0xFF00D4FF),
    },
    {
      "title": "Beden Dili",
      "tip": "Dik dur, göz teması kur, gülümse. Beden dilin sözlerinden daha çok şey anlatır.",
      "icon": Icons.accessibility_new_rounded,
      "color": const Color(0xFF4DB6AC),
    },
  ];

  late int _currentTipIndex;

  @override
  void initState() {
    super.initState();
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _currentTipIndex = dayOfYear % _tips.length;
  }

  void _showRandomTip() {
    setState(() {
      int newIndex;
      do {
        newIndex = Random().nextInt(_tips.length);
      } while (newIndex == _currentTipIndex && _tips.length > 1);
      _currentTipIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_currentTipIndex];

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
                      children: [
                        const SizedBox(height: 20),
                        _buildMainTipCard(tip),
                        const SizedBox(height: 24),
                        _buildRefreshButton(),
                        const SizedBox(height: 32),
                        _buildAllTipsSection(),
                      ],
                    ),
                  ),
                ),
              ],
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
                        Icons.tips_and_updates_rounded,
                        color: Color(0xFFFF6B9D),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Günlük Tavsiye",
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

  Widget _buildMainTipCard(Map<String, dynamic> tip) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  (tip["color"] as Color).withValues(alpha: 0.3),
                  (tip["color"] as Color).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: (tip["color"] as Color).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              tip["icon"] as IconData,
              color: tip["color"] as Color,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tip["title"] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tip["tip"] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  "Bugünün Tavsiyesi",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: _showRandomTip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B9D).withValues(alpha: 0.2),
              const Color(0xFF00D4FF).withValues(alpha: 0.2),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              "Yeni Tavsiye Göster (Demo)",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Tüm Tavsiyeler",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...List.generate(_tips.length, (index) {
          final tip = _tips[index];
          final isSelected = index == _currentTipIndex;

          return Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTipIndex = index;
                });
              },
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (tip["color"] as Color).withValues(alpha: isSelected ? 0.25 : 0.12),
                      ),
                      child: Icon(
                        tip["icon"] as IconData,
                        color: (tip["color"] as Color).withValues(alpha: isSelected ? 1 : 0.6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        tip["title"] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: isSelected ? 1 : 0.7),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                        ),
                        child: const Text(
                          "Aktif",
                          style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
