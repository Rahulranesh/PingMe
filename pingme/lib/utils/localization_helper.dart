import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Helper extension to easily access localization strings
extension LocalizationHelper on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Example usage:
/// 
/// Instead of hardcoded strings:
/// Text('Welcome')
/// 
/// Use localization:
/// Text(context.l10n.welcome)
/// 
/// For strings with parameters:
/// Text(context.l10n.fromUser('John'))
/// Text(context.l10n.lastSeen('2 hours ago'))
