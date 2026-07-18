// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ピングミー';

  @override
  String get welcome => 'ピングミーへようこそ';

  @override
  String get welcome_to_pingme => 'ピングミーへようこそ';

  @override
  String get connect_instantly => '近くのユーザーと瞬時に接続';

  @override
  String get enterYourEmail => 'メールを入力してください';

  @override
  String get enterYourPassword => 'パスワードを入力してください';

  @override
  String get continueWithGoogle => 'Googleで続ける';

  @override
  String get or => 'または';

  @override
  String get passwordResetComingSoon => 'パスワードリセット機能は近日公開予定';

  @override
  String get pleaseEnterEmail => 'メールアドレスを入力してください';

  @override
  String get pleaseEnterValidEmail => '正しいメールアドレスを入力してください';

  @override
  String get pleaseEnterPassword => 'パスワードを入力してください';

  @override
  String get passwordMinLength => 'パスワードは6文字以上必要です';

  @override
  String get googleSignInFailed => 'Googleサインインに失敗しました。もう一度お試しください。';

  @override
  String get welcomeSubtitle => 'WiFi経由のリアルタイムP2Pチャット';

  @override
  String get signIn => 'サインイン';

  @override
  String get signUp => 'サインアップ';

  @override
  String get email => 'メール';

  @override
  String get password => 'パスワード';

  @override
  String get name => '名前';

  @override
  String get fullName => 'フルネーム';

  @override
  String get enterYourName => '名前を入力してください';

  @override
  String get confirmPassword => 'パスワードを確認';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get joinPingMe => 'ローカルチャットのためにPingMeに参加';

  @override
  String get createPassword => 'パスワードを作成';

  @override
  String get reenterPassword => 'パスワードを再入力';

  @override
  String get pleaseEnterName => '名前を入力してください';

  @override
  String get nameMinLength => '名前は最低2文字必要です';

  @override
  String get pleaseConfirmPassword => 'パスワードを確認してください';

  @override
  String get iAgreeToThe => '同意します ';

  @override
  String get and => ' と ';

  @override
  String get pleaseAcceptTerms => '利用規約に同意してください';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get alreadyHaveAccount => 'アカウントをお持ちですか？';

  @override
  String get dontHaveAccount => 'アカウントをお持ちでないですか？';

  @override
  String get forgotPassword => 'パスワードを忘れましたか？';

  @override
  String get loginSuccessful => 'ログイン成功！';

  @override
  String get signUpSuccessful => 'サインアップ成功！';

  @override
  String get invalidEmailOrPassword => '無効なメールまたはパスワード';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get emailAlreadyInUse => 'メールはすでに使用されています';

  @override
  String get home => 'ホーム';

  @override
  String get chats => 'チャット';

  @override
  String get chat => 'チャット';

  @override
  String get discover => '探索';

  @override
  String get discoverDevices => 'デバイスを探す';

  @override
  String get searching => '検索中...';

  @override
  String get tapToConnect => 'タップして接続';

  @override
  String get noDevicesFound => 'デバイスが見つかりません';

  @override
  String get pleaseLoginToDiscoverDevices => 'デバイスを探すにはログインしてください';

  @override
  String get scanningForNearbyDevices => '近くのデバイスを検索中...';

  @override
  String get tapRadarButton => 'デバイスを見つけるにはレーダーボタンをタップ！';

  @override
  String get makeOtherDevicesNearby => '他のデバイスが近くにあり\nPingMeが開いていることを確認してください';

  @override
  String get tapScanButton => '近くのデバイスを探すには\nスキャンボタンをタップ';

  @override
  String connectTo(String name) {
    return '$nameに接続';
  }

  @override
  String get doYouWantToChat => 'このWiFiに接続されているこの人とチャットしますか？';

  @override
  String chatRequestSentTo(String name) {
    return '$nameにチャットリクエストを送信しました';
  }

  @override
  String failedToSendChatRequestTo(String name) {
    return '$nameへのチャットリクエスト送信に失敗しました';
  }

  @override
  String failedToStartDiscovery(String error) {
    return '検索開始に失敗: $error';
  }

  @override
  String failedToConnectError(String error) {
    return '接続に失敗: $error';
  }

  @override
  String get profile => 'プロフィール';

  @override
  String get settings => '設定';

  @override
  String get searchDevices => 'デバイスを検索';

  @override
  String get connecting => '接続中...';

  @override
  String get connected => '接続済み';

  @override
  String get disconnected => '切断';

  @override
  String get sendChatRequest => 'チャットリクエストを送信';

  @override
  String get chatRequestSent => 'チャットリクエストが送信されました';

  @override
  String get chatRequestAccepted => 'チャットリクエストが承認されました';

  @override
  String get chatRequestRejected => 'チャットリクエストが拒否されました';

  @override
  String get acceptChatRequest => '承認';

  @override
  String get rejectChatRequest => '拒否';

  @override
  String get incomingChatRequest => '着信チャットリクエスト';

  @override
  String fromUser(String userName) {
    return '送信者: $userName';
  }

  @override
  String get typeMessage => 'メッセージを入力...';

  @override
  String sayHiTo(String name) {
    return '$nameさんに挨拶しましょう';
  }

  @override
  String get startConversation => '会話を始める';

  @override
  String get failedToConnect => '接続に失敗しました。他のデバイスがオンラインであることを確認してください。';

  @override
  String get failedToSendMessage => 'メッセージの送信に失敗しました。もう一度お試しください。';

  @override
  String get file => 'ファイル';

  @override
  String get send => '送信';

  @override
  String get online => 'オンライン';

  @override
  String get offline => 'オフライン';

  @override
  String get typing => '入力中...';

  @override
  String lastSeen(String time) {
    return '最終確認 $time';
  }

  @override
  String get deleteMessage => 'メッセージを削除';

  @override
  String get copyMessage => 'メッセージをコピー';

  @override
  String get messageDeleted => 'メッセージが削除されました';

  @override
  String get messageCopied => 'メッセージがコピーされました';

  @override
  String get notifications => '通知';

  @override
  String get notificationsEnabled => '通知が有効';

  @override
  String get notificationsDisabled => '通知が無効';

  @override
  String get readReceipts => '既読確認';

  @override
  String get typingIndicator => '入力中表示';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get language => '言語';

  @override
  String get about => 'について';

  @override
  String get version => 'バージョン';

  @override
  String get deviceId => 'デバイスID';

  @override
  String get ipAddress => 'IPアドレス';

  @override
  String get notConnected => '未接続';

  @override
  String get editProfile => 'プロフィールを編集';

  @override
  String get saveChanges => '変更を保存';

  @override
  String get bio => '自己紹介';

  @override
  String get status => 'ステータス';

  @override
  String get tellAboutYourself => '自己紹介をしてください';

  @override
  String get whatsOnYourMind => '今何を考えていますか？';

  @override
  String get profileUpdated => 'プロフィールが正常に更新されました';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get chooseFromGallery => 'ギャラリーから選択';

  @override
  String get removePhoto => '写真を削除';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirmation => '本当にログアウトしますか？';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get connectionError => '接続エラー';

  @override
  String get tryAgain => 'もう一度試す';

  @override
  String get somethingWentWrong => '何か問題が発生しました';

  @override
  String get pleaseWait => 'お待ちください...';

  @override
  String get loading => '読み込み中...';

  @override
  String get noChatsYet => 'まだチャットはありません';

  @override
  String get startChatting => '近くのデバイスとチャットを開始';

  @override
  String get searchChats => 'チャットを検索';

  @override
  String get deleteChat => 'チャットを削除';

  @override
  String get clearChat => 'チャットをクリア';

  @override
  String get blockUser => 'ユーザーをブロック';

  @override
  String get unblockUser => 'ブロック解除';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String get justNow => 'たった今';

  @override
  String get photo => '写真';

  @override
  String get video => 'ビデオ';

  @override
  String get audio => 'オーディオ';

  @override
  String get document => 'ドキュメント';

  @override
  String get location => '位置';

  @override
  String get shareLocation => '位置を共有';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get hindi => 'हिंदी';

  @override
  String get japanese => '日本語';

  @override
  String get connectingAndSending => '接続してチャットリクエストを送信中...';

  @override
  String chatRequestAcceptedBy(String userName) {
    return '🎉 $userNameがチャットリクエストを承認しました！';
  }

  @override
  String chatRequestRejectedBy(String userName) {
    return '❌ $userNameがチャットリクエストを拒否しました';
  }

  @override
  String get wouldLikeToChat => 'こんにちは！チャットしませんか？';

  @override
  String get chatWith => 'チャット';

  @override
  String get profileInformation => 'プロフィール情報';

  @override
  String get nameCannotBeEmpty => '名前を空にすることはできません';

  @override
  String get pleaseLoginToUpdate => 'プロフィールを更新するにはログインしてください';

  @override
  String get pleaseLoginToView => 'プロフィールを表示するにはログインしてください';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfService => '利用規約';

  @override
  String get help => 'ヘルプ';

  @override
  String get contactUs => 'お問い合わせ';

  @override
  String get tellUsAboutYourself => 'あなたについて教えてください';

  @override
  String get unknown => '不明';

  @override
  String get appTagline => 'WiFi経由のリアルタイムP2Pチャット';

  @override
  String get failedToPickImage => '画像の選択に失敗しました';

  @override
  String get pleaseLoginToAccessSettings => '設定にアクセスするにはログインしてください';

  @override
  String get appearance => '外観';

  @override
  String get switchTheme => 'ライトとダークテーマを切り替え';

  @override
  String get changedToDarkMode => 'ダークモードに変更しました';

  @override
  String get changedToLightMode => 'ライトモードに変更しました';

  @override
  String get pushNotifications => 'プッシュ通知';

  @override
  String get receiveNotifications => 'メッセージ通知を受信';

  @override
  String get sound => 'サウンド';

  @override
  String get playSound => '通知音を再生';

  @override
  String get vibration => 'バイブレーション';

  @override
  String get vibrateNotifications => '通知時のバイブレーション';

  @override
  String get appLanguage => 'アプリの言語';

  @override
  String get privacyPermissions => 'プライバシーと権限';

  @override
  String get locationAccess => '位置情報アクセス';

  @override
  String get allowLocation => '近くのデバイス検索のため位置情報を許可';

  @override
  String get locationGranted => '位置情報アクセスが許可されました';

  @override
  String get locationDenied => '位置情報アクセスが拒否されました';

  @override
  String get locationDisabled => '位置情報アクセスが無効になりました';

  @override
  String get clearChatHistory => 'チャット履歴を消去';

  @override
  String get deleteAllMessages => 'すべてのメッセージを削除';

  @override
  String get exportData => 'データをエクスポート';

  @override
  String get exportProfileData => 'プロファイルデータをエクスポート';

  @override
  String get licenses => 'ライセンス';

  @override
  String get areYouSure => 'よろしいですか？';

  @override
  String get chatHistoryCleared => 'チャット履歴が消去されました';

  @override
  String get clear => 'クリア';

  @override
  String get exportingData => 'データをエクスポート中...';

  @override
  String get noConversationsYet => 'まだ会話がありません';

  @override
  String get discoverNearbyToChat => 'チャットを開始するには近くのデバイスを検索してください';

  @override
  String get viewConversationsHere => 'ここで会話を表示します！';

  @override
  String get discoverNearbyDevices => 'チャットする近くのデバイスを発見！';

  @override
  String get customizeProfileHere => 'ここでプロフィールをカスタマイズ！';

  @override
  String get adjustPreferences => 'アプリの設定を調整！';

  @override
  String get profileUpdatedSuccessfully => 'プロフィールが正常に更新されました';
}
