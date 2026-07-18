import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import 'package:crypto/crypto.dart';
import 'profile_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Add your OAuth Client ID here (optional but recommended)
    // clientId: 'YOUR_OAUTH_CLIENT_ID.apps.googleusercontent.com',
  );

  User? _currentUser;
  bool _isAuthenticated = false;
  SharedPreferences? _prefs;
  
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await checkSession();
  }

  Future<bool> checkSession() async {
    if (_prefs == null) await initialize();
    
    final sessionToken = _prefs!.getString('session_token');
    final userJson = _prefs!.getString('user_data');
    
    if (sessionToken != null && userJson != null) {
      try {
        _currentUser = User.fromJson(json.decode(userJson));
        _isAuthenticated = true;
        
        // Sync with ProfileService when restoring session
        await _prefs!.setString('user_profile', userJson);
        await ProfileService().loadProfile();
        debugPrint('✅ AuthService: Session restored and synced with ProfileService');
        
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Error restoring session: $e');
        await clearSession();
      }
    }
    return false;
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Ensure prefs is initialized
      if (_prefs == null) await initialize();
      
      // Validate email
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      // Validate password
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Check if user exists (in production, this would be a server call)
      final existingUser = _prefs!.getString('user_$email');
      if (existingUser != null) {
        throw Exception('User already exists');
      }

      // Hash password
      final passwordHash = _hashPassword(password);
      
      // Create user
      final userId = const Uuid().v4();
      final deviceId = const Uuid().v4();
      
      _currentUser = User(
        id: userId,
        name: name,
        deviceId: deviceId,
        ipAddress: '0.0.0.0',
        port: 8889,
        metadata: {
          'email': email,
          'authMethod': 'email',
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      // Store user credentials (in production, this would be on server)
      final userCredentials = {
        'email': email,
        'passwordHash': passwordHash,
        'userId': userId,
      };
      await _prefs!.setString('user_$email', json.encode(userCredentials));

      // Create session
      await _createSession(_currentUser!);
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Ensure prefs is initialized
      if (_prefs == null) await initialize();
      
      // Validate email
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      // Get user credentials (in production, this would be a server call)
      final userCredentialsJson = _prefs!.getString('user_$email');
      if (userCredentialsJson == null) {
        throw Exception('User not found');
      }

      final userCredentials = json.decode(userCredentialsJson);
      final storedPasswordHash = userCredentials['passwordHash'];
      final passwordHash = _hashPassword(password);

      if (storedPasswordHash != passwordHash) {
        throw Exception('Invalid password');
      }

      // Get or create user data
      final userDataJson = _prefs!.getString('user_data_${userCredentials['userId']}');
      if (userDataJson != null) {
        _currentUser = User.fromJson(json.decode(userDataJson));
      } else {
        // Create user from stored credentials
        final deviceId = const Uuid().v4();
        _currentUser = User(
          id: userCredentials['userId'],
          name: email.split('@')[0],
          deviceId: deviceId,
          ipAddress: '0.0.0.0',
          port: 8889,
          metadata: {
            'email': email,
            'authMethod': 'email',
            'lastLogin': DateTime.now().toIso8601String(),
          },
        );
      }

      // Create session
      await _createSession(_currentUser!);
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      // Ensure prefs is initialized
      if (_prefs == null) await initialize();
      
      // Force account picker to show
      await _googleSignIn.signOut(); // Sign out first
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null) {
        throw Exception('Failed to get Google access token');
      }

      // Create user from Google account
      final userId = const Uuid().v4();
      final deviceId = const Uuid().v4();
      
      _currentUser = User(
        id: userId,
        name: googleUser.displayName ?? googleUser.email.split('@')[0],
        avatarUrl: googleUser.photoUrl,
        deviceId: deviceId,
        ipAddress: '0.0.0.0',
        port: 8889,
        metadata: {
          'email': googleUser.email,
          'authMethod': 'google',
          'googleId': googleUser.id,
          'lastLogin': DateTime.now().toIso8601String(),
        },
      );

      // Store Google user data
      await _prefs!.setString(
        'google_user_${googleUser.id}',
        json.encode(_currentUser!.toJson()),
      );

      // Create session
      await _createSession(_currentUser!);
      
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Google if it was used
      if (_currentUser?.metadata['authMethod'] == 'google') {
        await _googleSignIn.signOut();
      }

      await clearSession();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  Future<void> _createSession(User user) async {
    if (_prefs == null) await initialize();
    final sessionToken = _generateSessionToken();
    await _prefs!.setString('session_token', sessionToken);
    await _prefs!.setString('user_data', json.encode(user.toJson()));
    await _prefs!.setString('user_data_${user.id}', json.encode(user.toJson()));
    await _prefs!.setInt('session_created', DateTime.now().millisecondsSinceEpoch);
    
    // Sync with ProfileService - save user profile using the same key ProfileService expects
    await _prefs!.setString('user_profile', json.encode(user.toJson()));
    // Force ProfileService to reload the profile
    await ProfileService().loadProfile();
    debugPrint('✅ AuthService: Synced user profile with ProfileService');
  }

  Future<void> clearSession() async {
    if (_prefs == null) await initialize();
    await _prefs!.remove('session_token');
    await _prefs!.remove('user_data');
    await _prefs!.remove('session_created');
  }

  Future<void> updateUserProfile({
    String? name,
    String? bio,
    String? avatarUrl,
    String? status,
  }) async {
    if (_currentUser == null) return;
    if (_prefs == null) await initialize();

    _currentUser = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      bio: bio ?? _currentUser!.bio,
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      status: status,
    );

    await _prefs!.setString('user_data', json.encode(_currentUser!.toJson()));
    await _prefs!.setString(
      'user_data_${_currentUser!.id}',
      json.encode(_currentUser!.toJson()),
    );
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = const Uuid().v4();
    final token = '$timestamp-$random';
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool isSessionValid() {
    if (!_isAuthenticated || _prefs == null) return false;
    
    final sessionCreated = _prefs!.getInt('session_created');
    if (sessionCreated == null) return false;
    
    // Session expires after 30 days
    final expirationTime = DateTime.fromMillisecondsSinceEpoch(sessionCreated)
        .add(const Duration(days: 30));
    
    return DateTime.now().isBefore(expirationTime);
  }

  Future<void> refreshSession() async {
    if (_currentUser != null && isSessionValid()) {
      await _createSession(_currentUser!);
    }
  }
}
