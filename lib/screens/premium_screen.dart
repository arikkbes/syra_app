import 'package:flutter/material.dart';

import '../theme/syra_theme.dart';
import '../utils/subscription_flow.dart';

/// Legacy route wrapper.
/// Keeps `/premium` route alive while redirecting to new paywall sheet.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await openPaywallSheet(context, initialTab: SubscriptionTab.core);
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SyraColors.background,
      body: SizedBox.shrink(),
    );
  }
}
