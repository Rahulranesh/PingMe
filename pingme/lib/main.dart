import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/mdns_discovery_service.dart';
import 'services/chat_service.dart';
import 'services/profile_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/chat_request_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize authentication service to check existing session
  final authService = AuthService();
  await authService.initialize();
  
  // Initialize profile service to load existing profile
  // Use the singleton instance
  await ProfileService().initialize();
  
  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();
  
  // Initialize language service
  final languageService = LanguageService();
  await languageService.initialize();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: ProfileService()),
        ChangeNotifierProvider(create: (_) => MDNSDiscoveryService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => ChatRequestService()),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: languageService),
      ],
      child: const PingMeApp(),
    ),
  );
}

class PingMeApp extends StatelessWidget {
  const PingMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthService, ThemeService, LanguageService>(
      builder: (context, authService, themeService, languageService, _) {
        return MaterialApp(
          title: 'PingMe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          locale: languageService.locale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('ta'), // Tamil
            Locale('hi'), // Hindi
            Locale('ja'), // Japanese
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: authService.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
