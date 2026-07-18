# PingMe App Localization Guide

## 🌍 Supported Languages
- English (en) 🇺🇸
- Tamil (ta) 🇮🇳
- Hindi (hi) 🇮🇳  
- Japanese (ja) 🇯🇵

## 📋 Setup Complete
All localization files have been created and configured:
- `l10n.yaml` - Configuration file
- `lib/l10n/app_en.arb` - English translations
- `lib/l10n/app_ta.arb` - Tamil translations
- `lib/l10n/app_hi.arb` - Hindi translations
- `lib/l10n/app_ja.arb` - Japanese translations
- `lib/l10n/app_localizations.dart` - Generated localization class

## 🔧 How to Use Translations in Your Code

### 1. Import the Helper
```dart
import '../../utils/localization_helper.dart';
```

### 2. Simple Text Translation
```dart
// Instead of:
Text('Welcome')

// Use:
Text(context.l10n.welcome)
```

### 3. Text with Parameters
```dart
// For text with dynamic content:
Text(context.l10n.fromUser('John Doe'))
Text(context.l10n.lastSeen('2 hours ago'))
Text(context.l10n.chatRequestAcceptedBy('Sarah'))
```

### 4. In Widgets
```dart
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.appTitle),
    ),
    body: Column(
      children: [
        Text(context.l10n.welcome),
        ElevatedButton(
          onPressed: () {},
          child: Text(context.l10n.signIn),
        ),
      ],
    ),
  );
}
```

### 5. In SnackBars and Dialogs
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(context.l10n.profileUpdated),
  ),
);

showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(context.l10n.confirm),
    content: Text(context.l10n.logoutConfirmation),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      TextButton(
        onPressed: () {},
        child: Text(context.l10n.logout),
      ),
    ],
  ),
);
```

## 🎯 Available Translation Keys

### Authentication
- `signIn` - Sign In
- `signUp` - Sign Up
- `email` - Email
- `password` - Password
- `signInWithGoogle` - Sign in with Google
- `loginSuccessful` - Login successful!

### Navigation
- `home` - Home
- `chats` - Chats
- `discover` - Discover
- `profile` - Profile
- `settings` - Settings

### Chat Features
- `typeMessage` - Type a message...
- `send` - Send
- `online` - Online
- `offline` - Offline
- `typing` - typing...
- `lastSeen` - Last seen {time}

### Discovery
- `searchDevices` - Search for devices
- `scanning` - Scanning for devices...
- `noDevicesFound` - No devices found
- `connecting` - Connecting...
- `connected` - Connected

### Profile
- `editProfile` - Edit Profile
- `saveChanges` - Save Changes
- `bio` - Bio
- `status` - Status
- `profileUpdated` - Profile updated successfully

### Common Actions
- `yes` - Yes
- `no` - No
- `cancel` - Cancel
- `confirm` - Confirm
- `tryAgain` - Try Again
- `loading` - Loading...

## 🔄 To Add New Translations

1. Add the key-value pair in all `.arb` files:
   ```json
   // In app_en.arb
   "newFeature": "New Feature"
   
   // In app_ta.arb
   "newFeature": "புதிய அம்சம்"
   
   // In app_hi.arb
   "newFeature": "नई सुविधा"
   
   // In app_ja.arb
   "newFeature": "新機能"
   ```

2. Run to regenerate localization files:
   ```bash
   flutter gen-l10n
   ```

3. Use in your code:
   ```dart
   Text(context.l10n.newFeature)
   ```

## 🌐 Language Switching

The app uses `LanguageService` to manage language preferences. Users can switch languages from:
- Settings Screen
- Language Selection Screen

The selected language is persisted in SharedPreferences and applied across the entire app.

## 📱 Testing Different Languages

1. Go to Settings → Language
2. Select your preferred language
3. The entire app UI will update immediately

## ⚠️ Important Notes

1. Always use localized strings instead of hardcoded text
2. Remember to add translations for all supported languages when adding new strings
3. Run `flutter gen-l10n` after modifying `.arb` files
4. Test your UI in all languages to ensure proper text fitting
5. Use `overflow: TextOverflow.ellipsis` for potentially long translated text

## 🐛 Common Issues

### If translations aren't working:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter gen-l10n`
4. Restart your IDE

### If a translation is missing:
- The app will fall back to the key name
- Check all `.arb` files have the key defined
- Ensure you've run `flutter gen-l10n`

## 📚 Resources
- [Flutter Internationalization Guide](https://docs.flutter.dev/accessibility-and-localization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle)
