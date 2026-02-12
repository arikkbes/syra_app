import 'package:flutter/material.dart';

import '../theme/syra_theme.dart';
import '../utils/subscription_flow.dart';

/// Legacy route wrapper.
/// Keeps `/premium-management` route alive while redirecting to new manage sheet.
class PremiumManagementScreen extends StatefulWidget {
  const PremiumManagementScreen({super.key});

  @override
  State<PremiumManagementScreen> createState() =>
      _PremiumManagementScreenState();
}

class _PremiumManagementScreenState extends State<PremiumManagementScreen> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await openManageSubscriptionSheet(context);
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
