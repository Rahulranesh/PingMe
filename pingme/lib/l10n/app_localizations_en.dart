// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PingMe';

  @override
  String get welcome => 'Welcome to PingMe';

  @override
  String get welcome_to_pingme => 'Welcome to PingMe';

  @override
  String get connect_instantly => 'Connect with nearby users instantly';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get or => 'OR';

  @override
  String get passwordResetComingSoon => 'Password reset feature coming soon';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get googleSignInFailed => 'Google sign-in failed. Please try again.';

  @override
  String get welcomeSubtitle => 'Real-time P2P Chat over WiFi';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterYourName => 'Enter your full name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinPingMe => 'Join PingMe to chat locally';

  @override
  String get createPassword => 'Create a password';

  @override
  String get reenterPassword => 'Re-enter your password';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get iAgreeToThe => 'I agree to the ';

  @override
  String get and => ' and ';

  @override
  String get pleaseAcceptTerms => 'Please accept the terms and conditions';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginSuccessful => 'Login successful!';

  @override
  String get signUpSuccessful => 'Sign up successful!';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get emailAlreadyInUse => 'Email already in use';

  @override
  String get home => 'Home';

  @override
  String get chats => 'Chats';

  @override
  String get chat => 'Chats';

  @override
  String get discover => 'Discover';

  @override
  String get discoverDevices => 'Discover Devices';

  @override
  String get searching => 'Searching...';

  @override
  String get tapToConnect => 'Tap to connect';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get pleaseLoginToDiscoverDevices => 'Please login to discover devices';

  @override
  String get scanningForNearbyDevices => 'Scanning for nearby devices...';

  @override
  String get tapRadarButton => 'Tap the radar button to find devices!';

  @override
  String get makeOtherDevicesNearby =>
      'Make sure other devices are nearby\nand have PingMe open';

  @override
  String get tapScanButton =>
      'Tap the scan button to search\nfor nearby devices';

  @override
  String connectTo(String name) {
    return 'Connect to $name';
  }

  @override
  String get doYouWantToChat =>
      'Do you want to chat with this person connected on this WiFi?';

  @override
  String chatRequestSentTo(String name) {
    return 'Chat request sent to $name';
  }

  @override
  String failedToSendChatRequestTo(String name) {
    return 'Failed to send chat request to $name';
  }

  @override
  String failedToStartDiscovery(String error) {
    return 'Failed to start discovery: $error';
  }

  @override
  String failedToConnectError(String error) {
    return 'Failed to connect: $error';
  }

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get searchDevices => 'Search for devices';

  @override
  String get connecting => 'Connecting...';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get sendChatRequest => 'Send Chat Request';

  @override
  String get chatRequestSent => 'Chat request sent';

  @override
  String get chatRequestAccepted => 'Chat request accepted';

  @override
  String get chatRequestRejected => 'Chat request rejected';

  @override
  String get acceptChatRequest => 'Accept';

  @override
  String get rejectChatRequest => 'Reject';

  @override
  String get incomingChatRequest => 'Incoming Chat Request';

  @override
  String fromUser(String userName) {
    return 'From: $userName';
  }

  @override
  String get typeMessage => 'Type a message...';

  @override
  String sayHiTo(String name) {
    return 'Say hi to $name';
  }

  @override
  String get startConversation => 'Start a conversation';

  @override
  String get failedToConnect =>
      'Failed to connect. Please ensure the other device is online.';

  @override
  String get failedToSendMessage => 'Failed to send message. Please try again.';

  @override
  String get file => 'File';

  @override
  String get send => 'Send';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get typing => 'typing...';

  @override
  String lastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get messageCopied => 'Message copied';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get readReceipts => 'Read Receipts';

  @override
  String get typingIndicator => 'Typing Indicator';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get deviceId => 'Device ID';

  @override
  String get ipAddress => 'IP Address';

  @override
  String get notConnected => 'Not connected';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get bio => 'Bio';

  @override
  String get status => 'Status';

  @override
  String get tellAboutYourself => 'Tell us about yourself';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get connectionError => 'Connection error';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get loading => 'Loading...';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get startChatting => 'Start chatting with nearby devices';

  @override
  String get searchChats => 'Search chats';

  @override
  String get deleteChat => 'Delete chat';

  @override
  String get clearChat => 'Clear chat';

  @override
  String get blockUser => 'Block user';

  @override
  String get unblockUser => 'Unblock user';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get justNow => 'Just now';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Audio';

  @override
  String get document => 'Document';

  @override
  String get location => 'Location';

  @override
  String get shareLocation => 'Share Location';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get hindi => 'हिंदी';

  @override
  String get japanese => '日本語';

  @override
  String get connectingAndSending => 'Connecting and sending chat request...';

  @override
  String chatRequestAcceptedBy(String userName) {
    return '🎉 $userName accepted your chat request!';
  }

  @override
  String chatRequestRejectedBy(String userName) {
    return '❌ $userName declined your chat request';
  }

  @override
  String get wouldLikeToChat => 'Hi! Would you like to chat?';

  @override
  String get chatWith => 'Chat';

  @override
  String get profileInformation => 'Profile Information';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get pleaseLoginToUpdate => 'Please login to update profile';

  @override
  String get pleaseLoginToView => 'Please login to view profile';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get help => 'Help';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get tellUsAboutYourself => 'Tell us about yourself';

  @override
  String get unknown => 'Unknown';

  @override
  String get appTagline => 'Real-time P2P Chat over WiFi';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get pleaseLoginToAccessSettings => 'Please login to access settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get switchTheme => 'Switch between light and dark theme';

  @override
  String get changedToDarkMode => 'Changed to Dark mode';

  @override
  String get changedToLightMode => 'Changed to Light mode';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receiveNotifications => 'Receive message notifications';

  @override
  String get sound => 'Sound';

  @override
  String get playSound => 'Play sound for notifications';

  @override
  String get vibration => 'Vibration';

  @override
  String get vibrateNotifications => 'Vibrate for notifications';

  @override
  String get appLanguage => 'App Language';

  @override
  String get privacyPermissions => 'Privacy & Permissions';

  @override
  String get locationAccess => 'Location Access';

  @override
  String get allowLocation => 'Allow location for nearby discovery';

  @override
  String get locationGranted => 'Location access granted';

  @override
  String get locationDenied => 'Location access denied';

  @override
  String get locationDisabled => 'Location access disabled';

  @override
  String get clearChatHistory => 'Clear Chat History';

  @override
  String get deleteAllMessages => 'Delete all messages';

  @override
  String get exportData => 'Export Data';

  @override
  String get exportProfileData => 'Export profile data';

  @override
  String get licenses => 'Licenses';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get chatHistoryCleared => 'Chat history cleared';

  @override
  String get clear => 'Clear';

  @override
  String get exportingData => 'Exporting data...';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get discoverNearbyToChat =>
      'Discover nearby devices to start chatting';

  @override
  String get viewConversationsHere => 'View your conversations here!';

  @override
  String get discoverNearbyDevices => 'Discover nearby devices to chat with!';

  @override
  String get customizeProfileHere => 'Customize your profile here!';

  @override
  String get adjustPreferences => 'Adjust your app preferences!';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';
}
