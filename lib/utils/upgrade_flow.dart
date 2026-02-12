import 'package:flutter/material.dart';
import 'subscription_flow.dart';

Future<void> openUpgrade(
  BuildContext context, {
  BuildContext? hostContext,
  bool focusUpgradeSection = true,
}) {
  return openSettingsSheet(
    context,
    hostContext: hostContext,
    focusUpgradeSection: focusUpgradeSection,
  );
}
