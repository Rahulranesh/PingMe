import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  SharedPreferences? _prefs;
  String _currentLanguage = 'en';
  
  // Supported languages
  static const Map<String, Map<String, String>> _languages = {
    'en': {
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
    },
    'ta': {
      'name': 'Tamil',
      'nativeName': 'தமிழ்',
      'flag': '🇮🇳',
    },
    'hi': {
      'name': 'Hindi',
      'nativeName': 'हिंदी',
      'flag': '🇮🇳',
    },
    'ja': {
      'name': 'Japanese',
      'nativeName': '日本語',
      'flag': '🇯🇵',
    },
  };

  // Translations
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'app_name': 'PingMe',
      'chat': 'Chat',
      'discovery': 'Discovery',
      'profile': 'Profile',
      'settings': 'Settings',
      'send_message': 'Send message...',
      'online': 'Online',
      'offline': 'Offline',
      'connecting': 'Connecting...',
      'connected': 'Connected',
      'send_chat_request': 'Send Chat Request',
      'chat_request': 'Chat Request',
      'accept': 'Accept',
      'decline': 'Decline',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'notifications': 'Notifications',
      'terms_of_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'about': 'About',
      'sign_out': 'Sign Out',
      'appearance': 'Appearance',
      'switch_theme': 'Switch between light and dark themes',
      'push_notifications': 'Push Notifications',
      'receive_notifications': 'Receive notifications for messages',
      'sound': 'Sound',
      'play_sound': 'Play sound for notifications',
      'vibration': 'Vibration',
      'vibrate_notifications': 'Vibrate for notifications',
      'app_language': 'App language',
      'welcome_to_pingme': 'Welcome to PingMe',
      'connect_instantly': 'Connect instantly with people nearby',
      'sign_in_google': 'Sign in with Google',
      'enter_name': 'Enter your name',
      'enter_email': 'Enter your email',
      'get_started': 'Get Started',
      'discover_devices': 'Discover Devices',
      'no_devices_found': 'No devices found nearby',
      'searching': 'Searching for devices...',
      'tap_to_connect': 'Tap on a device to connect',
      'my_profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'version': 'Version',
      'licenses': 'Licenses',
      'select_language': 'Select Language',
      'choose_language': 'Choose your preferred language for the app interface',
      'apply_language': 'Apply Language',
      'language_changed': 'Language changed successfully',
      'privacy_permissions': 'Privacy & Permissions',
      'location_access': 'Location Access',
      'allow_location': 'Allow app to access your location',
      'clear_chat_history': 'Clear Chat History',
      'delete_all_messages': 'Delete all message history',
      'export_data': 'Export Data',
      'export_profile_data': 'Export your profile and chat data',
      'are_you_sure': 'Are you sure?',
      'cannot_be_undone': 'This action cannot be undone',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'exporting_data': 'Exporting data...',
      'chat_history_cleared': 'Chat history cleared',
      'location_granted': 'Location access granted',
      'location_denied': 'Location access denied',
      'location_disabled': 'Location access disabled',
    },
    'es': {
      'app_name': 'PingMe',
      'chat': 'Chat',
      'discovery': 'Descubrimiento',
      'profile': 'Perfil',
      'settings': 'Configuración',
      'send_message': 'Enviar mensaje...',
      'online': 'En línea',
      'offline': 'Desconectado',
      'connecting': 'Conectando...',
      'connected': 'Conectado',
      'send_chat_request': 'Enviar Solicitud de Chat',
      'chat_request': 'Solicitud de Chat',
      'accept': 'Aceptar',
      'decline': 'Rechazar',
      'dark_mode': 'Modo Oscuro',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'terms_of_service': 'Términos de Servicio',
      'privacy_policy': 'Política de Privacidad',
      'about': 'Acerca de',
      'sign_out': 'Cerrar Sesión',
      'appearance': 'Apariencia',
      'switch_theme': 'Cambiar entre temas claro y oscuro',
      'push_notifications': 'Notificaciones Push',
      'receive_notifications': 'Recibir notificaciones de mensajes',
      'sound': 'Sonido',
      'play_sound': 'Reproducir sonido para notificaciones',
      'vibration': 'Vibración',
      'vibrate_notifications': 'Vibrar para notificaciones',
      'app_language': 'Idioma de la aplicación',
      'welcome_to_pingme': 'Bienvenido a PingMe',
      'connect_instantly': 'Conéctate instantáneamente con personas cercanas',
      'sign_in_google': 'Iniciar sesión con Google',
      'enter_name': 'Ingresa tu nombre',
      'enter_email': 'Ingresa tu email',
      'get_started': 'Comenzar',
      'discover_devices': 'Descubrir Dispositivos',
      'no_devices_found': 'No se encontraron dispositivos cercanos',
      'searching': 'Buscando dispositivos...',
      'tap_to_connect': 'Toca para escanear',
      'my_profile': 'Mi Perfil',
      'edit_profile': 'Editar Perfil',
      'version': 'Versión',
      'licenses': 'Licencias',
      'select_language': 'Seleccionar Idioma',
      'choose_language': 'Elige tu idioma preferido para la interfaz de la aplicación',
      'apply_language': 'Aplicar Idioma',
      'language_changed': 'Idioma cambiado exitosamente',
      'privacy_permissions': 'Privacidad y Permisos',
      'location_access': 'Acceso a Ubicación',
      'allow_location': 'Permitir que la aplicación acceda a tu ubicación',
      'clear_chat_history': 'Borrar Historial de Chat',
      'delete_all_messages': 'Eliminar todo el historial de mensajes',
      'export_data': 'Exportar Datos',
      'export_profile_data': 'Exportar tu perfil y datos de chat',
      'are_you_sure': '¿Estás seguro?',
      'cannot_be_undone': 'Esta acción no se puede deshacer',
      'cancel': 'Cancelar',
      'clear': 'Borrar',
      'exporting_data': 'Exportando datos...',
      'chat_history_cleared': 'Historial de chat borrado',
      'location_granted': 'Acceso a ubicación concedido',
      'location_denied': 'Acceso a ubicación denegado',
      'location_disabled': 'Acceso a ubicación deshabilitado',
    },
    'fr': {
      'app_name': 'PingMe',
      'chat': 'Chat',
      'discovery': 'Découverte',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'send_message': 'Envoyer un message...',
      'online': 'En ligne',
      'offline': 'Hors ligne',
      'connecting': 'Connexion...',
      'connected': 'Connecté',
      'send_chat_request': 'Envoyer une Demande de Chat',
      'chat_request': 'Demande de Chat',
      'accept': 'Accepter',
      'decline': 'Refuser',
      'dark_mode': 'Mode Sombre',
      'language': 'Langue',
      'notifications': 'Notifications',
      'terms_of_service': 'Conditions de Service',
      'privacy_policy': 'Politique de Confidentialité',
      'about': 'À propos',
      'sign_out': 'Se Déconnecter',
    },
    'hi': {
      'app_name': 'PingMe',
      'chat': 'चैट',
      'discovery': 'खोज',
      'profile': 'प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'send_message': 'संदेश भेजें...',
      'online': 'ऑनलाइन',
      'offline': 'ऑफलाइन',
      'connecting': 'कनेक्ट हो रहा है...',
      'connected': 'कनेक्टेड',
      'send_chat_request': 'चैट अनुरोध भेजें',
      'chat_request': 'चैट अनुरोध',
      'accept': 'स्वीकार करें',
      'decline': 'अस्वीकार करें',
      'dark_mode': 'डार्क मोड',
      'language': 'भाषा',
      'notifications': 'सूचनाएं',
      'terms_of_service': 'सेवा की शर्तें',
      'privacy_policy': 'गोपनीयता नीति',
      'about': 'के बारे में',
      'sign_out': 'साइन आउट',
    },
  };

  String get currentLanguage => _currentLanguage;
  Map<String, String> get supportedLanguages => _languages.map((key, value) => MapEntry(key, value['nativeName']!));
  Map<String, String> get languageFlags => _languages.map((key, value) => MapEntry(key, value['flag']!));

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs?.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_languages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      await _prefs?.setString('app_language', languageCode);
      notifyListeners();
    }
  }

  String translate(String key) {
    final translations = _translations[_currentLanguage] ?? _translations['en']!;
    return translations[key] ?? key;
  }

  String t(String key) => translate(key);

  Locale get locale => Locale(_currentLanguage);

  String getLanguageName(String languageCode) {
    return _languages[languageCode]?['nativeName'] ?? languageCode;
  }

  String getLanguageFlag(String languageCode) {
    return _languages[languageCode]?['flag'] ?? '🌐';
  }
}
