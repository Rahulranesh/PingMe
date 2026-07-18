// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'पिंगमी';

  @override
  String get welcome => 'पिंगमी में आपका स्वागत है';

  @override
  String get welcome_to_pingme => 'पिंगमी में आपका स्वागत है';

  @override
  String get connect_instantly => 'नजदीकी उपयोगकर्ताओं से तुरंत जुड़ें';

  @override
  String get enterYourEmail => 'अपना ईमेल दर्ज करें';

  @override
  String get enterYourPassword => 'अपना पासवर्ड दर्ज करें';

  @override
  String get continueWithGoogle => 'गूगल से जारी रखें';

  @override
  String get or => 'या';

  @override
  String get passwordResetComingSoon => 'पासवर्ड रीसेट सुविधा जल्द आ रही है';

  @override
  String get pleaseEnterEmail => 'कृपया अपना ईमेल दर्ज करें';

  @override
  String get pleaseEnterValidEmail => 'कृपया वैध ईमेल दर्ज करें';

  @override
  String get pleaseEnterPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get googleSignInFailed => 'गूगल साइन-इन विफल। कृपया पुनः प्रयास करें।';

  @override
  String get welcomeSubtitle => 'WiFi पर रीयल-टाइम P2P चैट';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signUp => 'साइन अप करें';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get name => 'नाम';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get enterYourName => 'अपना नाम दर्ज करें';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get createAccount => 'खाता बनाएं';

  @override
  String get joinPingMe => 'स्थानीय चैट के लिए पिंगमी ज्वाइन करें';

  @override
  String get createPassword => 'पासवर्ड बनाएं';

  @override
  String get reenterPassword => 'पासवर्ड फिर से दर्ज करें';

  @override
  String get pleaseEnterName => 'कृपया अपना नाम दर्ज करें';

  @override
  String get nameMinLength => 'नाम कम से कम 2 अक्षरों का होना चाहिए';

  @override
  String get pleaseConfirmPassword => 'कृपया अपने पासवर्ड की पुष्टि करें';

  @override
  String get iAgreeToThe => 'मैं सहमत हूं ';

  @override
  String get and => ' और ';

  @override
  String get pleaseAcceptTerms => 'कृपया नियमों और शर्तों को स्वीकार करें';

  @override
  String get signInWithGoogle => 'गूगल से साइन इन करें';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है?';

  @override
  String get dontHaveAccount => 'खाता नहीं है?';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get loginSuccessful => 'लॉगिन सफल!';

  @override
  String get signUpSuccessful => 'साइन अप सफल!';

  @override
  String get invalidEmailOrPassword => 'अमान्य ईमेल या पासवर्ड';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get emailAlreadyInUse => 'ईमेल पहले से उपयोग में है';

  @override
  String get home => 'होम';

  @override
  String get chats => 'चैट्स';

  @override
  String get chat => 'चैट्स';

  @override
  String get discover => 'खोजें';

  @override
  String get discoverDevices => 'डिवाइस खोजें';

  @override
  String get searching => 'खोज रहे हैं...';

  @override
  String get tapToConnect => 'कनेक्ट करने के लिए टैप करें';

  @override
  String get noDevicesFound => 'कोई डिवाइस नहीं मिला';

  @override
  String get pleaseLoginToDiscoverDevices => 'डिवाइस खोजने के लिए लॉगिन करें';

  @override
  String get scanningForNearbyDevices => 'पास के डिवाइसेस की खोज कर रहे हैं...';

  @override
  String get tapRadarButton => 'डिवाइस खोजने के लिए रेडार बटन दबाएं!';

  @override
  String get makeOtherDevicesNearby =>
      'सुनिश्चित करें कि अन्य डिवाइस पास हैं\nऔर पिंगमी खुला है';

  @override
  String get tapScanButton =>
      'पास के डिवाइसेस खोजने के लिए\nस्कैन बटन टैप करें';

  @override
  String connectTo(String name) {
    return '$name से कनेक्ट करें';
  }

  @override
  String get doYouWantToChat =>
      'क्या आप इस WiFi पर जुड़े इस व्यक्ति से चैट करना चाहते हैं?';

  @override
  String chatRequestSentTo(String name) {
    return '$name को चैट अनुरोध भेजा गया';
  }

  @override
  String failedToSendChatRequestTo(String name) {
    return '$name को चैट अनुरोध भेजने में विफल';
  }

  @override
  String failedToStartDiscovery(String error) {
    return 'खोज शुरू करने में विफल: $error';
  }

  @override
  String failedToConnectError(String error) {
    return 'कनेक्ट करने में विफल: $error';
  }

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get searchDevices => 'डिवाइसेज खोजें';

  @override
  String get connecting => 'कनेक्ट हो रहा है...';

  @override
  String get connected => 'कनेक्टेड';

  @override
  String get disconnected => 'डिस्कनेक्टेड';

  @override
  String get sendChatRequest => 'चैट अनुरोध भेजें';

  @override
  String get chatRequestSent => 'चैट अनुरोध भेजा गया';

  @override
  String get chatRequestAccepted => 'चैट अनुरोध स्वीकार किया गया';

  @override
  String get chatRequestRejected => 'चैट अनुरोध अस्वीकार किया गया';

  @override
  String get acceptChatRequest => 'स्वीकार करें';

  @override
  String get rejectChatRequest => 'अस्वीकार करें';

  @override
  String get incomingChatRequest => 'आने वाला चैट अनुरोध';

  @override
  String fromUser(String userName) {
    return 'भेजने वाला: $userName';
  }

  @override
  String get typeMessage => 'संदेश टाइप करें...';

  @override
  String sayHiTo(String name) {
    return '$name को हाय कहें';
  }

  @override
  String get startConversation => 'बातचीत शुरू करें';

  @override
  String get failedToConnect =>
      'कनेक्ट नहीं हो पाया। कृपया सुनिश्चित करें कि दूसरा डिवाइस ऑनलाइन है।';

  @override
  String get failedToSendMessage =>
      'संदेश भेजने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get file => 'फ़ाइल';

  @override
  String get send => 'भेजें';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफ़लाइन';

  @override
  String get typing => 'टाइप कर रहे हैं...';

  @override
  String lastSeen(String time) {
    return 'आखिरी बार देखा गया $time';
  }

  @override
  String get deleteMessage => 'संदेश हटाएं';

  @override
  String get copyMessage => 'संदेश कॉपी करें';

  @override
  String get messageDeleted => 'संदेश हटाया गया';

  @override
  String get messageCopied => 'संदेश कॉपी किया गया';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get notificationsEnabled => 'सूचनाएं सक्षम';

  @override
  String get notificationsDisabled => 'सूचनाएं अक्षम';

  @override
  String get readReceipts => 'रीड रसीदें';

  @override
  String get typingIndicator => 'टाइपिंग संकेतक';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get language => 'भाषा';

  @override
  String get about => 'के बारे में';

  @override
  String get version => 'संस्करण';

  @override
  String get deviceId => 'डिवाइस आईडी';

  @override
  String get ipAddress => 'IP पता';

  @override
  String get notConnected => 'कनेक्ट नहीं';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get bio => 'जीवनी';

  @override
  String get status => 'स्थिति';

  @override
  String get tellAboutYourself => 'अपने बारे में बताएं';

  @override
  String get whatsOnYourMind => 'आपके मन में क्या है?';

  @override
  String get profileUpdated => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई';

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get removePhoto => 'फोटो हटाएं';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get logoutConfirmation => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get connectionError => 'कनेक्शन त्रुटि';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get noChatsYet => 'अभी तक कोई चैट नहीं';

  @override
  String get startChatting => 'नजदीकी डिवाइसेज से चैट शुरू करें';

  @override
  String get searchChats => 'चैट्स खोजें';

  @override
  String get deleteChat => 'चैट हटाएं';

  @override
  String get clearChat => 'चैट साफ़ करें';

  @override
  String get blockUser => 'उपयोगकर्ता को ब्लॉक करें';

  @override
  String get unblockUser => 'अनब्लॉक करें';

  @override
  String get today => 'आज';

  @override
  String get yesterday => 'कल';

  @override
  String get justNow => 'अभी';

  @override
  String get photo => 'फोटो';

  @override
  String get video => 'वीडियो';

  @override
  String get audio => 'ऑडियो';

  @override
  String get document => 'दस्तावेज़';

  @override
  String get location => 'स्थान';

  @override
  String get shareLocation => 'स्थान साझा करें';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get hindi => 'हिंदी';

  @override
  String get japanese => '日本語';

  @override
  String get connectingAndSending => 'कनेक्ट करके चैट अनुरोध भेज रहे हैं...';

  @override
  String chatRequestAcceptedBy(String userName) {
    return '🎉 $userName ने आपका चैट अनुरोध स्वीकार किया!';
  }

  @override
  String chatRequestRejectedBy(String userName) {
    return '❌ $userName ने आपका चैट अनुरोध अस्वीकार किया';
  }

  @override
  String get wouldLikeToChat => 'हैलो! क्या आप चैट करना चाहेंगे?';

  @override
  String get chatWith => 'चैट';

  @override
  String get profileInformation => 'प्रोफ़ाइल जानकारी';

  @override
  String get nameCannotBeEmpty => 'नाम खाली नहीं हो सकता';

  @override
  String get pleaseLoginToUpdate => 'प्रोफ़ाइल अपडेट करने के लिए लॉगिन करें';

  @override
  String get pleaseLoginToView => 'प्रोफ़ाइल देखने के लिए लॉगिन करें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get help => 'मदद';

  @override
  String get contactUs => 'हमसे संपर्क करें';

  @override
  String get tellUsAboutYourself => 'अपने बारे में बताएं';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get appTagline => 'WiFi के माध्यम से रियल-टाइम P2P चैट';

  @override
  String get failedToPickImage => 'इमेज चुनने में विफल';

  @override
  String get pleaseLoginToAccessSettings =>
      'सेटिंग्स एक्सेस करने के लिए लॉगिन करें';

  @override
  String get appearance => 'रूप';

  @override
  String get switchTheme => 'लाइट और डार्क थीम के बीच स्विच करें';

  @override
  String get changedToDarkMode => 'डार्क मोड में बदल गया';

  @override
  String get changedToLightMode => 'लाइट मोड में बदल गया';

  @override
  String get pushNotifications => 'पुश सूचनाएं';

  @override
  String get receiveNotifications => 'संदेश सूचनाएं प्राप्त करें';

  @override
  String get sound => 'ध्वनि';

  @override
  String get playSound => 'सूचनाओं के लिए ध्वनि चलाएं';

  @override
  String get vibration => 'कंपन';

  @override
  String get vibrateNotifications => 'सूचनाओं के लिए कंपन';

  @override
  String get appLanguage => 'ऐप भाषा';

  @override
  String get privacyPermissions => 'गोपनीयता और अनुमतियां';

  @override
  String get locationAccess => 'स्थान एक्सेस';

  @override
  String get allowLocation => 'आसपास की खोज के लिए स्थान की अनुमति दें';

  @override
  String get locationGranted => 'स्थान एक्सेस दी गई';

  @override
  String get locationDenied => 'स्थान एक्सेस अस्वीकृत';

  @override
  String get locationDisabled => 'स्थान एक्सेस अक्षम';

  @override
  String get clearChatHistory => 'चैट इतिहास साफ करें';

  @override
  String get deleteAllMessages => 'सभी संदेश हटाएं';

  @override
  String get exportData => 'डेटा निर्यात करें';

  @override
  String get exportProfileData => 'प्रोफ़ाइल डेटा निर्यात करें';

  @override
  String get licenses => 'लाइसेंस';

  @override
  String get areYouSure => 'क्या आप सुनिश्चित हैं?';

  @override
  String get chatHistoryCleared => 'चैट इतिहास साफ किया गया';

  @override
  String get clear => 'साफ करें';

  @override
  String get exportingData => 'डेटा निर्यात हो रहा है...';

  @override
  String get noConversationsYet => 'अभी तक कोई बातचीत नहीं';

  @override
  String get discoverNearbyToChat =>
      'चैट शुरू करने के लिए आसपास के डिवाइसेज खोजें';

  @override
  String get viewConversationsHere => 'अपनी बातचीत यहां देखें!';

  @override
  String get discoverNearbyDevices =>
      'चैट करने के लिए आसपास के डिवाइसेज खोजें!';

  @override
  String get customizeProfileHere => 'अपनी प्रोफ़ाइल को यहां कस्टमाइज़ करें!';

  @override
  String get adjustPreferences => 'अपनी ऐप प्राथमिकताएं समायोजित करें!';

  @override
  String get profileUpdatedSuccessfully => 'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई';
}
