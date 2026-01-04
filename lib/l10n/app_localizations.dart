import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'Go.'**
  String get appTitle;

  /// No description provided for @homeTab.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get homeTab;

  /// No description provided for @searchTab.
  ///
  /// In ja, this message translates to:
  /// **'探す'**
  String get searchTab;

  /// No description provided for @notificationTab.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get notificationTab;

  /// No description provided for @userProfileTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get userProfileTitle;

  /// No description provided for @manageTab.
  ///
  /// In ja, this message translates to:
  /// **'管理'**
  String get manageTab;

  /// No description provided for @drawerFollow.
  ///
  /// In ja, this message translates to:
  /// **'フォロー'**
  String get drawerFollow;

  /// No description provided for @drawerFavoriteGames.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのゲーム'**
  String get drawerFavoriteGames;

  /// No description provided for @drawerSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get drawerSettings;

  /// No description provided for @drawerRateApp.
  ///
  /// In ja, this message translates to:
  /// **'アプリを評価'**
  String get drawerRateApp;

  /// No description provided for @drawerFooterTitle.
  ///
  /// In ja, this message translates to:
  /// **'Go - ゲームイベント管理'**
  String get drawerFooterTitle;

  /// No description provided for @guestUser.
  ///
  /// In ja, this message translates to:
  /// **'ゲストユーザー'**
  String get guestUser;

  /// No description provided for @setupIncomplete.
  ///
  /// In ja, this message translates to:
  /// **'（設定未完了）'**
  String get setupIncomplete;

  /// No description provided for @tapToCompleteSetup.
  ///
  /// In ja, this message translates to:
  /// **'タップして初回設定を完了'**
  String get tapToCompleteSetup;

  /// No description provided for @idNotSet.
  ///
  /// In ja, this message translates to:
  /// **'ID: 未設定'**
  String get idNotSet;

  /// No description provided for @copyFailed.
  ///
  /// In ja, this message translates to:
  /// **'コピーに失敗しました'**
  String get copyFailed;

  /// No description provided for @loading.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get error;

  /// No description provided for @ok.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @settingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settingsTitle;

  /// No description provided for @accountSection.
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get accountSection;

  /// No description provided for @signOut.
  ///
  /// In ja, this message translates to:
  /// **'サインアウト'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In ja, this message translates to:
  /// **'サインイン'**
  String get signIn;

  /// No description provided for @privacySettingsSection.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール公開設定'**
  String get privacySettingsSection;

  /// No description provided for @showManagedEvents.
  ///
  /// In ja, this message translates to:
  /// **'運営者としてのイベント'**
  String get showManagedEvents;

  /// No description provided for @showParticipatingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加予定イベント'**
  String get showParticipatingEvents;

  /// No description provided for @showParticipatedEvents.
  ///
  /// In ja, this message translates to:
  /// **'過去参加済みイベント'**
  String get showParticipatedEvents;

  /// No description provided for @notificationCategoryFollow.
  ///
  /// In ja, this message translates to:
  /// **'フォロー'**
  String get notificationCategoryFollow;

  /// No description provided for @notificationCategoryEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get notificationCategoryEvent;

  /// No description provided for @notificationCategoryViolation.
  ///
  /// In ja, this message translates to:
  /// **'違反管理'**
  String get notificationCategoryViolation;

  /// No description provided for @notificationCategoryMatch.
  ///
  /// In ja, this message translates to:
  /// **'試合結果'**
  String get notificationCategoryMatch;

  /// No description provided for @notificationCategorySystem.
  ///
  /// In ja, this message translates to:
  /// **'システム'**
  String get notificationCategorySystem;

  /// No description provided for @appInfoSection.
  ///
  /// In ja, this message translates to:
  /// **'アプリ情報'**
  String get appInfoSection;

  /// No description provided for @version.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get version;

  /// No description provided for @infoSupportSection.
  ///
  /// In ja, this message translates to:
  /// **'情報・サポート'**
  String get infoSupportSection;

  /// No description provided for @termsOfService.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get privacyPolicy;

  /// No description provided for @contact.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get contact;

  /// No description provided for @accountManagementSection.
  ///
  /// In ja, this message translates to:
  /// **'アカウント管理'**
  String get accountManagementSection;

  /// No description provided for @deleteAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウント退会'**
  String get deleteAccount;

  /// No description provided for @appSettingsSection.
  ///
  /// In ja, this message translates to:
  /// **'アプリ設定'**
  String get appSettingsSection;

  /// No description provided for @languageSection.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get languageSection;

  /// No description provided for @languageJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @languageEnglish.
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKorean.
  ///
  /// In ja, this message translates to:
  /// **'韓国語'**
  String get languageKorean;

  /// No description provided for @languageChineseSimplified.
  ///
  /// In ja, this message translates to:
  /// **'中国語（簡体字）'**
  String get languageChineseSimplified;

  /// No description provided for @languageChineseTraditional.
  ///
  /// In ja, this message translates to:
  /// **'中国語（繁体字）'**
  String get languageChineseTraditional;

  /// No description provided for @languageSystem.
  ///
  /// In ja, this message translates to:
  /// **'システム設定に従う'**
  String get languageSystem;

  /// No description provided for @settingsSaved.
  ///
  /// In ja, this message translates to:
  /// **'設定を保存しました'**
  String get settingsSaved;

  /// No description provided for @userInfoLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の読み込みに失敗しました'**
  String get userInfoLoadFailed;

  /// No description provided for @eventStatusDraft.
  ///
  /// In ja, this message translates to:
  /// **'下書き'**
  String get eventStatusDraft;

  /// No description provided for @eventStatusPublished.
  ///
  /// In ja, this message translates to:
  /// **'公開済み'**
  String get eventStatusPublished;

  /// No description provided for @eventStatusUpcoming.
  ///
  /// In ja, this message translates to:
  /// **'開催予定'**
  String get eventStatusUpcoming;

  /// No description provided for @eventStatusActive.
  ///
  /// In ja, this message translates to:
  /// **'開催中'**
  String get eventStatusActive;

  /// No description provided for @eventStatusCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get eventStatusCompleted;

  /// No description provided for @eventStatusExpired.
  ///
  /// In ja, this message translates to:
  /// **'期限切れ'**
  String get eventStatusExpired;

  /// No description provided for @eventStatusCancelled.
  ///
  /// In ja, this message translates to:
  /// **'中止'**
  String get eventStatusCancelled;

  /// No description provided for @eventTypeDaily.
  ///
  /// In ja, this message translates to:
  /// **'デイリー'**
  String get eventTypeDaily;

  /// No description provided for @eventTypeWeekly.
  ///
  /// In ja, this message translates to:
  /// **'ウィークリー'**
  String get eventTypeWeekly;

  /// No description provided for @eventTypeSpecial.
  ///
  /// In ja, this message translates to:
  /// **'スペシャル'**
  String get eventTypeSpecial;

  /// No description provided for @eventTypeSeasonal.
  ///
  /// In ja, this message translates to:
  /// **'シーズナル'**
  String get eventTypeSeasonal;

  /// No description provided for @eventGame.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム'**
  String get eventGame;

  /// No description provided for @eventGameNotSet.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get eventGameNotSet;

  /// No description provided for @eventCancelled.
  ///
  /// In ja, this message translates to:
  /// **'このイベントは中止されました'**
  String get eventCancelled;

  /// No description provided for @eventHasPrize.
  ///
  /// In ja, this message translates to:
  /// **'賞品あり'**
  String get eventHasPrize;

  /// No description provided for @eventFull.
  ///
  /// In ja, this message translates to:
  /// **'満員'**
  String get eventFull;

  /// No description provided for @eventDeadline.
  ///
  /// In ja, this message translates to:
  /// **'締切'**
  String get eventDeadline;

  /// No description provided for @eventPublishing.
  ///
  /// In ja, this message translates to:
  /// **'公開中'**
  String get eventPublishing;

  /// No description provided for @eventStartingSoon.
  ///
  /// In ja, this message translates to:
  /// **'間もなく開始'**
  String get eventStartingSoon;

  /// No description provided for @eventEndsToday.
  ///
  /// In ja, this message translates to:
  /// **'本日終了'**
  String get eventEndsToday;

  /// No description provided for @eventEnded.
  ///
  /// In ja, this message translates to:
  /// **'終了済み'**
  String get eventEnded;

  /// No description provided for @eventCancelledStatus.
  ///
  /// In ja, this message translates to:
  /// **'イベント中止'**
  String get eventCancelledStatus;

  /// No description provided for @hostEventTab.
  ///
  /// In ja, this message translates to:
  /// **'主催イベント管理'**
  String get hostEventTab;

  /// No description provided for @participantEventTab.
  ///
  /// In ja, this message translates to:
  /// **'参加イベント管理'**
  String get participantEventTab;

  /// No description provided for @createNew.
  ///
  /// In ja, this message translates to:
  /// **'新規作成'**
  String get createNew;

  /// No description provided for @signInRequired.
  ///
  /// In ja, this message translates to:
  /// **'サインインが必要です'**
  String get signInRequired;

  /// No description provided for @signInToUseManagement.
  ///
  /// In ja, this message translates to:
  /// **'サインインして管理機能を使用してください'**
  String get signInToUseManagement;

  /// No description provided for @initialSetupRequired.
  ///
  /// In ja, this message translates to:
  /// **'初回設定が必要です'**
  String get initialSetupRequired;

  /// No description provided for @completeSetupToUseManagement.
  ///
  /// In ja, this message translates to:
  /// **'初回設定を完了して管理機能を使用してください'**
  String get completeSetupToUseManagement;

  /// No description provided for @upcomingTab.
  ///
  /// In ja, this message translates to:
  /// **'参加予定'**
  String get upcomingTab;

  /// No description provided for @pastEventsTab.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベント'**
  String get pastEventsTab;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加予定のイベントがありません'**
  String get noUpcomingEvents;

  /// No description provided for @joinNewEventSuggestion.
  ///
  /// In ja, this message translates to:
  /// **'新しいイベントに参加してみませんか？'**
  String get joinNewEventSuggestion;

  /// No description provided for @dataFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'データの取得に失敗しました'**
  String get dataFetchFailed;

  /// No description provided for @tryAgain.
  ///
  /// In ja, this message translates to:
  /// **'再度お試しください'**
  String get tryAgain;

  /// No description provided for @noPastParticipatedEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加した過去のイベントがありません'**
  String get noPastParticipatedEvents;

  /// No description provided for @participateToGainRecord.
  ///
  /// In ja, this message translates to:
  /// **'イベントに参加して実績を積み重ねましょう'**
  String get participateToGainRecord;

  /// No description provided for @listView.
  ///
  /// In ja, this message translates to:
  /// **'リスト表示'**
  String get listView;

  /// No description provided for @calendarView.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー表示'**
  String get calendarView;

  /// No description provided for @participationCalendar.
  ///
  /// In ja, this message translates to:
  /// **'参加予定カレンダー'**
  String get participationCalendar;

  /// No description provided for @noEventsOnThisDay.
  ///
  /// In ja, this message translates to:
  /// **'この日はイベントがありません'**
  String get noEventsOnThisDay;

  /// No description provided for @calendarLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーの読み込みに失敗しました'**
  String get calendarLoadFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル済み'**
  String get statusCancelled;

  /// No description provided for @statusScheduled.
  ///
  /// In ja, this message translates to:
  /// **'開催予定'**
  String get statusScheduled;

  /// No description provided for @statusEnded.
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get statusEnded;

  /// No description provided for @quickActions.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクション'**
  String get quickActions;

  /// No description provided for @copyEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベントをコピー'**
  String get copyEvent;

  /// No description provided for @managementOptions.
  ///
  /// In ja, this message translates to:
  /// **'管理オプション'**
  String get managementOptions;

  /// No description provided for @createdEvents.
  ///
  /// In ja, this message translates to:
  /// **'作成したイベント'**
  String get createdEvents;

  /// No description provided for @createdEventsDescription.
  ///
  /// In ja, this message translates to:
  /// **'自分が作成したイベントを管理'**
  String get createdEventsDescription;

  /// No description provided for @collaborativeEvents.
  ///
  /// In ja, this message translates to:
  /// **'共同編集者のイベント'**
  String get collaborativeEvents;

  /// No description provided for @collaborativeEventsDescription.
  ///
  /// In ja, this message translates to:
  /// **'編集権限を持つイベントを管理'**
  String get collaborativeEventsDescription;

  /// No description provided for @draftEvents.
  ///
  /// In ja, this message translates to:
  /// **'下書き保存されたイベント'**
  String get draftEvents;

  /// No description provided for @draftEventsDescription.
  ///
  /// In ja, this message translates to:
  /// **'一時保存されたイベントを管理'**
  String get draftEventsDescription;

  /// No description provided for @pastEventHistory.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベント履歴'**
  String get pastEventHistory;

  /// No description provided for @pastEventHistoryDescription.
  ///
  /// In ja, this message translates to:
  /// **'終了したイベントを閲覧・統計確認'**
  String get pastEventHistoryDescription;

  /// No description provided for @noCreatedEvents.
  ///
  /// In ja, this message translates to:
  /// **'まだイベントを作成していません'**
  String get noCreatedEvents;

  /// No description provided for @noCollaborativeEvents.
  ///
  /// In ja, this message translates to:
  /// **'共同編集できるイベントがありません'**
  String get noCollaborativeEvents;

  /// No description provided for @noDraftEvents.
  ///
  /// In ja, this message translates to:
  /// **'下書き保存されたイベントがありません'**
  String get noDraftEvents;

  /// No description provided for @noCreatedEventsDetail.
  ///
  /// In ja, this message translates to:
  /// **'「新規作成」ボタンから最初のイベントを作成しましょう'**
  String get noCreatedEventsDetail;

  /// No description provided for @noCollaborativeEventsDetail.
  ///
  /// In ja, this message translates to:
  /// **'他のユーザーから編集権限の招待を受けた場合、ここに表示されます'**
  String get noCollaborativeEventsDetail;

  /// No description provided for @noDraftEventsDetail.
  ///
  /// In ja, this message translates to:
  /// **'イベント作成時に下書き保存を利用すると、ここに表示されます'**
  String get noDraftEventsDetail;

  /// No description provided for @noPastEventsDetail.
  ///
  /// In ja, this message translates to:
  /// **'イベントが終了すると、ここに履歴として表示されます'**
  String get noPastEventsDetail;

  /// No description provided for @matchStatusScheduled.
  ///
  /// In ja, this message translates to:
  /// **'開催予定'**
  String get matchStatusScheduled;

  /// No description provided for @matchStatusInProgress.
  ///
  /// In ja, this message translates to:
  /// **'進行中'**
  String get matchStatusInProgress;

  /// No description provided for @matchStatusCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get matchStatusCompleted;

  /// No description provided for @reportStatusSubmitted.
  ///
  /// In ja, this message translates to:
  /// **'提出済み'**
  String get reportStatusSubmitted;

  /// No description provided for @reportStatusReviewing.
  ///
  /// In ja, this message translates to:
  /// **'確認中'**
  String get reportStatusReviewing;

  /// No description provided for @reportStatusResolved.
  ///
  /// In ja, this message translates to:
  /// **'解決済み'**
  String get reportStatusResolved;

  /// No description provided for @reportStatusRejected.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get reportStatusRejected;

  /// No description provided for @createdEventsFullDescription.
  ///
  /// In ja, this message translates to:
  /// **'自分が作成したイベントの一覧です。編集や削除、複製が可能です。'**
  String get createdEventsFullDescription;

  /// No description provided for @draftEventsFullDescription.
  ///
  /// In ja, this message translates to:
  /// **'一時保存されたイベントの一覧です。編集を続行して公開できます。'**
  String get draftEventsFullDescription;

  /// No description provided for @pastEventsFullDescription.
  ///
  /// In ja, this message translates to:
  /// **'終了したイベントの一覧です。統計情報や参加者データを確認できます。'**
  String get pastEventsFullDescription;

  /// No description provided for @total.
  ///
  /// In ja, this message translates to:
  /// **'合計'**
  String get total;

  /// No description provided for @published.
  ///
  /// In ja, this message translates to:
  /// **'公開中'**
  String get published;

  /// No description provided for @noCopyableEvents.
  ///
  /// In ja, this message translates to:
  /// **'コピー可能なイベントがありません\\nまず最初のイベントを作成してください'**
  String get noCopyableEvents;

  /// No description provided for @selectEventToCopy.
  ///
  /// In ja, this message translates to:
  /// **'コピーするイベントを選択'**
  String get selectEventToCopy;

  /// No description provided for @noCopyableEventsShort.
  ///
  /// In ja, this message translates to:
  /// **'コピー可能なイベントがありません'**
  String get noCopyableEventsShort;

  /// No description provided for @eventFetchError.
  ///
  /// In ja, this message translates to:
  /// **'イベントの取得中にエラーが発生しました'**
  String get eventFetchError;

  /// No description provided for @loadingData.
  ///
  /// In ja, this message translates to:
  /// **'データを読み込み中...'**
  String get loadingData;

  /// No description provided for @verifyingUserInfo.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報を確認しています'**
  String get verifyingUserInfo;

  /// No description provided for @followScreenTitle.
  ///
  /// In ja, this message translates to:
  /// **'フォロー'**
  String get followScreenTitle;

  /// No description provided for @mutualFollowTab.
  ///
  /// In ja, this message translates to:
  /// **'相互フォロー'**
  String get mutualFollowTab;

  /// No description provided for @followingTab.
  ///
  /// In ja, this message translates to:
  /// **'フォロー中'**
  String get followingTab;

  /// No description provided for @followersTab.
  ///
  /// In ja, this message translates to:
  /// **'フォロワー'**
  String get followersTab;

  /// No description provided for @noMutualFollows.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローがいません'**
  String get noMutualFollows;

  /// No description provided for @noMutualFollowsHint.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローを増やすと\\nここから簡単に運営者を選択できます'**
  String get noMutualFollowsHint;

  /// No description provided for @noFollowing.
  ///
  /// In ja, this message translates to:
  /// **'フォロー中のユーザーがいません'**
  String get noFollowing;

  /// No description provided for @noFollowingHint.
  ///
  /// In ja, this message translates to:
  /// **'気になるユーザーをフォローして\\nイベント情報を受け取りましょう'**
  String get noFollowingHint;

  /// No description provided for @noFollowers.
  ///
  /// In ja, this message translates to:
  /// **'フォロワーがいません'**
  String get noFollowers;

  /// No description provided for @noFollowersHint.
  ///
  /// In ja, this message translates to:
  /// **'あなたをフォローしてくれる\\nユーザーを待っています'**
  String get noFollowersHint;

  /// No description provided for @fetchingData.
  ///
  /// In ja, this message translates to:
  /// **'データを取得中...'**
  String get fetchingData;

  /// No description provided for @retry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;

  /// No description provided for @searchUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーを検索'**
  String get searchUser;

  /// No description provided for @searchUserPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名またはIDで検索...'**
  String get searchUserPlaceholder;

  /// No description provided for @searchUserHint.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名またはIDで検索'**
  String get searchUserHint;

  /// No description provided for @searchUserDescription.
  ///
  /// In ja, this message translates to:
  /// **'フォローしたいユーザーを\\n検索して見つけましょう'**
  String get searchUserDescription;

  /// No description provided for @searchingUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーを検索中...'**
  String get searchingUser;

  /// No description provided for @userSearchError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー検索中にエラーが発生しました'**
  String get userSearchError;

  /// No description provided for @errorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get errorOccurred;

  /// No description provided for @favoriteGamesTitle.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのゲーム'**
  String get favoriteGamesTitle;

  /// No description provided for @deleteSelectedGames.
  ///
  /// In ja, this message translates to:
  /// **'選択したゲームを削除'**
  String get deleteSelectedGames;

  /// No description provided for @deleteMode.
  ///
  /// In ja, this message translates to:
  /// **'削除モード'**
  String get deleteMode;

  /// No description provided for @exitDeleteMode.
  ///
  /// In ja, this message translates to:
  /// **'削除モードを終了'**
  String get exitDeleteMode;

  /// No description provided for @loadingFavoriteGames.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームを読み込み中...'**
  String get loadingFavoriteGames;

  /// No description provided for @noFavoriteGames.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームがありません'**
  String get noFavoriteGames;

  /// No description provided for @quickAction.
  ///
  /// In ja, this message translates to:
  /// **'クイックアクション'**
  String get quickAction;

  /// No description provided for @addGame.
  ///
  /// In ja, this message translates to:
  /// **'ゲームを追加'**
  String get addGame;

  /// No description provided for @gameProfile.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィール'**
  String get gameProfile;

  /// No description provided for @favoriteGamesList.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲーム一覧'**
  String get favoriteGamesList;

  /// No description provided for @configured.
  ///
  /// In ja, this message translates to:
  /// **'設定済み'**
  String get configured;

  /// No description provided for @notConfigured.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get notConfigured;

  /// No description provided for @today.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ja, this message translates to:
  /// **'昨日'**
  String get yesterday;

  /// No description provided for @pleaseSetGameProfile.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールを設定してください'**
  String get pleaseSetGameProfile;

  /// No description provided for @editProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール編集'**
  String get editProfile;

  /// No description provided for @setProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール設定'**
  String get setProfile;

  /// No description provided for @deleteSelectedGamesTitle.
  ///
  /// In ja, this message translates to:
  /// **'選択したゲームを削除'**
  String get deleteSelectedGamesTitle;

  /// No description provided for @gameProfileWillBeDeleted.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールも同時に削除されます'**
  String get gameProfileWillBeDeleted;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @addFavoriteGame.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームを追加'**
  String get addFavoriteGame;

  /// No description provided for @account.
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get account;

  /// No description provided for @signedIn.
  ///
  /// In ja, this message translates to:
  /// **'サインイン済み'**
  String get signedIn;

  /// No description provided for @tapToViewProfile.
  ///
  /// In ja, this message translates to:
  /// **'タップしてプロフィールを表示'**
  String get tapToViewProfile;

  /// No description provided for @profileVisibilitySettings.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール公開設定'**
  String get profileVisibilitySettings;

  /// No description provided for @profileVisibilityDescription.
  ///
  /// In ja, this message translates to:
  /// **'他のユーザーがあなたのプロフィールで閲覧できる情報を設定します'**
  String get profileVisibilityDescription;

  /// No description provided for @eventsAsOrganizer.
  ///
  /// In ja, this message translates to:
  /// **'運営者としてのイベント'**
  String get eventsAsOrganizer;

  /// No description provided for @eventsAsOrganizerDescription.
  ///
  /// In ja, this message translates to:
  /// **'主催・共同編集者として関わるイベントを表示'**
  String get eventsAsOrganizerDescription;

  /// No description provided for @upcomingEventsVisibility.
  ///
  /// In ja, this message translates to:
  /// **'参加予定イベント'**
  String get upcomingEventsVisibility;

  /// No description provided for @upcomingEventsDescription.
  ///
  /// In ja, this message translates to:
  /// **'参加予定のイベントを表示'**
  String get upcomingEventsDescription;

  /// No description provided for @pastEventsVisibility.
  ///
  /// In ja, this message translates to:
  /// **'過去参加済みイベント'**
  String get pastEventsVisibility;

  /// No description provided for @pastEventsDescription.
  ///
  /// In ja, this message translates to:
  /// **'過去に参加したイベントを表示'**
  String get pastEventsDescription;

  /// No description provided for @appInfo.
  ///
  /// In ja, this message translates to:
  /// **'アプリ情報'**
  String get appInfo;

  /// No description provided for @infoAndSupport.
  ///
  /// In ja, this message translates to:
  /// **'情報・サポート'**
  String get infoAndSupport;

  /// No description provided for @accountManagement.
  ///
  /// In ja, this message translates to:
  /// **'アカウント管理'**
  String get accountManagement;

  /// No description provided for @accountManagementDescription.
  ///
  /// In ja, this message translates to:
  /// **'アカウントに関する重要な操作'**
  String get accountManagementDescription;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ja, this message translates to:
  /// **'アカウント退会'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In ja, this message translates to:
  /// **'アカウントとすべてのデータを削除します'**
  String get deleteAccountDescription;

  /// No description provided for @signOutTitle.
  ///
  /// In ja, this message translates to:
  /// **'サインアウト'**
  String get signOutTitle;

  /// No description provided for @signedOut.
  ///
  /// In ja, this message translates to:
  /// **'サインアウトしました'**
  String get signedOut;

  /// No description provided for @failedToGetUserInfo.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報を取得できませんでした'**
  String get failedToGetUserInfo;

  /// No description provided for @failedToShowProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール画面の表示に失敗しました'**
  String get failedToShowProfile;

  /// No description provided for @failedToOpenContactForm.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせフォームを開けませんでした。'**
  String get failedToOpenContactForm;

  /// No description provided for @errorOpeningContactForm.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせフォームを開く際にエラーが発生しました。'**
  String get errorOpeningContactForm;

  /// No description provided for @rateAppTitle.
  ///
  /// In ja, this message translates to:
  /// **'アプリを評価'**
  String get rateAppTitle;

  /// No description provided for @rateAppMessage.
  ///
  /// In ja, this message translates to:
  /// **'Goをご利用いただきありがとうございます！\\nどちらの方法で評価しますか？'**
  String get rateAppMessage;

  /// No description provided for @rateWithStars.
  ///
  /// In ja, this message translates to:
  /// **'星で評価'**
  String get rateWithStars;

  /// No description provided for @writeReview.
  ///
  /// In ja, this message translates to:
  /// **'レビューを書く'**
  String get writeReview;

  /// No description provided for @later.
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get later;

  /// No description provided for @markAllAsRead.
  ///
  /// In ja, this message translates to:
  /// **'全て既読'**
  String get markAllAsRead;

  /// No description provided for @loadingNotifications.
  ///
  /// In ja, this message translates to:
  /// **'通知を取得中...'**
  String get loadingNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In ja, this message translates to:
  /// **'通知はありません'**
  String get noNotifications;

  /// No description provided for @notificationsWillAppearHere.
  ///
  /// In ja, this message translates to:
  /// **'新しい通知が届くとここに表示されます'**
  String get notificationsWillAppearHere;

  /// No description provided for @justNow.
  ///
  /// In ja, this message translates to:
  /// **'たった今'**
  String get justNow;

  /// No description provided for @applicationStatusSubmitted.
  ///
  /// In ja, this message translates to:
  /// **'申請済み'**
  String get applicationStatusSubmitted;

  /// No description provided for @applicationStatusApproved.
  ///
  /// In ja, this message translates to:
  /// **'承認済み'**
  String get applicationStatusApproved;

  /// No description provided for @applicationStatusRejected.
  ///
  /// In ja, this message translates to:
  /// **'拒否'**
  String get applicationStatusRejected;

  /// No description provided for @eventInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報が見つかりません'**
  String get eventInfoNotFound;

  /// No description provided for @eventNotFoundMayBeDeleted.
  ///
  /// In ja, this message translates to:
  /// **'イベントが見つかりません。削除された可能性があります。'**
  String get eventNotFoundMayBeDeleted;

  /// No description provided for @errorFetchingEventInfo.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報の取得中にエラーが発生しました'**
  String get errorFetchingEventInfo;

  /// No description provided for @applicantInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'申請者の情報が見つかりません'**
  String get applicantInfoNotFound;

  /// No description provided for @featureDeprecated.
  ///
  /// In ja, this message translates to:
  /// **'この機能は廃止されました'**
  String get featureDeprecated;

  /// No description provided for @errorCheckingApplicantInfo.
  ///
  /// In ja, this message translates to:
  /// **'申請者の情報確認中にエラーが発生しました'**
  String get errorCheckingApplicantInfo;

  /// No description provided for @unavailable.
  ///
  /// In ja, this message translates to:
  /// **'利用できません'**
  String get unavailable;

  /// No description provided for @notificationSenderWithdrawn.
  ///
  /// In ja, this message translates to:
  /// **'この通知の送信者は退会済みのため、この通知を処理できません。'**
  String get notificationSenderWithdrawn;

  /// No description provided for @confirm.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get confirm;

  /// No description provided for @becameMutualFollow.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローになりました！'**
  String get becameMutualFollow;

  /// No description provided for @applicationInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'申込み情報が見つかりません'**
  String get applicationInfoNotFound;

  /// No description provided for @violationInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'違反報告情報が見つかりません'**
  String get violationInfoNotFound;

  /// No description provided for @violationRecordNotFound.
  ///
  /// In ja, this message translates to:
  /// **'違反記録が見つかりません'**
  String get violationRecordNotFound;

  /// No description provided for @appealAlreadySubmitted.
  ///
  /// In ja, this message translates to:
  /// **'この違反記録には既に異議申立が提出されています'**
  String get appealAlreadySubmitted;

  /// No description provided for @notificationDataNotFound.
  ///
  /// In ja, this message translates to:
  /// **'通知データが見つかりません'**
  String get notificationDataNotFound;

  /// No description provided for @appealApproved.
  ///
  /// In ja, this message translates to:
  /// **'異議申立が承認されました'**
  String get appealApproved;

  /// No description provided for @violationRecordCancelled.
  ///
  /// In ja, this message translates to:
  /// **'違反記録が取り消されました。'**
  String get violationRecordCancelled;

  /// No description provided for @appealRejected.
  ///
  /// In ja, this message translates to:
  /// **'異議申立が却下されました'**
  String get appealRejected;

  /// No description provided for @violationRecordMaintained.
  ///
  /// In ja, this message translates to:
  /// **'違反記録が維持されます。'**
  String get violationRecordMaintained;

  /// No description provided for @appealProcessed.
  ///
  /// In ja, this message translates to:
  /// **'異議申立の処理が完了しました。'**
  String get appealProcessed;

  /// No description provided for @eventInDraftCannotView.
  ///
  /// In ja, this message translates to:
  /// **'このイベントは下書き状態のため詳細を表示できません'**
  String get eventInDraftCannotView;

  /// No description provided for @reportInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'報告情報が見つかりません'**
  String get reportInfoNotFound;

  /// No description provided for @matchInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'試合情報が見つかりません'**
  String get matchInfoNotFound;

  /// No description provided for @navigationError.
  ///
  /// In ja, this message translates to:
  /// **'画面遷移でエラーが発生しました'**
  String get navigationError;

  /// No description provided for @matchReportStatusReviewing.
  ///
  /// In ja, this message translates to:
  /// **'確認中'**
  String get matchReportStatusReviewing;

  /// No description provided for @matchReportStatusResolved.
  ///
  /// In ja, this message translates to:
  /// **'解決済み'**
  String get matchReportStatusResolved;

  /// No description provided for @matchReportStatusRejected.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get matchReportStatusRejected;

  /// No description provided for @matchReportStatusUpdated.
  ///
  /// In ja, this message translates to:
  /// **'報告の状況が更新されました'**
  String get matchReportStatusUpdated;

  /// No description provided for @userInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報が見つかりません'**
  String get userInfoNotFound;

  /// No description provided for @errorFetchingUserInfo.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の取得中にエラーが発生しました'**
  String get errorFetchingUserInfo;

  /// No description provided for @violationReportProcessed.
  ///
  /// In ja, this message translates to:
  /// **'違反報告が処理されました'**
  String get violationReportProcessed;

  /// No description provided for @violationReportProcessedDefault.
  ///
  /// In ja, this message translates to:
  /// **'違反報告が運営によって処理されました。'**
  String get violationReportProcessedDefault;

  /// No description provided for @violationReportDismissed.
  ///
  /// In ja, this message translates to:
  /// **'違反報告が棄却されました'**
  String get violationReportDismissed;

  /// No description provided for @violationReportDismissedDefault.
  ///
  /// In ja, this message translates to:
  /// **'違反報告の内容が確認できなかったため棄却されました。'**
  String get violationReportDismissedDefault;

  /// No description provided for @violationRecordDeleted.
  ///
  /// In ja, this message translates to:
  /// **'違反記録を削除しました。関係者に通知されます。'**
  String get violationRecordDeleted;

  /// No description provided for @violationRecordDeletedDefault.
  ///
  /// In ja, this message translates to:
  /// **'違反記録が削除されました。'**
  String get violationRecordDeletedDefault;

  /// No description provided for @appealDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'異議申立'**
  String get appealDialogTitle;

  /// No description provided for @violationRecordLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反記録'**
  String get violationRecordLabel;

  /// No description provided for @appealReasonLabel.
  ///
  /// In ja, this message translates to:
  /// **'異議申立の理由 *'**
  String get appealReasonLabel;

  /// No description provided for @appealReasonRequired.
  ///
  /// In ja, this message translates to:
  /// **'異議申立の理由を入力してください'**
  String get appealReasonRequired;

  /// No description provided for @appealReasonMinLength.
  ///
  /// In ja, this message translates to:
  /// **'20文字以上で詳細な理由を記載してください'**
  String get appealReasonMinLength;

  /// No description provided for @done.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get done;

  /// No description provided for @aboutAppeal.
  ///
  /// In ja, this message translates to:
  /// **'異議申立について'**
  String get aboutAppeal;

  /// No description provided for @appealNote1.
  ///
  /// In ja, this message translates to:
  /// **'運営チームが内容を審査し、回答いたします'**
  String get appealNote1;

  /// No description provided for @appealNote2.
  ///
  /// In ja, this message translates to:
  /// **'審査には数日かかる場合があります'**
  String get appealNote2;

  /// No description provided for @appealNote3.
  ///
  /// In ja, this message translates to:
  /// **'虚偽の申立は新たな違反行為とみなされます'**
  String get appealNote3;

  /// No description provided for @appealNote4.
  ///
  /// In ja, this message translates to:
  /// **'一度提出した異議申立は取り消しできません'**
  String get appealNote4;

  /// No description provided for @submitAppeal.
  ///
  /// In ja, this message translates to:
  /// **'異議申立を提出'**
  String get submitAppeal;

  /// No description provided for @appealSubmittedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'異議申立を提出しました。運営からの回答をお待ちください。'**
  String get appealSubmittedSuccess;

  /// No description provided for @cannotGetUserInfo.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報が取得できません'**
  String get cannotGetUserInfo;

  /// No description provided for @homeCreateEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベント作成'**
  String get homeCreateEvent;

  /// No description provided for @homeSearchEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベント検索'**
  String get homeSearchEvent;

  /// No description provided for @homeUpcomingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加予定イベント'**
  String get homeUpcomingEvents;

  /// No description provided for @homeLoginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインしてください'**
  String get homeLoginRequired;

  /// No description provided for @homeUserInfoFetchError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の取得に失敗しました\\nしばらくしてから再試行してください'**
  String get homeUserInfoFetchError;

  /// No description provided for @homeSeeMore.
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get homeSeeMore;

  /// No description provided for @homeNoUpcomingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加予定のイベントはありません'**
  String get homeNoUpcomingEvents;

  /// No description provided for @homeNoUpcomingEventsHint.
  ///
  /// In ja, this message translates to:
  /// **'イベントに申し込んで承認されると\\nこちらに表示されます'**
  String get homeNoUpcomingEventsHint;

  /// No description provided for @homeExploreEvents.
  ///
  /// In ja, this message translates to:
  /// **'イベントを探す'**
  String get homeExploreEvents;

  /// No description provided for @homeYourActivity.
  ///
  /// In ja, this message translates to:
  /// **'あなたのアクティビティ'**
  String get homeYourActivity;

  /// No description provided for @homeDataFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'データの取得に失敗しました'**
  String get homeDataFetchFailed;

  /// No description provided for @homeDataFetchFailedAlt.
  ///
  /// In ja, this message translates to:
  /// **'データを取得できませんでした'**
  String get homeDataFetchFailedAlt;

  /// No description provided for @homeThisMonthEvents.
  ///
  /// In ja, this message translates to:
  /// **'今月の参加イベント'**
  String get homeThisMonthEvents;

  /// No description provided for @homeThisMonthParticipation.
  ///
  /// In ja, this message translates to:
  /// **'今月の参加'**
  String get homeThisMonthParticipation;

  /// No description provided for @homeApprovedEvents.
  ///
  /// In ja, this message translates to:
  /// **'承認済みイベント'**
  String get homeApprovedEvents;

  /// No description provided for @homePendingApplications.
  ///
  /// In ja, this message translates to:
  /// **'申し込み中のイベント'**
  String get homePendingApplications;

  /// No description provided for @homePendingLabel.
  ///
  /// In ja, this message translates to:
  /// **'申し込み中'**
  String get homePendingLabel;

  /// No description provided for @homeAwaitingApproval.
  ///
  /// In ja, this message translates to:
  /// **'承認待ち'**
  String get homeAwaitingApproval;

  /// No description provided for @homeParticipationHistory.
  ///
  /// In ja, this message translates to:
  /// **'参加履歴'**
  String get homeParticipationHistory;

  /// No description provided for @homeTotalParticipation.
  ///
  /// In ja, this message translates to:
  /// **'総参加数'**
  String get homeTotalParticipation;

  /// No description provided for @homeParticipatedSoFar.
  ///
  /// In ja, this message translates to:
  /// **'これまでに参加'**
  String get homeParticipatedSoFar;

  /// No description provided for @homeHostedEvents.
  ///
  /// In ja, this message translates to:
  /// **'運営イベント'**
  String get homeHostedEvents;

  /// No description provided for @homeHostingCount.
  ///
  /// In ja, this message translates to:
  /// **'運営数'**
  String get homeHostingCount;

  /// No description provided for @homeHostedEventsSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'運営に携わったイベント'**
  String get homeHostedEventsSubtitle;

  /// No description provided for @homeRecommendedEvents.
  ///
  /// In ja, this message translates to:
  /// **'おすすめイベント'**
  String get homeRecommendedEvents;

  /// No description provided for @homeNoRecommendedEvents.
  ///
  /// In ja, this message translates to:
  /// **'該当するイベントが見つかりません'**
  String get homeNoRecommendedEvents;

  /// No description provided for @homeNoRecommendedEventsHint.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームのイベントが\\n現在開催されていません'**
  String get homeNoRecommendedEventsHint;

  /// No description provided for @homeRegisterFavoriteGames.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのゲームを登録してください'**
  String get homeRegisterFavoriteGames;

  /// No description provided for @homeRegisterFavoriteGamesButton.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームを登録'**
  String get homeRegisterFavoriteGamesButton;

  /// No description provided for @homeManagedEvents.
  ///
  /// In ja, this message translates to:
  /// **'運営中のイベント'**
  String get homeManagedEvents;

  /// No description provided for @homeLoginRequiredShort.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get homeLoginRequiredShort;

  /// No description provided for @homeNoManagedEvents.
  ///
  /// In ja, this message translates to:
  /// **'運営中のイベントはありません'**
  String get homeNoManagedEvents;

  /// No description provided for @homeNoManagedEventsHint.
  ///
  /// In ja, this message translates to:
  /// **'イベントを作成すると\\nこちらに表示されます。'**
  String get homeNoManagedEventsHint;

  /// No description provided for @homeEventSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'イベント名やゲーム名で検索...'**
  String get homeEventSearchHint;

  /// No description provided for @homeAuthError.
  ///
  /// In ja, this message translates to:
  /// **'認証エラーが発生しました'**
  String get homeAuthError;

  /// No description provided for @searchSectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get searchSectionTitle;

  /// No description provided for @searchTarget.
  ///
  /// In ja, this message translates to:
  /// **'検索対象:'**
  String get searchTarget;

  /// No description provided for @searchTypeEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get searchTypeEvent;

  /// No description provided for @searchTypeUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get searchTypeUser;

  /// No description provided for @searchTypeGame.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム名'**
  String get searchTypeGame;

  /// No description provided for @filterByFavoriteGames.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームで絞り込み'**
  String get filterByFavoriteGames;

  /// No description provided for @favoriteGamesEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームを登録するとここに表示されます'**
  String get favoriteGamesEmptyHint;

  /// No description provided for @favoriteLabel.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り'**
  String get favoriteLabel;

  /// No description provided for @loadingEvents.
  ///
  /// In ja, this message translates to:
  /// **'イベントを読み込み中...'**
  String get loadingEvents;

  /// No description provided for @noRelatedEvents.
  ///
  /// In ja, this message translates to:
  /// **'関連イベントはありません'**
  String get noRelatedEvents;

  /// No description provided for @noRelatedEventsHint.
  ///
  /// In ja, this message translates to:
  /// **'このゲームに関連する公開イベント\\nが見つかりませんでした'**
  String get noRelatedEventsHint;

  /// No description provided for @userSearchResults.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー検索結果'**
  String get userSearchResults;

  /// No description provided for @searchByUsernameOrId.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名またはIDで検索'**
  String get searchByUsernameOrId;

  /// No description provided for @searchByUsernameOrIdHint.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名またはユーザーIDで他のユーザーを検索できます'**
  String get searchByUsernameOrIdHint;

  /// No description provided for @searchingUsers.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーを検索中...'**
  String get searchingUsers;

  /// No description provided for @gameSearchResults.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム検索結果'**
  String get gameSearchResults;

  /// No description provided for @searchByGameName.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム名で検索'**
  String get searchByGameName;

  /// No description provided for @searchByGameNameHint.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム名を入力してゲームを検索し、\\n関連するイベントを確認できます'**
  String get searchByGameNameHint;

  /// No description provided for @searchingGames.
  ///
  /// In ja, this message translates to:
  /// **'ゲームを検索中...'**
  String get searchingGames;

  /// No description provided for @eventSearchResults.
  ///
  /// In ja, this message translates to:
  /// **'イベント検索結果'**
  String get eventSearchResults;

  /// No description provided for @searchByEventName.
  ///
  /// In ja, this message translates to:
  /// **'イベント名で検索...'**
  String get searchByEventName;

  /// No description provided for @searchByEventNameHint.
  ///
  /// In ja, this message translates to:
  /// **'イベント名で検索...'**
  String get searchByEventNameHint;

  /// No description provided for @searchingEvents.
  ///
  /// In ja, this message translates to:
  /// **'イベントを検索中...'**
  String get searchingEvents;

  /// No description provided for @enterSearchKeyword.
  ///
  /// In ja, this message translates to:
  /// **'検索ワードを入力してください'**
  String get enterSearchKeyword;

  /// No description provided for @searchResults.
  ///
  /// In ja, this message translates to:
  /// **'検索結果'**
  String get searchResults;

  /// No description provided for @keyboardSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'キーワードを入力して検索'**
  String get keyboardSearchHint;

  /// No description provided for @keyboardSearchDescription.
  ///
  /// In ja, this message translates to:
  /// **'Enterキーを押すか、検索ボタンをタップして検索してください'**
  String get keyboardSearchDescription;

  /// No description provided for @userNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりません'**
  String get userNotFound;

  /// No description provided for @gameNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ゲームが見つかりません'**
  String get gameNotFound;

  /// No description provided for @eventNotFound.
  ///
  /// In ja, this message translates to:
  /// **'イベントが見つかりません'**
  String get eventNotFound;

  /// No description provided for @createButton.
  ///
  /// In ja, this message translates to:
  /// **'作成'**
  String get createButton;

  /// No description provided for @unknownGame.
  ///
  /// In ja, this message translates to:
  /// **'不明なゲーム'**
  String get unknownGame;

  /// No description provided for @eventSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'イベント名やゲーム名で検索...'**
  String get eventSearchHint;

  /// No description provided for @noMatchingEvents.
  ///
  /// In ja, this message translates to:
  /// **'条件に一致するイベントがありません'**
  String get noMatchingEvents;

  /// No description provided for @changeFilterSuggestion.
  ///
  /// In ja, this message translates to:
  /// **'フィルターを変更してみてください'**
  String get changeFilterSuggestion;

  /// No description provided for @clearFilter.
  ///
  /// In ja, this message translates to:
  /// **'フィルターをクリア'**
  String get clearFilter;

  /// No description provided for @noEventsOnDate.
  ///
  /// In ja, this message translates to:
  /// **'この日はイベントがありません'**
  String get noEventsOnDate;

  /// No description provided for @pastEventsHistoryTitle.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベント履歴'**
  String get pastEventsHistoryTitle;

  /// No description provided for @statusFilterLabel.
  ///
  /// In ja, this message translates to:
  /// **'ステータス'**
  String get statusFilterLabel;

  /// No description provided for @periodFilterLabel.
  ///
  /// In ja, this message translates to:
  /// **'期間'**
  String get periodFilterLabel;

  /// No description provided for @gameFilterLabel.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム'**
  String get gameFilterLabel;

  /// No description provided for @sortLabel.
  ///
  /// In ja, this message translates to:
  /// **'ソート'**
  String get sortLabel;

  /// No description provided for @allGames.
  ///
  /// In ja, this message translates to:
  /// **'全てのゲーム'**
  String get allGames;

  /// No description provided for @pastEventSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'イベント名、説明、ゲーム名で検索...'**
  String get pastEventSearchHint;

  /// No description provided for @filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get filterAll;

  /// No description provided for @filterCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了済み'**
  String get filterCompleted;

  /// No description provided for @filterCancelled.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get filterCancelled;

  /// No description provided for @sortDateNewest.
  ///
  /// In ja, this message translates to:
  /// **'開催日（新しい順）'**
  String get sortDateNewest;

  /// No description provided for @sortDateOldest.
  ///
  /// In ja, this message translates to:
  /// **'開催日（古い順）'**
  String get sortDateOldest;

  /// No description provided for @sortParticipantsDesc.
  ///
  /// In ja, this message translates to:
  /// **'参加者数（多い順）'**
  String get sortParticipantsDesc;

  /// No description provided for @sortParticipantsAsc.
  ///
  /// In ja, this message translates to:
  /// **'参加者数（少ない順）'**
  String get sortParticipantsAsc;

  /// No description provided for @periodMonth.
  ///
  /// In ja, this message translates to:
  /// **'最近1ヶ月'**
  String get periodMonth;

  /// No description provided for @periodThreeMonth.
  ///
  /// In ja, this message translates to:
  /// **'最近3ヶ月'**
  String get periodThreeMonth;

  /// No description provided for @periodSixMonth.
  ///
  /// In ja, this message translates to:
  /// **'最近6ヶ月'**
  String get periodSixMonth;

  /// No description provided for @periodYear.
  ///
  /// In ja, this message translates to:
  /// **'最近1年'**
  String get periodYear;

  /// No description provided for @periodAll.
  ///
  /// In ja, this message translates to:
  /// **'全期間'**
  String get periodAll;

  /// No description provided for @statusCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get statusCompleted;

  /// No description provided for @participantCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者数: '**
  String get participantCountLabel;

  /// No description provided for @noSearchResults.
  ///
  /// In ja, this message translates to:
  /// **'検索結果が見つかりません'**
  String get noSearchResults;

  /// No description provided for @changeSearchCondition.
  ///
  /// In ja, this message translates to:
  /// **'条件を変更して再度検索してください'**
  String get changeSearchCondition;

  /// No description provided for @noPastEvents.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベントがありません'**
  String get noPastEvents;

  /// No description provided for @noCompletedEventsYet.
  ///
  /// In ja, this message translates to:
  /// **'まだ完了したイベントがありません'**
  String get noCompletedEventsYet;

  /// No description provided for @gameProfileEditTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール編集'**
  String get gameProfileEditTitle;

  /// No description provided for @gameProfileCreateTitle.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィール作成'**
  String get gameProfileCreateTitle;

  /// No description provided for @deleteProfileTooltip.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを削除'**
  String get deleteProfileTooltip;

  /// No description provided for @saving.
  ///
  /// In ja, this message translates to:
  /// **'保存中...'**
  String get saving;

  /// No description provided for @gameName.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム名'**
  String get gameName;

  /// No description provided for @selectedGame.
  ///
  /// In ja, this message translates to:
  /// **'選択されたゲーム'**
  String get selectedGame;

  /// No description provided for @editExistingProfile.
  ///
  /// In ja, this message translates to:
  /// **'既存プロフィールを編集'**
  String get editExistingProfile;

  /// No description provided for @createNewProfile.
  ///
  /// In ja, this message translates to:
  /// **'新しいプロフィールを作成'**
  String get createNewProfile;

  /// No description provided for @createProfileDescription.
  ///
  /// In ja, this message translates to:
  /// **'すべての項目は任意入力です。後から編集も可能です'**
  String get createProfileDescription;

  /// No description provided for @basicInfo.
  ///
  /// In ja, this message translates to:
  /// **'基本情報'**
  String get basicInfo;

  /// No description provided for @gameUsername.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ユーザー名'**
  String get gameUsername;

  /// No description provided for @gameUsernameHint.
  ///
  /// In ja, this message translates to:
  /// **'例: プレイヤー001, GamerTag'**
  String get gameUsernameHint;

  /// No description provided for @gameUserId.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ユーザーID'**
  String get gameUserId;

  /// No description provided for @gameUserIdHint.
  ///
  /// In ja, this message translates to:
  /// **'例: #1234, @username, user_id_12345'**
  String get gameUserIdHint;

  /// No description provided for @clanName.
  ///
  /// In ja, this message translates to:
  /// **'クラン名'**
  String get clanName;

  /// No description provided for @clanNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例: TeamAlpha, ProGuild, [ABC]Clan'**
  String get clanNameHint;

  /// No description provided for @skillLevelSection.
  ///
  /// In ja, this message translates to:
  /// **'スキルレベル'**
  String get skillLevelSection;

  /// Skill level beginner
  ///
  /// In ja, this message translates to:
  /// **'初心者'**
  String get skillLevelBeginner;

  /// No description provided for @skillLevelBeginnerDescription.
  ///
  /// In ja, this message translates to:
  /// **'始めたばかり、基本的な操作を学習中'**
  String get skillLevelBeginnerDescription;

  /// Skill level intermediate
  ///
  /// In ja, this message translates to:
  /// **'中級者'**
  String get skillLevelIntermediate;

  /// No description provided for @skillLevelIntermediateDescription.
  ///
  /// In ja, this message translates to:
  /// **'基本操作は慣れて、戦略を学習中'**
  String get skillLevelIntermediateDescription;

  /// Skill level advanced
  ///
  /// In ja, this message translates to:
  /// **'上級者'**
  String get skillLevelAdvanced;

  /// No description provided for @skillLevelAdvancedDescription.
  ///
  /// In ja, this message translates to:
  /// **'高度な戦略やテクニックを習得済み'**
  String get skillLevelAdvancedDescription;

  /// No description provided for @skillLevelExpert.
  ///
  /// In ja, this message translates to:
  /// **'エキスパート'**
  String get skillLevelExpert;

  /// No description provided for @skillLevelExpertDescription.
  ///
  /// In ja, this message translates to:
  /// **'プロレベル、他の人に教えられる'**
  String get skillLevelExpertDescription;

  /// No description provided for @rankOrLevel.
  ///
  /// In ja, this message translates to:
  /// **'ランク・レベル'**
  String get rankOrLevel;

  /// No description provided for @rankOrLevelHint.
  ///
  /// In ja, this message translates to:
  /// **'例: ダイヤモンド, レベル50, プラチナⅢ'**
  String get rankOrLevelHint;

  /// No description provided for @playStyleSection.
  ///
  /// In ja, this message translates to:
  /// **'プレイスタイル'**
  String get playStyleSection;

  /// Play style casual
  ///
  /// In ja, this message translates to:
  /// **'カジュアル'**
  String get playStyleCasual;

  /// No description provided for @playStyleCasualDescription.
  ///
  /// In ja, this message translates to:
  /// **'のんびり楽しくプレイ'**
  String get playStyleCasualDescription;

  /// No description provided for @playStyleCompetitive.
  ///
  /// In ja, this message translates to:
  /// **'競技志向'**
  String get playStyleCompetitive;

  /// No description provided for @playStyleCompetitiveDescription.
  ///
  /// In ja, this message translates to:
  /// **'ランクマッチや大会を重視'**
  String get playStyleCompetitiveDescription;

  /// No description provided for @playStyleCooperative.
  ///
  /// In ja, this message translates to:
  /// **'協力プレイ'**
  String get playStyleCooperative;

  /// No description provided for @playStyleCooperativeDescription.
  ///
  /// In ja, this message translates to:
  /// **'チームで協力してプレイ'**
  String get playStyleCooperativeDescription;

  /// No description provided for @playStyleSolo.
  ///
  /// In ja, this message translates to:
  /// **'ソロプレイ'**
  String get playStyleSolo;

  /// No description provided for @playStyleSoloDescription.
  ///
  /// In ja, this message translates to:
  /// **'一人でじっくりプレイ'**
  String get playStyleSoloDescription;

  /// Play style social
  ///
  /// In ja, this message translates to:
  /// **'ソーシャル'**
  String get playStyleSocial;

  /// No description provided for @playStyleSocialDescription.
  ///
  /// In ja, this message translates to:
  /// **'他のプレイヤーとの交流を重視'**
  String get playStyleSocialDescription;

  /// No description provided for @playStyleSpeedrun.
  ///
  /// In ja, this message translates to:
  /// **'スピードラン'**
  String get playStyleSpeedrun;

  /// No description provided for @playStyleSpeedrunDescription.
  ///
  /// In ja, this message translates to:
  /// **'最短クリアを目指す'**
  String get playStyleSpeedrunDescription;

  /// No description provided for @playStyleCollector.
  ///
  /// In ja, this message translates to:
  /// **'コレクター'**
  String get playStyleCollector;

  /// No description provided for @playStyleCollectorDescription.
  ///
  /// In ja, this message translates to:
  /// **'アイテムや実績の収集を重視'**
  String get playStyleCollectorDescription;

  /// No description provided for @playStyleDescription.
  ///
  /// In ja, this message translates to:
  /// **'当てはまるものを選択してください（任意）'**
  String get playStyleDescription;

  /// No description provided for @activityTimeSection.
  ///
  /// In ja, this message translates to:
  /// **'活動時間帯'**
  String get activityTimeSection;

  /// No description provided for @activityTimeMorning.
  ///
  /// In ja, this message translates to:
  /// **'朝（6-12時）'**
  String get activityTimeMorning;

  /// No description provided for @activityTimeAfternoon.
  ///
  /// In ja, this message translates to:
  /// **'昼（12-18時）'**
  String get activityTimeAfternoon;

  /// No description provided for @activityTimeEvening.
  ///
  /// In ja, this message translates to:
  /// **'夜（18-24時）'**
  String get activityTimeEvening;

  /// No description provided for @activityTimeNight.
  ///
  /// In ja, this message translates to:
  /// **'深夜（24-6時）'**
  String get activityTimeNight;

  /// No description provided for @activityTimeWeekend.
  ///
  /// In ja, this message translates to:
  /// **'週末'**
  String get activityTimeWeekend;

  /// No description provided for @activityTimeWeekday.
  ///
  /// In ja, this message translates to:
  /// **'平日'**
  String get activityTimeWeekday;

  /// No description provided for @activityTimeDescription.
  ///
  /// In ja, this message translates to:
  /// **'よくプレイする時間帯を選択してください'**
  String get activityTimeDescription;

  /// No description provided for @voiceChatSection.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット'**
  String get voiceChatSection;

  /// No description provided for @inGameVC.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内VC'**
  String get inGameVC;

  /// No description provided for @vcAvailable.
  ///
  /// In ja, this message translates to:
  /// **'利用可能'**
  String get vcAvailable;

  /// No description provided for @vcUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'利用不可'**
  String get vcUnavailable;

  /// No description provided for @vcDetails.
  ///
  /// In ja, this message translates to:
  /// **'VC詳細情報'**
  String get vcDetails;

  /// No description provided for @vcDetailsHint.
  ///
  /// In ja, this message translates to:
  /// **'例: ゲーム内VCメイン、Discord: user#1234、○時以降はVC可能'**
  String get vcDetailsHint;

  /// No description provided for @additionalInfo.
  ///
  /// In ja, this message translates to:
  /// **'その他の情報'**
  String get additionalInfo;

  /// No description provided for @achievements.
  ///
  /// In ja, this message translates to:
  /// **'達成実績・アピールポイント'**
  String get achievements;

  /// No description provided for @achievementsHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 世界ランキング100位、大会優勝歴あり、配信経験あり'**
  String get achievementsHint;

  /// No description provided for @freeNotes.
  ///
  /// In ja, this message translates to:
  /// **'自由記入・メモ'**
  String get freeNotes;

  /// No description provided for @freeNotesHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 初心者歓迎、まったりプレイ希望、ボイスチャット可能'**
  String get freeNotesHint;

  /// No description provided for @snsAccountsSection.
  ///
  /// In ja, this message translates to:
  /// **'SNSアカウント'**
  String get snsAccountsSection;

  /// No description provided for @snsAccountsDescription.
  ///
  /// In ja, this message translates to:
  /// **'このゲーム専用のSNSアカウントがある場合は入力してください'**
  String get snsAccountsDescription;

  /// No description provided for @snsUsernameHint.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名（@なし）'**
  String get snsUsernameHint;

  /// No description provided for @youtubeChannelHint.
  ///
  /// In ja, this message translates to:
  /// **'チャンネル名（@なし）'**
  String get youtubeChannelHint;

  /// No description provided for @discordUsernameHint.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名#1234（#タグ込み）'**
  String get discordUsernameHint;

  /// No description provided for @saveChanges.
  ///
  /// In ja, this message translates to:
  /// **'変更を保存'**
  String get saveChanges;

  /// No description provided for @createProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを作成'**
  String get createProfile;

  /// No description provided for @failedToGetUserInfoShort.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の取得に失敗しました'**
  String get failedToGetUserInfoShort;

  /// No description provided for @profileUpdated.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを更新しました'**
  String get profileUpdated;

  /// No description provided for @profileCreated.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを作成しました'**
  String get profileCreated;

  /// No description provided for @saveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗しました。もう一度お試しください。'**
  String get saveFailed;

  /// No description provided for @deleteProfileTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを削除'**
  String get deleteProfileTitle;

  /// No description provided for @profileAndFavoriteDeleted.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールとお気に入りから削除しました'**
  String get profileAndFavoriteDeleted;

  /// No description provided for @gameSelection.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム選択'**
  String get gameSelection;

  /// No description provided for @searchSection.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get searchSection;

  /// No description provided for @searchGameHint.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム名で検索...'**
  String get searchGameHint;

  /// No description provided for @favoritesTab.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り'**
  String get favoritesTab;

  /// No description provided for @searchTab2.
  ///
  /// In ja, this message translates to:
  /// **'検索'**
  String get searchTab2;

  /// No description provided for @noFavoriteGamesShort.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームがありません'**
  String get noFavoriteGamesShort;

  /// No description provided for @addFavoriteGamesFromProfile.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール画面でゲームを\\nお気に入りに追加できます'**
  String get addFavoriteGamesFromProfile;

  /// No description provided for @enterGameNameToSearch.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム名を入力して検索してください'**
  String get enterGameNameToSearch;

  /// No description provided for @gameNotFoundShort.
  ///
  /// In ja, this message translates to:
  /// **'ゲームが見つかりませんでした'**
  String get gameNotFoundShort;

  /// No description provided for @notSelected.
  ///
  /// In ja, this message translates to:
  /// **'未選択'**
  String get notSelected;

  /// No description provided for @select.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get select;

  /// No description provided for @pleaseSelectGame.
  ///
  /// In ja, this message translates to:
  /// **'ゲームを選択してください'**
  String get pleaseSelectGame;

  /// No description provided for @profileUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりません'**
  String get profileUserNotFound;

  /// No description provided for @profileShareFailed.
  ///
  /// In ja, this message translates to:
  /// **'共有に失敗しました'**
  String get profileShareFailed;

  /// No description provided for @profileFetchingUserInfo.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報を取得中...'**
  String get profileFetchingUserInfo;

  /// No description provided for @profileRetry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get profileRetry;

  /// No description provided for @profileFollow.
  ///
  /// In ja, this message translates to:
  /// **'フォロー'**
  String get profileFollow;

  /// No description provided for @profileFollowing.
  ///
  /// In ja, this message translates to:
  /// **'フォロー中'**
  String get profileFollowing;

  /// No description provided for @profileMutualFollow.
  ///
  /// In ja, this message translates to:
  /// **'相互フォロー'**
  String get profileMutualFollow;

  /// No description provided for @profileSnsAccounts.
  ///
  /// In ja, this message translates to:
  /// **'SNSアカウント'**
  String get profileSnsAccounts;

  /// No description provided for @profileLinkOpenFailed.
  ///
  /// In ja, this message translates to:
  /// **'リンクを開けませんでした'**
  String get profileLinkOpenFailed;

  /// No description provided for @profileDiscordCopied.
  ///
  /// In ja, this message translates to:
  /// **'Discord ID をコピーしました'**
  String get profileDiscordCopied;

  /// No description provided for @profileCopyFailed.
  ///
  /// In ja, this message translates to:
  /// **'コピーに失敗しました'**
  String get profileCopyFailed;

  /// No description provided for @profileBio.
  ///
  /// In ja, this message translates to:
  /// **'自己紹介'**
  String get profileBio;

  /// No description provided for @profileOtherInfo.
  ///
  /// In ja, this message translates to:
  /// **'その他の情報'**
  String get profileOtherInfo;

  /// No description provided for @profileFavoriteGames.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲーム'**
  String get profileFavoriteGames;

  /// No description provided for @profileNoFavoriteGames.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームが設定されていません'**
  String get profileNoFavoriteGames;

  /// No description provided for @profileFollowedUser.
  ///
  /// In ja, this message translates to:
  /// **'フォローしました'**
  String get profileFollowedUser;

  /// No description provided for @profileFollowFailed.
  ///
  /// In ja, this message translates to:
  /// **'フォローに失敗しました'**
  String get profileFollowFailed;

  /// No description provided for @profileUnfollowedUser.
  ///
  /// In ja, this message translates to:
  /// **'フォロー解除しました'**
  String get profileUnfollowedUser;

  /// No description provided for @profileUnfollowFailed.
  ///
  /// In ja, this message translates to:
  /// **'フォロー解除に失敗しました'**
  String get profileUnfollowFailed;

  /// No description provided for @profileEventsAsOrganizer.
  ///
  /// In ja, this message translates to:
  /// **'運営者としてのイベント'**
  String get profileEventsAsOrganizer;

  /// No description provided for @profileNoOrganizerEvents.
  ///
  /// In ja, this message translates to:
  /// **'運営者として関わるイベントはありません'**
  String get profileNoOrganizerEvents;

  /// No description provided for @profileSeeMore.
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get profileSeeMore;

  /// No description provided for @profileUpcomingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加予定イベント'**
  String get profileUpcomingEvents;

  /// No description provided for @profileNoUpcomingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加予定のイベントはありません'**
  String get profileNoUpcomingEvents;

  /// No description provided for @profilePastEvents.
  ///
  /// In ja, this message translates to:
  /// **'過去参加済みイベント'**
  String get profilePastEvents;

  /// No description provided for @profileNoPastEvents.
  ///
  /// In ja, this message translates to:
  /// **'過去に参加したイベントはありません'**
  String get profileNoPastEvents;

  /// No description provided for @profilePastEventsEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'イベントに参加すると\\nこちらに履歴が表示されます'**
  String get profilePastEventsEmptyHint;

  /// No description provided for @profileGameProfileNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールが見つかりません'**
  String get profileGameProfileNotFound;

  /// No description provided for @userSettingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー設定'**
  String get userSettingsTitle;

  /// No description provided for @welcomeInitialSetup.
  ///
  /// In ja, this message translates to:
  /// **'ようこそ！初回設定'**
  String get welcomeInitialSetup;

  /// No description provided for @userInfoSection.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報'**
  String get userInfoSection;

  /// No description provided for @usernameLabel.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名'**
  String get usernameLabel;

  /// No description provided for @userIdLabel.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーID'**
  String get userIdLabel;

  /// No description provided for @bioLabel.
  ///
  /// In ja, this message translates to:
  /// **'自己紹介'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In ja, this message translates to:
  /// **'自分について簡単に紹介してください...'**
  String get bioHint;

  /// No description provided for @favoriteGamesSection.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲーム'**
  String get favoriteGamesSection;

  /// No description provided for @addButton.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get addButton;

  /// No description provided for @noFavoriteGamesRegistered.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームが登録されていません'**
  String get noFavoriteGamesRegistered;

  /// No description provided for @addFavoriteGameTitle.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームを追加'**
  String get addFavoriteGameTitle;

  /// No description provided for @communityOtherInfoSection.
  ///
  /// In ja, this message translates to:
  /// **'コミュニティ・その他の情報'**
  String get communityOtherInfoSection;

  /// No description provided for @communityOtherLabel.
  ///
  /// In ja, this message translates to:
  /// **'コミュニティ・その他'**
  String get communityOtherLabel;

  /// No description provided for @snsAccountSection.
  ///
  /// In ja, this message translates to:
  /// **'SNSアカウント'**
  String get snsAccountSection;

  /// No description provided for @cancelButton.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancelButton;

  /// No description provided for @saveButton.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get saveButton;

  /// No description provided for @completeSetupButton.
  ///
  /// In ja, this message translates to:
  /// **'設定を完了'**
  String get completeSetupButton;

  /// No description provided for @doneButton.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get doneButton;

  /// No description provided for @deleteAvatarTitle.
  ///
  /// In ja, this message translates to:
  /// **'アバターを削除'**
  String get deleteAvatarTitle;

  /// No description provided for @deleteAvatarMessage.
  ///
  /// In ja, this message translates to:
  /// **'アバター画像を削除しますか？'**
  String get deleteAvatarMessage;

  /// No description provided for @welcomeDescription.
  ///
  /// In ja, this message translates to:
  /// **'ゲームイベントをより楽しむために、プロフィール情報を設定しましょう。'**
  String get welcomeDescription;

  /// No description provided for @initialSetupMessage.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール設定を完了してゲームイベントを楽しみましょう'**
  String get initialSetupMessage;

  /// No description provided for @enterUsernameError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名を入力してください'**
  String get enterUsernameError;

  /// No description provided for @usernameMinLengthError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名は2文字以上で入力してください'**
  String get usernameMinLengthError;

  /// No description provided for @enterUserIdError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーIDを入力してください'**
  String get enterUserIdError;

  /// No description provided for @userIdLengthError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーIDは3文字以上20文字以下で入力してください'**
  String get userIdLengthError;

  /// No description provided for @userIdFormatError.
  ///
  /// In ja, this message translates to:
  /// **'英字・数字・アンダーバー(_)のみ入力できます'**
  String get userIdFormatError;

  /// No description provided for @userIdStartError.
  ///
  /// In ja, this message translates to:
  /// **'英字から始めてください（例: game123）'**
  String get userIdStartError;

  /// No description provided for @userIdReservedError.
  ///
  /// In ja, this message translates to:
  /// **'別のユーザーIDをお選びください'**
  String get userIdReservedError;

  /// No description provided for @userIdDuplicateError.
  ///
  /// In ja, this message translates to:
  /// **'このユーザーIDは既に使用されています'**
  String get userIdDuplicateError;

  /// No description provided for @noAuthenticatedUser.
  ///
  /// In ja, this message translates to:
  /// **'認証されたユーザーが見つかりません'**
  String get noAuthenticatedUser;

  /// No description provided for @settingsSavedTitle.
  ///
  /// In ja, this message translates to:
  /// **'設定保存'**
  String get settingsSavedTitle;

  /// No description provided for @settingsSavedMessage.
  ///
  /// In ja, this message translates to:
  /// **'設定が保存されました。'**
  String get settingsSavedMessage;

  /// No description provided for @guestUserDefault.
  ///
  /// In ja, this message translates to:
  /// **'ゲストユーザー'**
  String get guestUserDefault;

  /// No description provided for @userDefault.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get userDefault;

  /// No description provided for @eventNameCopied.
  ///
  /// In ja, this message translates to:
  /// **'イベント名をコピーしました'**
  String get eventNameCopied;

  /// No description provided for @shareEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベントを共有'**
  String get shareEvent;

  /// No description provided for @eventOverview.
  ///
  /// In ja, this message translates to:
  /// **'イベント概要'**
  String get eventOverview;

  /// No description provided for @copyEventName.
  ///
  /// In ja, this message translates to:
  /// **'イベント名をコピー'**
  String get copyEventName;

  /// No description provided for @eventCancellationNotice.
  ///
  /// In ja, this message translates to:
  /// **'イベント中止のお知らせ'**
  String get eventCancellationNotice;

  /// No description provided for @eventHasBeenCancelled.
  ///
  /// In ja, this message translates to:
  /// **'このイベントは中止されました'**
  String get eventHasBeenCancelled;

  /// No description provided for @cancellationReason.
  ///
  /// In ja, this message translates to:
  /// **'中止理由'**
  String get cancellationReason;

  /// No description provided for @detailsAndNotes.
  ///
  /// In ja, this message translates to:
  /// **'詳細・補足説明'**
  String get detailsAndNotes;

  /// No description provided for @schedule.
  ///
  /// In ja, this message translates to:
  /// **'スケジュール'**
  String get schedule;

  /// No description provided for @eventDateTimeLabel.
  ///
  /// In ja, this message translates to:
  /// **'開催日時'**
  String get eventDateTimeLabel;

  /// No description provided for @registrationDeadline.
  ///
  /// In ja, this message translates to:
  /// **'申込期限'**
  String get registrationDeadline;

  /// No description provided for @registrationExpired.
  ///
  /// In ja, this message translates to:
  /// **'申込期限切れ'**
  String get registrationExpired;

  /// No description provided for @registrationExpiredMessage.
  ///
  /// In ja, this message translates to:
  /// **'申込期限が過ぎています'**
  String get registrationExpiredMessage;

  /// No description provided for @gameInfo.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム情報'**
  String get gameInfo;

  /// No description provided for @gameInfoNotSet.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム情報未設定'**
  String get gameInfoNotSet;

  /// No description provided for @gameInfoNotSetDescription.
  ///
  /// In ja, this message translates to:
  /// **'このイベントではゲーム情報が指定されていません'**
  String get gameInfoNotSetDescription;

  /// No description provided for @prizeContent.
  ///
  /// In ja, this message translates to:
  /// **'賞品内容'**
  String get prizeContent;

  /// No description provided for @participationFee.
  ///
  /// In ja, this message translates to:
  /// **'参加費用'**
  String get participationFee;

  /// No description provided for @participationAmount.
  ///
  /// In ja, this message translates to:
  /// **'参加金額'**
  String get participationAmount;

  /// No description provided for @feeNote.
  ///
  /// In ja, this message translates to:
  /// **'参加費用補足'**
  String get feeNote;

  /// No description provided for @sponsor.
  ///
  /// In ja, this message translates to:
  /// **'スポンサー'**
  String get sponsor;

  /// No description provided for @participationInfo.
  ///
  /// In ja, this message translates to:
  /// **'参加情報'**
  String get participationInfo;

  /// No description provided for @participantCount.
  ///
  /// In ja, this message translates to:
  /// **'参加者数'**
  String get participantCount;

  /// No description provided for @eventFullMessage.
  ///
  /// In ja, this message translates to:
  /// **'このイベントは定員に達しています'**
  String get eventFullMessage;

  /// No description provided for @rulesAndTerms.
  ///
  /// In ja, this message translates to:
  /// **'ルール・規約'**
  String get rulesAndTerms;

  /// No description provided for @streamingViewing.
  ///
  /// In ja, this message translates to:
  /// **'配信視聴'**
  String get streamingViewing;

  /// No description provided for @cancellationPolicy.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル・変更ポリシー'**
  String get cancellationPolicy;

  /// No description provided for @additionalNotes.
  ///
  /// In ja, this message translates to:
  /// **'追加情報・注意事項'**
  String get additionalNotes;

  /// No description provided for @organizerInfo.
  ///
  /// In ja, this message translates to:
  /// **'運営情報'**
  String get organizerInfo;

  /// No description provided for @organizer.
  ///
  /// In ja, this message translates to:
  /// **'運営者'**
  String get organizer;

  /// No description provided for @adminOnlyInfo.
  ///
  /// In ja, this message translates to:
  /// **'管理者専用情報'**
  String get adminOnlyInfo;

  /// No description provided for @visibilityScope.
  ///
  /// In ja, this message translates to:
  /// **'公開範囲'**
  String get visibilityScope;

  /// No description provided for @passwordSetting.
  ///
  /// In ja, this message translates to:
  /// **'パスワード設定'**
  String get passwordSetting;

  /// No description provided for @invitedUsers.
  ///
  /// In ja, this message translates to:
  /// **'招待ユーザー'**
  String get invitedUsers;

  /// No description provided for @inviteOnlyPasswordNote.
  ///
  /// In ja, this message translates to:
  /// **'招待制イベントではパスワード認証により参加を制御しています'**
  String get inviteOnlyPasswordNote;

  /// No description provided for @creator.
  ///
  /// In ja, this message translates to:
  /// **'作成者'**
  String get creator;

  /// No description provided for @createdAt.
  ///
  /// In ja, this message translates to:
  /// **'作成日時'**
  String get createdAt;

  /// No description provided for @lastUpdatedBy.
  ///
  /// In ja, this message translates to:
  /// **'最終更新者'**
  String get lastUpdatedBy;

  /// No description provided for @lastUpdatedAt.
  ///
  /// In ja, this message translates to:
  /// **'最終更新日時'**
  String get lastUpdatedAt;

  /// No description provided for @eventManagement.
  ///
  /// In ja, this message translates to:
  /// **'イベント管理'**
  String get eventManagement;

  /// No description provided for @hasManagementPermission.
  ///
  /// In ja, this message translates to:
  /// **'このイベントの管理者権限があります'**
  String get hasManagementPermission;

  /// No description provided for @managementFeatures.
  ///
  /// In ja, this message translates to:
  /// **'管理機能'**
  String get managementFeatures;

  /// No description provided for @eventEdit.
  ///
  /// In ja, this message translates to:
  /// **'イベント編集'**
  String get eventEdit;

  /// No description provided for @eventEditDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報の編集・更新'**
  String get eventEditDescription;

  /// No description provided for @operationManagement.
  ///
  /// In ja, this message translates to:
  /// **'運営管理'**
  String get operationManagement;

  /// No description provided for @operationManagementDescription.
  ///
  /// In ja, this message translates to:
  /// **'参加者・グループ・結果管理'**
  String get operationManagementDescription;

  /// No description provided for @participantMenu.
  ///
  /// In ja, this message translates to:
  /// **'参加者メニュー'**
  String get participantMenu;

  /// No description provided for @approvedParticipantFeatures.
  ///
  /// In ja, this message translates to:
  /// **'承認済み参加者向け機能'**
  String get approvedParticipantFeatures;

  /// No description provided for @participantFeatures.
  ///
  /// In ja, this message translates to:
  /// **'参加者機能'**
  String get participantFeatures;

  /// No description provided for @groupInfo.
  ///
  /// In ja, this message translates to:
  /// **'グループ情報'**
  String get groupInfo;

  /// No description provided for @groupInfoSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'所属グループの確認'**
  String get groupInfoSubtitle;

  /// No description provided for @participantList.
  ///
  /// In ja, this message translates to:
  /// **'参加者一覧'**
  String get participantList;

  /// No description provided for @participantListSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加者の確認'**
  String get participantListSubtitle;

  /// No description provided for @matchResults.
  ///
  /// In ja, this message translates to:
  /// **'戦績・結果確認'**
  String get matchResults;

  /// No description provided for @matchResultsSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'試合結果とランキングの確認'**
  String get matchResultsSubtitle;

  /// No description provided for @violationReport.
  ///
  /// In ja, this message translates to:
  /// **'違反報告'**
  String get violationReport;

  /// No description provided for @violationReportSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'迷惑行為の報告'**
  String get violationReportSubtitle;

  /// No description provided for @applicationCompleted.
  ///
  /// In ja, this message translates to:
  /// **'参加申し込みが完了しました'**
  String get applicationCompleted;

  /// No description provided for @loginToApply.
  ///
  /// In ja, this message translates to:
  /// **'ログインして参加申し込み'**
  String get loginToApply;

  /// No description provided for @applyToParticipate.
  ///
  /// In ja, this message translates to:
  /// **'参加申し込み'**
  String get applyToParticipate;

  /// No description provided for @appliedWaitlist.
  ///
  /// In ja, this message translates to:
  /// **'申し込み済み（キャンセル待ち）'**
  String get appliedWaitlist;

  /// No description provided for @appliedPending.
  ///
  /// In ja, this message translates to:
  /// **'申し込み済み（承認待ち）'**
  String get appliedPending;

  /// No description provided for @waitlistNote.
  ///
  /// In ja, this message translates to:
  /// **'このイベントは満員ですが、あなたの申請はキャンセル待ちとして受付中です。'**
  String get waitlistNote;

  /// No description provided for @cancelApplication.
  ///
  /// In ja, this message translates to:
  /// **'申し込みをキャンセル'**
  String get cancelApplication;

  /// No description provided for @participationConfirmed.
  ///
  /// In ja, this message translates to:
  /// **'参加確定'**
  String get participationConfirmed;

  /// No description provided for @participationApproved.
  ///
  /// In ja, this message translates to:
  /// **'参加が承認されました'**
  String get participationApproved;

  /// No description provided for @cancelParticipation.
  ///
  /// In ja, this message translates to:
  /// **'参加をキャンセル'**
  String get cancelParticipation;

  /// No description provided for @waitlistPromotionNote.
  ///
  /// In ja, this message translates to:
  /// **'参加者が辞退した場合、順番に承認いたします。'**
  String get waitlistPromotionNote;

  /// No description provided for @cancelWaitlist.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちを取り消す'**
  String get cancelWaitlist;

  /// No description provided for @applicationRejected.
  ///
  /// In ja, this message translates to:
  /// **'参加申し込みが拒否されました'**
  String get applicationRejected;

  /// No description provided for @cancelled.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル済み'**
  String get cancelled;

  /// No description provided for @participationStatusFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'参加状況の取得に失敗しました'**
  String get participationStatusFetchFailed;

  /// No description provided for @apply.
  ///
  /// In ja, this message translates to:
  /// **'申し込み'**
  String get apply;

  /// No description provided for @loginError.
  ///
  /// In ja, this message translates to:
  /// **'ログインエラー'**
  String get loginError;

  /// No description provided for @userNotFoundShort.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりません'**
  String get userNotFoundShort;

  /// No description provided for @cancelWaitlistConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちを取り消しますか？'**
  String get cancelWaitlistConfirmTitle;

  /// No description provided for @withdraw.
  ///
  /// In ja, this message translates to:
  /// **'取り消す'**
  String get withdraw;

  /// No description provided for @cancelWaitlistByUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーによるキャンセル待ち取り消し'**
  String get cancelWaitlistByUser;

  /// No description provided for @waitlistCancelledSuccess.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちを取り消しました'**
  String get waitlistCancelledSuccess;

  /// No description provided for @participationCancelledSuccess.
  ///
  /// In ja, this message translates to:
  /// **'参加をキャンセルしました'**
  String get participationCancelledSuccess;

  /// No description provided for @participationCancelFailed.
  ///
  /// In ja, this message translates to:
  /// **'キャンセルに失敗しました'**
  String get participationCancelFailed;

  /// No description provided for @participationCancelTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加キャンセル'**
  String get participationCancelTitle;

  /// No description provided for @cancellationReasonRequired.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル理由（必須）'**
  String get cancellationReasonRequired;

  /// No description provided for @cancellationReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'主催者へキャンセル理由をお知らせください'**
  String get cancellationReasonHint;

  /// No description provided for @back.
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// No description provided for @confirmCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセルする'**
  String get confirmCancel;

  /// No description provided for @pleaseEnterCancellationReason.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル理由を入力してください'**
  String get pleaseEnterCancellationReason;

  /// No description provided for @eventEditTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント編集'**
  String get eventEditTitle;

  /// No description provided for @visibilityPublic.
  ///
  /// In ja, this message translates to:
  /// **'パブリック'**
  String get visibilityPublic;

  /// No description provided for @visibilityInviteOnly.
  ///
  /// In ja, this message translates to:
  /// **'招待制'**
  String get visibilityInviteOnly;

  /// No description provided for @approvalAutomatic.
  ///
  /// In ja, this message translates to:
  /// **'自動承認'**
  String get approvalAutomatic;

  /// No description provided for @changeImage.
  ///
  /// In ja, this message translates to:
  /// **'画像を変更'**
  String get changeImage;

  /// No description provided for @selectImage.
  ///
  /// In ja, this message translates to:
  /// **'画像を選択'**
  String get selectImage;

  /// No description provided for @takePhoto.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get takePhoto;

  /// No description provided for @selectFromGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get selectFromGallery;

  /// No description provided for @selectFromPastEventImages.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベント画像から選択'**
  String get selectFromPastEventImages;

  /// No description provided for @selectFromPastEventImagesTitle.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベント画像から選択'**
  String get selectFromPastEventImagesTitle;

  /// No description provided for @noImagesAvailable.
  ///
  /// In ja, this message translates to:
  /// **'利用可能な画像がありません'**
  String get noImagesAvailable;

  /// No description provided for @selectDateTime.
  ///
  /// In ja, this message translates to:
  /// **'日時を選択してください'**
  String get selectDateTime;

  /// No description provided for @registrationDeadlineLabel.
  ///
  /// In ja, this message translates to:
  /// **'申込期限'**
  String get registrationDeadlineLabel;

  /// No description provided for @noRegistrationDeadline.
  ///
  /// In ja, this message translates to:
  /// **'申込期限なし - 参加者はいつでも申し込み可能です'**
  String get noRegistrationDeadline;

  /// No description provided for @participantCancelDeadline.
  ///
  /// In ja, this message translates to:
  /// **'参加者キャンセル期限（任意）'**
  String get participantCancelDeadline;

  /// No description provided for @selectGame.
  ///
  /// In ja, this message translates to:
  /// **'ゲームを選択してください'**
  String get selectGame;

  /// No description provided for @prizeContentHint.
  ///
  /// In ja, this message translates to:
  /// **'例：1位 10万円、2位 5万円、3位 1万円'**
  String get prizeContentHint;

  /// No description provided for @addSponsor.
  ///
  /// In ja, this message translates to:
  /// **'スポンサーを追加'**
  String get addSponsor;

  /// No description provided for @addSponsorPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'スポンサーを追加してください'**
  String get addSponsorPlaceholder;

  /// No description provided for @aboutPrizeSetting.
  ///
  /// In ja, this message translates to:
  /// **'賞品設定について'**
  String get aboutPrizeSetting;

  /// No description provided for @prizeNote1.
  ///
  /// In ja, this message translates to:
  /// **'賞品情報は参加者への案内として表示されます'**
  String get prizeNote1;

  /// No description provided for @prizeNote2.
  ///
  /// In ja, this message translates to:
  /// **'実際の受け渡しは主催者と参加者間で行ってください'**
  String get prizeNote2;

  /// No description provided for @prizeNote3.
  ///
  /// In ja, this message translates to:
  /// **'アプリでは受け渡しの仲介や保証は行いません'**
  String get prizeNote3;

  /// No description provided for @prizeNote4.
  ///
  /// In ja, this message translates to:
  /// **'受け渡し方法は事前に参加者と相談してください'**
  String get prizeNote4;

  /// No description provided for @understood.
  ///
  /// In ja, this message translates to:
  /// **'了解'**
  String get understood;

  /// No description provided for @blockedUsers.
  ///
  /// In ja, this message translates to:
  /// **'参加NGユーザー'**
  String get blockedUsers;

  /// No description provided for @addBlockedUserPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'ブロックするユーザーを追加してください'**
  String get addBlockedUserPlaceholder;

  /// No description provided for @eventOrganizers.
  ///
  /// In ja, this message translates to:
  /// **'イベント運営者'**
  String get eventOrganizers;

  /// No description provided for @addOrganizerPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'イベント運営者を追加してください'**
  String get addOrganizerPlaceholder;

  /// No description provided for @addSelf.
  ///
  /// In ja, this message translates to:
  /// **'自分を追加'**
  String get addSelf;

  /// No description provided for @fromMutualFollows.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから'**
  String get fromMutualFollows;

  /// No description provided for @userSearch.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー検索'**
  String get userSearch;

  /// No description provided for @searchOrganizer.
  ///
  /// In ja, this message translates to:
  /// **'イベント運営者を検索'**
  String get searchOrganizer;

  /// No description provided for @searchOrganizerDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベントを管理する運営者を追加してください'**
  String get searchOrganizerDescription;

  /// No description provided for @selectFromMutualFollowsOrganizer.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから運営者を選択'**
  String get selectFromMutualFollowsOrganizer;

  /// No description provided for @addSponsorDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'スポンサーを追加'**
  String get addSponsorDialogTitle;

  /// No description provided for @addSponsorDialogMessage.
  ///
  /// In ja, this message translates to:
  /// **'どの方法でスポンサーを追加しますか？'**
  String get addSponsorDialogMessage;

  /// No description provided for @selectFromMutualFollows.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから選択'**
  String get selectFromMutualFollows;

  /// No description provided for @searchSponsor.
  ///
  /// In ja, this message translates to:
  /// **'スポンサーを検索'**
  String get searchSponsor;

  /// No description provided for @searchSponsorDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベントのスポンサーを追加してください'**
  String get searchSponsorDescription;

  /// No description provided for @selectFromMutualFollowsSponsor.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローからスポンサーを選択'**
  String get selectFromMutualFollowsSponsor;

  /// No description provided for @addBlockedUserDescription.
  ///
  /// In ja, this message translates to:
  /// **'このイベントをブロックするユーザーを追加してください'**
  String get addBlockedUserDescription;

  /// No description provided for @cannotBlockOrganizerOrSponsor.
  ///
  /// In ja, this message translates to:
  /// **'運営者やスポンサーをNGユーザーに設定することはできません'**
  String get cannotBlockOrganizerOrSponsor;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが認証されていません'**
  String get userNotAuthenticated;

  /// No description provided for @alreadyAddedAsOrganizer.
  ///
  /// In ja, this message translates to:
  /// **'既に運営者として追加されています'**
  String get alreadyAddedAsOrganizer;

  /// No description provided for @alreadyAddedAsSponsor.
  ///
  /// In ja, this message translates to:
  /// **'既にスポンサーとして追加されています'**
  String get alreadyAddedAsSponsor;

  /// No description provided for @searchInviteMembers.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバーを検索'**
  String get searchInviteMembers;

  /// No description provided for @searchInviteMembersDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベントに招待するメンバーを追加してください'**
  String get searchInviteMembersDescription;

  /// No description provided for @addInviteMembersPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'招待するメンバーを追加してください'**
  String get addInviteMembersPlaceholder;

  /// No description provided for @addInviteMembers.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバーを追加してください'**
  String get addInviteMembers;

  /// No description provided for @streamingUrlHint.
  ///
  /// In ja, this message translates to:
  /// **'YouTube、Twitch等の配信URLを入力してください'**
  String get streamingUrlHint;

  /// No description provided for @streamingUrlRequired.
  ///
  /// In ja, this message translates to:
  /// **'最低1つの配信URLを入力してください'**
  String get streamingUrlRequired;

  /// No description provided for @cancellationPolicyHint.
  ///
  /// In ja, this message translates to:
  /// **'例：イベント開始24時間前まではキャンセル可能'**
  String get cancellationPolicyHint;

  /// No description provided for @creatingEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベントを作成中...'**
  String get creatingEvent;

  /// No description provided for @savingDraft.
  ///
  /// In ja, this message translates to:
  /// **'下書きを保存中...'**
  String get savingDraft;

  /// No description provided for @enableRegistrationDeadline.
  ///
  /// In ja, this message translates to:
  /// **'申込期限を有効にして設定してください'**
  String get enableRegistrationDeadline;

  /// No description provided for @cancelDeadlineTooShort.
  ///
  /// In ja, this message translates to:
  /// **'申込期限から開催日時まで間隔が短すぎるため、キャンセル期限を設定できません'**
  String get cancelDeadlineTooShort;

  /// No description provided for @setEventDateTimeFirst.
  ///
  /// In ja, this message translates to:
  /// **'まず開催日時を設定してください'**
  String get setEventDateTimeFirst;

  /// No description provided for @eventDateTimeTooClose.
  ///
  /// In ja, this message translates to:
  /// **'開催日時が近すぎるため申込期限を設定できません（開催3時間前まで設定可能）'**
  String get eventDateTimeTooClose;

  /// No description provided for @cancelDeadlineAfterRegistration.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル期限は申込期限以降に設定してください'**
  String get cancelDeadlineAfterRegistration;

  /// No description provided for @cancelDeadlineBeforeEventTime.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル期限は開催日時より前に設定してください'**
  String get cancelDeadlineBeforeEventTime;

  /// No description provided for @registrationDeadlineAfterNow.
  ///
  /// In ja, this message translates to:
  /// **'申込期限は現在時刻より後に設定してください'**
  String get registrationDeadlineAfterNow;

  /// No description provided for @eventDateTimeAfterNow.
  ///
  /// In ja, this message translates to:
  /// **'開催日時は現在時刻より後に設定してください'**
  String get eventDateTimeAfterNow;

  /// No description provided for @changeToDraft.
  ///
  /// In ja, this message translates to:
  /// **'下書きに変更'**
  String get changeToDraft;

  /// No description provided for @impactOnParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者への影響について'**
  String get impactOnParticipants;

  /// No description provided for @draftImpactWarning.
  ///
  /// In ja, this message translates to:
  /// **'下書きに戻すと、参加者は以下の影響を受けます：'**
  String get draftImpactWarning;

  /// No description provided for @draftImpact1.
  ///
  /// In ja, this message translates to:
  /// **'イベントが非公開になり、参加者がアクセスできなくなります'**
  String get draftImpact1;

  /// No description provided for @draftImpact2.
  ///
  /// In ja, this message translates to:
  /// **'参加者に通知が送信されます'**
  String get draftImpact2;

  /// No description provided for @draftImpact3.
  ///
  /// In ja, this message translates to:
  /// **'参加申込は保持されますが、一時的に無効となります'**
  String get draftImpact3;

  /// No description provided for @draftRecoveryNote.
  ///
  /// In ja, this message translates to:
  /// **'下書きから再公開した際、参加申込は自動的に復活します。'**
  String get draftRecoveryNote;

  /// No description provided for @revertToDraft.
  ///
  /// In ja, this message translates to:
  /// **'下書きに変更'**
  String get revertToDraft;

  /// No description provided for @organizerDefault.
  ///
  /// In ja, this message translates to:
  /// **'主催者'**
  String get organizerDefault;

  /// No description provided for @userNotAuthenticatedLogin.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが認証されていません。ログインしてください。'**
  String get userNotAuthenticatedLogin;

  /// No description provided for @eventUpdated.
  ///
  /// In ja, this message translates to:
  /// **'イベントを更新しました'**
  String get eventUpdated;

  /// No description provided for @changesSaved.
  ///
  /// In ja, this message translates to:
  /// **'変更を保存しました'**
  String get changesSaved;

  /// No description provided for @draftSaved.
  ///
  /// In ja, this message translates to:
  /// **'下書きを保存しました'**
  String get draftSaved;

  /// No description provided for @updateAndPublishEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベントを更新・公開する'**
  String get updateAndPublishEvent;

  /// No description provided for @publishEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベントを公開する'**
  String get publishEvent;

  /// No description provided for @pleaseEnterEventName.
  ///
  /// In ja, this message translates to:
  /// **'イベント名を入力してください'**
  String get pleaseEnterEventName;

  /// No description provided for @pleaseEnterEventContent.
  ///
  /// In ja, this message translates to:
  /// **'イベント内容を入力してください'**
  String get pleaseEnterEventContent;

  /// No description provided for @pleaseEnterParticipationRules.
  ///
  /// In ja, this message translates to:
  /// **'参加ルールを入力してください'**
  String get pleaseEnterParticipationRules;

  /// No description provided for @pleaseSelectPlatform.
  ///
  /// In ja, this message translates to:
  /// **'プラットフォームを選択してください'**
  String get pleaseSelectPlatform;

  /// No description provided for @pleaseSetEventDateTime.
  ///
  /// In ja, this message translates to:
  /// **'開催日時を設定してください'**
  String get pleaseSetEventDateTime;

  /// No description provided for @eventDateTimeMustBeFuture.
  ///
  /// In ja, this message translates to:
  /// **'開催日時は現在時刻より後に設定してください'**
  String get eventDateTimeMustBeFuture;

  /// No description provided for @pleaseSetRegistrationDeadline.
  ///
  /// In ja, this message translates to:
  /// **'参加申込締切を設定してください'**
  String get pleaseSetRegistrationDeadline;

  /// No description provided for @registrationDeadlineBeforeEvent.
  ///
  /// In ja, this message translates to:
  /// **'参加申込締切は開催日時より前に設定してください'**
  String get registrationDeadlineBeforeEvent;

  /// No description provided for @pleaseEnterMaxParticipants.
  ///
  /// In ja, this message translates to:
  /// **'最大参加人数を入力してください'**
  String get pleaseEnterMaxParticipants;

  /// No description provided for @maxParticipantsPositiveInteger.
  ///
  /// In ja, this message translates to:
  /// **'最大参加人数は正の整数で入力してください'**
  String get maxParticipantsPositiveInteger;

  /// No description provided for @pleaseAddInviteMembers.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバーを追加してください'**
  String get pleaseAddInviteMembers;

  /// No description provided for @pleaseEnterPrizeContent.
  ///
  /// In ja, this message translates to:
  /// **'賞品内容を入力してください'**
  String get pleaseEnterPrizeContent;

  /// No description provided for @pleaseAddOrganizerForPrize.
  ///
  /// In ja, this message translates to:
  /// **'賞品設定時は運営者を追加してください'**
  String get pleaseAddOrganizerForPrize;

  /// No description provided for @pleaseEnterStreamingUrl.
  ///
  /// In ja, this message translates to:
  /// **'配信URLを入力してください'**
  String get pleaseEnterStreamingUrl;

  /// No description provided for @eventPublished.
  ///
  /// In ja, this message translates to:
  /// **'イベントを公開しました！'**
  String get eventPublished;

  /// No description provided for @eventDetailViewNote.
  ///
  /// In ja, this message translates to:
  /// **'イベント詳細画面で参加者の管理や\\nイベント情報の確認ができます'**
  String get eventDetailViewNote;

  /// No description provided for @checkLater.
  ///
  /// In ja, this message translates to:
  /// **'後で確認'**
  String get checkLater;

  /// No description provided for @viewDetails.
  ///
  /// In ja, this message translates to:
  /// **'詳細を見る'**
  String get viewDetails;

  /// No description provided for @checkInputContent.
  ///
  /// In ja, this message translates to:
  /// **'入力内容を確認してください'**
  String get checkInputContent;

  /// No description provided for @fillRequiredFields.
  ///
  /// In ja, this message translates to:
  /// **'以下の必須項目（※）を入力してください：'**
  String get fillRequiredFields;

  /// No description provided for @attentionRequired.
  ///
  /// In ja, this message translates to:
  /// **'注意が必要です'**
  String get attentionRequired;

  /// No description provided for @enterChangeReason.
  ///
  /// In ja, this message translates to:
  /// **'変更理由を記入してください：'**
  String get enterChangeReason;

  /// No description provided for @changeReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'例：スケジュール変更により内容を更新しました'**
  String get changeReasonHint;

  /// No description provided for @cannotRevertToDraft.
  ///
  /// In ja, this message translates to:
  /// **'イベントの下書き化はできません'**
  String get cannotRevertToDraft;

  /// No description provided for @operationsDashboard.
  ///
  /// In ja, this message translates to:
  /// **'運営ダッシュボード'**
  String get operationsDashboard;

  /// No description provided for @operationsMode.
  ///
  /// In ja, this message translates to:
  /// **'運営モード'**
  String get operationsMode;

  /// No description provided for @dashboardParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者'**
  String get dashboardParticipants;

  /// No description provided for @dashboardApproveReject.
  ///
  /// In ja, this message translates to:
  /// **'承認・拒否'**
  String get dashboardApproveReject;

  /// No description provided for @dashboardGroupAssignment.
  ///
  /// In ja, this message translates to:
  /// **'グループ分け'**
  String get dashboardGroupAssignment;

  /// No description provided for @dashboardRoomAllocation.
  ///
  /// In ja, this message translates to:
  /// **'部屋割り当て'**
  String get dashboardRoomAllocation;

  /// No description provided for @dashboardManagementMenu.
  ///
  /// In ja, this message translates to:
  /// **'運営管理メニュー'**
  String get dashboardManagementMenu;

  /// No description provided for @dashboardParticipantsTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者'**
  String get dashboardParticipantsTitle;

  /// No description provided for @dashboardParticipantsDesc.
  ///
  /// In ja, this message translates to:
  /// **'参加申請の承認・拒否、参加者一覧'**
  String get dashboardParticipantsDesc;

  /// No description provided for @dashboardGroupTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループ'**
  String get dashboardGroupTitle;

  /// No description provided for @dashboardGroupDesc.
  ///
  /// In ja, this message translates to:
  /// **'チーム分け'**
  String get dashboardGroupDesc;

  /// No description provided for @dashboardResultsTitle.
  ///
  /// In ja, this message translates to:
  /// **'戦績・結果'**
  String get dashboardResultsTitle;

  /// No description provided for @dashboardResultsDesc.
  ///
  /// In ja, this message translates to:
  /// **'試合結果入力、順位管理、統計'**
  String get dashboardResultsDesc;

  /// No description provided for @dashboardViolationTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反'**
  String get dashboardViolationTitle;

  /// No description provided for @dashboardViolationDesc.
  ///
  /// In ja, this message translates to:
  /// **'違反記録、警告管理、ペナルティ'**
  String get dashboardViolationDesc;

  /// No description provided for @dashboardUserDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー詳細'**
  String get dashboardUserDetailTitle;

  /// No description provided for @dashboardUserDetailDesc.
  ///
  /// In ja, this message translates to:
  /// **'参加履歴、詳細情報、総合評価'**
  String get dashboardUserDetailDesc;

  /// No description provided for @dashboardLoading.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中'**
  String get dashboardLoading;

  /// No description provided for @dashboardCancelled.
  ///
  /// In ja, this message translates to:
  /// **'中止済み'**
  String get dashboardCancelled;

  /// No description provided for @dashboardCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了済み'**
  String get dashboardCompleted;

  /// No description provided for @dashboardDeleteEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベント削除'**
  String get dashboardDeleteEvent;

  /// No description provided for @dashboardCancelEvent.
  ///
  /// In ja, this message translates to:
  /// **'イベント中止'**
  String get dashboardCancelEvent;

  /// No description provided for @participantsTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者'**
  String get participantsTitle;

  /// No description provided for @participationApplications.
  ///
  /// In ja, this message translates to:
  /// **'参加申請'**
  String get participationApplications;

  /// No description provided for @tabPending.
  ///
  /// In ja, this message translates to:
  /// **'申請中'**
  String get tabPending;

  /// No description provided for @tabApproved.
  ///
  /// In ja, this message translates to:
  /// **'承認済み'**
  String get tabApproved;

  /// No description provided for @tabRejected.
  ///
  /// In ja, this message translates to:
  /// **'拒否'**
  String get tabRejected;

  /// No description provided for @tabWaitlisted.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ち'**
  String get tabWaitlisted;

  /// No description provided for @tabCancelled.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル済み'**
  String get tabCancelled;

  /// No description provided for @dataLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'データの読み込みに失敗しました'**
  String get dataLoadFailed;

  /// No description provided for @noPendingParticipants.
  ///
  /// In ja, this message translates to:
  /// **'申請中の参加者はいません'**
  String get noPendingParticipants;

  /// No description provided for @noApprovedParticipants.
  ///
  /// In ja, this message translates to:
  /// **'承認済みの参加者はいません'**
  String get noApprovedParticipants;

  /// No description provided for @noRejectedParticipants.
  ///
  /// In ja, this message translates to:
  /// **'拒否済みの参加者はいません'**
  String get noRejectedParticipants;

  /// No description provided for @noWaitlistedParticipants.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちの参加者はいません'**
  String get noWaitlistedParticipants;

  /// No description provided for @noCancelledParticipants.
  ///
  /// In ja, this message translates to:
  /// **'キャンセルした参加者はいません'**
  String get noCancelledParticipants;

  /// No description provided for @noParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者はいません'**
  String get noParticipants;

  /// No description provided for @loadingText.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get loadingText;

  /// No description provided for @gameAccountInfo.
  ///
  /// In ja, this message translates to:
  /// **'ゲームアカウント情報'**
  String get gameAccountInfo;

  /// No description provided for @inGameUsername.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ユーザー名'**
  String get inGameUsername;

  /// No description provided for @inGameUserId.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ユーザーID'**
  String get inGameUserId;

  /// No description provided for @noGameAccountInfo.
  ///
  /// In ja, this message translates to:
  /// **'ゲームアカウント情報が登録されていません'**
  String get noGameAccountInfo;

  /// No description provided for @approve.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In ja, this message translates to:
  /// **'拒否'**
  String get reject;

  /// No description provided for @statusPending.
  ///
  /// In ja, this message translates to:
  /// **'承認待ち'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In ja, this message translates to:
  /// **'承認済み'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In ja, this message translates to:
  /// **'拒否'**
  String get statusRejected;

  /// No description provided for @statusWaitlisted.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ち'**
  String get statusWaitlisted;

  /// No description provided for @statusUnknown.
  ///
  /// In ja, this message translates to:
  /// **'不明'**
  String get statusUnknown;

  /// No description provided for @approveApplicationTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を承認'**
  String get approveApplicationTitle;

  /// No description provided for @rejectApplicationTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を拒否'**
  String get rejectApplicationTitle;

  /// No description provided for @approveApplicationMessageHint.
  ///
  /// In ja, this message translates to:
  /// **'申請者にメッセージを送信できます（任意）'**
  String get approveApplicationMessageHint;

  /// No description provided for @rejectApplicationMessageHint.
  ///
  /// In ja, this message translates to:
  /// **'拒否理由をメッセージで送信できます（任意）'**
  String get rejectApplicationMessageHint;

  /// No description provided for @messageInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get messageInputLabel;

  /// No description provided for @rejectReasonInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'拒否理由'**
  String get rejectReasonInputLabel;

  /// No description provided for @approveMessagePlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'承認に関する詳細やイベント参加の注意事項など'**
  String get approveMessagePlaceholder;

  /// No description provided for @rejectMessagePlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'拒否の理由や今後の改善点など'**
  String get rejectMessagePlaceholder;

  /// No description provided for @approveButton.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get approveButton;

  /// No description provided for @rejectButton.
  ///
  /// In ja, this message translates to:
  /// **'差し戻し'**
  String get rejectButton;

  /// No description provided for @waitlistUserApproved.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちユーザーを承認しました'**
  String get waitlistUserApproved;

  /// No description provided for @applicationApproved.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を承認しました'**
  String get applicationApproved;

  /// No description provided for @approvalFailed.
  ///
  /// In ja, this message translates to:
  /// **'承認に失敗しました'**
  String get approvalFailed;

  /// No description provided for @applicationRejectedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を拒否しました'**
  String get applicationRejectedSuccess;

  /// No description provided for @rejectionFailed.
  ///
  /// In ja, this message translates to:
  /// **'拒否に失敗しました'**
  String get rejectionFailed;

  /// No description provided for @revokeApprovalAndReturnToPending.
  ///
  /// In ja, this message translates to:
  /// **'承認を取り消して申請中に戻す'**
  String get revokeApprovalAndReturnToPending;

  /// No description provided for @revokeRejectionAndReturnToPending.
  ///
  /// In ja, this message translates to:
  /// **'拒否を取り消して申請中に戻す'**
  String get revokeRejectionAndReturnToPending;

  /// No description provided for @revokeApprovalTitle.
  ///
  /// In ja, this message translates to:
  /// **'承認を取り消しますか？'**
  String get revokeApprovalTitle;

  /// No description provided for @revokeRejectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'拒否を取り消しますか？'**
  String get revokeRejectionTitle;

  /// No description provided for @enterReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'理由を入力...'**
  String get enterReasonHint;

  /// No description provided for @returnToPendingButton.
  ///
  /// In ja, this message translates to:
  /// **'申請中に戻す'**
  String get returnToPendingButton;

  /// No description provided for @approvalRevoked.
  ///
  /// In ja, this message translates to:
  /// **'承認が取り消されました'**
  String get approvalRevoked;

  /// No description provided for @rejectionRevoked.
  ///
  /// In ja, this message translates to:
  /// **'拒否が取り消されました'**
  String get rejectionRevoked;

  /// No description provided for @revokeApprovalSuccess.
  ///
  /// In ja, this message translates to:
  /// **'承認を取り消して申請中に戻しました'**
  String get revokeApprovalSuccess;

  /// No description provided for @revokeRejectionSuccess.
  ///
  /// In ja, this message translates to:
  /// **'拒否を取り消して申請中に戻しました'**
  String get revokeRejectionSuccess;

  /// No description provided for @revokeApprovalFailed.
  ///
  /// In ja, this message translates to:
  /// **'承認取り消しに失敗しました'**
  String get revokeApprovalFailed;

  /// No description provided for @revokeRejectionFailed.
  ///
  /// In ja, this message translates to:
  /// **'拒否取り消しに失敗しました'**
  String get revokeRejectionFailed;

  /// No description provided for @withdrawnUserProfileNotAvailable.
  ///
  /// In ja, this message translates to:
  /// **'退会したユーザーのプロフィールは表示できません'**
  String get withdrawnUserProfileNotAvailable;

  /// No description provided for @userNotFoundError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりませんでした'**
  String get userNotFoundError;

  /// No description provided for @userProfileLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'ユーザープロフィールの表示に失敗しました'**
  String get userProfileLoadFailed;

  /// No description provided for @gameProfileInfoMissing.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィール情報が不足しています'**
  String get gameProfileInfoMissing;

  /// No description provided for @approveWaitlistUser.
  ///
  /// In ja, this message translates to:
  /// **'承認する'**
  String get approveWaitlistUser;

  /// No description provided for @returnWaitlistToPending.
  ///
  /// In ja, this message translates to:
  /// **'申請中に戻す'**
  String get returnWaitlistToPending;

  /// No description provided for @cancellationReasonTitle.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル理由'**
  String get cancellationReasonTitle;

  /// No description provided for @viewReason.
  ///
  /// In ja, this message translates to:
  /// **'理由を確認'**
  String get viewReason;

  /// No description provided for @noCancellationReasonRecorded.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル理由の記録がありません'**
  String get noCancellationReasonRecorded;

  /// No description provided for @closeButton.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get closeButton;

  /// No description provided for @detailButton.
  ///
  /// In ja, this message translates to:
  /// **'詳細'**
  String get detailButton;

  /// No description provided for @editButton.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get editButton;

  /// No description provided for @deleteButton.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get deleteButton;

  /// No description provided for @capacityExceededTitle.
  ///
  /// In ja, this message translates to:
  /// **'定員超過のため承認できません'**
  String get capacityExceededTitle;

  /// No description provided for @eventInfoFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'イベント情報の取得に失敗しました'**
  String get eventInfoFetchFailed;

  /// No description provided for @capacityCheckFailed.
  ///
  /// In ja, this message translates to:
  /// **'定員チェックに失敗しました'**
  String get capacityCheckFailed;

  /// No description provided for @noBlockedUsersSet.
  ///
  /// In ja, this message translates to:
  /// **'NGユーザーは設定されていません'**
  String get noBlockedUsersSet;

  /// No description provided for @myGroup.
  ///
  /// In ja, this message translates to:
  /// **'自分のグループ'**
  String get myGroup;

  /// No description provided for @allGroups.
  ///
  /// In ja, this message translates to:
  /// **'全グループ'**
  String get allGroups;

  /// No description provided for @noGroupAssigned.
  ///
  /// In ja, this message translates to:
  /// **'グループが割り当てられていません'**
  String get noGroupAssigned;

  /// No description provided for @waitForOrganizerGuidance.
  ///
  /// In ja, this message translates to:
  /// **'運営からの案内をお待ちください'**
  String get waitForOrganizerGuidance;

  /// No description provided for @noGroupsCreated.
  ///
  /// In ja, this message translates to:
  /// **'グループが作成されていません'**
  String get noGroupsCreated;

  /// No description provided for @groupDescription.
  ///
  /// In ja, this message translates to:
  /// **'グループ説明'**
  String get groupDescription;

  /// No description provided for @groupAnnouncements.
  ///
  /// In ja, this message translates to:
  /// **'グループ連絡'**
  String get groupAnnouncements;

  /// No description provided for @user.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get user;

  /// No description provided for @commonAnnouncements.
  ///
  /// In ja, this message translates to:
  /// **'全体連絡事項'**
  String get commonAnnouncements;

  /// No description provided for @gameProfileDisplayFailed.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールの表示に失敗しました'**
  String get gameProfileDisplayFailed;

  /// No description provided for @participantDetails.
  ///
  /// In ja, this message translates to:
  /// **'参加者詳細'**
  String get participantDetails;

  /// No description provided for @checkParticipantProfiles.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加者のプロフィール情報を確認'**
  String get checkParticipantProfiles;

  /// No description provided for @searchByUsernameOrGameId.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名やゲームIDで検索...'**
  String get searchByUsernameOrGameId;

  /// No description provided for @noParticipantsInEvent.
  ///
  /// In ja, this message translates to:
  /// **'参加者がいません'**
  String get noParticipantsInEvent;

  /// No description provided for @teamMatch.
  ///
  /// In ja, this message translates to:
  /// **'チーム戦'**
  String get teamMatch;

  /// No description provided for @individualMatch.
  ///
  /// In ja, this message translates to:
  /// **'個人戦'**
  String get individualMatch;

  /// No description provided for @matchResultsTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合結果'**
  String get matchResultsTitle;

  /// No description provided for @allMatches.
  ///
  /// In ja, this message translates to:
  /// **'すべての試合'**
  String get allMatches;

  /// No description provided for @myMatches.
  ///
  /// In ja, this message translates to:
  /// **'自分の試合'**
  String get myMatches;

  /// No description provided for @noMatchesRegistered.
  ///
  /// In ja, this message translates to:
  /// **'まだ試合が登録されていません'**
  String get noMatchesRegistered;

  /// No description provided for @noMyMatchesFound.
  ///
  /// In ja, this message translates to:
  /// **'あなたが参加した試合はありません'**
  String get noMyMatchesFound;

  /// No description provided for @score.
  ///
  /// In ja, this message translates to:
  /// **'スコア'**
  String get score;

  /// No description provided for @aboutViolationReport.
  ///
  /// In ja, this message translates to:
  /// **'違反報告について'**
  String get aboutViolationReport;

  /// No description provided for @importantNotesForProperUse.
  ///
  /// In ja, this message translates to:
  /// **'適切な利用のための重要な注意事項'**
  String get importantNotesForProperUse;

  /// No description provided for @reportPrecautions.
  ///
  /// In ja, this message translates to:
  /// **'報告時の注意事項：'**
  String get reportPrecautions;

  /// No description provided for @violationReportPrecaution1.
  ///
  /// In ja, this message translates to:
  /// **'虚偽の報告や悪意のある報告は禁止されています'**
  String get violationReportPrecaution1;

  /// No description provided for @violationReportPrecaution2.
  ///
  /// In ja, this message translates to:
  /// **'報告内容は運営が確認し、必要に応じて対処いたします'**
  String get violationReportPrecaution2;

  /// No description provided for @violationReportPrecaution3.
  ///
  /// In ja, this message translates to:
  /// **'報告者の情報は適切に保護されます'**
  String get violationReportPrecaution3;

  /// No description provided for @violationReportPrecaution4.
  ///
  /// In ja, this message translates to:
  /// **'重複報告を避けるため、同じ内容での報告は控えてください'**
  String get violationReportPrecaution4;

  /// No description provided for @createViolationReport.
  ///
  /// In ja, this message translates to:
  /// **'違反報告を作成'**
  String get createViolationReport;

  /// No description provided for @selectParticipantToReport.
  ///
  /// In ja, this message translates to:
  /// **'参加者を選択して違反内容を報告'**
  String get selectParticipantToReport;

  /// No description provided for @startViolationReport.
  ///
  /// In ja, this message translates to:
  /// **'違反報告を開始'**
  String get startViolationReport;

  /// No description provided for @violationReportSent.
  ///
  /// In ja, this message translates to:
  /// **'違反報告を送信しました。運営で確認いたします。'**
  String get violationReportSent;

  /// No description provided for @noAvailableImages.
  ///
  /// In ja, this message translates to:
  /// **'利用可能な画像がありません'**
  String get noAvailableImages;

  /// No description provided for @groupTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループ'**
  String get groupTitle;

  /// No description provided for @editGeneralAnnouncementsTooltip.
  ///
  /// In ja, this message translates to:
  /// **'全体連絡事項を編集'**
  String get editGeneralAnnouncementsTooltip;

  /// No description provided for @groupManagement.
  ///
  /// In ja, this message translates to:
  /// **'グループ管理'**
  String get groupManagement;

  /// No description provided for @createGroup.
  ///
  /// In ja, this message translates to:
  /// **'グループ作成'**
  String get createGroup;

  /// No description provided for @noGroupsYet.
  ///
  /// In ja, this message translates to:
  /// **'まだグループがありません'**
  String get noGroupsYet;

  /// No description provided for @createGroupDescription.
  ///
  /// In ja, this message translates to:
  /// **'チーム戦を開催するために\\nグループ（チーム）を作成しましょう'**
  String get createGroupDescription;

  /// No description provided for @viewUnassignedParticipants.
  ///
  /// In ja, this message translates to:
  /// **'未割り当て参加者を確認'**
  String get viewUnassignedParticipants;

  /// No description provided for @generalAnnouncements.
  ///
  /// In ja, this message translates to:
  /// **'全体連絡事項'**
  String get generalAnnouncements;

  /// No description provided for @visibleToAllParticipants.
  ///
  /// In ja, this message translates to:
  /// **'全参加者が閲覧可能'**
  String get visibleToAllParticipants;

  /// No description provided for @editAction.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get editAction;

  /// No description provided for @addMemberAction.
  ///
  /// In ja, this message translates to:
  /// **'メンバー追加'**
  String get addMemberAction;

  /// No description provided for @deleteAction.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get deleteAction;

  /// No description provided for @groupDescriptionLabel.
  ///
  /// In ja, this message translates to:
  /// **'グループ説明'**
  String get groupDescriptionLabel;

  /// No description provided for @groupAnnouncementsLabel.
  ///
  /// In ja, this message translates to:
  /// **'グループ連絡事項'**
  String get groupAnnouncementsLabel;

  /// No description provided for @noMembersInGroup.
  ///
  /// In ja, this message translates to:
  /// **'メンバーがいません'**
  String get noMembersInGroup;

  /// No description provided for @addMemberFromMenuHint.
  ///
  /// In ja, this message translates to:
  /// **'メニューからメンバーを追加してください'**
  String get addMemberFromMenuHint;

  /// No description provided for @addToGroup.
  ///
  /// In ja, this message translates to:
  /// **'グループに追加'**
  String get addToGroup;

  /// No description provided for @failedToRemoveParticipant.
  ///
  /// In ja, this message translates to:
  /// **'参加者の削除に失敗しました'**
  String get failedToRemoveParticipant;

  /// No description provided for @failedToAddParticipant.
  ///
  /// In ja, this message translates to:
  /// **'参加者の追加に失敗しました'**
  String get failedToAddParticipant;

  /// No description provided for @noParticipantsToAdd.
  ///
  /// In ja, this message translates to:
  /// **'追加できる参加者がいません'**
  String get noParticipantsToAdd;

  /// No description provided for @generalAnnouncementsUpdated.
  ///
  /// In ja, this message translates to:
  /// **'全体連絡事項を更新しました'**
  String get generalAnnouncementsUpdated;

  /// No description provided for @editGeneralAnnouncementsTitle.
  ///
  /// In ja, this message translates to:
  /// **'全体連絡事項の編集'**
  String get editGeneralAnnouncementsTitle;

  /// No description provided for @generalAnnouncementsLabel.
  ///
  /// In ja, this message translates to:
  /// **'全体連絡事項'**
  String get generalAnnouncementsLabel;

  /// No description provided for @generalAnnouncementsHint.
  ///
  /// In ja, this message translates to:
  /// **'例：イベント開始時刻が30分変更になりました'**
  String get generalAnnouncementsHint;

  /// No description provided for @createNewGroup.
  ///
  /// In ja, this message translates to:
  /// **'新しいグループを作成'**
  String get createNewGroup;

  /// No description provided for @groupNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'グループ名'**
  String get groupNameLabel;

  /// No description provided for @groupNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例：チームA'**
  String get groupNameHint;

  /// No description provided for @groupDescriptionOptional.
  ///
  /// In ja, this message translates to:
  /// **'グループ説明（任意）'**
  String get groupDescriptionOptional;

  /// No description provided for @groupDescriptionHint.
  ///
  /// In ja, this message translates to:
  /// **'例：攻撃担当のメンバー'**
  String get groupDescriptionHint;

  /// No description provided for @createAction.
  ///
  /// In ja, this message translates to:
  /// **'作成'**
  String get createAction;

  /// No description provided for @pleaseEnterGroupName.
  ///
  /// In ja, this message translates to:
  /// **'グループ名を入力してください'**
  String get pleaseEnterGroupName;

  /// No description provided for @failedToCreateGroup.
  ///
  /// In ja, this message translates to:
  /// **'グループの作成に失敗しました'**
  String get failedToCreateGroup;

  /// No description provided for @editGroup.
  ///
  /// In ja, this message translates to:
  /// **'グループを編集'**
  String get editGroup;

  /// No description provided for @groupAnnouncementsOptional.
  ///
  /// In ja, this message translates to:
  /// **'グループ連絡事項'**
  String get groupAnnouncementsOptional;

  /// No description provided for @groupAnnouncementsHint.
  ///
  /// In ja, this message translates to:
  /// **'例：次回の練習は19時からです'**
  String get groupAnnouncementsHint;

  /// No description provided for @updateAction.
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get updateAction;

  /// No description provided for @failedToUpdateGroup.
  ///
  /// In ja, this message translates to:
  /// **'グループの更新に失敗しました'**
  String get failedToUpdateGroup;

  /// No description provided for @cannotDeleteGroup.
  ///
  /// In ja, this message translates to:
  /// **'グループを削除できません'**
  String get cannotDeleteGroup;

  /// No description provided for @cannotDeleteGroupReason.
  ///
  /// In ja, this message translates to:
  /// **'戦績データを保護するため、関連する戦績があるグループは削除できません。'**
  String get cannotDeleteGroupReason;

  /// No description provided for @deleteGroupHint.
  ///
  /// In ja, this message translates to:
  /// **'どうしても削除が必要な場合は、先に関連する戦績データを個別に削除してください。'**
  String get deleteGroupHint;

  /// No description provided for @understoodAction.
  ///
  /// In ja, this message translates to:
  /// **'了解'**
  String get understoodAction;

  /// No description provided for @goToMatchManagement.
  ///
  /// In ja, this message translates to:
  /// **'戦績管理へ'**
  String get goToMatchManagement;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループを削除'**
  String get deleteGroupTitle;

  /// No description provided for @failedToDeleteGroup.
  ///
  /// In ja, this message translates to:
  /// **'グループの削除に失敗しました'**
  String get failedToDeleteGroup;

  /// No description provided for @gameInfoNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム情報が見つかりません'**
  String get gameInfoNotFound;

  /// No description provided for @failedToShowGameProfile.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールの表示に失敗しました'**
  String get failedToShowGameProfile;

  /// No description provided for @collapseText.
  ///
  /// In ja, this message translates to:
  /// **'折りたたむ'**
  String get collapseText;

  /// No description provided for @showMoreText.
  ///
  /// In ja, this message translates to:
  /// **'もっと見る'**
  String get showMoreText;

  /// No description provided for @unassignedParticipantsDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'未割り当て参加者'**
  String get unassignedParticipantsDialogTitle;

  /// No description provided for @approvedNotAssignedDescription.
  ///
  /// In ja, this message translates to:
  /// **'承認済みでグループに割り当てられていない参加者：'**
  String get approvedNotAssignedDescription;

  /// No description provided for @createGroupForParticipantsHint.
  ///
  /// In ja, this message translates to:
  /// **'グループを作成してこれらの参加者を割り当ててください'**
  String get createGroupForParticipantsHint;

  /// No description provided for @defaultUserName.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get defaultUserName;

  /// No description provided for @sortNewest.
  ///
  /// In ja, this message translates to:
  /// **'新しい順'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In ja, this message translates to:
  /// **'古い順'**
  String get sortOldest;

  /// No description provided for @sortReportCount.
  ///
  /// In ja, this message translates to:
  /// **'報告数順'**
  String get sortReportCount;

  /// No description provided for @sortPendingReports.
  ///
  /// In ja, this message translates to:
  /// **'未処理報告優先'**
  String get sortPendingReports;

  /// No description provided for @sortStatus.
  ///
  /// In ja, this message translates to:
  /// **'ステータス順'**
  String get sortStatus;

  /// No description provided for @matchResultTitle.
  ///
  /// In ja, this message translates to:
  /// **'戦績・結果'**
  String get matchResultTitle;

  /// No description provided for @matchResultLabel.
  ///
  /// In ja, this message translates to:
  /// **'試合結果'**
  String get matchResultLabel;

  /// No description provided for @showPendingReportsOnly.
  ///
  /// In ja, this message translates to:
  /// **'未処理報告のみ表示'**
  String get showPendingReportsOnly;

  /// No description provided for @addMatch.
  ///
  /// In ja, this message translates to:
  /// **'試合追加'**
  String get addMatch;

  /// No description provided for @noPendingReports.
  ///
  /// In ja, this message translates to:
  /// **'未処理の報告はありません'**
  String get noPendingReports;

  /// No description provided for @problemMatchesDescription.
  ///
  /// In ja, this message translates to:
  /// **'問題が発生した試合は、ここに表示されます'**
  String get problemMatchesDescription;

  /// No description provided for @teamMatchDescription.
  ///
  /// In ja, this message translates to:
  /// **'チーム（グループ）対戦の試合結果を記録して管理しましょう'**
  String get teamMatchDescription;

  /// No description provided for @individualMatchDescription.
  ///
  /// In ja, this message translates to:
  /// **'参加者同士の個人戦の試合結果を記録して管理しましょう'**
  String get individualMatchDescription;

  /// No description provided for @needTwoTeamsForMatch.
  ///
  /// In ja, this message translates to:
  /// **'試合を開催するには2つ以上のチーム（グループ）が必要です'**
  String get needTwoTeamsForMatch;

  /// No description provided for @needTwoParticipantsForMatch.
  ///
  /// In ja, this message translates to:
  /// **'試合を開催するには2人以上の参加者が必要です'**
  String get needTwoParticipantsForMatch;

  /// No description provided for @needGroupsForTeamMatch.
  ///
  /// In ja, this message translates to:
  /// **'チーム戦を開催するには事前にグループの作成が必要です'**
  String get needGroupsForTeamMatch;

  /// No description provided for @goToGroupManagement.
  ///
  /// In ja, this message translates to:
  /// **'グループ管理画面へ'**
  String get goToGroupManagement;

  /// No description provided for @needParticipantsForMatch.
  ///
  /// In ja, this message translates to:
  /// **'イベントに参加者を追加してから試合を開始できます'**
  String get needParticipantsForMatch;

  /// No description provided for @goToParticipantManagement.
  ///
  /// In ja, this message translates to:
  /// **'参加者管理画面へ'**
  String get goToParticipantManagement;

  /// No description provided for @changeStatus.
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更'**
  String get changeStatus;

  /// No description provided for @editResult.
  ///
  /// In ja, this message translates to:
  /// **'結果編集'**
  String get editResult;

  /// No description provided for @inputResult.
  ///
  /// In ja, this message translates to:
  /// **'結果入力'**
  String get inputResult;

  /// No description provided for @matchResultSaved.
  ///
  /// In ja, this message translates to:
  /// **'試合結果を保存しました'**
  String get matchResultSaved;

  /// No description provided for @changeStatusTitle.
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更'**
  String get changeStatusTitle;

  /// No description provided for @matchReportsTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合報告'**
  String get matchReportsTitle;

  /// No description provided for @noReportsForMatch.
  ///
  /// In ja, this message translates to:
  /// **'この試合に関する報告はありません'**
  String get noReportsForMatch;

  /// No description provided for @deleteMatchTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合削除'**
  String get deleteMatchTitle;

  /// No description provided for @deleteMatchWarning.
  ///
  /// In ja, this message translates to:
  /// **'この操作は取り消せません。\\n試合データは完全に削除されます。'**
  String get deleteMatchWarning;

  /// No description provided for @matchInfoTabLabel.
  ///
  /// In ja, this message translates to:
  /// **'試合情報'**
  String get matchInfoTabLabel;

  /// No description provided for @issueReportTabLabel.
  ///
  /// In ja, this message translates to:
  /// **'問題報告'**
  String get issueReportTabLabel;

  /// No description provided for @awaitingResultStatus.
  ///
  /// In ja, this message translates to:
  /// **'結果入力待ち'**
  String get awaitingResultStatus;

  /// No description provided for @scheduledStatus.
  ///
  /// In ja, this message translates to:
  /// **'開催予定'**
  String get scheduledStatus;

  /// No description provided for @rankColumnLabel.
  ///
  /// In ja, this message translates to:
  /// **'順位'**
  String get rankColumnLabel;

  /// No description provided for @scoreColumnLabel.
  ///
  /// In ja, this message translates to:
  /// **'スコア'**
  String get scoreColumnLabel;

  /// No description provided for @individualScoreLabel.
  ///
  /// In ja, this message translates to:
  /// **'個人スコア'**
  String get individualScoreLabel;

  /// No description provided for @resultSavedMessage.
  ///
  /// In ja, this message translates to:
  /// **'試合結果を保存しました'**
  String get resultSavedMessage;

  /// No description provided for @publicMemoLabel.
  ///
  /// In ja, this message translates to:
  /// **'公開メモ（ユーザー閲覧可能）'**
  String get publicMemoLabel;

  /// No description provided for @publicMemoHint.
  ///
  /// In ja, this message translates to:
  /// **'参加者に公開される運営メモです'**
  String get publicMemoHint;

  /// No description provided for @privateMemoLabel.
  ///
  /// In ja, this message translates to:
  /// **'プライベートメモ（運営者のみ閲覧可能）'**
  String get privateMemoLabel;

  /// No description provided for @privateMemoHint.
  ///
  /// In ja, this message translates to:
  /// **'内部管理用のメモです（参加者には表示されません）'**
  String get privateMemoHint;

  /// No description provided for @noParticipantsText.
  ///
  /// In ja, this message translates to:
  /// **'参加者: なし'**
  String get noParticipantsText;

  /// No description provided for @participantsPrefix.
  ///
  /// In ja, this message translates to:
  /// **'参加者: '**
  String get participantsPrefix;

  /// No description provided for @noReportsHint.
  ///
  /// In ja, this message translates to:
  /// **'問題が発生した場合は、参加者から報告が届きます'**
  String get noReportsHint;

  /// No description provided for @reporterPrefix.
  ///
  /// In ja, this message translates to:
  /// **'報告者: '**
  String get reporterPrefix;

  /// No description provided for @adminActionLabel.
  ///
  /// In ja, this message translates to:
  /// **'運営対応'**
  String get adminActionLabel;

  /// No description provided for @violationTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反'**
  String get violationTitle;

  /// No description provided for @violationRecords.
  ///
  /// In ja, this message translates to:
  /// **'違反記録'**
  String get violationRecords;

  /// No description provided for @operationGuideTooltip.
  ///
  /// In ja, this message translates to:
  /// **'操作説明'**
  String get operationGuideTooltip;

  /// No description provided for @noViolationRecords.
  ///
  /// In ja, this message translates to:
  /// **'違反記録はありません'**
  String get noViolationRecords;

  /// No description provided for @noViolationReportsYet.
  ///
  /// In ja, this message translates to:
  /// **'このイベントでは違反報告がまだありません'**
  String get noViolationReportsYet;

  /// No description provided for @violationProcessButton.
  ///
  /// In ja, this message translates to:
  /// **'違反処理'**
  String get violationProcessButton;

  /// No description provided for @waitingAppealPeriod.
  ///
  /// In ja, this message translates to:
  /// **'異議申立期間中（待機）'**
  String get waitingAppealPeriod;

  /// No description provided for @processAppeal.
  ///
  /// In ja, this message translates to:
  /// **'異議申立を処理'**
  String get processAppeal;

  /// No description provided for @revertToPending.
  ///
  /// In ja, this message translates to:
  /// **'未処理に戻す'**
  String get revertToPending;

  /// No description provided for @statusInvestigating.
  ///
  /// In ja, this message translates to:
  /// **'調査中'**
  String get statusInvestigating;

  /// No description provided for @statusResolved.
  ///
  /// In ja, this message translates to:
  /// **'処理済み'**
  String get statusResolved;

  /// No description provided for @retryButton.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retryButton;

  /// No description provided for @severityMinor.
  ///
  /// In ja, this message translates to:
  /// **'軽微'**
  String get severityMinor;

  /// No description provided for @severityModerate.
  ///
  /// In ja, this message translates to:
  /// **'中程度'**
  String get severityModerate;

  /// No description provided for @severitySevere.
  ///
  /// In ja, this message translates to:
  /// **'重大'**
  String get severitySevere;

  /// No description provided for @violationTypeLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反の種類 *'**
  String get violationTypeLabel;

  /// No description provided for @severityLabel.
  ///
  /// In ja, this message translates to:
  /// **'重要度 *'**
  String get severityLabel;

  /// No description provided for @reportedAtLabel.
  ///
  /// In ja, this message translates to:
  /// **'報告日時'**
  String get reportedAtLabel;

  /// No description provided for @statusLabel.
  ///
  /// In ja, this message translates to:
  /// **'ステータス'**
  String get statusLabel;

  /// No description provided for @penaltyLabel.
  ///
  /// In ja, this message translates to:
  /// **'ペナルティ'**
  String get penaltyLabel;

  /// No description provided for @notesLabel.
  ///
  /// In ja, this message translates to:
  /// **'備考'**
  String get notesLabel;

  /// No description provided for @detailContentLabel.
  ///
  /// In ja, this message translates to:
  /// **'詳細内容:'**
  String get detailContentLabel;

  /// No description provided for @processViolationTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反処理'**
  String get processViolationTitle;

  /// No description provided for @penaltyContentLabel.
  ///
  /// In ja, this message translates to:
  /// **'ペナルティ内容'**
  String get penaltyContentLabel;

  /// No description provided for @penaltyContentHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 警告1回、1週間参加停止'**
  String get penaltyContentHint;

  /// No description provided for @notesOptionalLabel.
  ///
  /// In ja, this message translates to:
  /// **'備考（任意）'**
  String get notesOptionalLabel;

  /// No description provided for @processingNotesHint.
  ///
  /// In ja, this message translates to:
  /// **'処理に関するメモ'**
  String get processingNotesHint;

  /// No description provided for @doneButtonText.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get doneButtonText;

  /// No description provided for @pleaseEnterPenalty.
  ///
  /// In ja, this message translates to:
  /// **'ペナルティ内容を入力してください'**
  String get pleaseEnterPenalty;

  /// No description provided for @violationProcessed.
  ///
  /// In ja, this message translates to:
  /// **'違反を処理しました'**
  String get violationProcessed;

  /// No description provided for @processButton.
  ///
  /// In ja, this message translates to:
  /// **'処理する'**
  String get processButton;

  /// No description provided for @deleteViolationRecordTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反記録削除'**
  String get deleteViolationRecordTitle;

  /// No description provided for @importantCannotUndo.
  ///
  /// In ja, this message translates to:
  /// **'⚠️ 重要：この操作は取り消せません'**
  String get importantCannotUndo;

  /// No description provided for @deleteViolationRecordConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この違反記録を完全に削除しますか？'**
  String get deleteViolationRecordConfirm;

  /// No description provided for @rejectViolationRecordTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反記録却下'**
  String get rejectViolationRecordTitle;

  /// No description provided for @aboutRejection.
  ///
  /// In ja, this message translates to:
  /// **'ℹ️ 却下について'**
  String get aboutRejection;

  /// No description provided for @rejectViolationRecordConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この違反記録を却下しますか？'**
  String get rejectViolationRecordConfirm;

  /// No description provided for @rejectReasonOptionalLabel.
  ///
  /// In ja, this message translates to:
  /// **'却下理由（任意）'**
  String get rejectReasonOptionalLabel;

  /// No description provided for @rejectReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'却下する理由を記載してください'**
  String get rejectReasonHint;

  /// No description provided for @violationRecordRejected.
  ///
  /// In ja, this message translates to:
  /// **'違反記録を却下しました。関係者に通知されます。'**
  String get violationRecordRejected;

  /// No description provided for @reporterLabel.
  ///
  /// In ja, this message translates to:
  /// **'報告者:'**
  String get reporterLabel;

  /// No description provided for @gameProfileNotFound.
  ///
  /// In ja, this message translates to:
  /// **'このゲームのプロフィールが見つかりません'**
  String get gameProfileNotFound;

  /// No description provided for @selectGameTitle.
  ///
  /// In ja, this message translates to:
  /// **'ゲームを選択'**
  String get selectGameTitle;

  /// No description provided for @violationManagementGuide.
  ///
  /// In ja, this message translates to:
  /// **'違反管理の操作説明'**
  String get violationManagementGuide;

  /// No description provided for @guideBasicOperations.
  ///
  /// In ja, this message translates to:
  /// **'📝 基本操作'**
  String get guideBasicOperations;

  /// No description provided for @guideCardButtonsDesc.
  ///
  /// In ja, this message translates to:
  /// **'違反記録カードにある各ボタンの機能を説明します。'**
  String get guideCardButtonsDesc;

  /// No description provided for @guideImportantOperations.
  ///
  /// In ja, this message translates to:
  /// **'⚠️ 重要な操作'**
  String get guideImportantOperations;

  /// No description provided for @guideRestoreFeature.
  ///
  /// In ja, this message translates to:
  /// **'🔄 復旧機能'**
  String get guideRestoreFeature;

  /// No description provided for @guideDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'詳細'**
  String get guideDetailTitle;

  /// No description provided for @guideDetailDesc.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の詳細情報を表示します。'**
  String get guideDetailDesc;

  /// No description provided for @guideEditTitle.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get guideEditTitle;

  /// No description provided for @guideEditDesc.
  ///
  /// In ja, this message translates to:
  /// **'違反の種類、重要度、説明などを編集できます。'**
  String get guideEditDesc;

  /// No description provided for @guideProcessTitle.
  ///
  /// In ja, this message translates to:
  /// **'処理'**
  String get guideProcessTitle;

  /// No description provided for @guideProcessDesc.
  ///
  /// In ja, this message translates to:
  /// **'違反を確認し、ペナルティを記録して解決済みにします。'**
  String get guideProcessDesc;

  /// No description provided for @guideCautionOperations.
  ///
  /// In ja, this message translates to:
  /// **'以下の操作は慎重に実行してください。'**
  String get guideCautionOperations;

  /// No description provided for @guideRejectTitle.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get guideRejectTitle;

  /// No description provided for @guideRejectDesc.
  ///
  /// In ja, this message translates to:
  /// **'違反として不適切と判断した場合に使用。記録は残りますが「却下済み」になります。'**
  String get guideRejectDesc;

  /// No description provided for @guideDeleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get guideDeleteTitle;

  /// No description provided for @guideMistakeRecovery.
  ///
  /// In ja, this message translates to:
  /// **'誤操作した場合の対処法です。'**
  String get guideMistakeRecovery;

  /// No description provided for @guideRecoveryTitle.
  ///
  /// In ja, this message translates to:
  /// **'復旧'**
  String get guideRecoveryTitle;

  /// No description provided for @guideRecoveryDesc.
  ///
  /// In ja, this message translates to:
  /// **'処理済み・却下済みの記録を未処理状態に戻します。削除した記録は復旧できません。'**
  String get guideRecoveryDesc;

  /// No description provided for @guideRecoveryHint.
  ///
  /// In ja, this message translates to:
  /// **'ヒント：誤って処理や却下した場合は「復旧」ボタンで元に戻せます'**
  String get guideRecoveryHint;

  /// No description provided for @restoreViolationRecordTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反記録復旧'**
  String get restoreViolationRecordTitle;

  /// No description provided for @restoreReasonOptionalLabel.
  ///
  /// In ja, this message translates to:
  /// **'復旧理由（任意）'**
  String get restoreReasonOptionalLabel;

  /// No description provided for @restoreReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'復旧する理由を記載してください'**
  String get restoreReasonHint;

  /// No description provided for @violationRecordRestored.
  ///
  /// In ja, this message translates to:
  /// **'違反記録を復旧しました'**
  String get violationRecordRestored;

  /// No description provided for @restoreButton.
  ///
  /// In ja, this message translates to:
  /// **'復旧する'**
  String get restoreButton;

  /// No description provided for @appealSubmittedWaiting.
  ///
  /// In ja, this message translates to:
  /// **'異議申立済み - 処理待ち'**
  String get appealSubmittedWaiting;

  /// No description provided for @processableStatus.
  ///
  /// In ja, this message translates to:
  /// **'処理可能'**
  String get processableStatus;

  /// No description provided for @appealDeadlineExpired.
  ///
  /// In ja, this message translates to:
  /// **'異議申立期限切れ - 処理可能'**
  String get appealDeadlineExpired;

  /// No description provided for @gameProfileTitle.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィール'**
  String get gameProfileTitle;

  /// No description provided for @gameInfoSection.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム情報'**
  String get gameInfoSection;

  /// No description provided for @inGameId.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ID'**
  String get inGameId;

  /// No description provided for @notSet.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get notSet;

  /// No description provided for @usernameUnknown.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名不明'**
  String get usernameUnknown;

  /// No description provided for @noUserIdSet.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーIDなし'**
  String get noUserIdSet;

  /// No description provided for @communicationSection.
  ///
  /// In ja, this message translates to:
  /// **'コミュニケーション'**
  String get communicationSection;

  /// No description provided for @voiceChat.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット'**
  String get voiceChat;

  /// No description provided for @vcUsable.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット使用可能'**
  String get vcUsable;

  /// No description provided for @vcNotUsable.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット不使用'**
  String get vcNotUsable;

  /// No description provided for @vcDetailsSection.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット詳細'**
  String get vcDetailsSection;

  /// No description provided for @achievementsGoals.
  ///
  /// In ja, this message translates to:
  /// **'実績・達成目標'**
  String get achievementsGoals;

  /// No description provided for @notesSection.
  ///
  /// In ja, this message translates to:
  /// **'メモ・備考'**
  String get notesSection;

  /// No description provided for @snsAccountsTitle.
  ///
  /// In ja, this message translates to:
  /// **'SNSアカウント'**
  String get snsAccountsTitle;

  /// No description provided for @userDetailsTitle.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー詳細'**
  String get userDetailsTitle;

  /// No description provided for @userListTitle.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー一覧'**
  String get userListTitle;

  /// No description provided for @searchByUsernameOrGameIdHint.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名やゲームIDで検索...'**
  String get searchByUsernameOrGameIdHint;

  /// No description provided for @noParticipantsYet.
  ///
  /// In ja, this message translates to:
  /// **'まだ参加者はいません'**
  String get noParticipantsYet;

  /// No description provided for @gameExperience.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム歴'**
  String get gameExperience;

  /// No description provided for @clanLabel.
  ///
  /// In ja, this message translates to:
  /// **'クラン'**
  String get clanLabel;

  /// No description provided for @eventDefault.
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get eventDefault;

  /// No description provided for @reportViolation.
  ///
  /// In ja, this message translates to:
  /// **'違反を報告'**
  String get reportViolation;

  /// No description provided for @profileDisplaySection.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール表示'**
  String get profileDisplaySection;

  /// No description provided for @gameProfileDescription.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内でのプロフィール情報'**
  String get gameProfileDescription;

  /// No description provided for @userProfileLabel.
  ///
  /// In ja, this message translates to:
  /// **'ユーザープロフィール'**
  String get userProfileLabel;

  /// No description provided for @userProfileDescription.
  ///
  /// In ja, this message translates to:
  /// **'アプリ内でのユーザー情報'**
  String get userProfileDescription;

  /// No description provided for @visibilityPrivate.
  ///
  /// In ja, this message translates to:
  /// **'プライベート'**
  String get visibilityPrivate;

  /// No description provided for @approvalAuto.
  ///
  /// In ja, this message translates to:
  /// **'自動承認'**
  String get approvalAuto;

  /// No description provided for @approvalManual.
  ///
  /// In ja, this message translates to:
  /// **'手動承認'**
  String get approvalManual;

  /// No description provided for @hidePassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを隠す'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを表示'**
  String get showPassword;

  /// No description provided for @exampleCount.
  ///
  /// In ja, this message translates to:
  /// **'例：100'**
  String get exampleCount;

  /// No description provided for @prizeSettingsTitle.
  ///
  /// In ja, this message translates to:
  /// **'賞品設定について'**
  String get prizeSettingsTitle;

  /// No description provided for @prizeInfoBullet1.
  ///
  /// In ja, this message translates to:
  /// **'賞品情報は参加者への案内として表示されます'**
  String get prizeInfoBullet1;

  /// No description provided for @prizeInfoBullet2.
  ///
  /// In ja, this message translates to:
  /// **'実際の受け渡しは主催者と参加者間で行ってください'**
  String get prizeInfoBullet2;

  /// No description provided for @prizeInfoBullet3.
  ///
  /// In ja, this message translates to:
  /// **'アプリでは受け渡しの仲介や保証は行いません'**
  String get prizeInfoBullet3;

  /// No description provided for @prizeInfoBullet4.
  ///
  /// In ja, this message translates to:
  /// **'受け渡し方法は事前に参加者と相談してください'**
  String get prizeInfoBullet4;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加NGユーザー'**
  String get blockedUsersTitle;

  /// No description provided for @eventOperatorsTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント運営者'**
  String get eventOperatorsTitle;

  /// No description provided for @addOperatorPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'イベント運営者を追加してください'**
  String get addOperatorPlaceholder;

  /// No description provided for @addMyselfButton.
  ///
  /// In ja, this message translates to:
  /// **'自分を追加'**
  String get addMyselfButton;

  /// No description provided for @searchOperatorTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント運営者を検索'**
  String get searchOperatorTitle;

  /// No description provided for @searchOperatorDesc.
  ///
  /// In ja, this message translates to:
  /// **'イベントを管理する運営者を追加してください'**
  String get searchOperatorDesc;

  /// No description provided for @selectOperatorFromFollows.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから運営者を選択'**
  String get selectOperatorFromFollows;

  /// No description provided for @selectOperatorFromFollowsDesc.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローの中からイベント運営者を追加してください'**
  String get selectOperatorFromFollowsDesc;

  /// No description provided for @addSponsorTitle.
  ///
  /// In ja, this message translates to:
  /// **'スポンサーを追加'**
  String get addSponsorTitle;

  /// No description provided for @addSponsorQuestion.
  ///
  /// In ja, this message translates to:
  /// **'どの方法でスポンサーを追加しますか？'**
  String get addSponsorQuestion;

  /// No description provided for @searchSponsorTitle.
  ///
  /// In ja, this message translates to:
  /// **'スポンサーを検索'**
  String get searchSponsorTitle;

  /// No description provided for @searchSponsorDesc.
  ///
  /// In ja, this message translates to:
  /// **'イベントのスポンサーを追加してください'**
  String get searchSponsorDesc;

  /// No description provided for @selectSponsorFromFollows.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローからスポンサーを選択'**
  String get selectSponsorFromFollows;

  /// No description provided for @selectSponsorFromFollowsDesc.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローの中からイベントスポンサーを追加してください'**
  String get selectSponsorFromFollowsDesc;

  /// No description provided for @addBlockedUserDesc.
  ///
  /// In ja, this message translates to:
  /// **'このイベントをブロックするユーザーを追加してください'**
  String get addBlockedUserDesc;

  /// No description provided for @cannotBlockOperatorOrSponsor.
  ///
  /// In ja, this message translates to:
  /// **'運営者やスポンサーをNGユーザーに設定することはできません'**
  String get cannotBlockOperatorOrSponsor;

  /// No description provided for @defaultUsername.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get defaultUsername;

  /// No description provided for @alreadyAddedAsOperator.
  ///
  /// In ja, this message translates to:
  /// **'既に運営者として追加されています'**
  String get alreadyAddedAsOperator;

  /// No description provided for @searchInviteMemberTitle.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバーを検索'**
  String get searchInviteMemberTitle;

  /// No description provided for @searchInviteMemberDesc.
  ///
  /// In ja, this message translates to:
  /// **'イベントに招待するメンバーを追加してください'**
  String get searchInviteMemberDesc;

  /// No description provided for @addInviteMemberPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'招待するメンバーを追加してください'**
  String get addInviteMemberPlaceholder;

  /// No description provided for @addInviteMemberButton.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバーを追加'**
  String get addInviteMemberButton;

  /// No description provided for @setDeadlineFirst.
  ///
  /// In ja, this message translates to:
  /// **'申込期限を有効にして設定してください'**
  String get setDeadlineFirst;

  /// No description provided for @setEventDateFirst.
  ///
  /// In ja, this message translates to:
  /// **'まず開催日時を設定してください'**
  String get setEventDateFirst;

  /// No description provided for @deadlineMustBe3HoursBefore.
  ///
  /// In ja, this message translates to:
  /// **'申込期限は開催時刻の少なくとも3時間前に設定してください'**
  String get deadlineMustBe3HoursBefore;

  /// No description provided for @cancelDeadlineBeforeEvent.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル期限は開催日時より前に設定してください'**
  String get cancelDeadlineBeforeEvent;

  /// No description provided for @deadlineMustBeFuture.
  ///
  /// In ja, this message translates to:
  /// **'申込期限は現在時刻より後に設定してください'**
  String get deadlineMustBeFuture;

  /// No description provided for @deadlineMust3HoursBeforeEvent.
  ///
  /// In ja, this message translates to:
  /// **'申込期限は開催日時の3時間前までに設定してください'**
  String get deadlineMust3HoursBeforeEvent;

  /// No description provided for @eventDateMustBeFuture.
  ///
  /// In ja, this message translates to:
  /// **'開催日時は現在時刻より後に設定してください'**
  String get eventDateMustBeFuture;

  /// No description provided for @impactOnParticipantsTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者への影響について'**
  String get impactOnParticipantsTitle;

  /// No description provided for @impactOnRevertToDraft.
  ///
  /// In ja, this message translates to:
  /// **'下書きに戻すと、参加者は以下の影響を受けます：'**
  String get impactOnRevertToDraft;

  /// No description provided for @impactEventHidden.
  ///
  /// In ja, this message translates to:
  /// **'イベントが非公開になり、参加者がアクセスできなくなります'**
  String get impactEventHidden;

  /// No description provided for @impactParticipantsNotified.
  ///
  /// In ja, this message translates to:
  /// **'参加者に通知が送信されます'**
  String get impactParticipantsNotified;

  /// No description provided for @impactRegistrationTemporarilyInvalid.
  ///
  /// In ja, this message translates to:
  /// **'参加申込は保持されますが、一時的に無効となります'**
  String get impactRegistrationTemporarilyInvalid;

  /// No description provided for @revertToDraftButton.
  ///
  /// In ja, this message translates to:
  /// **'下書きに戻す'**
  String get revertToDraftButton;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが認証されていません。ログインしてください。'**
  String get pleaseLoginFirst;

  /// No description provided for @enterEventName.
  ///
  /// In ja, this message translates to:
  /// **'イベント名を入力してください'**
  String get enterEventName;

  /// No description provided for @enterEventDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベント内容を入力してください'**
  String get enterEventDescription;

  /// No description provided for @enterParticipationRules.
  ///
  /// In ja, this message translates to:
  /// **'参加ルールを入力してください'**
  String get enterParticipationRules;

  /// No description provided for @selectPlatform.
  ///
  /// In ja, this message translates to:
  /// **'プラットフォームを選択してください'**
  String get selectPlatform;

  /// No description provided for @setEventDate.
  ///
  /// In ja, this message translates to:
  /// **'開催日時を設定してください'**
  String get setEventDate;

  /// No description provided for @setRegistrationDeadline.
  ///
  /// In ja, this message translates to:
  /// **'参加申込締切を設定してください'**
  String get setRegistrationDeadline;

  /// No description provided for @deadlineBeforeEvent.
  ///
  /// In ja, this message translates to:
  /// **'参加申込締切は開催日時より前に設定してください'**
  String get deadlineBeforeEvent;

  /// No description provided for @enterMaxParticipants.
  ///
  /// In ja, this message translates to:
  /// **'最大参加人数を入力してください'**
  String get enterMaxParticipants;

  /// No description provided for @maxParticipantsPositive.
  ///
  /// In ja, this message translates to:
  /// **'最大参加人数は正の整数で入力してください'**
  String get maxParticipantsPositive;

  /// No description provided for @enterPrizeContent.
  ///
  /// In ja, this message translates to:
  /// **'賞品内容を入力してください'**
  String get enterPrizeContent;

  /// No description provided for @addOperatorForPrize.
  ///
  /// In ja, this message translates to:
  /// **'賞品設定時は運営者を追加してください'**
  String get addOperatorForPrize;

  /// No description provided for @enterStreamingUrl.
  ///
  /// In ja, this message translates to:
  /// **'配信URLを入力してください'**
  String get enterStreamingUrl;

  /// No description provided for @eventDetailDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベント詳細画面で参加者の管理や\\nイベント情報の確認ができます'**
  String get eventDetailDescription;

  /// No description provided for @confirmButton.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get confirmButton;

  /// No description provided for @cautionNeeded.
  ///
  /// In ja, this message translates to:
  /// **'注意が必要です'**
  String get cautionNeeded;

  /// No description provided for @cannotRevertToDraftTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベントの下書き化はできません'**
  String get cannotRevertToDraftTitle;

  /// No description provided for @selectedDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'選択した日付'**
  String get selectedDateLabel;

  /// No description provided for @backToCalendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーに戻る'**
  String get backToCalendar;

  /// No description provided for @weekdayMonday.
  ///
  /// In ja, this message translates to:
  /// **'月曜日'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In ja, this message translates to:
  /// **'火曜日'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In ja, this message translates to:
  /// **'水曜日'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In ja, this message translates to:
  /// **'木曜日'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In ja, this message translates to:
  /// **'金曜日'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In ja, this message translates to:
  /// **'土曜日'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In ja, this message translates to:
  /// **'日曜日'**
  String get weekdaySunday;

  /// No description provided for @weekdayShortMon.
  ///
  /// In ja, this message translates to:
  /// **'月'**
  String get weekdayShortMon;

  /// No description provided for @weekdayShortTue.
  ///
  /// In ja, this message translates to:
  /// **'火'**
  String get weekdayShortTue;

  /// No description provided for @weekdayShortWed.
  ///
  /// In ja, this message translates to:
  /// **'水'**
  String get weekdayShortWed;

  /// No description provided for @weekdayShortThu.
  ///
  /// In ja, this message translates to:
  /// **'木'**
  String get weekdayShortThu;

  /// No description provided for @weekdayShortFri.
  ///
  /// In ja, this message translates to:
  /// **'金'**
  String get weekdayShortFri;

  /// No description provided for @weekdayShortSat.
  ///
  /// In ja, this message translates to:
  /// **'土'**
  String get weekdayShortSat;

  /// No description provided for @weekdayShortSun.
  ///
  /// In ja, this message translates to:
  /// **'日'**
  String get weekdayShortSun;

  /// No description provided for @eventsLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get eventsLabel;

  /// No description provided for @displayFilter.
  ///
  /// In ja, this message translates to:
  /// **'表示フィルター'**
  String get displayFilter;

  /// No description provided for @applyButton.
  ///
  /// In ja, this message translates to:
  /// **'適用'**
  String get applyButton;

  /// No description provided for @publishedEventsFilter.
  ///
  /// In ja, this message translates to:
  /// **'公開済みイベント'**
  String get publishedEventsFilter;

  /// No description provided for @draftEventsFilter.
  ///
  /// In ja, this message translates to:
  /// **'下書きイベント'**
  String get draftEventsFilter;

  /// No description provided for @completedEventsFilter.
  ///
  /// In ja, this message translates to:
  /// **'完了済みイベント'**
  String get completedEventsFilter;

  /// No description provided for @hostEventCalendar.
  ///
  /// In ja, this message translates to:
  /// **'主催イベントカレンダー'**
  String get hostEventCalendar;

  /// No description provided for @noEventsOnSelectedDate.
  ///
  /// In ja, this message translates to:
  /// **'選択した日にはイベントがありません'**
  String get noEventsOnSelectedDate;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーがログインしていません'**
  String get userNotLoggedIn;

  /// No description provided for @participatingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加予定イベント'**
  String get participatingEvents;

  /// No description provided for @noParticipatingEvents.
  ///
  /// In ja, this message translates to:
  /// **'参加中のイベントはありません'**
  String get noParticipatingEvents;

  /// No description provided for @tryJoinNewEvents.
  ///
  /// In ja, this message translates to:
  /// **'新しいイベントに参加してみませんか？'**
  String get tryJoinNewEvents;

  /// No description provided for @createEventTitle.
  ///
  /// In ja, this message translates to:
  /// **'新規イベント作成'**
  String get createEventTitle;

  /// No description provided for @basicInfoSection.
  ///
  /// In ja, this message translates to:
  /// **'基本情報'**
  String get basicInfoSection;

  /// No description provided for @eventNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント名'**
  String get eventNameLabel;

  /// No description provided for @eventNameHint.
  ///
  /// In ja, this message translates to:
  /// **'イベント名を入力してください'**
  String get eventNameHint;

  /// No description provided for @subtitleLabel.
  ///
  /// In ja, this message translates to:
  /// **'サブタイトル'**
  String get subtitleLabel;

  /// No description provided for @subtitleHint.
  ///
  /// In ja, this message translates to:
  /// **'サブタイトルを入力（任意）'**
  String get subtitleHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント詳細説明'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In ja, this message translates to:
  /// **'イベントの詳細な説明を入力してください'**
  String get descriptionHint;

  /// No description provided for @rulesLabel.
  ///
  /// In ja, this message translates to:
  /// **'ルール'**
  String get rulesLabel;

  /// No description provided for @rulesHint.
  ///
  /// In ja, this message translates to:
  /// **'イベントのルールを入力してください'**
  String get rulesHint;

  /// No description provided for @imageLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント画像'**
  String get imageLabel;

  /// No description provided for @addImageButton.
  ///
  /// In ja, this message translates to:
  /// **'画像を追加'**
  String get addImageButton;

  /// No description provided for @scheduleSection.
  ///
  /// In ja, this message translates to:
  /// **'開催設定'**
  String get scheduleSection;

  /// No description provided for @eventDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'開催日時'**
  String get eventDateLabel;

  /// No description provided for @gameSettingsSection.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム・参加設定'**
  String get gameSettingsSection;

  /// No description provided for @gameSelectionLabel.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム選択'**
  String get gameSelectionLabel;

  /// No description provided for @platformLabel.
  ///
  /// In ja, this message translates to:
  /// **'対象プラットフォーム'**
  String get platformLabel;

  /// No description provided for @maxParticipantsLabel.
  ///
  /// In ja, this message translates to:
  /// **'最大参加者数'**
  String get maxParticipantsLabel;

  /// No description provided for @additionalInfoLabel.
  ///
  /// In ja, this message translates to:
  /// **'追加情報・注意事項'**
  String get additionalInfoLabel;

  /// No description provided for @additionalInfoHint.
  ///
  /// In ja, this message translates to:
  /// **'追加情報があれば記載してください'**
  String get additionalInfoHint;

  /// No description provided for @eventTagsLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベントタグ'**
  String get eventTagsLabel;

  /// No description provided for @eventTagsHint.
  ///
  /// In ja, this message translates to:
  /// **'タグを入力してEnter'**
  String get eventTagsHint;

  /// No description provided for @prizeSection.
  ///
  /// In ja, this message translates to:
  /// **'賞品'**
  String get prizeSection;

  /// No description provided for @hasPrizeLabel.
  ///
  /// In ja, this message translates to:
  /// **'賞品あり'**
  String get hasPrizeLabel;

  /// No description provided for @prizeContentLabel.
  ///
  /// In ja, this message translates to:
  /// **'賞品内容'**
  String get prizeContentLabel;

  /// No description provided for @sponsorsLabel.
  ///
  /// In ja, this message translates to:
  /// **'スポンサー'**
  String get sponsorsLabel;

  /// No description provided for @managementSection.
  ///
  /// In ja, this message translates to:
  /// **'運営・管理'**
  String get managementSection;

  /// No description provided for @categorySection.
  ///
  /// In ja, this message translates to:
  /// **'公開設定'**
  String get categorySection;

  /// No description provided for @visibilityLabel.
  ///
  /// In ja, this message translates to:
  /// **'公開範囲'**
  String get visibilityLabel;

  /// No description provided for @invitationSection.
  ///
  /// In ja, this message translates to:
  /// **'招待設定'**
  String get invitationSection;

  /// No description provided for @eventPasswordLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベントパスワード'**
  String get eventPasswordLabel;

  /// No description provided for @eventPasswordHint.
  ///
  /// In ja, this message translates to:
  /// **'参加に必要なパスワードを設定してください'**
  String get eventPasswordHint;

  /// No description provided for @inviteMembersLabel.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバー'**
  String get inviteMembersLabel;

  /// No description provided for @externalSection.
  ///
  /// In ja, this message translates to:
  /// **'外部連携'**
  String get externalSection;

  /// No description provided for @contactLabel.
  ///
  /// In ja, this message translates to:
  /// **'コミュニティ・その他'**
  String get contactLabel;

  /// No description provided for @streamingLabel.
  ///
  /// In ja, this message translates to:
  /// **'配信予定'**
  String get streamingLabel;

  /// No description provided for @streamingUrlLabel.
  ///
  /// In ja, this message translates to:
  /// **'配信URL'**
  String get streamingUrlLabel;

  /// No description provided for @streamingUrlInputHint.
  ///
  /// In ja, this message translates to:
  /// **'https://... と入力してEnterで追加'**
  String get streamingUrlInputHint;

  /// No description provided for @streamingUrlDuplicate.
  ///
  /// In ja, this message translates to:
  /// **'このURLは既に追加されています'**
  String get streamingUrlDuplicate;

  /// No description provided for @streamingUrlMaxReached.
  ///
  /// In ja, this message translates to:
  /// **'最大{maxUrls}個まで配信URLを追加できます'**
  String streamingUrlMaxReached(int maxUrls);

  /// No description provided for @streamingUrlInvalid.
  ///
  /// In ja, this message translates to:
  /// **'有効なURLを入力してください (https://... または http://...)'**
  String get streamingUrlInvalid;

  /// No description provided for @streamingUrlCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}/{maxUrls}個の配信URL'**
  String streamingUrlCount(int count, int maxUrls);

  /// No description provided for @deleteUrlTooltip.
  ///
  /// In ja, this message translates to:
  /// **'URLを削除'**
  String get deleteUrlTooltip;

  /// No description provided for @otherSection.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get otherSection;

  /// No description provided for @policyLabel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル・変更ポリシー'**
  String get policyLabel;

  /// No description provided for @saveDraftButton.
  ///
  /// In ja, this message translates to:
  /// **'下書き保存'**
  String get saveDraftButton;

  /// No description provided for @iosLabel.
  ///
  /// In ja, this message translates to:
  /// **'iOS'**
  String get iosLabel;

  /// No description provided for @androidLabel.
  ///
  /// In ja, this message translates to:
  /// **'Android'**
  String get androidLabel;

  /// No description provided for @noDeadlineInfo.
  ///
  /// In ja, this message translates to:
  /// **'申込期限なし - 参加者はいつでも申し込み可能です'**
  String get noDeadlineInfo;

  /// No description provided for @participantCancelDeadlineLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者キャンセル期限（任意）'**
  String get participantCancelDeadlineLabel;

  /// No description provided for @selectGamePlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'ゲームを選択してください'**
  String get selectGamePlaceholder;

  /// No description provided for @maxParticipantsHint.
  ///
  /// In ja, this message translates to:
  /// **'例：100'**
  String get maxParticipantsHint;

  /// No description provided for @prizeContentHintText.
  ///
  /// In ja, this message translates to:
  /// **'例：1位 10万円、2位 5万円、3位 1万円'**
  String get prizeContentHintText;

  /// No description provided for @addSponsorButtonText.
  ///
  /// In ja, this message translates to:
  /// **'スポンサーを追加'**
  String get addSponsorButtonText;

  /// No description provided for @eventOperatorsLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント運営者'**
  String get eventOperatorsLabel;

  /// No description provided for @addSelfButton.
  ///
  /// In ja, this message translates to:
  /// **'自分を追加'**
  String get addSelfButton;

  /// No description provided for @fromMutualFollowsButton.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから'**
  String get fromMutualFollowsButton;

  /// No description provided for @userSearchButton.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー検索'**
  String get userSearchButton;

  /// No description provided for @blockedUsersLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加NGユーザー'**
  String get blockedUsersLabel;

  /// No description provided for @addBlockedUserButton.
  ///
  /// In ja, this message translates to:
  /// **'NGユーザーを追加'**
  String get addBlockedUserButton;

  /// No description provided for @minStreamingUrlError.
  ///
  /// In ja, this message translates to:
  /// **'最低1つの配信URLを入力してください'**
  String get minStreamingUrlError;

  /// No description provided for @policyHint.
  ///
  /// In ja, this message translates to:
  /// **'例：イベント開始24時間前まではキャンセル可能'**
  String get policyHint;

  /// No description provided for @createEventButton.
  ///
  /// In ja, this message translates to:
  /// **'イベントを作成'**
  String get createEventButton;

  /// No description provided for @creatingEventLoading.
  ///
  /// In ja, this message translates to:
  /// **'イベントを作成中...'**
  String get creatingEventLoading;

  /// No description provided for @savingDraftLoading.
  ///
  /// In ja, this message translates to:
  /// **'下書きを保存中...'**
  String get savingDraftLoading;

  /// No description provided for @selectDateTimePlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'日時を選択してください'**
  String get selectDateTimePlaceholder;

  /// No description provided for @selectOperatorFromFollowsTitle.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから運営者を選択'**
  String get selectOperatorFromFollowsTitle;

  /// No description provided for @addSponsorDialogQuestion.
  ///
  /// In ja, this message translates to:
  /// **'どの方法でスポンサーを追加しますか？'**
  String get addSponsorDialogQuestion;

  /// No description provided for @selectFromMutualFollowsButton.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから選択'**
  String get selectFromMutualFollowsButton;

  /// No description provided for @selectSponsorFromFollowsTitle.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローからスポンサーを選択'**
  String get selectSponsorFromFollowsTitle;

  /// No description provided for @searchBlockedUserTitle.
  ///
  /// In ja, this message translates to:
  /// **'NGユーザーを検索'**
  String get searchBlockedUserTitle;

  /// No description provided for @searchBlockedUserDesc.
  ///
  /// In ja, this message translates to:
  /// **'このイベントをブロックするユーザーを追加してください'**
  String get searchBlockedUserDesc;

  /// No description provided for @userNotAuthenticatedError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが認証されていません'**
  String get userNotAuthenticatedError;

  /// No description provided for @alreadyAddedAsOperatorError.
  ///
  /// In ja, this message translates to:
  /// **'既に運営者として追加されています'**
  String get alreadyAddedAsOperatorError;

  /// No description provided for @alreadyAddedAsSponsorError.
  ///
  /// In ja, this message translates to:
  /// **'既にスポンサーとして追加されています'**
  String get alreadyAddedAsSponsorError;

  /// No description provided for @prizeSettingsDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'賞品設定について'**
  String get prizeSettingsDialogTitle;

  /// No description provided for @registrationDeadlineSectionLabel.
  ///
  /// In ja, this message translates to:
  /// **'申込期限'**
  String get registrationDeadlineSectionLabel;

  /// No description provided for @matchDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合詳細'**
  String get matchDetailTitle;

  /// No description provided for @recommendedEventsTitle.
  ///
  /// In ja, this message translates to:
  /// **'おすすめイベント'**
  String get recommendedEventsTitle;

  /// No description provided for @profileImageCropTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール画像を調整'**
  String get profileImageCropTitle;

  /// No description provided for @removeParticipantDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者の除名'**
  String get removeParticipantDialogTitle;

  /// No description provided for @rejectParticipantDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加申請の拒否'**
  String get rejectParticipantDialogTitle;

  /// No description provided for @selectFromPastEventsTitle.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベントから選択'**
  String get selectFromPastEventsTitle;

  /// No description provided for @matchReportManagementTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合報告管理'**
  String get matchReportManagementTitle;

  /// No description provided for @paymentManagementTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加費管理'**
  String get paymentManagementTitle;

  /// No description provided for @participantManagementTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者管理'**
  String get participantManagementTitle;

  /// No description provided for @groupInfoTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループ情報'**
  String get groupInfoTitle;

  /// No description provided for @participantListTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者一覧'**
  String get participantListTitle;

  /// No description provided for @violationReportMenuTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反報告'**
  String get violationReportMenuTitle;

  /// No description provided for @approveApplicationDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を承認しますか？'**
  String get approveApplicationDialogTitle;

  /// No description provided for @rejectApplicationDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を拒否しますか？'**
  String get rejectApplicationDialogTitle;

  /// No description provided for @applicationMessageLabel.
  ///
  /// In ja, this message translates to:
  /// **'申込メッセージ:'**
  String get applicationMessageLabel;

  /// No description provided for @approvalMessageLabel.
  ///
  /// In ja, this message translates to:
  /// **'承認メッセージ:'**
  String get approvalMessageLabel;

  /// No description provided for @rejectionReasonTitle.
  ///
  /// In ja, this message translates to:
  /// **'拒否理由:'**
  String get rejectionReasonTitle;

  /// No description provided for @approvalSuccessMessage.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を承認しました'**
  String get approvalSuccessMessage;

  /// No description provided for @rejectionSuccessMessage.
  ///
  /// In ja, this message translates to:
  /// **'参加申請を拒否しました'**
  String get rejectionSuccessMessage;

  /// No description provided for @approvalFailedMessage.
  ///
  /// In ja, this message translates to:
  /// **'承認に失敗しました'**
  String get approvalFailedMessage;

  /// No description provided for @cannotApproveFullCapacity.
  ///
  /// In ja, this message translates to:
  /// **'満員のため承認できません'**
  String get cannotApproveFullCapacity;

  /// No description provided for @nearCapacityWarning.
  ///
  /// In ja, this message translates to:
  /// **'定員間近です'**
  String get nearCapacityWarning;

  /// No description provided for @approvalWillReachCapacity.
  ///
  /// In ja, this message translates to:
  /// **'承認すると定員に達します。'**
  String get approvalWillReachCapacity;

  /// No description provided for @continueApproval.
  ///
  /// In ja, this message translates to:
  /// **'承認を続けますか？'**
  String get continueApproval;

  /// No description provided for @enterApprovalMessageOptional.
  ///
  /// In ja, this message translates to:
  /// **'承認メッセージを入力できます（任意）'**
  String get enterApprovalMessageOptional;

  /// No description provided for @enterRejectionReasonOptional.
  ///
  /// In ja, this message translates to:
  /// **'拒否理由を入力してください（任意）'**
  String get enterRejectionReasonOptional;

  /// No description provided for @enterApprovalMessagePlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'承認メッセージを入力...'**
  String get enterApprovalMessagePlaceholder;

  /// No description provided for @enterRejectionReasonPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'拒否理由を入力...'**
  String get enterRejectionReasonPlaceholder;

  /// No description provided for @revokeApprovalReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'理由を入力（任意）...'**
  String get revokeApprovalReasonHint;

  /// No description provided for @approvalRevokedMessage.
  ///
  /// In ja, this message translates to:
  /// **'承認が取り消されました'**
  String get approvalRevokedMessage;

  /// No description provided for @confirmButtonLabel.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get confirmButtonLabel;

  /// No description provided for @approveButtonLabel.
  ///
  /// In ja, this message translates to:
  /// **'承認する'**
  String get approveButtonLabel;

  /// No description provided for @doneButtonLabel.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get doneButtonLabel;

  /// No description provided for @noRecommendedEvents.
  ///
  /// In ja, this message translates to:
  /// **'おすすめイベントがありません'**
  String get noRecommendedEvents;

  /// No description provided for @registerFavoriteGamesHint.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのゲームを登録すると\\n関連するイベントが表示されます'**
  String get registerFavoriteGamesHint;

  /// No description provided for @participantMenuTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者メニュー'**
  String get participantMenuTitle;

  /// No description provided for @loginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get loginRequired;

  /// No description provided for @groupInfoDescription.
  ///
  /// In ja, this message translates to:
  /// **'自分の所属グループとメンバーを確認'**
  String get groupInfoDescription;

  /// No description provided for @participantListDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベントの参加者一覧を確認'**
  String get participantListDescription;

  /// No description provided for @violationReportDescription.
  ///
  /// In ja, this message translates to:
  /// **'迷惑行為や違反行為を報告'**
  String get violationReportDescription;

  /// No description provided for @participantMode.
  ///
  /// In ja, this message translates to:
  /// **'参加者モード'**
  String get participantMode;

  /// No description provided for @userSearchTitle.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーを検索'**
  String get userSearchTitle;

  /// No description provided for @eventPaid.
  ///
  /// In ja, this message translates to:
  /// **'有料'**
  String get eventPaid;

  /// No description provided for @eventFree.
  ///
  /// In ja, this message translates to:
  /// **'無料'**
  String get eventFree;

  /// No description provided for @managementStatusDraft.
  ///
  /// In ja, this message translates to:
  /// **'下書き'**
  String get managementStatusDraft;

  /// No description provided for @managementStatusPublished.
  ///
  /// In ja, this message translates to:
  /// **'公開済み'**
  String get managementStatusPublished;

  /// No description provided for @managementStatusPublishing.
  ///
  /// In ja, this message translates to:
  /// **'公開中'**
  String get managementStatusPublishing;

  /// No description provided for @managementStatusActive.
  ///
  /// In ja, this message translates to:
  /// **'開催中'**
  String get managementStatusActive;

  /// No description provided for @managementStatusEnded.
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get managementStatusEnded;

  /// No description provided for @managementStatusCancelled.
  ///
  /// In ja, this message translates to:
  /// **'中止'**
  String get managementStatusCancelled;

  /// No description provided for @managementVisibilityLimited.
  ///
  /// In ja, this message translates to:
  /// **'限定'**
  String get managementVisibilityLimited;

  /// No description provided for @addInviteMembersDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベントに招待するメンバーを追加してください'**
  String get addInviteMembersDescription;

  /// No description provided for @addInviteMembersEmptyMessage.
  ///
  /// In ja, this message translates to:
  /// **'招待するメンバーを追加してください'**
  String get addInviteMembersEmptyMessage;

  /// No description provided for @addInviteMembersButton.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバーを追加'**
  String get addInviteMembersButton;

  /// No description provided for @eventDateAfterNow.
  ///
  /// In ja, this message translates to:
  /// **'開催日時は現在時刻より後に設定してください'**
  String get eventDateAfterNow;

  /// No description provided for @changeToRevertToDraft.
  ///
  /// In ja, this message translates to:
  /// **'下書きに変更'**
  String get changeToRevertToDraft;

  /// No description provided for @participantsWillBeNotified.
  ///
  /// In ja, this message translates to:
  /// **'参加者に通知が送信されます'**
  String get participantsWillBeNotified;

  /// No description provided for @eventUpdatedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'イベントを更新しました'**
  String get eventUpdatedSuccess;

  /// No description provided for @changesSavedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'変更を保存しました'**
  String get changesSavedSuccess;

  /// No description provided for @draftSavedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'下書きを保存しました'**
  String get draftSavedSuccess;

  /// No description provided for @validationEventNameRequired.
  ///
  /// In ja, this message translates to:
  /// **'イベント名を入力してください'**
  String get validationEventNameRequired;

  /// No description provided for @validationEventDescriptionRequired.
  ///
  /// In ja, this message translates to:
  /// **'イベント説明を入力してください'**
  String get validationEventDescriptionRequired;

  /// No description provided for @validationRulesRequired.
  ///
  /// In ja, this message translates to:
  /// **'参加ルールを入力してください'**
  String get validationRulesRequired;

  /// No description provided for @validationGameRequired.
  ///
  /// In ja, this message translates to:
  /// **'ゲームを選択してください'**
  String get validationGameRequired;

  /// No description provided for @validationPlatformRequired.
  ///
  /// In ja, this message translates to:
  /// **'プラットフォームを選択してください'**
  String get validationPlatformRequired;

  /// No description provided for @validationEventDateRequired.
  ///
  /// In ja, this message translates to:
  /// **'開催日時を設定してください'**
  String get validationEventDateRequired;

  /// No description provided for @validationEventDateFuture.
  ///
  /// In ja, this message translates to:
  /// **'開催日時は現在時刻より後に設定してください'**
  String get validationEventDateFuture;

  /// No description provided for @validationRegistrationDeadlineRequired.
  ///
  /// In ja, this message translates to:
  /// **'参加申込締切を設定してください'**
  String get validationRegistrationDeadlineRequired;

  /// No description provided for @validationMaxParticipantsRequired.
  ///
  /// In ja, this message translates to:
  /// **'最大参加者数を入力してください'**
  String get validationMaxParticipantsRequired;

  /// No description provided for @validationMaxParticipantsPositive.
  ///
  /// In ja, this message translates to:
  /// **'最大参加人数は正の整数で入力してください'**
  String get validationMaxParticipantsPositive;

  /// No description provided for @validationInviteMembersRequired.
  ///
  /// In ja, this message translates to:
  /// **'招待メンバーを追加してください'**
  String get validationInviteMembersRequired;

  /// No description provided for @validationPrizeContentRequired.
  ///
  /// In ja, this message translates to:
  /// **'賞品内容を入力してください'**
  String get validationPrizeContentRequired;

  /// No description provided for @validationManagerRequiredForPrize.
  ///
  /// In ja, this message translates to:
  /// **'賞品設定時は運営者を追加してください'**
  String get validationManagerRequiredForPrize;

  /// No description provided for @validationStreamingUrlRequired.
  ///
  /// In ja, this message translates to:
  /// **'配信URLを入力してください'**
  String get validationStreamingUrlRequired;

  /// No description provided for @atLeastOneStreamingUrlRequired.
  ///
  /// In ja, this message translates to:
  /// **'最低1つの配信URLを入力してください'**
  String get atLeastOneStreamingUrlRequired;

  /// No description provided for @cautionRequired.
  ///
  /// In ja, this message translates to:
  /// **'注意が必要です'**
  String get cautionRequired;

  /// No description provided for @eventCancellationDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント中止確認'**
  String get eventCancellationDialogTitle;

  /// No description provided for @eventCancellationImportantNotice.
  ///
  /// In ja, this message translates to:
  /// **'重要な注意事項'**
  String get eventCancellationImportantNotice;

  /// No description provided for @eventCancellationDescription.
  ///
  /// In ja, this message translates to:
  /// **'イベントを中止すると以下の処理が実行されます：'**
  String get eventCancellationDescription;

  /// No description provided for @eventCancellationReasonRequired.
  ///
  /// In ja, this message translates to:
  /// **'中止理由（必須）'**
  String get eventCancellationReasonRequired;

  /// No description provided for @eventCancellationReasonOrganizerConvenience.
  ///
  /// In ja, this message translates to:
  /// **'主催者の都合による中止'**
  String get eventCancellationReasonOrganizerConvenience;

  /// No description provided for @eventCancellationReasonLackOfParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者不足による中止'**
  String get eventCancellationReasonLackOfParticipants;

  /// No description provided for @eventCancellationReasonGameMaintenance.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム側のメンテナンス・障害による中止'**
  String get eventCancellationReasonGameMaintenance;

  /// No description provided for @eventCancellationReasonEmergency.
  ///
  /// In ja, this message translates to:
  /// **'緊急事態による中止'**
  String get eventCancellationReasonEmergency;

  /// No description provided for @eventCancellationReasonOther.
  ///
  /// In ja, this message translates to:
  /// **'その他の理由（詳細は下記に記載）'**
  String get eventCancellationReasonOther;

  /// No description provided for @eventCancellationDetailLabel.
  ///
  /// In ja, this message translates to:
  /// **'詳細・補足説明（任意）'**
  String get eventCancellationDetailLabel;

  /// No description provided for @eventCancellationDetailHint.
  ///
  /// In ja, this message translates to:
  /// **'参加者へのメッセージや詳細な説明を入力してください...'**
  String get eventCancellationDetailHint;

  /// No description provided for @eventCancellationProcessing.
  ///
  /// In ja, this message translates to:
  /// **'中止処理中...'**
  String get eventCancellationProcessing;

  /// No description provided for @eventCancellationConfirmButton.
  ///
  /// In ja, this message translates to:
  /// **'イベントを中止する'**
  String get eventCancellationConfirmButton;

  /// No description provided for @eventCancellationSuccessMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベントを中止しました。関係者に通知を送信しています。'**
  String get eventCancellationSuccessMessage;

  /// No description provided for @eventCancellationFailedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント中止処理に失敗しました。再度お試しください。'**
  String get eventCancellationFailedMessage;

  /// No description provided for @adminMemoOnlyAdminVisible.
  ///
  /// In ja, this message translates to:
  /// **'管理者のみ閲覧・編集可能'**
  String get adminMemoOnlyAdminVisible;

  /// No description provided for @adminMemoContentLabel.
  ///
  /// In ja, this message translates to:
  /// **'メモ内容'**
  String get adminMemoContentLabel;

  /// No description provided for @adminMemoHint.
  ///
  /// In ja, this message translates to:
  /// **'管理上の注意点やメモを入力してください'**
  String get adminMemoHint;

  /// No description provided for @adminMemoSaved.
  ///
  /// In ja, this message translates to:
  /// **'メモを保存しました'**
  String get adminMemoSaved;

  /// No description provided for @adminMemoSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'メモの保存に失敗しました'**
  String get adminMemoSaveFailed;

  /// No description provided for @adminMemoAdd.
  ///
  /// In ja, this message translates to:
  /// **'管理者メモを追加'**
  String get adminMemoAdd;

  /// No description provided for @participantProfileLabel.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get participantProfileLabel;

  /// No description provided for @voiceChatAvailable.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット対応'**
  String get voiceChatAvailable;

  /// No description provided for @voiceChatNotUsed.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット不使用'**
  String get voiceChatNotUsed;

  /// No description provided for @violationHistoryLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反履歴'**
  String get violationHistoryLabel;

  /// No description provided for @violationRiskNone.
  ///
  /// In ja, this message translates to:
  /// **'リスクなし'**
  String get violationRiskNone;

  /// No description provided for @violationRiskLow.
  ///
  /// In ja, this message translates to:
  /// **'低リスク'**
  String get violationRiskLow;

  /// No description provided for @violationRiskMedium.
  ///
  /// In ja, this message translates to:
  /// **'中リスク'**
  String get violationRiskMedium;

  /// No description provided for @violationRiskHigh.
  ///
  /// In ja, this message translates to:
  /// **'高リスク'**
  String get violationRiskHigh;

  /// No description provided for @violationStatTotal.
  ///
  /// In ja, this message translates to:
  /// **'合計'**
  String get violationStatTotal;

  /// No description provided for @violationStatResolved.
  ///
  /// In ja, this message translates to:
  /// **'処理済み'**
  String get violationStatResolved;

  /// No description provided for @violationStatPending.
  ///
  /// In ja, this message translates to:
  /// **'未処理'**
  String get violationStatPending;

  /// No description provided for @participationStatusPending.
  ///
  /// In ja, this message translates to:
  /// **'承認待ち'**
  String get participationStatusPending;

  /// No description provided for @participationStatusWaitlisted.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ち'**
  String get participationStatusWaitlisted;

  /// No description provided for @participationStatusApproved.
  ///
  /// In ja, this message translates to:
  /// **'承認済み'**
  String get participationStatusApproved;

  /// No description provided for @participationStatusRejected.
  ///
  /// In ja, this message translates to:
  /// **'拒否'**
  String get participationStatusRejected;

  /// No description provided for @participationStatusCancelled.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル済み'**
  String get participationStatusCancelled;

  /// No description provided for @languageSettingLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント言語'**
  String get languageSettingLabel;

  /// No description provided for @languageOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get languageOther;

  /// No description provided for @notificationEventVisibilityChangedTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント公開設定変更'**
  String get notificationEventVisibilityChangedTitle;

  /// No description provided for @notificationEventApprovedTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加申請が承認されました'**
  String get notificationEventApprovedTitle;

  /// No description provided for @notificationEventRejectedTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加申請が拒否されました'**
  String get notificationEventRejectedTitle;

  /// No description provided for @notificationEventApplicationTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント申込みがありました'**
  String get notificationEventApplicationTitle;

  /// No description provided for @notificationViolationReportedToViolatedTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベントでの違反報告'**
  String get notificationViolationReportedToViolatedTitle;

  /// No description provided for @notificationViolationReportedToOrganizerTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反報告の受信'**
  String get notificationViolationReportedToOrganizerTitle;

  /// No description provided for @notificationViolationProcessedResolvedTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反報告の処理完了'**
  String get notificationViolationProcessedResolvedTitle;

  /// No description provided for @notificationViolationProcessedDismissedTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反報告の却下'**
  String get notificationViolationProcessedDismissedTitle;

  /// No description provided for @notificationAppealSubmittedTitle.
  ///
  /// In ja, this message translates to:
  /// **'異議申立の受信'**
  String get notificationAppealSubmittedTitle;

  /// No description provided for @notificationAppealApprovedTitle.
  ///
  /// In ja, this message translates to:
  /// **'異議申立が承認されました'**
  String get notificationAppealApprovedTitle;

  /// No description provided for @notificationAppealRejectedTitle.
  ///
  /// In ja, this message translates to:
  /// **'異議申立が却下されました'**
  String get notificationAppealRejectedTitle;

  /// No description provided for @notificationViolationDeletedToViolatedTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反記録が削除されました'**
  String get notificationViolationDeletedToViolatedTitle;

  /// No description provided for @notificationViolationDeletedToReporterTitle.
  ///
  /// In ja, this message translates to:
  /// **'報告した違反記録が削除されました'**
  String get notificationViolationDeletedToReporterTitle;

  /// No description provided for @notificationViolationDismissedToViolatedTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反記録が却下されました'**
  String get notificationViolationDismissedToViolatedTitle;

  /// No description provided for @notificationEventCancellationTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント中止のお知らせ'**
  String get notificationEventCancellationTitle;

  /// No description provided for @notificationEventCancellationManagerTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント中止処理完了'**
  String get notificationEventCancellationManagerTitle;

  /// No description provided for @notificationEventReminderTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベントリマインダー'**
  String get notificationEventReminderTitle;

  /// No description provided for @notificationEventReminderTimeSoon.
  ///
  /// In ja, this message translates to:
  /// **'まもなく'**
  String get notificationEventReminderTimeSoon;

  /// No description provided for @notificationEventUpdateImportantTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント内容の重要な変更'**
  String get notificationEventUpdateImportantTitle;

  /// No description provided for @notificationEventUpdateTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント内容が更新されました'**
  String get notificationEventUpdateTitle;

  /// No description provided for @eventChangeSummaryNoChanges.
  ///
  /// In ja, this message translates to:
  /// **'変更はありません'**
  String get eventChangeSummaryNoChanges;

  /// No description provided for @eventChangeTypeEventDate.
  ///
  /// In ja, this message translates to:
  /// **'開催日時'**
  String get eventChangeTypeEventDate;

  /// No description provided for @eventChangeTypeRegistrationDeadline.
  ///
  /// In ja, this message translates to:
  /// **'申込み締切'**
  String get eventChangeTypeRegistrationDeadline;

  /// No description provided for @eventChangeTypeMaxParticipants.
  ///
  /// In ja, this message translates to:
  /// **'最大参加者数'**
  String get eventChangeTypeMaxParticipants;

  /// No description provided for @eventChangeTypeHasParticipationFee.
  ///
  /// In ja, this message translates to:
  /// **'参加費'**
  String get eventChangeTypeHasParticipationFee;

  /// No description provided for @eventChangeTypeParticipationFeeText.
  ///
  /// In ja, this message translates to:
  /// **'参加費詳細'**
  String get eventChangeTypeParticipationFeeText;

  /// No description provided for @eventChangeTypeRules.
  ///
  /// In ja, this message translates to:
  /// **'ルール'**
  String get eventChangeTypeRules;

  /// No description provided for @eventChangeTypeEventTags.
  ///
  /// In ja, this message translates to:
  /// **'イベントタグ'**
  String get eventChangeTypeEventTags;

  /// No description provided for @eventChangeTypeContactInfo.
  ///
  /// In ja, this message translates to:
  /// **'連絡先'**
  String get eventChangeTypeContactInfo;

  /// No description provided for @eventChangeTypeVisibility.
  ///
  /// In ja, this message translates to:
  /// **'公開設定'**
  String get eventChangeTypeVisibility;

  /// No description provided for @eventChangeTypeEventPassword.
  ///
  /// In ja, this message translates to:
  /// **'イベントパスワード'**
  String get eventChangeTypeEventPassword;

  /// No description provided for @eventChangeTypePlatforms.
  ///
  /// In ja, this message translates to:
  /// **'対応プラットフォーム'**
  String get eventChangeTypePlatforms;

  /// No description provided for @eventChangeTypeGameId.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム'**
  String get eventChangeTypeGameId;

  /// No description provided for @eventChangeTypeStatus.
  ///
  /// In ja, this message translates to:
  /// **'イベントステータス'**
  String get eventChangeTypeStatus;

  /// No description provided for @eventChangeTypeName.
  ///
  /// In ja, this message translates to:
  /// **'イベント名'**
  String get eventChangeTypeName;

  /// No description provided for @eventChangeTypeSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'サブタイトル'**
  String get eventChangeTypeSubtitle;

  /// No description provided for @eventChangeTypeDescription.
  ///
  /// In ja, this message translates to:
  /// **'説明'**
  String get eventChangeTypeDescription;

  /// No description provided for @eventChangeTypeAdditionalInfo.
  ///
  /// In ja, this message translates to:
  /// **'追加情報'**
  String get eventChangeTypeAdditionalInfo;

  /// No description provided for @eventChangeTypeHasStreaming.
  ///
  /// In ja, this message translates to:
  /// **'配信'**
  String get eventChangeTypeHasStreaming;

  /// No description provided for @eventChangeTypeStreamingUrls.
  ///
  /// In ja, this message translates to:
  /// **'配信URL'**
  String get eventChangeTypeStreamingUrls;

  /// No description provided for @eventChangeTypePolicy.
  ///
  /// In ja, this message translates to:
  /// **'ポリシー'**
  String get eventChangeTypePolicy;

  /// No description provided for @eventChangeTypeManagerIds.
  ///
  /// In ja, this message translates to:
  /// **'共同編集者'**
  String get eventChangeTypeManagerIds;

  /// No description provided for @eventChangeTypeImageUrl.
  ///
  /// In ja, this message translates to:
  /// **'イベント画像'**
  String get eventChangeTypeImageUrl;

  /// No description provided for @eventChangeTypeLanguage.
  ///
  /// In ja, this message translates to:
  /// **'言語設定'**
  String get eventChangeTypeLanguage;

  /// No description provided for @eventChangeTypeBlockedUserIds.
  ///
  /// In ja, this message translates to:
  /// **'ブロックユーザー'**
  String get eventChangeTypeBlockedUserIds;

  /// No description provided for @eventChangeTypeSponsorIds.
  ///
  /// In ja, this message translates to:
  /// **'スポンサー'**
  String get eventChangeTypeSponsorIds;

  /// No description provided for @eventChangeTypeHasPrize.
  ///
  /// In ja, this message translates to:
  /// **'賞品'**
  String get eventChangeTypeHasPrize;

  /// No description provided for @eventChangeTypePrizeContent.
  ///
  /// In ja, this message translates to:
  /// **'賞品内容'**
  String get eventChangeTypePrizeContent;

  /// No description provided for @eventChangeTypeParticipationFeeSupplement.
  ///
  /// In ja, this message translates to:
  /// **'参加費補足'**
  String get eventChangeTypeParticipationFeeSupplement;

  /// No description provided for @eventChangeTypeGameName.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム名'**
  String get eventChangeTypeGameName;

  /// No description provided for @eventChangeNotSet.
  ///
  /// In ja, this message translates to:
  /// **'（未設定）'**
  String get eventChangeNotSet;

  /// No description provided for @eventChangeYes.
  ///
  /// In ja, this message translates to:
  /// **'あり'**
  String get eventChangeYes;

  /// No description provided for @eventChangeNo.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get eventChangeNo;

  /// No description provided for @listSeparator.
  ///
  /// In ja, this message translates to:
  /// **'、'**
  String get listSeparator;

  /// No description provided for @notificationNewFollowerTitle.
  ///
  /// In ja, this message translates to:
  /// **'新しいフォロワー'**
  String get notificationNewFollowerTitle;

  /// No description provided for @notificationEventDraftRevertedTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加取り消し'**
  String get notificationEventDraftRevertedTitle;

  /// No description provided for @notificationEventInviteTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベントに招待されました'**
  String get notificationEventInviteTitle;

  /// No description provided for @notificationEventWaitlistTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント満員のお知らせ'**
  String get notificationEventWaitlistTitle;

  /// No description provided for @notificationEventWaitlistRegisteredTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント満員・キャンセル待ち登録完了'**
  String get notificationEventWaitlistRegisteredTitle;

  /// No description provided for @notificationEventFullTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント満員'**
  String get notificationEventFullTitle;

  /// No description provided for @notificationEventCapacityWarningTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント定員間近'**
  String get notificationEventCapacityWarningTitle;

  /// No description provided for @notificationEventCapacityVacancyTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント空き枠発生'**
  String get notificationEventCapacityVacancyTitle;

  /// No description provided for @notificationParticipantCancelledTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者キャンセル'**
  String get notificationParticipantCancelledTitle;

  /// No description provided for @notificationMatchReportTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合結果報告'**
  String get notificationMatchReportTitle;

  /// No description provided for @notificationMatchReportMessage.
  ///
  /// In ja, this message translates to:
  /// **'試合結果が報告されました。'**
  String get notificationMatchReportMessage;

  /// No description provided for @notificationMatchReportResponseTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合結果報告への回答'**
  String get notificationMatchReportResponseTitle;

  /// No description provided for @notificationMatchReportResponseMessage.
  ///
  /// In ja, this message translates to:
  /// **'試合結果報告への回答がありました。'**
  String get notificationMatchReportResponseMessage;

  /// No description provided for @violationReportDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反報告'**
  String get violationReportDialogTitle;

  /// No description provided for @violationReportTargetLabel.
  ///
  /// In ja, this message translates to:
  /// **'報告対象'**
  String get violationReportTargetLabel;

  /// No description provided for @violationReportTypeLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反の種類'**
  String get violationReportTypeLabel;

  /// No description provided for @violationReportSeverityLabel.
  ///
  /// In ja, this message translates to:
  /// **'重要度'**
  String get violationReportSeverityLabel;

  /// No description provided for @violationReportDescriptionLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反内容の詳細'**
  String get violationReportDescriptionLabel;

  /// No description provided for @violationReportDescriptionHint.
  ///
  /// In ja, this message translates to:
  /// **'違反の具体的な内容を記載してください'**
  String get violationReportDescriptionHint;

  /// No description provided for @violationReportDescriptionRequired.
  ///
  /// In ja, this message translates to:
  /// **'違反内容を入力してください'**
  String get violationReportDescriptionRequired;

  /// No description provided for @violationReportDescriptionMinLength.
  ///
  /// In ja, this message translates to:
  /// **'10文字以上で詳細を記載してください'**
  String get violationReportDescriptionMinLength;

  /// No description provided for @violationReportNotesLabel.
  ///
  /// In ja, this message translates to:
  /// **'メモ（任意）'**
  String get violationReportNotesLabel;

  /// No description provided for @violationReportNotesHint.
  ///
  /// In ja, this message translates to:
  /// **'追加情報があれば記載してください'**
  String get violationReportNotesHint;

  /// No description provided for @violationReportSubmitButton.
  ///
  /// In ja, this message translates to:
  /// **'報告する'**
  String get violationReportSubmitButton;

  /// No description provided for @violationReportSuccessMessage.
  ///
  /// In ja, this message translates to:
  /// **'違反報告を送信しました'**
  String get violationReportSuccessMessage;

  /// No description provided for @violationReportUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報が取得できません'**
  String get violationReportUserNotFound;

  /// No description provided for @violationTypeHarassment.
  ///
  /// In ja, this message translates to:
  /// **'ハラスメント'**
  String get violationTypeHarassment;

  /// No description provided for @violationTypeCheating.
  ///
  /// In ja, this message translates to:
  /// **'チート・不正行為'**
  String get violationTypeCheating;

  /// No description provided for @violationTypeSpam.
  ///
  /// In ja, this message translates to:
  /// **'スパム・迷惑行為'**
  String get violationTypeSpam;

  /// No description provided for @violationTypeAbusiveLanguage.
  ///
  /// In ja, this message translates to:
  /// **'暴言・不適切な発言'**
  String get violationTypeAbusiveLanguage;

  /// No description provided for @violationTypeNoShow.
  ///
  /// In ja, this message translates to:
  /// **'無断欠席'**
  String get violationTypeNoShow;

  /// No description provided for @violationTypeDisruptiveBehavior.
  ///
  /// In ja, this message translates to:
  /// **'妨害行為'**
  String get violationTypeDisruptiveBehavior;

  /// No description provided for @violationTypeRuleViolation.
  ///
  /// In ja, this message translates to:
  /// **'ルール違反'**
  String get violationTypeRuleViolation;

  /// No description provided for @violationTypeOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get violationTypeOther;

  /// No description provided for @violationSeverityMinor.
  ///
  /// In ja, this message translates to:
  /// **'軽微'**
  String get violationSeverityMinor;

  /// No description provided for @violationSeverityModerate.
  ///
  /// In ja, this message translates to:
  /// **'中程度'**
  String get violationSeverityModerate;

  /// No description provided for @violationSeveritySevere.
  ///
  /// In ja, this message translates to:
  /// **'重大'**
  String get violationSeveritySevere;

  /// No description provided for @groupMemoSaved.
  ///
  /// In ja, this message translates to:
  /// **'グループメモを保存しました'**
  String get groupMemoSaved;

  /// No description provided for @groupMemoSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'グループメモの保存に失敗しました'**
  String get groupMemoSaveFailed;

  /// No description provided for @groupMemoAdminOnly.
  ///
  /// In ja, this message translates to:
  /// **'管理者のみ閲覧・編集可能'**
  String get groupMemoAdminOnly;

  /// No description provided for @groupMemoLabel.
  ///
  /// In ja, this message translates to:
  /// **'グループメモ'**
  String get groupMemoLabel;

  /// No description provided for @groupMemoHint.
  ///
  /// In ja, this message translates to:
  /// **'グループ管理上の注意点やメモを入力してください'**
  String get groupMemoHint;

  /// No description provided for @groupMemoAdd.
  ///
  /// In ja, this message translates to:
  /// **'グループメモを追加'**
  String get groupMemoAdd;

  /// No description provided for @accountWithdrawalTitle.
  ///
  /// In ja, this message translates to:
  /// **'アカウント退会'**
  String get accountWithdrawalTitle;

  /// No description provided for @accountWithdrawalCancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get accountWithdrawalCancel;

  /// No description provided for @accountWithdrawalConfirmButton.
  ///
  /// In ja, this message translates to:
  /// **'退会する'**
  String get accountWithdrawalConfirmButton;

  /// No description provided for @accountWithdrawalImportantNotice.
  ///
  /// In ja, this message translates to:
  /// **'重要な注意事項'**
  String get accountWithdrawalImportantNotice;

  /// No description provided for @accountWithdrawalDataDeletionTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除されるデータ'**
  String get accountWithdrawalDataDeletionTitle;

  /// No description provided for @accountWithdrawalDataItem1.
  ///
  /// In ja, this message translates to:
  /// **'アカウント情報（ユーザー名、プロフィール画像など）'**
  String get accountWithdrawalDataItem1;

  /// No description provided for @accountWithdrawalDataItem2.
  ///
  /// In ja, this message translates to:
  /// **'作成したイベント'**
  String get accountWithdrawalDataItem2;

  /// No description provided for @accountWithdrawalDataItem3.
  ///
  /// In ja, this message translates to:
  /// **'参加申請データ'**
  String get accountWithdrawalDataItem3;

  /// No description provided for @accountWithdrawalDataItem4.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィール情報'**
  String get accountWithdrawalDataItem4;

  /// No description provided for @accountWithdrawalDataItem5.
  ///
  /// In ja, this message translates to:
  /// **'その他の個人データ'**
  String get accountWithdrawalDataItem5;

  /// No description provided for @accountWithdrawalHistoryNote.
  ///
  /// In ja, this message translates to:
  /// **'イベント履歴等では「退会したユーザー」として表示されます'**
  String get accountWithdrawalHistoryNote;

  /// No description provided for @accountWithdrawalConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get accountWithdrawalConfirmTitle;

  /// No description provided for @accountWithdrawalCheckboxLabel.
  ///
  /// In ja, this message translates to:
  /// **'上記の内容を理解し、アカウント退会に同意します'**
  String get accountWithdrawalCheckboxLabel;

  /// No description provided for @accountWithdrawalTextInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'「退会する」と入力してください'**
  String get accountWithdrawalTextInputLabel;

  /// No description provided for @accountWithdrawalTextInputHint.
  ///
  /// In ja, this message translates to:
  /// **'退会する'**
  String get accountWithdrawalTextInputHint;

  /// No description provided for @accountWithdrawalUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりません'**
  String get accountWithdrawalUserNotFound;

  /// No description provided for @accountWithdrawalSuccess.
  ///
  /// In ja, this message translates to:
  /// **'アカウント退会が完了しました'**
  String get accountWithdrawalSuccess;

  /// No description provided for @accountWithdrawalReauthTitle.
  ///
  /// In ja, this message translates to:
  /// **'セキュリティ確認が必要です'**
  String get accountWithdrawalReauthTitle;

  /// No description provided for @accountWithdrawalReauthLogout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get accountWithdrawalReauthLogout;

  /// No description provided for @withdrawnUserDisplayName.
  ///
  /// In ja, this message translates to:
  /// **'退会したユーザー'**
  String get withdrawnUserDisplayName;

  /// No description provided for @authDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'アカウントでサインイン'**
  String get authDialogTitle;

  /// No description provided for @authDialogDescription.
  ///
  /// In ja, this message translates to:
  /// **'アカウントでサインインすると、データの同期やバックアップが利用できます。'**
  String get authDialogDescription;

  /// No description provided for @authTermsAnd.
  ///
  /// In ja, this message translates to:
  /// **'と'**
  String get authTermsAnd;

  /// No description provided for @authTermsAgreementSuffix.
  ///
  /// In ja, this message translates to:
  /// **'に同意します'**
  String get authTermsAgreementSuffix;

  /// No description provided for @signInWithGoogle.
  ///
  /// In ja, this message translates to:
  /// **'Googleでサインイン'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In ja, this message translates to:
  /// **'Apple IDでサインイン'**
  String get signInWithApple;

  /// No description provided for @signingIn.
  ///
  /// In ja, this message translates to:
  /// **'サインイン中...'**
  String get signingIn;

  /// No description provided for @skipAndContinue.
  ///
  /// In ja, this message translates to:
  /// **'スキップして続行'**
  String get skipAndContinue;

  /// No description provided for @signInFailedGoogle.
  ///
  /// In ja, this message translates to:
  /// **'Googleサインインに失敗しました'**
  String get signInFailedGoogle;

  /// No description provided for @signInErrorGoogle.
  ///
  /// In ja, this message translates to:
  /// **'Googleサインインエラーが発生しました'**
  String get signInErrorGoogle;

  /// No description provided for @signInFailedApple.
  ///
  /// In ja, this message translates to:
  /// **'Apple IDサインインに失敗しました'**
  String get signInFailedApple;

  /// No description provided for @signInErrorApple.
  ///
  /// In ja, this message translates to:
  /// **'Apple IDサインインエラーが発生しました'**
  String get signInErrorApple;

  /// No description provided for @failedToOpenTerms.
  ///
  /// In ja, this message translates to:
  /// **'利用規約のページを開けませんでした。'**
  String get failedToOpenTerms;

  /// No description provided for @errorOpeningTerms.
  ///
  /// In ja, this message translates to:
  /// **'利用規約のページを開く際にエラーが発生しました。'**
  String get errorOpeningTerms;

  /// No description provided for @failedToOpenPrivacy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシーのページを開けませんでした。'**
  String get failedToOpenPrivacy;

  /// No description provided for @errorOpeningPrivacy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシーのページを開く際にエラーが発生しました。'**
  String get errorOpeningPrivacy;

  /// No description provided for @welcomeBack.
  ///
  /// In ja, this message translates to:
  /// **'おかえりなさい！'**
  String get welcomeBack;

  /// No description provided for @signInCompleted.
  ///
  /// In ja, this message translates to:
  /// **'サインインが完了しました。\\nアプリを引き続きお楽しみください。'**
  String get signInCompleted;

  /// No description provided for @violatorSelectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反者選択'**
  String get violatorSelectionTitle;

  /// No description provided for @violatorSelectionDescription.
  ///
  /// In ja, this message translates to:
  /// **'違反を報告する参加者を選択してください'**
  String get violatorSelectionDescription;

  /// No description provided for @searchParticipant.
  ///
  /// In ja, this message translates to:
  /// **'参加者を検索'**
  String get searchParticipant;

  /// No description provided for @searchByNameOrId.
  ///
  /// In ja, this message translates to:
  /// **'名前、ユーザーIDで検索'**
  String get searchByNameOrId;

  /// No description provided for @noApprovedParticipantsShort.
  ///
  /// In ja, this message translates to:
  /// **'承認済み参加者がいません'**
  String get noApprovedParticipantsShort;

  /// No description provided for @noSearchResultsShort.
  ///
  /// In ja, this message translates to:
  /// **'検索結果がありません'**
  String get noSearchResultsShort;

  /// No description provided for @reportButton.
  ///
  /// In ja, this message translates to:
  /// **'報告'**
  String get reportButton;

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In ja, this message translates to:
  /// **'別のキーワードで検索してください'**
  String get tryDifferentKeyword;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredForParticipation.
  ///
  /// In ja, this message translates to:
  /// **'参加申し込みにはログインが必要です。'**
  String get loginRequiredForParticipation;

  /// No description provided for @closeButtonText.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get closeButtonText;

  /// No description provided for @loginButtonText.
  ///
  /// In ja, this message translates to:
  /// **'ログイン'**
  String get loginButtonText;

  /// No description provided for @errorTitle.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get errorTitle;

  /// No description provided for @participationApplicationTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加申し込み'**
  String get participationApplicationTitle;

  /// No description provided for @privateEventTitle.
  ///
  /// In ja, this message translates to:
  /// **'プライベートイベント'**
  String get privateEventTitle;

  /// No description provided for @inviteOnlyEventTitle.
  ///
  /// In ja, this message translates to:
  /// **'招待制イベント'**
  String get inviteOnlyEventTitle;

  /// No description provided for @eventTargetGameLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント対象ゲーム'**
  String get eventTargetGameLabel;

  /// No description provided for @checkingProfileTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを確認中'**
  String get checkingProfileTitle;

  /// No description provided for @checkingGameProfileText.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールを確認しています...'**
  String get checkingGameProfileText;

  /// No description provided for @profileReadyTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール設定完了'**
  String get profileReadyTitle;

  /// No description provided for @gameUsernameSetText.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ユーザー名が設定されています。'**
  String get gameUsernameSetText;

  /// No description provided for @profileSetupRequiredTitle.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール設定が必要'**
  String get profileSetupRequiredTitle;

  /// No description provided for @createProfileForGameText.
  ///
  /// In ja, this message translates to:
  /// **'このゲームのプロフィールを作成してください。'**
  String get createProfileForGameText;

  /// No description provided for @registerFavoriteAndCreateProfileButtonText.
  ///
  /// In ja, this message translates to:
  /// **'お気に入り登録してプロフィール作成'**
  String get registerFavoriteAndCreateProfileButtonText;

  /// No description provided for @createProfileButtonText.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール作成'**
  String get createProfileButtonText;

  /// No description provided for @usernameSetupRequiredTitle.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名設定が必要'**
  String get usernameSetupRequiredTitle;

  /// No description provided for @setGameUsernameInProfileText.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールにゲーム内ユーザー名を設定してください。'**
  String get setGameUsernameInProfileText;

  /// No description provided for @editProfileButtonText.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを編集'**
  String get editProfileButtonText;

  /// No description provided for @gameUsernameLabel.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ユーザー名'**
  String get gameUsernameLabel;

  /// No description provided for @userIdLabelText.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーID'**
  String get userIdLabelText;

  /// No description provided for @participationFeeLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加費'**
  String get participationFeeLabel;

  /// No description provided for @contactOrganizerForDetailsText.
  ///
  /// In ja, this message translates to:
  /// **'詳細は主催者にお問い合わせください'**
  String get contactOrganizerForDetailsText;

  /// No description provided for @enterPasswordHintText.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力してください'**
  String get enterPasswordHintText;

  /// No description provided for @messageToOrganizerLabel.
  ///
  /// In ja, this message translates to:
  /// **'主催者へのメッセージ（任意）'**
  String get messageToOrganizerLabel;

  /// No description provided for @messageToOrganizerHintText.
  ///
  /// In ja, this message translates to:
  /// **'主催者へのメッセージを入力（任意）'**
  String get messageToOrganizerHintText;

  /// No description provided for @cancelButtonText.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancelButtonText;

  /// No description provided for @checkingStatusText.
  ///
  /// In ja, this message translates to:
  /// **'確認中...'**
  String get checkingStatusText;

  /// No description provided for @setupProfileButtonText.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールを設定する'**
  String get setupProfileButtonText;

  /// No description provided for @setupUsernameButtonText.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名を設定する'**
  String get setupUsernameButtonText;

  /// No description provided for @cannotApplyButtonText.
  ///
  /// In ja, this message translates to:
  /// **'申し込めません'**
  String get cannotApplyButtonText;

  /// No description provided for @applyButtonText.
  ///
  /// In ja, this message translates to:
  /// **'申し込む'**
  String get applyButtonText;

  /// No description provided for @joinButtonText.
  ///
  /// In ja, this message translates to:
  /// **'参加する'**
  String get joinButtonText;

  /// No description provided for @applicationCompleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'申し込み完了'**
  String get applicationCompleteTitle;

  /// No description provided for @participationConfirmedText.
  ///
  /// In ja, this message translates to:
  /// **'イベントへの参加が確定しました！'**
  String get participationConfirmedText;

  /// No description provided for @applicationReceivedText.
  ///
  /// In ja, this message translates to:
  /// **'申し込みを受け付けました。主催者による承認をお待ちください。'**
  String get applicationReceivedText;

  /// No description provided for @okButtonText.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get okButtonText;

  /// No description provided for @unexpectedErrorText.
  ///
  /// In ja, this message translates to:
  /// **'予期しないエラーが発生しました。しばらく経ってからお試しください。'**
  String get unexpectedErrorText;

  /// No description provided for @profileCreationErrorText.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール作成中にエラーが発生しました。'**
  String get profileCreationErrorText;

  /// No description provided for @gameInfoNotFoundText.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム情報が取得できませんでした。'**
  String get gameInfoNotFoundText;

  /// No description provided for @gameFallbackText.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム'**
  String get gameFallbackText;

  /// No description provided for @participantCountLoadingText.
  ///
  /// In ja, this message translates to:
  /// **'参加者数を取得中...'**
  String get participantCountLoadingText;

  /// No description provided for @eventFullNoteText.
  ///
  /// In ja, this message translates to:
  /// **'※ このイベントは満員です'**
  String get eventFullNoteText;

  /// No description provided for @eventNotFoundErrorText.
  ///
  /// In ja, this message translates to:
  /// **'イベントが見つかりませんでした。'**
  String get eventNotFoundErrorText;

  /// No description provided for @cannotApplyToEventErrorText.
  ///
  /// In ja, this message translates to:
  /// **'このイベントには参加申し込みができません。'**
  String get cannotApplyToEventErrorText;

  /// No description provided for @alreadyAppliedErrorText.
  ///
  /// In ja, this message translates to:
  /// **'既にこのイベントに申し込み済みです。'**
  String get alreadyAppliedErrorText;

  /// No description provided for @incorrectPasswordErrorText.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが間違っています。'**
  String get incorrectPasswordErrorText;

  /// No description provided for @eventFullErrorText.
  ///
  /// In ja, this message translates to:
  /// **'このイベントは満員のため申し込みができません。'**
  String get eventFullErrorText;

  /// No description provided for @permissionDeniedErrorText.
  ///
  /// In ja, this message translates to:
  /// **'アクセス権限がありません。'**
  String get permissionDeniedErrorText;

  /// No description provided for @networkErrorText.
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラーが発生しました。'**
  String get networkErrorText;

  /// No description provided for @unknownErrorText.
  ///
  /// In ja, this message translates to:
  /// **'予期しないエラーが発生しました。'**
  String get unknownErrorText;

  /// No description provided for @applicationCompleteText.
  ///
  /// In ja, this message translates to:
  /// **'申し込みが完了しました。'**
  String get applicationCompleteText;

  /// No description provided for @removalDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者の除名'**
  String get removalDialogTitle;

  /// No description provided for @removalDialogDescription.
  ///
  /// In ja, this message translates to:
  /// **'この参加者をイベントから除名しますか？\\n除名理由を入力してください。'**
  String get removalDialogDescription;

  /// No description provided for @removalButtonText.
  ///
  /// In ja, this message translates to:
  /// **'除名'**
  String get removalButtonText;

  /// No description provided for @removalReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'除名理由を入力（任意）'**
  String get removalReasonHint;

  /// No description provided for @rejectionDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'参加申請の拒否'**
  String get rejectionDialogTitle;

  /// No description provided for @rejectionDialogDescription.
  ///
  /// In ja, this message translates to:
  /// **'この申請を拒否しますか？\\n拒否理由を入力してください。'**
  String get rejectionDialogDescription;

  /// No description provided for @rejectionButtonText.
  ///
  /// In ja, this message translates to:
  /// **'拒否'**
  String get rejectionButtonText;

  /// No description provided for @rejectionReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'拒否理由を入力（任意）'**
  String get rejectionReasonHint;

  /// No description provided for @reasonRequiredError.
  ///
  /// In ja, this message translates to:
  /// **'理由の入力は必須です'**
  String get reasonRequiredError;

  /// No description provided for @userSearchHint.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名またはユーザーIDで検索'**
  String get userSearchHint;

  /// No description provided for @enterUsernameOrId.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー名またはユーザーIDを入力してください'**
  String get enterUsernameOrId;

  /// No description provided for @searchingText.
  ///
  /// In ja, this message translates to:
  /// **'検索中...'**
  String get searchingText;

  /// No description provided for @mutualFollowLoadingError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報が取得できませんでした'**
  String get mutualFollowLoadingError;

  /// No description provided for @mutualFollowLoading.
  ///
  /// In ja, this message translates to:
  /// **'相互フォロー情報を取得中...'**
  String get mutualFollowLoading;

  /// No description provided for @retryText.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retryText;

  /// No description provided for @allMutualFollowsSelected.
  ///
  /// In ja, this message translates to:
  /// **'すべての相互フォローが選択済みです'**
  String get allMutualFollowsSelected;

  /// No description provided for @noSelectableMutualFollows.
  ///
  /// In ja, this message translates to:
  /// **'選択可能な相互フォローがありません'**
  String get noSelectableMutualFollows;

  /// No description provided for @selectText.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get selectText;

  /// No description provided for @adjustProfileImage.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール画像を調整'**
  String get adjustProfileImage;

  /// No description provided for @loadingImageText.
  ///
  /// In ja, this message translates to:
  /// **'画像を読み込んでいます...'**
  String get loadingImageText;

  /// No description provided for @confirmProfileImage.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール画像の確認'**
  String get confirmProfileImage;

  /// No description provided for @useThisImageConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この画像をプロフィール画像として使用しますか？'**
  String get useThisImageConfirm;

  /// No description provided for @useText.
  ///
  /// In ja, this message translates to:
  /// **'使用する'**
  String get useText;

  /// No description provided for @eventDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント詳細'**
  String get eventDetailTitle;

  /// No description provided for @notSetText.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get notSetText;

  /// No description provided for @gameLabel.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム'**
  String get gameLabel;

  /// No description provided for @eventPeriod.
  ///
  /// In ja, this message translates to:
  /// **'イベント期間'**
  String get eventPeriod;

  /// No description provided for @startLabel.
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get endLabel;

  /// No description provided for @endsTodayText.
  ///
  /// In ja, this message translates to:
  /// **'本日終了'**
  String get endsTodayText;

  /// No description provided for @startingSoonText.
  ///
  /// In ja, this message translates to:
  /// **'間もなく開始'**
  String get startingSoonText;

  /// No description provided for @statisticsLabel.
  ///
  /// In ja, this message translates to:
  /// **'統計情報'**
  String get statisticsLabel;

  /// No description provided for @prizesLabel.
  ///
  /// In ja, this message translates to:
  /// **'賞品'**
  String get prizesLabel;

  /// No description provided for @closeText.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get closeText;

  /// No description provided for @editText.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get editText;

  /// No description provided for @joinText.
  ///
  /// In ja, this message translates to:
  /// **'参加'**
  String get joinText;

  /// No description provided for @resultCheckText.
  ///
  /// In ja, this message translates to:
  /// **'結果確認'**
  String get resultCheckText;

  /// No description provided for @duplicateText.
  ///
  /// In ja, this message translates to:
  /// **'複製'**
  String get duplicateText;

  /// No description provided for @detailCheckText.
  ///
  /// In ja, this message translates to:
  /// **'詳細確認'**
  String get detailCheckText;

  /// No description provided for @selectFromPastEvents.
  ///
  /// In ja, this message translates to:
  /// **'過去のイベントから選択'**
  String get selectFromPastEvents;

  /// No description provided for @noCopyableEventsMessage.
  ///
  /// In ja, this message translates to:
  /// **'コピー可能なイベントがありません'**
  String get noCopyableEventsMessage;

  /// No description provided for @searchEventsPlaceholder.
  ///
  /// In ja, this message translates to:
  /// **'イベント名やゲーム名で検索...'**
  String get searchEventsPlaceholder;

  /// No description provided for @errorUnknown.
  ///
  /// In ja, this message translates to:
  /// **'不明なエラーが発生しました'**
  String get errorUnknown;

  /// No description provided for @errorNetwork.
  ///
  /// In ja, this message translates to:
  /// **'ネットワーク接続を確認してください'**
  String get errorNetwork;

  /// No description provided for @errorPermission.
  ///
  /// In ja, this message translates to:
  /// **'アクセス権限がありません'**
  String get errorPermission;

  /// No description provided for @errorTimeout.
  ///
  /// In ja, this message translates to:
  /// **'通信がタイムアウトしました。もう一度お試しください'**
  String get errorTimeout;

  /// No description provided for @errorUnexpected.
  ///
  /// In ja, this message translates to:
  /// **'予期しないエラーが発生しました。しばらく時間をおいてから再度お試しください'**
  String get errorUnexpected;

  /// No description provided for @errorResourceExhausted.
  ///
  /// In ja, this message translates to:
  /// **'サービスの利用上限に達しています。しばらく時間をおいてからお試しください'**
  String get errorResourceExhausted;

  /// No description provided for @errorDataInconsistency.
  ///
  /// In ja, this message translates to:
  /// **'データの整合性に問題があります。アプリを再起動してお試しください'**
  String get errorDataInconsistency;

  /// No description provided for @errorAborted.
  ///
  /// In ja, this message translates to:
  /// **'処理が中断されました。もう一度お試しください'**
  String get errorAborted;

  /// No description provided for @errorOutOfRange.
  ///
  /// In ja, this message translates to:
  /// **'入力値が範囲外です'**
  String get errorOutOfRange;

  /// No description provided for @errorNotImplemented.
  ///
  /// In ja, this message translates to:
  /// **'この機能は現在利用できません'**
  String get errorNotImplemented;

  /// No description provided for @errorInternal.
  ///
  /// In ja, this message translates to:
  /// **'サーバー内部エラーが発生しました'**
  String get errorInternal;

  /// No description provided for @errorDataLoss.
  ///
  /// In ja, this message translates to:
  /// **'データの破損が検出されました'**
  String get errorDataLoss;

  /// No description provided for @errorUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりません'**
  String get errorUserNotFound;

  /// No description provided for @errorWrongPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが正しくありません'**
  String get errorWrongPassword;

  /// No description provided for @errorUserDisabled.
  ///
  /// In ja, this message translates to:
  /// **'このユーザーアカウントは無効化されています'**
  String get errorUserDisabled;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In ja, this message translates to:
  /// **'リクエスト数が上限に達しました。しばらく時間をおいてからお試しください'**
  String get errorTooManyRequests;

  /// No description provided for @errorOperationNotAllowed.
  ///
  /// In ja, this message translates to:
  /// **'この認証方法は許可されていません'**
  String get errorOperationNotAllowed;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get errorInvalidEmail;

  /// No description provided for @errorEmailAlreadyInUse.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に使用されています'**
  String get errorEmailAlreadyInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが脆弱です。より強力なパスワードを設定してください'**
  String get errorWeakPassword;

  /// No description provided for @errorDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get errorDialogTitle;

  /// No description provided for @errorRetryHint.
  ///
  /// In ja, this message translates to:
  /// **'しばらく時間をおいてから再度お試しください。'**
  String get errorRetryHint;

  /// No description provided for @retryButtonText.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retryButtonText;

  /// No description provided for @paymentSummaryTitle.
  ///
  /// In ja, this message translates to:
  /// **'収支サマリー'**
  String get paymentSummaryTitle;

  /// No description provided for @totalParticipantsLabel.
  ///
  /// In ja, this message translates to:
  /// **'総参加者'**
  String get totalParticipantsLabel;

  /// No description provided for @paidLabel.
  ///
  /// In ja, this message translates to:
  /// **'支払済'**
  String get paidLabel;

  /// No description provided for @collectedAmountLabel.
  ///
  /// In ja, this message translates to:
  /// **'収集済金額'**
  String get collectedAmountLabel;

  /// No description provided for @pendingAmountLabel.
  ///
  /// In ja, this message translates to:
  /// **'未収金額'**
  String get pendingAmountLabel;

  /// No description provided for @tabAll.
  ///
  /// In ja, this message translates to:
  /// **'全て'**
  String get tabAll;

  /// No description provided for @tabUnpaid.
  ///
  /// In ja, this message translates to:
  /// **'未払い'**
  String get tabUnpaid;

  /// No description provided for @tabPendingConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'確認待ち'**
  String get tabPendingConfirmation;

  /// No description provided for @tabCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get tabCompleted;

  /// No description provided for @paymentDataLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'データの読み込みに失敗しました'**
  String get paymentDataLoadFailed;

  /// No description provided for @noPaymentRecords.
  ///
  /// In ja, this message translates to:
  /// **'支払い記録がありません'**
  String get noPaymentRecords;

  /// No description provided for @noUnpaidParticipants.
  ///
  /// In ja, this message translates to:
  /// **'未払いの参加者はいません'**
  String get noUnpaidParticipants;

  /// No description provided for @noPendingPayments.
  ///
  /// In ja, this message translates to:
  /// **'確認待ちの支払いはありません'**
  String get noPendingPayments;

  /// No description provided for @noCompletedPayments.
  ///
  /// In ja, this message translates to:
  /// **'完了した支払いはありません'**
  String get noCompletedPayments;

  /// No description provided for @noDisputedPayments.
  ///
  /// In ja, this message translates to:
  /// **'問題のある支払いはありません'**
  String get noDisputedPayments;

  /// No description provided for @participantNoteLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者からのメモ'**
  String get participantNoteLabel;

  /// No description provided for @evidenceExists.
  ///
  /// In ja, this message translates to:
  /// **'証跡あり'**
  String get evidenceExists;

  /// No description provided for @paymentStatusPending.
  ///
  /// In ja, this message translates to:
  /// **'未払い'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusSubmitted.
  ///
  /// In ja, this message translates to:
  /// **'確認待ち'**
  String get paymentStatusSubmitted;

  /// No description provided for @paymentStatusVerified.
  ///
  /// In ja, this message translates to:
  /// **'確認済み'**
  String get paymentStatusVerified;

  /// No description provided for @paymentStatusDisputed.
  ///
  /// In ja, this message translates to:
  /// **'問題あり'**
  String get paymentStatusDisputed;

  /// No description provided for @participantNoteDialogLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者からのメモ:'**
  String get participantNoteDialogLabel;

  /// No description provided for @paymentVerifiedNote.
  ///
  /// In ja, this message translates to:
  /// **'支払い確認済み'**
  String get paymentVerifiedNote;

  /// No description provided for @paymentEvidenceIssueNote.
  ///
  /// In ja, this message translates to:
  /// **'証跡に問題があります'**
  String get paymentEvidenceIssueNote;

  /// No description provided for @paymentApprovedMessage.
  ///
  /// In ja, this message translates to:
  /// **'支払いを承認しました'**
  String get paymentApprovedMessage;

  /// No description provided for @paymentRejectedMessage.
  ///
  /// In ja, this message translates to:
  /// **'支払いを差し戻しました'**
  String get paymentRejectedMessage;

  /// No description provided for @reloadButton.
  ///
  /// In ja, this message translates to:
  /// **'再読み込み'**
  String get reloadButton;

  /// No description provided for @filterNew.
  ///
  /// In ja, this message translates to:
  /// **'新規'**
  String get filterNew;

  /// No description provided for @filterReviewing.
  ///
  /// In ja, this message translates to:
  /// **'確認中'**
  String get filterReviewing;

  /// No description provided for @filterResolved.
  ///
  /// In ja, this message translates to:
  /// **'解決済み'**
  String get filterResolved;

  /// No description provided for @filterRejected.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get filterRejected;

  /// No description provided for @noReportsAll.
  ///
  /// In ja, this message translates to:
  /// **'報告がありません'**
  String get noReportsAll;

  /// No description provided for @noReportsFiltered.
  ///
  /// In ja, this message translates to:
  /// **'該当する報告がありません'**
  String get noReportsFiltered;

  /// No description provided for @matchInfoNotAvailable.
  ///
  /// In ja, this message translates to:
  /// **'試合情報なし'**
  String get matchInfoNotAvailable;

  /// No description provided for @unknownUser.
  ///
  /// In ja, this message translates to:
  /// **'不明'**
  String get unknownUser;

  /// No description provided for @violationEditDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反記録編集'**
  String get violationEditDialogTitle;

  /// No description provided for @reportTargetLabel.
  ///
  /// In ja, this message translates to:
  /// **'報告対象'**
  String get reportTargetLabel;

  /// No description provided for @loadingUserInfo.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報読み込み中...'**
  String get loadingUserInfo;

  /// No description provided for @violationDetailLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反内容の詳細 *'**
  String get violationDetailLabel;

  /// No description provided for @violationDetailHint.
  ///
  /// In ja, this message translates to:
  /// **'違反の具体的な内容を記載してください'**
  String get violationDetailHint;

  /// No description provided for @enterViolationContentError.
  ///
  /// In ja, this message translates to:
  /// **'違反内容を入力してください'**
  String get enterViolationContentError;

  /// No description provided for @memoOptionalLabel.
  ///
  /// In ja, this message translates to:
  /// **'メモ（任意）'**
  String get memoOptionalLabel;

  /// No description provided for @unchangeableInfoLabel.
  ///
  /// In ja, this message translates to:
  /// **'変更不可な情報'**
  String get unchangeableInfoLabel;

  /// No description provided for @updateButton.
  ///
  /// In ja, this message translates to:
  /// **'更新'**
  String get updateButton;

  /// No description provided for @violationRecordUpdatedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'違反記録を更新しました'**
  String get violationRecordUpdatedSuccess;

  /// No description provided for @historyPeriodAll.
  ///
  /// In ja, this message translates to:
  /// **'全期間'**
  String get historyPeriodAll;

  /// No description provided for @historyPeriodThisMonth.
  ///
  /// In ja, this message translates to:
  /// **'今月'**
  String get historyPeriodThisMonth;

  /// No description provided for @historyPeriodLastThreeMonths.
  ///
  /// In ja, this message translates to:
  /// **'過去3ヶ月'**
  String get historyPeriodLastThreeMonths;

  /// No description provided for @historyPeriodLastSixMonths.
  ///
  /// In ja, this message translates to:
  /// **'過去6ヶ月'**
  String get historyPeriodLastSixMonths;

  /// No description provided for @historyPeriodThisYear.
  ///
  /// In ja, this message translates to:
  /// **'今年'**
  String get historyPeriodThisYear;

  /// No description provided for @noParticipationHistory.
  ///
  /// In ja, this message translates to:
  /// **'参加履歴がありません'**
  String get noParticipationHistory;

  /// No description provided for @noMatchingHistory.
  ///
  /// In ja, this message translates to:
  /// **'条件に一致する履歴がありません'**
  String get noMatchingHistory;

  /// No description provided for @noPendingApplications.
  ///
  /// In ja, this message translates to:
  /// **'申し込み中のイベントはありません'**
  String get noPendingApplications;

  /// No description provided for @noPendingApproval.
  ///
  /// In ja, this message translates to:
  /// **'承認待ちの申し込みはありません'**
  String get noPendingApproval;

  /// No description provided for @noEventsThisPeriod.
  ///
  /// In ja, this message translates to:
  /// **'該当期間に参加したイベントはありません'**
  String get noEventsThisPeriod;

  /// No description provided for @userInfoNotAvailable.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報が取得できませんでした'**
  String get userInfoNotAvailable;

  /// No description provided for @noHostingEvents.
  ///
  /// In ja, this message translates to:
  /// **'運営中のイベントはありません'**
  String get noHostingEvents;

  /// No description provided for @eventNameLoading.
  ///
  /// In ja, this message translates to:
  /// **'イベント名を取得中...'**
  String get eventNameLoading;

  /// No description provided for @noDataAvailable.
  ///
  /// In ja, this message translates to:
  /// **'データがありません'**
  String get noDataAvailable;

  /// No description provided for @noEventsToParticipateThisMonth.
  ///
  /// In ja, this message translates to:
  /// **'今月参加するイベントはありません'**
  String get noEventsToParticipateThisMonth;

  /// No description provided for @gameProfileConfirmationTitle.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールの確認'**
  String get gameProfileConfirmationTitle;

  /// No description provided for @editButtonText.
  ///
  /// In ja, this message translates to:
  /// **'編集する'**
  String get editButtonText;

  /// No description provided for @applyWithThisContent.
  ///
  /// In ja, this message translates to:
  /// **'この内容で申請'**
  String get applyWithThisContent;

  /// No description provided for @gameUserIdLabel.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ユーザーID'**
  String get gameUserIdLabel;

  /// No description provided for @skillLevelLabel.
  ///
  /// In ja, this message translates to:
  /// **'スキルレベル'**
  String get skillLevelLabel;

  /// No description provided for @rankLevelLabel.
  ///
  /// In ja, this message translates to:
  /// **'ランク・レベル'**
  String get rankLevelLabel;

  /// No description provided for @playStyleLabel.
  ///
  /// In ja, this message translates to:
  /// **'プレイスタイル'**
  String get playStyleLabel;

  /// No description provided for @activityTimeLabel.
  ///
  /// In ja, this message translates to:
  /// **'活動時間'**
  String get activityTimeLabel;

  /// No description provided for @inGameVoiceChatLabel.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム内ボイスチャット'**
  String get inGameVoiceChatLabel;

  /// No description provided for @useVoiceChat.
  ///
  /// In ja, this message translates to:
  /// **'利用する'**
  String get useVoiceChat;

  /// No description provided for @notUseVoiceChat.
  ///
  /// In ja, this message translates to:
  /// **'利用しない'**
  String get notUseVoiceChat;

  /// No description provided for @voiceChatDetailsLabel.
  ///
  /// In ja, this message translates to:
  /// **'ボイスチャット詳細'**
  String get voiceChatDetailsLabel;

  /// No description provided for @achievementsLabel.
  ///
  /// In ja, this message translates to:
  /// **'実績・成果'**
  String get achievementsLabel;

  /// No description provided for @otherNotesLabel.
  ///
  /// In ja, this message translates to:
  /// **'その他メモ'**
  String get otherNotesLabel;

  /// No description provided for @appealProcessDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'異議申立処理'**
  String get appealProcessDialogTitle;

  /// No description provided for @violationRecordSectionLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反記録'**
  String get violationRecordSectionLabel;

  /// No description provided for @appealContentLabel.
  ///
  /// In ja, this message translates to:
  /// **'異議申立内容'**
  String get appealContentLabel;

  /// No description provided for @processingResultLabel.
  ///
  /// In ja, this message translates to:
  /// **'処理結果 *'**
  String get processingResultLabel;

  /// No description provided for @approveLabel.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get approveLabel;

  /// No description provided for @approveDescription.
  ///
  /// In ja, this message translates to:
  /// **'異議申立を認め、違反記録を取り消します'**
  String get approveDescription;

  /// No description provided for @rejectLabelDialog.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get rejectLabelDialog;

  /// No description provided for @rejectDescription.
  ///
  /// In ja, this message translates to:
  /// **'異議申立を却下し、違反記録を維持します'**
  String get rejectDescription;

  /// No description provided for @responseToAppellantLabel.
  ///
  /// In ja, this message translates to:
  /// **'申立者への回答 *'**
  String get responseToAppellantLabel;

  /// No description provided for @responseToAppellantHint.
  ///
  /// In ja, this message translates to:
  /// **'処理結果の理由や詳細を申立者に説明してください'**
  String get responseToAppellantHint;

  /// No description provided for @enterResponseError.
  ///
  /// In ja, this message translates to:
  /// **'申立者への回答を入力してください'**
  String get enterResponseError;

  /// No description provided for @userInfoNotRetrievable.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報が取得できません'**
  String get userInfoNotRetrievable;

  /// No description provided for @approveActionButton.
  ///
  /// In ja, this message translates to:
  /// **'承認する'**
  String get approveActionButton;

  /// No description provided for @rejectActionButton.
  ///
  /// In ja, this message translates to:
  /// **'却下する'**
  String get rejectActionButton;

  /// No description provided for @violationReportSubmitted.
  ///
  /// In ja, this message translates to:
  /// **'違反報告を送信しました。運営で確認いたします。'**
  String get violationReportSubmitted;

  /// No description provided for @closeKeyboardTooltip.
  ///
  /// In ja, this message translates to:
  /// **'キーボードを閉じる'**
  String get closeKeyboardTooltip;

  /// No description provided for @tagDuplicateError.
  ///
  /// In ja, this message translates to:
  /// **'このタグは既に追加されています'**
  String get tagDuplicateError;

  /// No description provided for @tagInvalidCharError.
  ///
  /// In ja, this message translates to:
  /// **'タグに使用できない文字が含まれています'**
  String get tagInvalidCharError;

  /// No description provided for @tagInputHint.
  ///
  /// In ja, this message translates to:
  /// **'タグを入力してEnterで追加'**
  String get tagInputHint;

  /// No description provided for @youtubeLoading.
  ///
  /// In ja, this message translates to:
  /// **'YouTube動画を読み込み中...'**
  String get youtubeLoading;

  /// No description provided for @playerLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'プレイヤーを読み込めませんでした'**
  String get playerLoadFailed;

  /// No description provided for @openInYoutube.
  ///
  /// In ja, this message translates to:
  /// **'YouTubeで開く'**
  String get openInYoutube;

  /// No description provided for @openInExternalApp.
  ///
  /// In ja, this message translates to:
  /// **'外部アプリで開く'**
  String get openInExternalApp;

  /// No description provided for @errorNetworkCheck.
  ///
  /// In ja, this message translates to:
  /// **'ネットワーク接続を確認してください'**
  String get errorNetworkCheck;

  /// No description provided for @errorAccessDenied.
  ///
  /// In ja, this message translates to:
  /// **'アクセス権限がありません'**
  String get errorAccessDenied;

  /// No description provided for @errorQuotaExceeded.
  ///
  /// In ja, this message translates to:
  /// **'サービスの利用上限に達しています。しばらく時間をおいてからお試しください'**
  String get errorQuotaExceeded;

  /// No description provided for @errorDataIntegrity.
  ///
  /// In ja, this message translates to:
  /// **'データの整合性に問題があります。アプリを再起動してお試しください'**
  String get errorDataIntegrity;

  /// No description provided for @errorCancelled.
  ///
  /// In ja, this message translates to:
  /// **'処理が中断されました。もう一度お試しください'**
  String get errorCancelled;

  /// No description provided for @errorFeatureUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'この機能は現在利用できません'**
  String get errorFeatureUnavailable;

  /// No description provided for @errorServerInternal.
  ///
  /// In ja, this message translates to:
  /// **'サーバー内部エラーが発生しました'**
  String get errorServerInternal;

  /// No description provided for @errorDataCorrupted.
  ///
  /// In ja, this message translates to:
  /// **'データの破損が検出されました'**
  String get errorDataCorrupted;

  /// No description provided for @errorAccountDisabled.
  ///
  /// In ja, this message translates to:
  /// **'このユーザーアカウントは無効化されています'**
  String get errorAccountDisabled;

  /// No description provided for @errorAuthMethodNotAllowed.
  ///
  /// In ja, this message translates to:
  /// **'この認証方法は許可されていません'**
  String get errorAuthMethodNotAllowed;

  /// No description provided for @errorEmailAlreadyUsed.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に使用されています'**
  String get errorEmailAlreadyUsed;

  /// No description provided for @errorEventNotFound.
  ///
  /// In ja, this message translates to:
  /// **'イベントが見つかりません'**
  String get errorEventNotFound;

  /// No description provided for @errorCannotFollowSelf.
  ///
  /// In ja, this message translates to:
  /// **'自分自身をフォローすることはできません'**
  String get errorCannotFollowSelf;

  /// No description provided for @errorAlreadyFollowing.
  ///
  /// In ja, this message translates to:
  /// **'既にフォローしています'**
  String get errorAlreadyFollowing;

  /// No description provided for @errorFollowNotFound.
  ///
  /// In ja, this message translates to:
  /// **'フォロー関係が見つかりません'**
  String get errorFollowNotFound;

  /// No description provided for @errorUserNotAuthenticated.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが認証されていません'**
  String get errorUserNotAuthenticated;

  /// No description provided for @errorFileNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ファイルが存在しません'**
  String get errorFileNotFound;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In ja, this message translates to:
  /// **'ファイルサイズが大きすぎます（最大5MB）'**
  String get errorFileTooLarge;

  /// No description provided for @errorUnsupportedFormat.
  ///
  /// In ja, this message translates to:
  /// **'サポートされていないファイル形式です（JPEG, PNG のみ）'**
  String get errorUnsupportedFormat;

  /// No description provided for @errorUploadCancelled.
  ///
  /// In ja, this message translates to:
  /// **'アップロードがキャンセルされました'**
  String get errorUploadCancelled;

  /// No description provided for @errorStorageNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ストレージが見つかりません'**
  String get errorStorageNotFound;

  /// No description provided for @errorStorageQuotaExceeded.
  ///
  /// In ja, this message translates to:
  /// **'ストレージ容量を超過しました'**
  String get errorStorageQuotaExceeded;

  /// No description provided for @errorRetryLimitExceeded.
  ///
  /// In ja, this message translates to:
  /// **'リトライ制限を超過しました'**
  String get errorRetryLimitExceeded;

  /// No description provided for @errorFileCorrupted.
  ///
  /// In ja, this message translates to:
  /// **'ファイルが破損している可能性があります'**
  String get errorFileCorrupted;

  /// No description provided for @labelGroupNameNotSet.
  ///
  /// In ja, this message translates to:
  /// **'グループ名未設定'**
  String get labelGroupNameNotSet;

  /// No description provided for @labelDeletedGroup.
  ///
  /// In ja, this message translates to:
  /// **'削除されたグループ'**
  String get labelDeletedGroup;

  /// No description provided for @labelUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get labelUser;

  /// No description provided for @labelGuestUser.
  ///
  /// In ja, this message translates to:
  /// **'ゲストユーザー'**
  String get labelGuestUser;

  /// No description provided for @errorViolationRecordNotFound.
  ///
  /// In ja, this message translates to:
  /// **'違反記録が見つかりません'**
  String get errorViolationRecordNotFound;

  /// No description provided for @errorViolationAlreadyPending.
  ///
  /// In ja, this message translates to:
  /// **'この違反記録は既に未処理状態です'**
  String get errorViolationAlreadyPending;

  /// No description provided for @errorMatchResultIdNotSet.
  ///
  /// In ja, this message translates to:
  /// **'試合結果IDが指定されていません'**
  String get errorMatchResultIdNotSet;

  /// No description provided for @errorMatchResultNotFound.
  ///
  /// In ja, this message translates to:
  /// **'試合結果が見つかりません'**
  String get errorMatchResultNotFound;

  /// No description provided for @errorReporterNotFound.
  ///
  /// In ja, this message translates to:
  /// **'報告者の情報が見つかりません'**
  String get errorReporterNotFound;

  /// No description provided for @errorEnhancedMatchResultIdNotSet.
  ///
  /// In ja, this message translates to:
  /// **'拡張試合結果IDが指定されていません'**
  String get errorEnhancedMatchResultIdNotSet;

  /// No description provided for @errorLegacyResultNotFound.
  ///
  /// In ja, this message translates to:
  /// **'レガシー試合結果が見つかりません'**
  String get errorLegacyResultNotFound;

  /// No description provided for @errorImageNotFound.
  ///
  /// In ja, this message translates to:
  /// **'画像ファイルが見つかりません'**
  String get errorImageNotFound;

  /// No description provided for @errorImageDecode.
  ///
  /// In ja, this message translates to:
  /// **'画像のデコードに失敗しました'**
  String get errorImageDecode;

  /// No description provided for @errorGameProfileExists.
  ///
  /// In ja, this message translates to:
  /// **'このゲームのプロフィールは既に存在します'**
  String get errorGameProfileExists;

  /// No description provided for @errorGameIdNotSet.
  ///
  /// In ja, this message translates to:
  /// **'ゲームIDが設定されていません'**
  String get errorGameIdNotSet;

  /// No description provided for @errorGameProfileNotFound.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールが見つかりません'**
  String get errorGameProfileNotFound;

  /// No description provided for @errorUserNotLoggedIn.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーがログインしていません'**
  String get errorUserNotLoggedIn;

  /// No description provided for @errorUserDataNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーデータが見つかりません'**
  String get errorUserDataNotFound;

  /// No description provided for @errorCancelledEventCannotDelete.
  ///
  /// In ja, this message translates to:
  /// **'中止済みのイベントは削除できません'**
  String get errorCancelledEventCannotDelete;

  /// No description provided for @errorCompletedEventCannotDelete.
  ///
  /// In ja, this message translates to:
  /// **'完了済みのイベントは削除できません'**
  String get errorCompletedEventCannotDelete;

  /// No description provided for @errorEventHasParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加申込者がいるイベントは削除できません。中止機能をご利用ください。'**
  String get errorEventHasParticipants;

  /// No description provided for @errorEventInviteSend.
  ///
  /// In ja, this message translates to:
  /// **'イベント招待の送信に失敗しました'**
  String get errorEventInviteSend;

  /// No description provided for @errorEventCreate.
  ///
  /// In ja, this message translates to:
  /// **'イベントの作成に失敗しました'**
  String get errorEventCreate;

  /// No description provided for @errorEventUpdate.
  ///
  /// In ja, this message translates to:
  /// **'イベントの更新に失敗しました'**
  String get errorEventUpdate;

  /// No description provided for @errorEventStatusUpdate.
  ///
  /// In ja, this message translates to:
  /// **'イベントステータスの更新に失敗しました'**
  String get errorEventStatusUpdate;

  /// No description provided for @errorEventGet.
  ///
  /// In ja, this message translates to:
  /// **'イベントの取得に失敗しました'**
  String get errorEventGet;

  /// No description provided for @errorUserEventsGet.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーのイベント一覧の取得に失敗しました'**
  String get errorUserEventsGet;

  /// No description provided for @errorPublicEventsGet.
  ///
  /// In ja, this message translates to:
  /// **'公開イベントの取得に失敗しました'**
  String get errorPublicEventsGet;

  /// No description provided for @errorEventDeleteNotFound.
  ///
  /// In ja, this message translates to:
  /// **'削除対象のイベントが見つかりません'**
  String get errorEventDeleteNotFound;

  /// No description provided for @errorEventDelete.
  ///
  /// In ja, this message translates to:
  /// **'イベントの削除に失敗しました'**
  String get errorEventDelete;

  /// No description provided for @errorEventSearch.
  ///
  /// In ja, this message translates to:
  /// **'イベントの検索に失敗しました'**
  String get errorEventSearch;

  /// No description provided for @errorGameEventsGet.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム関連イベントの取得に失敗しました'**
  String get errorGameEventsGet;

  /// No description provided for @errorUserParticipatingEventsGet.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーの参加イベント一覧の取得に失敗しました'**
  String get errorUserParticipatingEventsGet;

  /// No description provided for @errorWrongEventPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが正しくありません'**
  String get errorWrongEventPassword;

  /// No description provided for @errorAlreadyApplied.
  ///
  /// In ja, this message translates to:
  /// **'既に参加申請済みです'**
  String get errorAlreadyApplied;

  /// No description provided for @errorApplicationSubmit.
  ///
  /// In ja, this message translates to:
  /// **'参加申請の送信に失敗しました'**
  String get errorApplicationSubmit;

  /// No description provided for @errorApplicationApprove.
  ///
  /// In ja, this message translates to:
  /// **'参加申請の承認に失敗しました'**
  String get errorApplicationApprove;

  /// No description provided for @errorApplicationReject.
  ///
  /// In ja, this message translates to:
  /// **'参加申請の拒否に失敗しました'**
  String get errorApplicationReject;

  /// No description provided for @matchResultInputTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合結果入力'**
  String get matchResultInputTitle;

  /// No description provided for @matchNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'試合名'**
  String get matchNameLabel;

  /// No description provided for @matchNameRequired.
  ///
  /// In ja, this message translates to:
  /// **'試合名 *'**
  String get matchNameRequired;

  /// No description provided for @matchNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 準決勝、第3戦'**
  String get matchNameHint;

  /// No description provided for @matchNameValidation.
  ///
  /// In ja, this message translates to:
  /// **'試合名を入力してください'**
  String get matchNameValidation;

  /// No description provided for @gameTitleLabel.
  ///
  /// In ja, this message translates to:
  /// **'ゲームタイトル'**
  String get gameTitleLabel;

  /// No description provided for @gameTitleHint.
  ///
  /// In ja, this message translates to:
  /// **'例: スプラトゥーン3、ストリートファイター6'**
  String get gameTitleHint;

  /// No description provided for @matchFormatLabel.
  ///
  /// In ja, this message translates to:
  /// **'試合形式'**
  String get matchFormatLabel;

  /// No description provided for @matchFormatTournament.
  ///
  /// In ja, this message translates to:
  /// **'トーナメント'**
  String get matchFormatTournament;

  /// No description provided for @matchFormatLeague.
  ///
  /// In ja, this message translates to:
  /// **'リーグ戦'**
  String get matchFormatLeague;

  /// No description provided for @matchFormatFree.
  ///
  /// In ja, this message translates to:
  /// **'フリー対戦'**
  String get matchFormatFree;

  /// No description provided for @matchFormatPractice.
  ///
  /// In ja, this message translates to:
  /// **'練習試合'**
  String get matchFormatPractice;

  /// No description provided for @matchFormatOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get matchFormatOther;

  /// No description provided for @resultTypeLabel.
  ///
  /// In ja, this message translates to:
  /// **'記録方式'**
  String get resultTypeLabel;

  /// No description provided for @resultTypeRanking.
  ///
  /// In ja, this message translates to:
  /// **'順位制'**
  String get resultTypeRanking;

  /// No description provided for @resultTypeRankingDesc.
  ///
  /// In ja, this message translates to:
  /// **'各参加者の順位を記録（1位、2位、3位...）'**
  String get resultTypeRankingDesc;

  /// No description provided for @resultTypeScore.
  ///
  /// In ja, this message translates to:
  /// **'スコア制'**
  String get resultTypeScore;

  /// No description provided for @resultTypeScoreDesc.
  ///
  /// In ja, this message translates to:
  /// **'各参加者のスコアを記録'**
  String get resultTypeScoreDesc;

  /// No description provided for @resultTypeWinLoss.
  ///
  /// In ja, this message translates to:
  /// **'勝敗制'**
  String get resultTypeWinLoss;

  /// No description provided for @resultTypeWinLossDesc.
  ///
  /// In ja, this message translates to:
  /// **'各参加者の勝敗を記録'**
  String get resultTypeWinLossDesc;

  /// No description provided for @resultTypeTime.
  ///
  /// In ja, this message translates to:
  /// **'タイム制'**
  String get resultTypeTime;

  /// No description provided for @resultTypeTimeDesc.
  ///
  /// In ja, this message translates to:
  /// **'クリアタイムや記録時間を記録'**
  String get resultTypeTimeDesc;

  /// No description provided for @resultTypeAchievement.
  ///
  /// In ja, this message translates to:
  /// **'達成度制'**
  String get resultTypeAchievement;

  /// No description provided for @resultTypeAchievementDesc.
  ///
  /// In ja, this message translates to:
  /// **'達成度や評価を記録（星の数、ランク等）'**
  String get resultTypeAchievementDesc;

  /// No description provided for @resultTypeCustom.
  ///
  /// In ja, this message translates to:
  /// **'カスタム'**
  String get resultTypeCustom;

  /// No description provided for @resultTypeCustomDesc.
  ///
  /// In ja, this message translates to:
  /// **'自由形式で結果を記録'**
  String get resultTypeCustomDesc;

  /// No description provided for @rankingInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'順位入力'**
  String get rankingInputLabel;

  /// No description provided for @rankLabel.
  ///
  /// In ja, this message translates to:
  /// **'順位'**
  String get rankLabel;

  /// No description provided for @scoreInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'スコア入力'**
  String get scoreInputLabel;

  /// No description provided for @scoreLabel.
  ///
  /// In ja, this message translates to:
  /// **'スコア'**
  String get scoreLabel;

  /// No description provided for @winLossInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'結果'**
  String get winLossInputLabel;

  /// No description provided for @winLabel.
  ///
  /// In ja, this message translates to:
  /// **'勝利'**
  String get winLabel;

  /// No description provided for @drawLabel.
  ///
  /// In ja, this message translates to:
  /// **'引分'**
  String get drawLabel;

  /// No description provided for @lossLabel.
  ///
  /// In ja, this message translates to:
  /// **'敗北'**
  String get lossLabel;

  /// No description provided for @timeInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'タイム入力'**
  String get timeInputLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In ja, this message translates to:
  /// **'分'**
  String get minutesLabel;

  /// No description provided for @secondsLabel.
  ///
  /// In ja, this message translates to:
  /// **'秒'**
  String get secondsLabel;

  /// No description provided for @millisecondsLabel.
  ///
  /// In ja, this message translates to:
  /// **'ミリ秒'**
  String get millisecondsLabel;

  /// No description provided for @achievementInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'達成度入力'**
  String get achievementInputLabel;

  /// No description provided for @achievedLabel.
  ///
  /// In ja, this message translates to:
  /// **'達成'**
  String get achievedLabel;

  /// No description provided for @ratingLabel.
  ///
  /// In ja, this message translates to:
  /// **'評価'**
  String get ratingLabel;

  /// No description provided for @ratingNone.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get ratingNone;

  /// No description provided for @customResultInputLabel.
  ///
  /// In ja, this message translates to:
  /// **'カスタム結果入力'**
  String get customResultInputLabel;

  /// No description provided for @customResultHint.
  ///
  /// In ja, this message translates to:
  /// **'結果詳細は備考欄に記入してください'**
  String get customResultHint;

  /// No description provided for @notesHint.
  ///
  /// In ja, this message translates to:
  /// **'メモ、特記事項など'**
  String get notesHint;

  /// No description provided for @matchAddTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合を追加'**
  String get matchAddTitle;

  /// No description provided for @matchNameInputHint.
  ///
  /// In ja, this message translates to:
  /// **'試合名を入力'**
  String get matchNameInputHint;

  /// No description provided for @participantTeamsLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加チーム（グループ）'**
  String get participantTeamsLabel;

  /// No description provided for @participantsLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者: '**
  String get participantsLabel;

  /// No description provided for @selectButton.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get selectButton;

  /// No description provided for @deselectButton.
  ///
  /// In ja, this message translates to:
  /// **'解除'**
  String get deselectButton;

  /// No description provided for @selectAtLeastTwoTeams.
  ///
  /// In ja, this message translates to:
  /// **'少なくとも2つのチーム（グループ）を選択してください'**
  String get selectAtLeastTwoTeams;

  /// No description provided for @selectAtLeastTwoParticipants.
  ///
  /// In ja, this message translates to:
  /// **'少なくとも2つの参加者を選択してください'**
  String get selectAtLeastTwoParticipants;

  /// No description provided for @registeringMatch.
  ///
  /// In ja, this message translates to:
  /// **'登録中...'**
  String get registeringMatch;

  /// No description provided for @registerMatchButton.
  ///
  /// In ja, this message translates to:
  /// **'試合を登録'**
  String get registerMatchButton;

  /// No description provided for @groupDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループ詳細'**
  String get groupDetailTitle;

  /// No description provided for @groupInfoLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'グループ情報の読み込みに失敗しました'**
  String get groupInfoLoadFailed;

  /// No description provided for @memberCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'メンバー数'**
  String get memberCountLabel;

  /// No description provided for @groupNoticeLabel.
  ///
  /// In ja, this message translates to:
  /// **'グループ連絡事項'**
  String get groupNoticeLabel;

  /// No description provided for @reportDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'報告詳細'**
  String get reportDetailTitle;

  /// No description provided for @problemTypeLabel.
  ///
  /// In ja, this message translates to:
  /// **'問題の種類'**
  String get problemTypeLabel;

  /// No description provided for @reportDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'報告日時'**
  String get reportDateLabel;

  /// No description provided for @detailDescriptionLabel.
  ///
  /// In ja, this message translates to:
  /// **'詳細説明'**
  String get detailDescriptionLabel;

  /// No description provided for @adminResponseLabel.
  ///
  /// In ja, this message translates to:
  /// **'運営からの回答'**
  String get adminResponseLabel;

  /// No description provided for @respondButton.
  ///
  /// In ja, this message translates to:
  /// **'対応する'**
  String get respondButton;

  /// No description provided for @pleaseChangeStatus.
  ///
  /// In ja, this message translates to:
  /// **'ステータスを変更してください'**
  String get pleaseChangeStatus;

  /// No description provided for @pleaseEnterResponse.
  ///
  /// In ja, this message translates to:
  /// **'対応内容を入力してください'**
  String get pleaseEnterResponse;

  /// No description provided for @statusUpdatedMessage.
  ///
  /// In ja, this message translates to:
  /// **'ステータスを更新しました'**
  String get statusUpdatedMessage;

  /// No description provided for @reportResponseTitle.
  ///
  /// In ja, this message translates to:
  /// **'報告への対応'**
  String get reportResponseTitle;

  /// No description provided for @matchLabel.
  ///
  /// In ja, this message translates to:
  /// **'試合'**
  String get matchLabel;

  /// No description provided for @problemLabel.
  ///
  /// In ja, this message translates to:
  /// **'問題'**
  String get problemLabel;

  /// No description provided for @statusChangeTitle.
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更'**
  String get statusChangeTitle;

  /// No description provided for @responseContentLabel.
  ///
  /// In ja, this message translates to:
  /// **'対応内容・コメント'**
  String get responseContentLabel;

  /// No description provided for @requiredMark.
  ///
  /// In ja, this message translates to:
  /// **'※ 必須'**
  String get requiredMark;

  /// No description provided for @optionalMark.
  ///
  /// In ja, this message translates to:
  /// **'※ 任意'**
  String get optionalMark;

  /// No description provided for @responseContentHint.
  ///
  /// In ja, this message translates to:
  /// **'対応内容や報告者への回答を入力してください'**
  String get responseContentHint;

  /// No description provided for @currentStatusLabel.
  ///
  /// In ja, this message translates to:
  /// **'（現在のステータス）'**
  String get currentStatusLabel;

  /// No description provided for @recordInfoToRecord.
  ///
  /// In ja, this message translates to:
  /// **'記録する情報'**
  String get recordInfoToRecord;

  /// No description provided for @checkRequiredInfo.
  ///
  /// In ja, this message translates to:
  /// **'必要な情報にチェックを入れてください（複数選択可）'**
  String get checkRequiredInfo;

  /// No description provided for @scorePointsLabel.
  ///
  /// In ja, this message translates to:
  /// **'スコア・点数'**
  String get scorePointsLabel;

  /// No description provided for @scorePointsDesc.
  ///
  /// In ja, this message translates to:
  /// **'ゲームで獲得したスコアや点数を記録'**
  String get scorePointsDesc;

  /// No description provided for @rankingPositionLabel.
  ///
  /// In ja, this message translates to:
  /// **'順位・ランキング'**
  String get rankingPositionLabel;

  /// No description provided for @rankingPositionDesc.
  ///
  /// In ja, this message translates to:
  /// **'参加者の順位を記録（1位、2位、3位...)'**
  String get rankingPositionDesc;

  /// No description provided for @winLossResultLabel.
  ///
  /// In ja, this message translates to:
  /// **'勝敗結果'**
  String get winLossResultLabel;

  /// No description provided for @winLossResultDesc.
  ///
  /// In ja, this message translates to:
  /// **'勝ち、負け、引き分けの結果を記録'**
  String get winLossResultDesc;

  /// No description provided for @selectAtLeastOneInfo.
  ///
  /// In ja, this message translates to:
  /// **'記録したい情報を1つ以上選択してください'**
  String get selectAtLeastOneInfo;

  /// No description provided for @participantResultsLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者の結果'**
  String get participantResultsLabel;

  /// No description provided for @pointsSuffix.
  ///
  /// In ja, this message translates to:
  /// **'点'**
  String get pointsSuffix;

  /// No description provided for @matchDetailMemo.
  ///
  /// In ja, this message translates to:
  /// **'試合の詳細や特記事項'**
  String get matchDetailMemo;

  /// No description provided for @winLossWin.
  ///
  /// In ja, this message translates to:
  /// **'勝ち'**
  String get winLossWin;

  /// No description provided for @winLossLoss.
  ///
  /// In ja, this message translates to:
  /// **'負け'**
  String get winLossLoss;

  /// No description provided for @winLossDraw.
  ///
  /// In ja, this message translates to:
  /// **'引き分け'**
  String get winLossDraw;

  /// No description provided for @matchNameExampleHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 第1回トーナメント決勝'**
  String get matchNameExampleHint;

  /// No description provided for @resultTypeScoreLabel.
  ///
  /// In ja, this message translates to:
  /// **'スコア'**
  String get resultTypeScoreLabel;

  /// No description provided for @resultTypeRankLabel.
  ///
  /// In ja, this message translates to:
  /// **'順位'**
  String get resultTypeRankLabel;

  /// No description provided for @resultTypeWinLossLabel.
  ///
  /// In ja, this message translates to:
  /// **'勝敗'**
  String get resultTypeWinLossLabel;

  /// No description provided for @evidenceImageTitle.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像'**
  String get evidenceImageTitle;

  /// No description provided for @evidenceImageAdd.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像の追加'**
  String get evidenceImageAdd;

  /// No description provided for @cameraCapture.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get cameraCapture;

  /// No description provided for @gallerySelect.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get gallerySelect;

  /// No description provided for @imageDeleted.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除しました'**
  String get imageDeleted;

  /// No description provided for @deleteImageTitle.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除'**
  String get deleteImageTitle;

  /// No description provided for @deleteImageConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この画像を削除しますか？この操作は取り消せません。'**
  String get deleteImageConfirm;

  /// No description provided for @imageOperationsTitle.
  ///
  /// In ja, this message translates to:
  /// **'画像の操作'**
  String get imageOperationsTitle;

  /// No description provided for @replaceImageLabel.
  ///
  /// In ja, this message translates to:
  /// **'画像を置き換え'**
  String get replaceImageLabel;

  /// No description provided for @replaceImageDesc.
  ///
  /// In ja, this message translates to:
  /// **'新しい画像で置き換えます（古い画像は自動削除）'**
  String get replaceImageDesc;

  /// No description provided for @deleteImageLabel.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除'**
  String get deleteImageLabel;

  /// No description provided for @deleteImageDesc.
  ///
  /// In ja, this message translates to:
  /// **'この画像を完全に削除します'**
  String get deleteImageDesc;

  /// No description provided for @replaceImageTitle.
  ///
  /// In ja, this message translates to:
  /// **'画像の置き換え'**
  String get replaceImageTitle;

  /// No description provided for @replaceImageNote.
  ///
  /// In ja, this message translates to:
  /// **'古い画像は自動的に削除され、新しい画像に置き換わります'**
  String get replaceImageNote;

  /// No description provided for @imageReplaced.
  ///
  /// In ja, this message translates to:
  /// **'画像を置き換えました（古い画像は自動削除されました）'**
  String get imageReplaced;

  /// No description provided for @replaceAllImagesTitle.
  ///
  /// In ja, this message translates to:
  /// **'全ての画像を置き換え'**
  String get replaceAllImagesTitle;

  /// No description provided for @replaceButton.
  ///
  /// In ja, this message translates to:
  /// **'置き換える'**
  String get replaceButton;

  /// No description provided for @replaceImageTooltip.
  ///
  /// In ja, this message translates to:
  /// **'画像を置き換え'**
  String get replaceImageTooltip;

  /// No description provided for @deleteImageTooltip.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除'**
  String get deleteImageTooltip;

  /// No description provided for @imageLoadFailedSimple.
  ///
  /// In ja, this message translates to:
  /// **'画像の読み込みに失敗しました'**
  String get imageLoadFailedSimple;

  /// No description provided for @uploaderLabel.
  ///
  /// In ja, this message translates to:
  /// **'アップロード者'**
  String get uploaderLabel;

  /// No description provided for @uploadDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'アップロード日時'**
  String get uploadDateLabel;

  /// No description provided for @replaceAllButton.
  ///
  /// In ja, this message translates to:
  /// **'置き換える'**
  String get replaceAllButton;

  /// No description provided for @evidenceImageInfo.
  ///
  /// In ja, this message translates to:
  /// **'試合の証拠となる画像をアップロードできます'**
  String get evidenceImageInfo;

  /// No description provided for @noEvidenceImages.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像がありません'**
  String get noEvidenceImages;

  /// No description provided for @uploadFromAddButton.
  ///
  /// In ja, this message translates to:
  /// **'「画像を追加」ボタンから画像をアップロードできます'**
  String get uploadFromAddButton;

  /// No description provided for @uploadedAtLabel.
  ///
  /// In ja, this message translates to:
  /// **'アップロード日時'**
  String get uploadedAtLabel;

  /// No description provided for @imageActionMenuTitle.
  ///
  /// In ja, this message translates to:
  /// **'画像の操作'**
  String get imageActionMenuTitle;

  /// No description provided for @loadingMessage.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get loadingMessage;

  /// No description provided for @userUnknown.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー不明'**
  String get userUnknown;

  /// No description provided for @noneLabel.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get noneLabel;

  /// No description provided for @eventLabel.
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get eventLabel;

  /// No description provided for @noEventsTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベントがありません'**
  String get noEventsTitle;

  /// No description provided for @noEventsMessage.
  ///
  /// In ja, this message translates to:
  /// **'まだイベントが作成されていません'**
  String get noEventsMessage;

  /// No description provided for @searchEventsHint.
  ///
  /// In ja, this message translates to:
  /// **'イベント名で検索...'**
  String get searchEventsHint;

  /// No description provided for @coEditorEvents.
  ///
  /// In ja, this message translates to:
  /// **'共同編集者のイベント'**
  String get coEditorEvents;

  /// No description provided for @applicationStatusPending.
  ///
  /// In ja, this message translates to:
  /// **'承認待ち'**
  String get applicationStatusPending;

  /// No description provided for @applicationStatusWaitlist.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ち'**
  String get applicationStatusWaitlist;

  /// No description provided for @applicationStatusCancelled.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル済み'**
  String get applicationStatusCancelled;

  /// No description provided for @urlAlreadyAdded.
  ///
  /// In ja, this message translates to:
  /// **'このURLは既に追加されています'**
  String get urlAlreadyAdded;

  /// No description provided for @invalidUrlFormat.
  ///
  /// In ja, this message translates to:
  /// **'有効なURLを入力してください (https://... または http://...)'**
  String get invalidUrlFormat;

  /// No description provided for @imageLoadFailedGeneric.
  ///
  /// In ja, this message translates to:
  /// **'画像を読み込めませんでした'**
  String get imageLoadFailedGeneric;

  /// No description provided for @keyboardCloseLabel.
  ///
  /// In ja, this message translates to:
  /// **'キーボードを閉じる'**
  String get keyboardCloseLabel;

  /// No description provided for @keyboardCloseTooltip.
  ///
  /// In ja, this message translates to:
  /// **'キーボードを閉じる'**
  String get keyboardCloseTooltip;

  /// No description provided for @fieldRequired.
  ///
  /// In ja, this message translates to:
  /// **'この項目は必須です'**
  String get fieldRequired;

  /// No description provided for @enterValidNumber.
  ///
  /// In ja, this message translates to:
  /// **'正しい数値を入力してください'**
  String get enterValidNumber;

  /// No description provided for @enterValidInteger.
  ///
  /// In ja, this message translates to:
  /// **'正しい整数を入力してください'**
  String get enterValidInteger;

  /// No description provided for @eventTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベントタイトル'**
  String get eventTitle;

  /// No description provided for @avatarSelectTitle.
  ///
  /// In ja, this message translates to:
  /// **'アバター画像を選択'**
  String get avatarSelectTitle;

  /// No description provided for @avatarCropTitle.
  ///
  /// In ja, this message translates to:
  /// **'アバターを調整'**
  String get avatarCropTitle;

  /// No description provided for @socialFollowing.
  ///
  /// In ja, this message translates to:
  /// **'フォロー中'**
  String get socialFollowing;

  /// No description provided for @socialFollower.
  ///
  /// In ja, this message translates to:
  /// **'フォロワー'**
  String get socialFollower;

  /// No description provided for @socialMutualFollow.
  ///
  /// In ja, this message translates to:
  /// **'相互フォロー'**
  String get socialMutualFollow;

  /// No description provided for @noMutualFollowersYet.
  ///
  /// In ja, this message translates to:
  /// **'まだ相互フォローがいません'**
  String get noMutualFollowersYet;

  /// No description provided for @noFollowersYet.
  ///
  /// In ja, this message translates to:
  /// **'まだフォロワーがいません'**
  String get noFollowersYet;

  /// No description provided for @notFollowingAnyone.
  ///
  /// In ja, this message translates to:
  /// **'まだ誰もフォローしていません'**
  String get notFollowingAnyone;

  /// No description provided for @loadingGameProfile.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールを取得中...'**
  String get loadingGameProfile;

  /// No description provided for @newMatchReport.
  ///
  /// In ja, this message translates to:
  /// **'新しい試合報告'**
  String get newMatchReport;

  /// No description provided for @reportReviewing.
  ///
  /// In ja, this message translates to:
  /// **'報告を確認中'**
  String get reportReviewing;

  /// No description provided for @reportReviewingMessage.
  ///
  /// In ja, this message translates to:
  /// **'ご報告いただいた問題を確認しています'**
  String get reportReviewingMessage;

  /// No description provided for @reportResolved.
  ///
  /// In ja, this message translates to:
  /// **'報告が解決されました'**
  String get reportResolved;

  /// No description provided for @reportResolvedMessage.
  ///
  /// In ja, this message translates to:
  /// **'ご報告いただいた問題が解決されました'**
  String get reportResolvedMessage;

  /// No description provided for @reportRejectedTitle.
  ///
  /// In ja, this message translates to:
  /// **'報告について'**
  String get reportRejectedTitle;

  /// No description provided for @reportRejectedMessage.
  ///
  /// In ja, this message translates to:
  /// **'ご報告いただいた内容を確認しましたが、修正の必要がないと判断いたします'**
  String get reportRejectedMessage;

  /// No description provided for @matchReportStatusSubmitted.
  ///
  /// In ja, this message translates to:
  /// **'報告済み'**
  String get matchReportStatusSubmitted;

  /// No description provided for @skillLevelBeginnerDesc.
  ///
  /// In ja, this message translates to:
  /// **'始めたばかり、基本的な操作を学習中'**
  String get skillLevelBeginnerDesc;

  /// No description provided for @skillLevelIntermediateDesc.
  ///
  /// In ja, this message translates to:
  /// **'基本操作は慣れて、戦略を学習中'**
  String get skillLevelIntermediateDesc;

  /// No description provided for @skillLevelAdvancedDesc.
  ///
  /// In ja, this message translates to:
  /// **'高度な戦略やテクニックを習得済み'**
  String get skillLevelAdvancedDesc;

  /// No description provided for @skillLevelExpertDesc.
  ///
  /// In ja, this message translates to:
  /// **'プロレベル、他の人に教えられる'**
  String get skillLevelExpertDesc;

  /// No description provided for @playStyleCoop.
  ///
  /// In ja, this message translates to:
  /// **'協力プレイ'**
  String get playStyleCoop;

  /// No description provided for @playStyleCasualDesc.
  ///
  /// In ja, this message translates to:
  /// **'のんびり楽しくプレイ'**
  String get playStyleCasualDesc;

  /// No description provided for @playStyleCompetitiveDesc.
  ///
  /// In ja, this message translates to:
  /// **'ランクマッチや大会を重視'**
  String get playStyleCompetitiveDesc;

  /// No description provided for @playStyleCoopDesc.
  ///
  /// In ja, this message translates to:
  /// **'チームで協力してプレイ'**
  String get playStyleCoopDesc;

  /// No description provided for @playStyleSoloDesc.
  ///
  /// In ja, this message translates to:
  /// **'一人でじっくりプレイ'**
  String get playStyleSoloDesc;

  /// No description provided for @playStyleSocialDesc.
  ///
  /// In ja, this message translates to:
  /// **'他のプレイヤーとの交流を重視'**
  String get playStyleSocialDesc;

  /// No description provided for @playStyleSpeedrunDesc.
  ///
  /// In ja, this message translates to:
  /// **'最短クリアを目指す'**
  String get playStyleSpeedrunDesc;

  /// No description provided for @playStyleCollectorDesc.
  ///
  /// In ja, this message translates to:
  /// **'アイテムや実績の収集を重視'**
  String get playStyleCollectorDesc;

  /// No description provided for @playTimeMorning.
  ///
  /// In ja, this message translates to:
  /// **'朝（6-12時）'**
  String get playTimeMorning;

  /// No description provided for @playTimeAfternoon.
  ///
  /// In ja, this message translates to:
  /// **'昼（12-18時）'**
  String get playTimeAfternoon;

  /// No description provided for @playTimeEvening.
  ///
  /// In ja, this message translates to:
  /// **'夜（18-24時）'**
  String get playTimeEvening;

  /// No description provided for @playTimeNight.
  ///
  /// In ja, this message translates to:
  /// **'深夜（24-6時）'**
  String get playTimeNight;

  /// No description provided for @playTimeWeekend.
  ///
  /// In ja, this message translates to:
  /// **'週末'**
  String get playTimeWeekend;

  /// No description provided for @playTimeWeekday.
  ///
  /// In ja, this message translates to:
  /// **'平日'**
  String get playTimeWeekday;

  /// No description provided for @violationTypeDisruptive.
  ///
  /// In ja, this message translates to:
  /// **'妨害行為'**
  String get violationTypeDisruptive;

  /// No description provided for @violationTypeHarassmentDesc.
  ///
  /// In ja, this message translates to:
  /// **'他の参加者に対する嫌がらせやいじめ行為'**
  String get violationTypeHarassmentDesc;

  /// No description provided for @violationTypeCheatingDesc.
  ///
  /// In ja, this message translates to:
  /// **'不正なソフトウェアの使用や規約違反'**
  String get violationTypeCheatingDesc;

  /// No description provided for @violationTypeSpamDesc.
  ///
  /// In ja, this message translates to:
  /// **'スパムメッセージや迷惑行為'**
  String get violationTypeSpamDesc;

  /// No description provided for @violationTypeAbusiveLanguageDesc.
  ///
  /// In ja, this message translates to:
  /// **'暴言、差別的発言、不適切な言動'**
  String get violationTypeAbusiveLanguageDesc;

  /// No description provided for @violationTypeNoShowDesc.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加申請後の無断不参加'**
  String get violationTypeNoShowDesc;

  /// No description provided for @violationTypeDisruptiveDesc.
  ///
  /// In ja, this message translates to:
  /// **'イベント進行を妨害する行為'**
  String get violationTypeDisruptiveDesc;

  /// No description provided for @violationTypeRuleViolationDesc.
  ///
  /// In ja, this message translates to:
  /// **'イベントルールへの違反行為'**
  String get violationTypeRuleViolationDesc;

  /// No description provided for @violationTypeOtherDesc.
  ///
  /// In ja, this message translates to:
  /// **'その他の規約違反行為'**
  String get violationTypeOtherDesc;

  /// No description provided for @violationSeverityMinorDesc.
  ///
  /// In ja, this message translates to:
  /// **'軽微な違反。注意や警告で対応可能'**
  String get violationSeverityMinorDesc;

  /// No description provided for @violationSeverityModerateDesc.
  ///
  /// In ja, this message translates to:
  /// **'中程度の違反。一時的な制限措置が必要'**
  String get violationSeverityModerateDesc;

  /// No description provided for @violationSeveritySevereDesc.
  ///
  /// In ja, this message translates to:
  /// **'重大な違反。厳重な処分が必要'**
  String get violationSeveritySevereDesc;

  /// No description provided for @violationStatusPending.
  ///
  /// In ja, this message translates to:
  /// **'未処理'**
  String get violationStatusPending;

  /// No description provided for @violationStatusUnderReview.
  ///
  /// In ja, this message translates to:
  /// **'調査中'**
  String get violationStatusUnderReview;

  /// No description provided for @violationStatusResolved.
  ///
  /// In ja, this message translates to:
  /// **'処理済み'**
  String get violationStatusResolved;

  /// No description provided for @violationStatusDismissed.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get violationStatusDismissed;

  /// No description provided for @violationStatusPendingDesc.
  ///
  /// In ja, this message translates to:
  /// **'報告されたが未だ対応していない状態'**
  String get violationStatusPendingDesc;

  /// No description provided for @violationStatusUnderReviewDesc.
  ///
  /// In ja, this message translates to:
  /// **'詳細調査中の状態'**
  String get violationStatusUnderReviewDesc;

  /// No description provided for @violationStatusResolvedDesc.
  ///
  /// In ja, this message translates to:
  /// **'適切な処分を行い完了した状態'**
  String get violationStatusResolvedDesc;

  /// No description provided for @violationStatusDismissedDesc.
  ///
  /// In ja, this message translates to:
  /// **'調査の結果、違反に該当しないと判断された状態'**
  String get violationStatusDismissedDesc;

  /// No description provided for @appealStatusPending.
  ///
  /// In ja, this message translates to:
  /// **'審査待ち'**
  String get appealStatusPending;

  /// No description provided for @appealStatusUnderReview.
  ///
  /// In ja, this message translates to:
  /// **'審査中'**
  String get appealStatusUnderReview;

  /// No description provided for @appealStatusApproved.
  ///
  /// In ja, this message translates to:
  /// **'承認'**
  String get appealStatusApproved;

  /// No description provided for @appealStatusRejected.
  ///
  /// In ja, this message translates to:
  /// **'却下'**
  String get appealStatusRejected;

  /// No description provided for @appealStatusPendingDesc.
  ///
  /// In ja, this message translates to:
  /// **'異議申立が提出され、審査待ちの状態'**
  String get appealStatusPendingDesc;

  /// No description provided for @appealStatusUnderReviewDesc.
  ///
  /// In ja, this message translates to:
  /// **'運営による詳細審査中の状態'**
  String get appealStatusUnderReviewDesc;

  /// No description provided for @appealStatusApprovedDesc.
  ///
  /// In ja, this message translates to:
  /// **'異議が認められ、違反記録が取り消された状態'**
  String get appealStatusApprovedDesc;

  /// No description provided for @appealStatusRejectedDesc.
  ///
  /// In ja, this message translates to:
  /// **'異議が却下され、違反記録が維持された状態'**
  String get appealStatusRejectedDesc;

  /// No description provided for @riskLevelNone.
  ///
  /// In ja, this message translates to:
  /// **'リスクなし'**
  String get riskLevelNone;

  /// No description provided for @riskLevelLow.
  ///
  /// In ja, this message translates to:
  /// **'低リスク'**
  String get riskLevelLow;

  /// No description provided for @riskLevelMedium.
  ///
  /// In ja, this message translates to:
  /// **'中リスク'**
  String get riskLevelMedium;

  /// No description provided for @riskLevelHigh.
  ///
  /// In ja, this message translates to:
  /// **'高リスク'**
  String get riskLevelHigh;

  /// No description provided for @riskLevelNoneDesc.
  ///
  /// In ja, this message translates to:
  /// **'これまでに違反記録はありません'**
  String get riskLevelNoneDesc;

  /// No description provided for @riskLevelLowDesc.
  ///
  /// In ja, this message translates to:
  /// **'軽微な違反が1〜2件あります'**
  String get riskLevelLowDesc;

  /// No description provided for @riskLevelMediumDesc.
  ///
  /// In ja, this message translates to:
  /// **'中程度以上の違反があるか、複数の違反があります'**
  String get riskLevelMediumDesc;

  /// No description provided for @riskLevelHighDesc.
  ///
  /// In ja, this message translates to:
  /// **'重大な違反があるか、多数の違反履歴があります'**
  String get riskLevelHighDesc;

  /// No description provided for @eventStatusScheduled.
  ///
  /// In ja, this message translates to:
  /// **'開催予定'**
  String get eventStatusScheduled;

  /// No description provided for @eventStatusOngoing.
  ///
  /// In ja, this message translates to:
  /// **'開催中'**
  String get eventStatusOngoing;

  /// No description provided for @eventCategoryDaily.
  ///
  /// In ja, this message translates to:
  /// **'デイリー'**
  String get eventCategoryDaily;

  /// No description provided for @eventCategoryWeekly.
  ///
  /// In ja, this message translates to:
  /// **'ウィークリー'**
  String get eventCategoryWeekly;

  /// No description provided for @eventCategorySpecial.
  ///
  /// In ja, this message translates to:
  /// **'スペシャル'**
  String get eventCategorySpecial;

  /// No description provided for @eventCategorySeasonal.
  ///
  /// In ja, this message translates to:
  /// **'シーズナル'**
  String get eventCategorySeasonal;

  /// No description provided for @approvalMethodAuto.
  ///
  /// In ja, this message translates to:
  /// **'自動承認'**
  String get approvalMethodAuto;

  /// No description provided for @appealCancelledNote.
  ///
  /// In ja, this message translates to:
  /// **'異議申立により取り消し'**
  String get appealCancelledNote;

  /// No description provided for @hashtags.
  ///
  /// In ja, this message translates to:
  /// **'#Go. #ゲームイベント'**
  String get hashtags;

  /// No description provided for @notesOptional.
  ///
  /// In ja, this message translates to:
  /// **'メモ（任意）'**
  String get notesOptional;

  /// No description provided for @matchDetailsHint.
  ///
  /// In ja, this message translates to:
  /// **'試合の詳細やメモを入力...'**
  String get matchDetailsHint;

  /// No description provided for @matchResultEditTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合結果編集'**
  String get matchResultEditTitle;

  /// No description provided for @rankingSectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'順位付け'**
  String get rankingSectionTitle;

  /// No description provided for @rankingDragDropHint.
  ///
  /// In ja, this message translates to:
  /// **'カードをドラッグ&ドロップして順位を決定してください'**
  String get rankingDragDropHint;

  /// No description provided for @rankingTopIsFirst.
  ///
  /// In ja, this message translates to:
  /// **'上が1位、下が最下位'**
  String get rankingTopIsFirst;

  /// No description provided for @scoreInputSectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'スコア入力'**
  String get scoreInputSectionTitle;

  /// No description provided for @scoreInputHint.
  ///
  /// In ja, this message translates to:
  /// **'スコア種別を追加して複数の評価軸で記録できます'**
  String get scoreInputHint;

  /// No description provided for @addScoreTypeTooltip.
  ///
  /// In ja, this message translates to:
  /// **'スコア種別を追加'**
  String get addScoreTypeTooltip;

  /// No description provided for @addScoreTypeDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'スコア種別を追加'**
  String get addScoreTypeDialogTitle;

  /// No description provided for @scoreNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'スコア名'**
  String get scoreNameLabel;

  /// No description provided for @scoreNameHint.
  ///
  /// In ja, this message translates to:
  /// **'キル数、ポイント、ダメージなど'**
  String get scoreNameHint;

  /// No description provided for @scoreUnitLabel.
  ///
  /// In ja, this message translates to:
  /// **'単位'**
  String get scoreUnitLabel;

  /// No description provided for @scoreUnitHint.
  ///
  /// In ja, this message translates to:
  /// **'キル、ポイント、HPなど'**
  String get scoreUnitHint;

  /// No description provided for @targetLabel.
  ///
  /// In ja, this message translates to:
  /// **'対象'**
  String get targetLabel;

  /// No description provided for @groupTargetLabel.
  ///
  /// In ja, this message translates to:
  /// **'グループ'**
  String get groupTargetLabel;

  /// No description provided for @teamScoreSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'チーム単位のスコア'**
  String get teamScoreSubtitle;

  /// No description provided for @individualTargetLabel.
  ///
  /// In ja, this message translates to:
  /// **'個人'**
  String get individualTargetLabel;

  /// No description provided for @individualScoreSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'個人単位のスコア'**
  String get individualScoreSubtitle;

  /// No description provided for @addScoreTypeEmptyTitle.
  ///
  /// In ja, this message translates to:
  /// **'スコア種別を追加してください'**
  String get addScoreTypeEmptyTitle;

  /// No description provided for @addScoreTypeEmptySubtitle.
  ///
  /// In ja, this message translates to:
  /// **'キル数、ポイント、ダメージなど\\nお好みの評価軸を設定できます'**
  String get addScoreTypeEmptySubtitle;

  /// No description provided for @deleteTooltip.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get deleteTooltip;

  /// No description provided for @userDefaultName.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get userDefaultName;

  /// No description provided for @updatingResult.
  ///
  /// In ja, this message translates to:
  /// **'更新中...'**
  String get updatingResult;

  /// No description provided for @savingResult.
  ///
  /// In ja, this message translates to:
  /// **'保存中...'**
  String get savingResult;

  /// No description provided for @updateResult.
  ///
  /// In ja, this message translates to:
  /// **'結果を更新'**
  String get updateResult;

  /// No description provided for @saveResult.
  ///
  /// In ja, this message translates to:
  /// **'結果を保存'**
  String get saveResult;

  /// No description provided for @evidenceImageSectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像'**
  String get evidenceImageSectionTitle;

  /// No description provided for @addImageButtonLabel.
  ///
  /// In ja, this message translates to:
  /// **'画像を追加'**
  String get addImageButtonLabel;

  /// No description provided for @addEvidenceImageTitle.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像の追加'**
  String get addEvidenceImageTitle;

  /// No description provided for @cameraLabel.
  ///
  /// In ja, this message translates to:
  /// **'カメラ'**
  String get cameraLabel;

  /// No description provided for @galleryLabel.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリー'**
  String get galleryLabel;

  /// No description provided for @photoTakenMessage.
  ///
  /// In ja, this message translates to:
  /// **'写真を撮影しました'**
  String get photoTakenMessage;

  /// No description provided for @imageSelectedMessage.
  ///
  /// In ja, this message translates to:
  /// **'画像を選択しました'**
  String get imageSelectedMessage;

  /// No description provided for @adminNotesSectionTitle.
  ///
  /// In ja, this message translates to:
  /// **'運営メモ'**
  String get adminNotesSectionTitle;

  /// No description provided for @adminNotesDescription.
  ///
  /// In ja, this message translates to:
  /// **'試合結果に関する運営側のメモを記入できます'**
  String get adminNotesDescription;

  /// No description provided for @publicNoteTitle.
  ///
  /// In ja, this message translates to:
  /// **'公開メモ（ユーザー閲覧可能）'**
  String get publicNoteTitle;

  /// No description provided for @publicNoteDescription.
  ///
  /// In ja, this message translates to:
  /// **'参加者が閲覧できるメモです。試合の詳細や特記事項を記入してください。'**
  String get publicNoteDescription;

  /// No description provided for @publicNoteHint.
  ///
  /// In ja, this message translates to:
  /// **'例：接続不良により再戦を実施、MVP賞を追加授与など...'**
  String get publicNoteHint;

  /// No description provided for @privateNoteTitle.
  ///
  /// In ja, this message translates to:
  /// **'プライベートメモ（運営者のみ閲覧可能）'**
  String get privateNoteTitle;

  /// No description provided for @privateNoteDescription.
  ///
  /// In ja, this message translates to:
  /// **'運営者のみが閲覧できる内部メモです。参加者には表示されません。'**
  String get privateNoteDescription;

  /// No description provided for @privateNoteHint.
  ///
  /// In ja, this message translates to:
  /// **'例：参加者Aから異議申し立てあり、要確認事項など...'**
  String get privateNoteHint;

  /// No description provided for @pointsUnit.
  ///
  /// In ja, this message translates to:
  /// **'点'**
  String get pointsUnit;

  /// No description provided for @optionalLabel.
  ///
  /// In ja, this message translates to:
  /// **'任意'**
  String get optionalLabel;

  /// No description provided for @takePhotoLabel.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get takePhotoLabel;

  /// No description provided for @selectFromGalleryLabel.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get selectFromGalleryLabel;

  /// No description provided for @imageDeletedMessage.
  ///
  /// In ja, this message translates to:
  /// **'画像を削除しました'**
  String get imageDeletedMessage;

  /// No description provided for @deleteImageConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'この画像を削除しますか？この操作は取り消せません。'**
  String get deleteImageConfirmMessage;

  /// No description provided for @replaceImageDescription.
  ///
  /// In ja, this message translates to:
  /// **'新しい画像で置き換えます（古い画像は自動削除）'**
  String get replaceImageDescription;

  /// No description provided for @deleteImageDescription.
  ///
  /// In ja, this message translates to:
  /// **'この画像を完全に削除します'**
  String get deleteImageDescription;

  /// No description provided for @replaceImageInfo.
  ///
  /// In ja, this message translates to:
  /// **'古い画像は自動的に削除され、新しい画像に置き換わります'**
  String get replaceImageInfo;

  /// No description provided for @imageReplacedMessage.
  ///
  /// In ja, this message translates to:
  /// **'画像を置き換えました（古い画像は自動削除されました）'**
  String get imageReplacedMessage;

  /// No description provided for @imageLoadFailedMessage.
  ///
  /// In ja, this message translates to:
  /// **'画像の読み込みに失敗しました'**
  String get imageLoadFailedMessage;

  /// No description provided for @uploadDateTimeLabel.
  ///
  /// In ja, this message translates to:
  /// **'アップロード日時'**
  String get uploadDateTimeLabel;

  /// No description provided for @replaceAllLabel.
  ///
  /// In ja, this message translates to:
  /// **'全て置換'**
  String get replaceAllLabel;

  /// No description provided for @noEvidenceImagesDescription.
  ///
  /// In ja, this message translates to:
  /// **'「画像を追加」ボタンから画像をアップロードできます'**
  String get noEvidenceImagesDescription;

  /// No description provided for @replaceImageDialogDescription.
  ///
  /// In ja, this message translates to:
  /// **'古い画像は自動的に削除され、新しい画像に置き換わります'**
  String get replaceImageDialogDescription;

  /// No description provided for @imageLoadErrorSimple.
  ///
  /// In ja, this message translates to:
  /// **'画像の読み込みに失敗しました'**
  String get imageLoadErrorSimple;

  /// No description provided for @evidenceImageDescription.
  ///
  /// In ja, this message translates to:
  /// **'試合の証拠となる画像をアップロードできます'**
  String get evidenceImageDescription;

  /// No description provided for @eventDeletionConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'イベント削除確認'**
  String get eventDeletionConfirmTitle;

  /// No description provided for @warningLabel.
  ///
  /// In ja, this message translates to:
  /// **'注意'**
  String get warningLabel;

  /// No description provided for @deleteDraftEventMessage.
  ///
  /// In ja, this message translates to:
  /// **'この下書きイベントを完全に削除します。'**
  String get deleteDraftEventMessage;

  /// No description provided for @deleteEventMessage.
  ///
  /// In ja, this message translates to:
  /// **'このイベントを完全に削除します。'**
  String get deleteEventMessage;

  /// No description provided for @confirmDeletionCheckbox.
  ///
  /// In ja, this message translates to:
  /// **'このイベントを削除することを確認しました'**
  String get confirmDeletionCheckbox;

  /// No description provided for @deletingText.
  ///
  /// In ja, this message translates to:
  /// **'削除中...'**
  String get deletingText;

  /// No description provided for @deleteEventButton.
  ///
  /// In ja, this message translates to:
  /// **'イベントを削除する'**
  String get deleteEventButton;

  /// No description provided for @eventDeletedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'イベントを削除しました'**
  String get eventDeletedSuccess;

  /// No description provided for @eventDeleteFailed.
  ///
  /// In ja, this message translates to:
  /// **'イベント削除に失敗しました。再度お試しください。'**
  String get eventDeleteFailed;

  /// No description provided for @matchInfoTab.
  ///
  /// In ja, this message translates to:
  /// **'試合情報'**
  String get matchInfoTab;

  /// No description provided for @problemReportTab.
  ///
  /// In ja, this message translates to:
  /// **'問題報告'**
  String get problemReportTab;

  /// No description provided for @winnerWithDraw.
  ///
  /// In ja, this message translates to:
  /// **'引き分け'**
  String get winnerWithDraw;

  /// No description provided for @waitingResultInput.
  ///
  /// In ja, this message translates to:
  /// **'結果入力待ち'**
  String get waitingResultInput;

  /// No description provided for @scheduledMatchStatus.
  ///
  /// In ja, this message translates to:
  /// **'開催予定'**
  String get scheduledMatchStatus;

  /// No description provided for @rankingTitle.
  ///
  /// In ja, this message translates to:
  /// **'順位'**
  String get rankingTitle;

  /// No description provided for @scoresTitle.
  ///
  /// In ja, this message translates to:
  /// **'スコア'**
  String get scoresTitle;

  /// No description provided for @individualScoresTitle.
  ///
  /// In ja, this message translates to:
  /// **'個人スコア'**
  String get individualScoresTitle;

  /// No description provided for @resultInputButton.
  ///
  /// In ja, this message translates to:
  /// **'結果入力'**
  String get resultInputButton;

  /// No description provided for @resultEditButton.
  ///
  /// In ja, this message translates to:
  /// **'結果編集'**
  String get resultEditButton;

  /// No description provided for @publicNoteSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'参加者に公開される運営メモです'**
  String get publicNoteSubtitle;

  /// No description provided for @privateNoteSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'内部管理用のメモです（参加者には表示されません）'**
  String get privateNoteSubtitle;

  /// No description provided for @noParticipantsLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者: なし'**
  String get noParticipantsLabel;

  /// No description provided for @reporterWithColon.
  ///
  /// In ja, this message translates to:
  /// **'報告者: '**
  String get reporterWithColon;

  /// No description provided for @viewDetailsButton.
  ///
  /// In ja, this message translates to:
  /// **'詳細を確認'**
  String get viewDetailsButton;

  /// No description provided for @adminResponseTitle.
  ///
  /// In ja, this message translates to:
  /// **'運営対応'**
  String get adminResponseTitle;

  /// No description provided for @validationEmailRequired.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを入力してください'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In ja, this message translates to:
  /// **'パスワードを入力してください'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordConfirmRequired.
  ///
  /// In ja, this message translates to:
  /// **'パスワード確認を入力してください'**
  String get validationPasswordConfirmRequired;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが一致しません'**
  String get validationPasswordMismatch;

  /// No description provided for @validationFieldRequiredDefault.
  ///
  /// In ja, this message translates to:
  /// **'この項目は必須です'**
  String get validationFieldRequiredDefault;

  /// No description provided for @validationEventNameMinLength.
  ///
  /// In ja, this message translates to:
  /// **'イベント名は3文字以上で入力してください'**
  String get validationEventNameMinLength;

  /// No description provided for @validationEventNameMaxLength.
  ///
  /// In ja, this message translates to:
  /// **'イベント名は100文字以内で入力してください'**
  String get validationEventNameMaxLength;

  /// No description provided for @validationEventNameForbiddenChars.
  ///
  /// In ja, this message translates to:
  /// **'イベント名に使用できない文字が含まれています'**
  String get validationEventNameForbiddenChars;

  /// No description provided for @validationEventDescriptionMinLength.
  ///
  /// In ja, this message translates to:
  /// **'イベント説明は10文字以上で入力してください'**
  String get validationEventDescriptionMinLength;

  /// No description provided for @validationEventDescriptionMaxLength.
  ///
  /// In ja, this message translates to:
  /// **'イベント説明は2000文字以内で入力してください'**
  String get validationEventDescriptionMaxLength;

  /// No description provided for @validationEventRulesRequired.
  ///
  /// In ja, this message translates to:
  /// **'イベントルールを入力してください'**
  String get validationEventRulesRequired;

  /// No description provided for @validationEventRulesMinLength.
  ///
  /// In ja, this message translates to:
  /// **'イベントルールは5文字以上で入力してください'**
  String get validationEventRulesMinLength;

  /// No description provided for @validationEventRulesMaxLength.
  ///
  /// In ja, this message translates to:
  /// **'イベントルールは1000文字以内で入力してください'**
  String get validationEventRulesMaxLength;

  /// No description provided for @validationNumberRequired.
  ///
  /// In ja, this message translates to:
  /// **'数値を入力してください'**
  String get validationNumberRequired;

  /// No description provided for @validationMaxParticipantsMin.
  ///
  /// In ja, this message translates to:
  /// **'最大参加者数は2人以上で設定してください'**
  String get validationMaxParticipantsMin;

  /// No description provided for @validationMaxParticipantsMax.
  ///
  /// In ja, this message translates to:
  /// **'最大参加者数は10,000人以下で設定してください'**
  String get validationMaxParticipantsMax;

  /// No description provided for @validationParticipationFeeRequired.
  ///
  /// In ja, this message translates to:
  /// **'参加費を入力してください'**
  String get validationParticipationFeeRequired;

  /// No description provided for @validationParticipationFeeMaxLength.
  ///
  /// In ja, this message translates to:
  /// **'参加費は100文字以内で入力してください'**
  String get validationParticipationFeeMaxLength;

  /// No description provided for @validationForbiddenChars.
  ///
  /// In ja, this message translates to:
  /// **'使用できない文字が含まれています'**
  String get validationForbiddenChars;

  /// No description provided for @validationImageRequired.
  ///
  /// In ja, this message translates to:
  /// **'画像を選択してください'**
  String get validationImageRequired;

  /// No description provided for @validationImageSizeMax.
  ///
  /// In ja, this message translates to:
  /// **'画像ファイルサイズは10MB以下にしてください'**
  String get validationImageSizeMax;

  /// No description provided for @validationEventTagsRequired.
  ///
  /// In ja, this message translates to:
  /// **'イベントタグを少なくとも1つ追加してください'**
  String get validationEventTagsRequired;

  /// No description provided for @validationEventTagsMaxCount.
  ///
  /// In ja, this message translates to:
  /// **'イベントタグは10個以下で設定してください'**
  String get validationEventTagsMaxCount;

  /// No description provided for @validationTagEmpty.
  ///
  /// In ja, this message translates to:
  /// **'空のタグは使用できません'**
  String get validationTagEmpty;

  /// No description provided for @validationTagMaxLength.
  ///
  /// In ja, this message translates to:
  /// **'タグは20文字以内で設定してください'**
  String get validationTagMaxLength;

  /// No description provided for @validationTagForbiddenChars.
  ///
  /// In ja, this message translates to:
  /// **'タグに使用できない文字が含まれています'**
  String get validationTagForbiddenChars;

  /// No description provided for @validationTagInvalidChars.
  ///
  /// In ja, this message translates to:
  /// **'タグは英数字、ひらがな、カタカナ、漢字、一部記号のみ使用可能です'**
  String get validationTagInvalidChars;

  /// No description provided for @validationTagDuplicate.
  ///
  /// In ja, this message translates to:
  /// **'重複するタグは使用できません'**
  String get validationTagDuplicate;

  /// No description provided for @validationPhoneRequired.
  ///
  /// In ja, this message translates to:
  /// **'電話番号を入力してください'**
  String get validationPhoneRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In ja, this message translates to:
  /// **'電話番号の形式が正しくありません'**
  String get validationPhoneInvalid;

  /// No description provided for @validationEventPasswordRequired.
  ///
  /// In ja, this message translates to:
  /// **'イベントパスワードを設定してください'**
  String get validationEventPasswordRequired;

  /// No description provided for @validationEventPasswordMinLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは4文字以上で設定してください'**
  String get validationEventPasswordMinLength;

  /// No description provided for @validationEventPasswordMaxLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは20文字以内で設定してください'**
  String get validationEventPasswordMaxLength;

  /// No description provided for @validationEventPasswordInvalidChars.
  ///
  /// In ja, this message translates to:
  /// **'パスワードには英数字と一般的な記号のみ使用できます'**
  String get validationEventPasswordInvalidChars;

  /// No description provided for @participantMatchYourMatch.
  ///
  /// In ja, this message translates to:
  /// **'あなたの試合'**
  String get participantMatchYourMatch;

  /// No description provided for @participantMatchInfoTitle.
  ///
  /// In ja, this message translates to:
  /// **'試合情報'**
  String get participantMatchInfoTitle;

  /// No description provided for @participantMatchFormatLabel.
  ///
  /// In ja, this message translates to:
  /// **'形式'**
  String get participantMatchFormatLabel;

  /// No description provided for @participantMatchTeamLabel.
  ///
  /// In ja, this message translates to:
  /// **'チーム'**
  String get participantMatchTeamLabel;

  /// No description provided for @participantMatchParticipantsLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者'**
  String get participantMatchParticipantsLabel;

  /// No description provided for @participantMatchWinnerLabel.
  ///
  /// In ja, this message translates to:
  /// **'勝者'**
  String get participantMatchWinnerLabel;

  /// No description provided for @participantMatchAdminNoticeTitle.
  ///
  /// In ja, this message translates to:
  /// **'運営からのお知らせ'**
  String get participantMatchAdminNoticeTitle;

  /// No description provided for @participantMatchAdminNoticeDesc.
  ///
  /// In ja, this message translates to:
  /// **'運営側からの重要な情報です'**
  String get participantMatchAdminNoticeDesc;

  /// No description provided for @participantMatchYourReportStatus.
  ///
  /// In ja, this message translates to:
  /// **'あなたの報告状況'**
  String get participantMatchYourReportStatus;

  /// No description provided for @participantMatchAdminResponse.
  ///
  /// In ja, this message translates to:
  /// **'運営回答'**
  String get participantMatchAdminResponse;

  /// No description provided for @participantMatchEvidenceDesc.
  ///
  /// In ja, this message translates to:
  /// **'運営がアップロードした試合の証拠画像です'**
  String get participantMatchEvidenceDesc;

  /// No description provided for @participantMatchReportProblemTitle.
  ///
  /// In ja, this message translates to:
  /// **'問題の報告'**
  String get participantMatchReportProblemTitle;

  /// No description provided for @participantMatchReportProblemDesc.
  ///
  /// In ja, this message translates to:
  /// **'試合結果に誤りがある場合は運営に報告できます'**
  String get participantMatchReportProblemDesc;

  /// No description provided for @participantMatchReportProblemButton.
  ///
  /// In ja, this message translates to:
  /// **'問題を報告する'**
  String get participantMatchReportProblemButton;

  /// No description provided for @participantMatchReportDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'問題を報告'**
  String get participantMatchReportDialogTitle;

  /// No description provided for @participantMatchIssueTypeTitle.
  ///
  /// In ja, this message translates to:
  /// **'問題の種類'**
  String get participantMatchIssueTypeTitle;

  /// No description provided for @participantMatchDetailDescHint.
  ///
  /// In ja, this message translates to:
  /// **'問題の詳細を説明してください...'**
  String get participantMatchDetailDescHint;

  /// No description provided for @participantMatchSubmitReport.
  ///
  /// In ja, this message translates to:
  /// **'報告する'**
  String get participantMatchSubmitReport;

  /// No description provided for @participantMatchEnterDetailDesc.
  ///
  /// In ja, this message translates to:
  /// **'詳細説明を入力してください'**
  String get participantMatchEnterDetailDesc;

  /// No description provided for @participantMatchReportSuccess.
  ///
  /// In ja, this message translates to:
  /// **'問題を報告しました。運営が確認次第対応いたします。'**
  String get participantMatchReportSuccess;

  /// No description provided for @participantMatchIssueScoreError.
  ///
  /// In ja, this message translates to:
  /// **'スコア誤り'**
  String get participantMatchIssueScoreError;

  /// No description provided for @participantMatchIssueWinnerError.
  ///
  /// In ja, this message translates to:
  /// **'勝者判定誤り'**
  String get participantMatchIssueWinnerError;

  /// No description provided for @participantMatchIssueParticipantError.
  ///
  /// In ja, this message translates to:
  /// **'参加者誤り'**
  String get participantMatchIssueParticipantError;

  /// No description provided for @participantMatchIssueStatusError.
  ///
  /// In ja, this message translates to:
  /// **'試合ステータス誤り'**
  String get participantMatchIssueStatusError;

  /// No description provided for @participantMatchIssueOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get participantMatchIssueOther;

  /// No description provided for @recordMethodLabel.
  ///
  /// In ja, this message translates to:
  /// **'記録方式'**
  String get recordMethodLabel;

  /// No description provided for @scoreSystemLabel.
  ///
  /// In ja, this message translates to:
  /// **'スコア制'**
  String get scoreSystemLabel;

  /// No description provided for @rankingSystemLabel.
  ///
  /// In ja, this message translates to:
  /// **'順位制'**
  String get rankingSystemLabel;

  /// No description provided for @winLossSystemLabel.
  ///
  /// In ja, this message translates to:
  /// **'勝敗制'**
  String get winLossSystemLabel;

  /// No description provided for @scoreSystemDesc.
  ///
  /// In ja, this message translates to:
  /// **'各参加者のスコアを記録'**
  String get scoreSystemDesc;

  /// No description provided for @rankingSystemDesc.
  ///
  /// In ja, this message translates to:
  /// **'各参加者の順位を記録（1位、2位、3位...）'**
  String get rankingSystemDesc;

  /// No description provided for @winLossSystemDesc.
  ///
  /// In ja, this message translates to:
  /// **'各参加者の勝敗を記録'**
  String get winLossSystemDesc;

  /// No description provided for @resultLabel.
  ///
  /// In ja, this message translates to:
  /// **'結果'**
  String get resultLabel;

  /// No description provided for @groupInfoLoadError.
  ///
  /// In ja, this message translates to:
  /// **'グループ情報の読み込みに失敗しました'**
  String get groupInfoLoadError;

  /// No description provided for @drawerVersion.
  ///
  /// In ja, this message translates to:
  /// **'バージョン {version}'**
  String drawerVersion(Object version);

  /// No description provided for @idLabel.
  ///
  /// In ja, this message translates to:
  /// **'ID: {userId}'**
  String idLabel(Object userId);

  /// No description provided for @copiedUserId.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーID \"{userId}\" をコピーしました'**
  String copiedUserId(Object userId);

  /// No description provided for @settingsSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'設定の保存に失敗しました: {error}'**
  String settingsSaveFailed(Object error);

  /// No description provided for @eventCancellationReason.
  ///
  /// In ja, this message translates to:
  /// **'理由: {reason}'**
  String eventCancellationReason(Object reason);

  /// No description provided for @eventCoinReward.
  ///
  /// In ja, this message translates to:
  /// **'{amount}コイン'**
  String eventCoinReward(Object amount);

  /// No description provided for @eventGemReward.
  ///
  /// In ja, this message translates to:
  /// **'{amount}ジェム'**
  String eventGemReward(Object amount);

  /// No description provided for @eventExpReward.
  ///
  /// In ja, this message translates to:
  /// **'{amount}経験値'**
  String eventExpReward(Object amount);

  /// No description provided for @eventParticipants.
  ///
  /// In ja, this message translates to:
  /// **'{current}/{max}人'**
  String eventParticipants(Object current, Object max);

  /// No description provided for @eventDaysRemaining.
  ///
  /// In ja, this message translates to:
  /// **'残り{days}日'**
  String eventDaysRemaining(Object days);

  /// No description provided for @eventDateTime.
  ///
  /// In ja, this message translates to:
  /// **'開催日時: {date} {time}'**
  String eventDateTime(Object date, Object time);

  /// No description provided for @eventDaysUntilStart.
  ///
  /// In ja, this message translates to:
  /// **'開始まで{days}日'**
  String eventDaysUntilStart(Object days);

  /// No description provided for @pendingReportsCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String pendingReportsCount(Object count);

  /// No description provided for @resolvedReportsCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String resolvedReportsCount(Object count);

  /// No description provided for @userInfoFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の取得に失敗しました: {error}'**
  String userInfoFetchFailed(Object error);

  /// No description provided for @eventListFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'イベント一覧の取得に失敗しました: {error}'**
  String eventListFetchFailed(Object error);

  /// No description provided for @eventNameCopySuffix.
  ///
  /// In ja, this message translates to:
  /// **'{eventName}のコピー'**
  String eventNameCopySuffix(Object eventName);

  /// No description provided for @eventCopied.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」をコピーしました'**
  String eventCopied(Object eventName);

  /// No description provided for @eventCopyFailed.
  ///
  /// In ja, this message translates to:
  /// **'イベントのコピーに失敗しました: {error}'**
  String eventCopyFailed(Object error);

  /// No description provided for @mutualFollowTabCount.
  ///
  /// In ja, this message translates to:
  /// **'相互フォロー ({count})'**
  String mutualFollowTabCount(int count);

  /// No description provided for @followingTabCount.
  ///
  /// In ja, this message translates to:
  /// **'フォロー中 ({count})'**
  String followingTabCount(int count);

  /// No description provided for @followersTabCount.
  ///
  /// In ja, this message translates to:
  /// **'フォロワー ({count})'**
  String followersTabCount(int count);

  /// No description provided for @dataFetchFailedWithError.
  ///
  /// In ja, this message translates to:
  /// **'データの取得に失敗しました: {error}'**
  String dataFetchFailedWithError(String error);

  /// No description provided for @gameCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}個'**
  String gameCount(int count);

  /// No description provided for @gameProfileConfigured.
  ///
  /// In ja, this message translates to:
  /// **'{configured}/{total} ゲーム設定済み'**
  String gameProfileConfigured(int configured, int total);

  /// No description provided for @lastUpdated.
  ///
  /// In ja, this message translates to:
  /// **'更新: {date}'**
  String lastUpdated(String date);

  /// No description provided for @daysAgo.
  ///
  /// In ja, this message translates to:
  /// **'{count}日前'**
  String daysAgo(int count);

  /// No description provided for @deleteSelectedGamesConfirm.
  ///
  /// In ja, this message translates to:
  /// **'以下の{count}つのゲームをお気に入りから削除しますか？'**
  String deleteSelectedGamesConfirm(int count);

  /// No description provided for @gamesDeleted.
  ///
  /// In ja, this message translates to:
  /// **'{count}つのゲームを削除しました'**
  String gamesDeleted(int count);

  /// No description provided for @deleteFailed.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました: {error}'**
  String deleteFailed(String error);

  /// No description provided for @versionLabel.
  ///
  /// In ja, this message translates to:
  /// **'バージョン {version}'**
  String versionLabel(String version);

  /// No description provided for @signOutFailed.
  ///
  /// In ja, this message translates to:
  /// **'サインアウトに失敗しました: {error}'**
  String signOutFailed(String error);

  /// No description provided for @failedToOpenPage.
  ///
  /// In ja, this message translates to:
  /// **'{page}のページを開けませんでした。'**
  String failedToOpenPage(String page);

  /// No description provided for @errorOpeningPage.
  ///
  /// In ja, this message translates to:
  /// **'{page}のページを開く際にエラーが発生しました。'**
  String errorOpeningPage(String page);

  /// No description provided for @hoursAgo.
  ///
  /// In ja, this message translates to:
  /// **'{count}時間前'**
  String hoursAgo(int count);

  /// No description provided for @minutesAgo.
  ///
  /// In ja, this message translates to:
  /// **'{count}分前'**
  String minutesAgo(int count);

  /// No description provided for @errorWithDetails.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @responseFromOrganizer.
  ///
  /// In ja, this message translates to:
  /// **'\\n\\n運営からの回答:\\n{response}'**
  String responseFromOrganizer(String response);

  /// No description provided for @homeErrorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました\\n{error}'**
  String homeErrorOccurred(Object error);

  /// No description provided for @searchHint.
  ///
  /// In ja, this message translates to:
  /// **'{searchType}を検索...'**
  String searchHint(String searchType);

  /// No description provided for @relatedEventsTitle.
  ///
  /// In ja, this message translates to:
  /// **'{gameName}の関連イベント'**
  String relatedEventsTitle(String gameName);

  /// No description provided for @userSearchErrorPrefix.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー検索中にエラーが発生しました: {error}'**
  String userSearchErrorPrefix(String error);

  /// No description provided for @gameSearchErrorPrefix.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム検索中にエラーが発生しました: {error}'**
  String gameSearchErrorPrefix(String error);

  /// No description provided for @eventSearchErrorPrefix.
  ///
  /// In ja, this message translates to:
  /// **'イベント検索でエラーが発生しました: {error}'**
  String eventSearchErrorPrefix(String error);

  /// No description provided for @searchByTypeHint.
  ///
  /// In ja, this message translates to:
  /// **'{searchType}名で検索できます'**
  String searchByTypeHint(String searchType);

  /// No description provided for @userNotFoundWithQuery.
  ///
  /// In ja, this message translates to:
  /// **'「{query}」に一致する\\nユーザーが見つかりませんでした'**
  String userNotFoundWithQuery(String query);

  /// No description provided for @gameNotFoundWithQuery.
  ///
  /// In ja, this message translates to:
  /// **'「{query}」に一致する\\nゲームが見つかりませんでした'**
  String gameNotFoundWithQuery(String query);

  /// No description provided for @eventNotFoundWithQuery.
  ///
  /// In ja, this message translates to:
  /// **'「{query}」に一致する\\nパブリックイベントが見つかりませんでした'**
  String eventNotFoundWithQuery(String query);

  /// No description provided for @eventCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'{count}件のイベント'**
  String eventCountLabel(int count);

  /// No description provided for @allGamesFilter.
  ///
  /// In ja, this message translates to:
  /// **'すべて ({count})'**
  String allGamesFilter(int count);

  /// No description provided for @filteredEventCount.
  ///
  /// In ja, this message translates to:
  /// **'{filtered}件のイベント（全{total}件中）'**
  String filteredEventCount(int filtered, int total);

  /// No description provided for @editProfileDescription.
  ///
  /// In ja, this message translates to:
  /// **'{gameName} のプロフィール情報を変更できます'**
  String editProfileDescription(String gameName);

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In ja, this message translates to:
  /// **'{gameName} のプロフィールを削除しますか？\\n\\nお気に入りゲームからも削除されます。\\n\\nこの操作は元に戻せません。'**
  String deleteProfileConfirm(String gameName);

  /// No description provided for @gameSearchFailed.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム検索に失敗しました: {error}'**
  String gameSearchFailed(String error);

  /// No description provided for @profileFetchError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報の取得に失敗しました: {error}'**
  String profileFetchError(Object error);

  /// No description provided for @profileErrorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String profileErrorOccurred(Object error);

  /// No description provided for @imageSelectionFailed.
  ///
  /// In ja, this message translates to:
  /// **'画像の選択に失敗しました: {error}'**
  String imageSelectionFailed(String error);

  /// No description provided for @welcomeUserName.
  ///
  /// In ja, this message translates to:
  /// **'{userName} さん'**
  String welcomeUserName(String userName);

  /// No description provided for @imageUploadFailed.
  ///
  /// In ja, this message translates to:
  /// **'画像のアップロードに失敗しました: {error}'**
  String imageUploadFailed(String error);

  /// No description provided for @initialSetupSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'初期設定の保存に失敗しました\\n\\n{error}'**
  String initialSetupSaveFailed(String error);

  /// No description provided for @settingsSaveFailedWithError.
  ///
  /// In ja, this message translates to:
  /// **'設定の保存に失敗しました\\n\\n{error}'**
  String settingsSaveFailedWithError(String error);

  /// No description provided for @shareFailed.
  ///
  /// In ja, this message translates to:
  /// **'共有に失敗しました: {error}'**
  String shareFailed(String error);

  /// No description provided for @cancelledDateTime.
  ///
  /// In ja, this message translates to:
  /// **'中止日時: {dateTime}'**
  String cancelledDateTime(String dateTime);

  /// No description provided for @feeAmountYen.
  ///
  /// In ja, this message translates to:
  /// **'{amount}円'**
  String feeAmountYen(int amount);

  /// No description provided for @ageRestriction.
  ///
  /// In ja, this message translates to:
  /// **'{age}歳以上'**
  String ageRestriction(int age);

  /// No description provided for @applicationDate.
  ///
  /// In ja, this message translates to:
  /// **'申し込み日: {date}'**
  String applicationDate(String date);

  /// No description provided for @waitlistPosition.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ち {position}番目'**
  String waitlistPosition(int position);

  /// No description provided for @rejectionReason.
  ///
  /// In ja, this message translates to:
  /// **'理由: {reason}'**
  String rejectionReason(String reason);

  /// No description provided for @cancelledAt.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル日時: {dateTime}'**
  String cancelledAt(String dateTime);

  /// No description provided for @cancellationReasonLabel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル理由: {reason}'**
  String cancellationReasonLabel(String reason);

  /// No description provided for @waitlistCancelFailed.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちの取り消しに失敗しました: {error}'**
  String waitlistCancelFailed(String error);

  /// No description provided for @cancelError.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル中にエラーが発生しました: {error}'**
  String cancelError(String error);

  /// No description provided for @pastImageLoadError.
  ///
  /// In ja, this message translates to:
  /// **'過去の画像の読み込みでエラーが発生しました: {error}'**
  String pastImageLoadError(String error);

  /// No description provided for @exampleHint.
  ///
  /// In ja, this message translates to:
  /// **'例：{example}'**
  String exampleHint(String example);

  /// No description provided for @participantCountCheckFailed.
  ///
  /// In ja, this message translates to:
  /// **'参加者数の確認に失敗しました: {error}'**
  String participantCountCheckFailed(String error);

  /// No description provided for @currentParticipantCount.
  ///
  /// In ja, this message translates to:
  /// **'現在の参加者数: {current}/{max}人'**
  String currentParticipantCount(int current, int max);

  /// No description provided for @participantExistsWarning.
  ///
  /// In ja, this message translates to:
  /// **'現在{count}名の参加者がいるため、変更には慎重な検討が必要です。'**
  String participantExistsWarning(int count);

  /// No description provided for @cannotRevertWithParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者が{count}人いるため、イベントを下書きに戻すことはできません。'**
  String cannotRevertWithParticipants(int count);

  /// No description provided for @errorLabel.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String errorLabel(String error);

  /// No description provided for @applicationDateTime.
  ///
  /// In ja, this message translates to:
  /// **'申請日時: {dateTime}'**
  String applicationDateTime(String dateTime);

  /// No description provided for @messageLabel.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ: {message}'**
  String messageLabel(String message);

  /// No description provided for @rejectionReasonLabel.
  ///
  /// In ja, this message translates to:
  /// **'拒否理由: {reason}'**
  String rejectionReasonLabel(String reason);

  /// No description provided for @userCancelledParticipation.
  ///
  /// In ja, this message translates to:
  /// **'{userName}さんがキャンセルしました'**
  String userCancelledParticipation(String userName);

  /// No description provided for @cancellationDateTimeLabel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル日時: {dateTime}'**
  String cancellationDateTimeLabel(String dateTime);

  /// No description provided for @capacityExceededMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベントが満員です（現在 {current}/{max}人）。\\n\\n承認済み参加者が辞退してから、再度承認してください。'**
  String capacityExceededMessage(int current, int max);

  /// No description provided for @memberCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}名のメンバー'**
  String memberCount(int count);

  /// No description provided for @groupMemberCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}名のグループ'**
  String groupMemberCount(int count);

  /// No description provided for @membersLabel.
  ///
  /// In ja, this message translates to:
  /// **'メンバー ({count}名)'**
  String membersLabel(int count);

  /// No description provided for @participantInfoLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'参加者情報の読み込みに失敗しました: {error}'**
  String participantInfoLoadFailed(Object error);

  /// No description provided for @personCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}名'**
  String personCount(int count);

  /// No description provided for @winner.
  ///
  /// In ja, this message translates to:
  /// **'勝者: {name}'**
  String winner(String name);

  /// No description provided for @points.
  ///
  /// In ja, this message translates to:
  /// **'{value}点'**
  String points(int value);

  /// No description provided for @cancellationErrorWithMessage.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル中にエラーが発生しました: {error}'**
  String cancellationErrorWithMessage(String error);

  /// No description provided for @unassignedParticipantsWarning.
  ///
  /// In ja, this message translates to:
  /// **'{count}名の承認済み参加者が\\nグループ未割り当てです'**
  String unassignedParticipantsWarning(int count);

  /// No description provided for @unassignedParticipantsTitle.
  ///
  /// In ja, this message translates to:
  /// **'未割り当て参加者 ({count})'**
  String unassignedParticipantsTitle(int count);

  /// No description provided for @participantsCount.
  ///
  /// In ja, this message translates to:
  /// **'参加者: {count}名'**
  String participantsCount(int count);

  /// No description provided for @selectGroupToAddParticipant.
  ///
  /// In ja, this message translates to:
  /// **'{name}を追加するグループ'**
  String selectGroupToAddParticipant(String name);

  /// No description provided for @membersCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}人'**
  String membersCount(int count);

  /// No description provided for @participantRemovedFromGroup.
  ///
  /// In ja, this message translates to:
  /// **'{participantName}を{groupName}から削除しました'**
  String participantRemovedFromGroup(String participantName, String groupName);

  /// No description provided for @participantAddedToGroup.
  ///
  /// In ja, this message translates to:
  /// **'{participantName}を{groupName}に追加しました'**
  String participantAddedToGroup(String participantName, String groupName);

  /// No description provided for @addMemberToGroup.
  ///
  /// In ja, this message translates to:
  /// **'{groupName}にメンバーを追加'**
  String addMemberToGroup(String groupName);

  /// No description provided for @failedToUpdateGeneralAnnouncements.
  ///
  /// In ja, this message translates to:
  /// **'全体連絡事項の更新に失敗しました: {error}'**
  String failedToUpdateGeneralAnnouncements(String error);

  /// No description provided for @groupCreated.
  ///
  /// In ja, this message translates to:
  /// **'グループ「{name}」を作成しました'**
  String groupCreated(String name);

  /// No description provided for @failedToCreateGroupWithError.
  ///
  /// In ja, this message translates to:
  /// **'グループの作成に失敗しました: {error}'**
  String failedToCreateGroupWithError(String error);

  /// No description provided for @groupUpdated.
  ///
  /// In ja, this message translates to:
  /// **'グループ「{name}」を更新しました'**
  String groupUpdated(String name);

  /// No description provided for @failedToUpdateGroupWithError.
  ///
  /// In ja, this message translates to:
  /// **'グループの更新に失敗しました: {error}'**
  String failedToUpdateGroupWithError(String error);

  /// No description provided for @groupHasRelatedMatches.
  ///
  /// In ja, this message translates to:
  /// **'「{groupName}」は{matchCount}件の戦績データに関連付けられています。'**
  String groupHasRelatedMatches(String groupName, int matchCount);

  /// No description provided for @deleteGroupConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を削除しますか？\\nこの操作は取り消せません。'**
  String deleteGroupConfirmation(String name);

  /// No description provided for @groupDeleted.
  ///
  /// In ja, this message translates to:
  /// **'グループ「{name}」を削除しました'**
  String groupDeleted(String name);

  /// No description provided for @failedToLoadParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者の読み込みに失敗しました: {error}'**
  String failedToLoadParticipants(Object error);

  /// No description provided for @failedToLoadData.
  ///
  /// In ja, this message translates to:
  /// **'データの読み込みに失敗しました: {error}'**
  String failedToLoadData(Object error);

  /// No description provided for @confirmReportsCount.
  ///
  /// In ja, this message translates to:
  /// **'問題報告を確認 ({count}件)'**
  String confirmReportsCount(Object count);

  /// No description provided for @winnerLabel.
  ///
  /// In ja, this message translates to:
  /// **'勝者: {winner}'**
  String winnerLabel(Object winner);

  /// No description provided for @matchRegisteredMessage.
  ///
  /// In ja, this message translates to:
  /// **'試合「{name}」を登録しました'**
  String matchRegisteredMessage(Object name);

  /// No description provided for @failedToRegisterMatch.
  ///
  /// In ja, this message translates to:
  /// **'試合の登録に失敗しました: {error}'**
  String failedToRegisterMatch(Object error);

  /// No description provided for @failedToSaveMatchResult.
  ///
  /// In ja, this message translates to:
  /// **'試合結果の保存に失敗しました: {error}'**
  String failedToSaveMatchResult(Object error);

  /// No description provided for @statusChangedMessage.
  ///
  /// In ja, this message translates to:
  /// **'ステータスを「{status}」に変更しました'**
  String statusChangedMessage(Object status);

  /// No description provided for @failedToChangeStatus.
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更に失敗しました: {error}'**
  String failedToChangeStatus(Object error);

  /// No description provided for @matchCreatedAtLabel.
  ///
  /// In ja, this message translates to:
  /// **'作成: {dateTime}'**
  String matchCreatedAtLabel(Object dateTime);

  /// No description provided for @matchCompletedAtLabel.
  ///
  /// In ja, this message translates to:
  /// **'完了: {dateTime}'**
  String matchCompletedAtLabel(Object dateTime);

  /// No description provided for @statusChangeFailedMessage.
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更に失敗しました: {error}'**
  String statusChangeFailedMessage(Object error);

  /// No description provided for @resultSaveFailedMessage.
  ///
  /// In ja, this message translates to:
  /// **'試合結果の保存に失敗しました: {error}'**
  String resultSaveFailedMessage(Object error);

  /// No description provided for @matchDeletedMessage.
  ///
  /// In ja, this message translates to:
  /// **'試合「{name}」を削除しました'**
  String matchDeletedMessage(Object name);

  /// No description provided for @failedToDeleteMatch.
  ///
  /// In ja, this message translates to:
  /// **'試合の削除に失敗しました: {error}'**
  String failedToDeleteMatch(Object error);

  /// No description provided for @selectStatusForMatch.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」のステータスを選択してください'**
  String selectStatusForMatch(Object name);

  /// No description provided for @deleteMatchConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」を削除しますか？'**
  String deleteMatchConfirmation(Object name);

  /// No description provided for @failedToGetViolationRecords.
  ///
  /// In ja, this message translates to:
  /// **'イベント違反記録の取得に失敗: {error}'**
  String failedToGetViolationRecords(Object error);

  /// No description provided for @failedToLoadDataError.
  ///
  /// In ja, this message translates to:
  /// **'データの取得に失敗しました: {error}'**
  String failedToLoadDataError(Object error);

  /// No description provided for @reportedAt.
  ///
  /// In ja, this message translates to:
  /// **'報告日時: {dateTime}'**
  String reportedAt(Object dateTime);

  /// No description provided for @penaltyValue.
  ///
  /// In ja, this message translates to:
  /// **'ペナルティ: {penalty}'**
  String penaltyValue(Object penalty);

  /// No description provided for @violationDetailTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反詳細 - {type}'**
  String violationDetailTitle(Object type);

  /// No description provided for @violatorLabel.
  ///
  /// In ja, this message translates to:
  /// **'違反者: {name}'**
  String violatorLabel(Object name);

  /// No description provided for @realNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'実名: {name}'**
  String realNameLabel(Object name);

  /// No description provided for @failedToProcess.
  ///
  /// In ja, this message translates to:
  /// **'処理に失敗しました: {error}'**
  String failedToProcess(Object error);

  /// No description provided for @failedToDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました: {error}'**
  String failedToDelete(Object error);

  /// No description provided for @failedToReject.
  ///
  /// In ja, this message translates to:
  /// **'却下に失敗しました: {error}'**
  String failedToReject(Object error);

  /// No description provided for @failedToGetGameProfile.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールの取得に失敗しました: {error}'**
  String failedToGetGameProfile(Object error);

  /// No description provided for @restoreViolationRecordConfirm.
  ///
  /// In ja, this message translates to:
  /// **'この違反記録を未処理状態に戻しますか？\\n現在のステータス: {status}'**
  String restoreViolationRecordConfirm(Object status);

  /// No description provided for @failedToRestore.
  ///
  /// In ja, this message translates to:
  /// **'復旧に失敗しました: {error}'**
  String failedToRestore(Object error);

  /// No description provided for @appealPeriodRemaining.
  ///
  /// In ja, this message translates to:
  /// **'異議申立期間中 - あと{hours}時間'**
  String appealPeriodRemaining(Object hours);

  /// No description provided for @deadlineLabel.
  ///
  /// In ja, this message translates to:
  /// **'期限: {dateTime}'**
  String deadlineLabel(Object dateTime);

  /// No description provided for @discordIdCopied.
  ///
  /// In ja, this message translates to:
  /// **'Discord ID「{discordId}」をコピーしました'**
  String discordIdCopied(Object discordId);

  /// No description provided for @copyFailedWithError.
  ///
  /// In ja, this message translates to:
  /// **'コピーに失敗しました: {error}'**
  String copyFailedWithError(Object error);

  /// Participant info load error
  ///
  /// In ja, this message translates to:
  /// **'参加者情報の読み込みに失敗しました: {error}'**
  String participantInfoLoadError(String error);

  /// No description provided for @errorOccurredWithDetails.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String errorOccurredWithDetails(Object error);

  /// No description provided for @currentParticipantsCount.
  ///
  /// In ja, this message translates to:
  /// **'現在{count}名が参加申込済みです'**
  String currentParticipantsCount(Object count);

  /// No description provided for @currentlyParticipantsApplied.
  ///
  /// In ja, this message translates to:
  /// **'現在{count}名が参加申込済みです'**
  String currentlyParticipantsApplied(int count);

  /// No description provided for @participantsRequireCarefulChange.
  ///
  /// In ja, this message translates to:
  /// **'現在{count}名の参加者がいるため、変更には慎重な検討が必要です。'**
  String participantsRequireCarefulChange(Object count);

  /// No description provided for @cannotRevertToDraftMessage.
  ///
  /// In ja, this message translates to:
  /// **'参加者が{count}人いるため、イベントを下書きに戻すことはできません。\\n\\n申し込み締切後の大幅な変更は参加者の混乱を招く可能性があります。'**
  String cannotRevertToDraftMessage(Object count);

  /// No description provided for @eventLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'イベントの読み込みに失敗しました: {error}'**
  String eventLoadFailed(Object error);

  /// No description provided for @monthDayFormat.
  ///
  /// In ja, this message translates to:
  /// **'{month}月{day}日'**
  String monthDayFormat(Object day, Object month);

  /// No description provided for @yearWeekdayFormat.
  ///
  /// In ja, this message translates to:
  /// **'{year}年 {weekday}'**
  String yearWeekdayFormat(Object weekday, Object year);

  /// No description provided for @yearMonthFormat.
  ///
  /// In ja, this message translates to:
  /// **'{year}年{month}月'**
  String yearMonthFormat(Object month, Object year);

  /// No description provided for @eventsOnDate.
  ///
  /// In ja, this message translates to:
  /// **'{month}月{day}日のイベント'**
  String eventsOnDate(Object day, Object month);

  /// No description provided for @participantCountFormat.
  ///
  /// In ja, this message translates to:
  /// **'{current}/{max}人'**
  String participantCountFormat(Object current, Object max);

  /// No description provided for @requiredFieldError.
  ///
  /// In ja, this message translates to:
  /// **'{field}は必須項目です'**
  String requiredFieldError(String field);

  /// No description provided for @addedAsOperatorMessage.
  ///
  /// In ja, this message translates to:
  /// **'{username}を運営者に追加しました'**
  String addedAsOperatorMessage(String username);

  /// No description provided for @eventCancellationDate.
  ///
  /// In ja, this message translates to:
  /// **'中止日: {date}'**
  String eventCancellationDate(Object date);

  /// No description provided for @eventCancellationErrorMessage.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String eventCancellationErrorMessage(Object error);

  /// No description provided for @adminMemoTitle.
  ///
  /// In ja, this message translates to:
  /// **'管理者メモ - {userName}'**
  String adminMemoTitle(String userName);

  /// No description provided for @violationStatCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String violationStatCount(Object count);

  /// No description provided for @violationLatest.
  ///
  /// In ja, this message translates to:
  /// **'最新: {type} ({date})'**
  String violationLatest(Object date, Object type);

  /// No description provided for @notificationEventVisibilityChangedMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」の公開設定がパブリックに変更されました。パスワードなしで参加申請できます。'**
  String notificationEventVisibilityChangedMessage(Object eventName);

  /// No description provided for @notificationEventApprovedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」への参加申請が承認されました。'**
  String notificationEventApprovedMessage(Object eventName);

  /// No description provided for @notificationEventApprovedWithAdminMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」への参加申請が承認されました。\\n\\n運営からのメッセージ:\\n{adminMessage}'**
  String notificationEventApprovedWithAdminMessage(
    Object adminMessage,
    Object eventName,
  );

  /// No description provided for @notificationEventRejectedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」への参加申請が拒否されました。'**
  String notificationEventRejectedMessage(Object eventName);

  /// No description provided for @notificationEventRejectedWithAdminMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」への参加申請が拒否されました。\\n\\n運営からのメッセージ:\\n{adminMessage}'**
  String notificationEventRejectedWithAdminMessage(
    Object adminMessage,
    Object eventName,
  );

  /// No description provided for @notificationEventApplicationMessage.
  ///
  /// In ja, this message translates to:
  /// **'{applicantUsername}さんが「{eventTitle}」に申込みをしました'**
  String notificationEventApplicationMessage(
    Object applicantUsername,
    Object eventTitle,
  );

  /// No description provided for @notificationViolationReportedToViolatedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」で違反の報告がありました。内容を確認し、必要に応じて異議申立を行うことができます。タップして詳細を確認してください。'**
  String notificationViolationReportedToViolatedMessage(Object eventName);

  /// No description provided for @notificationViolationReportedToOrganizerMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」で新しい違反報告がありました。管理画面で確認してください。'**
  String notificationViolationReportedToOrganizerMessage(Object eventName);

  /// No description provided for @notificationViolationProcessedResolvedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での違反報告が処理されました。'**
  String notificationViolationProcessedResolvedMessage(Object eventName);

  /// No description provided for @notificationViolationProcessedResolvedWithPenalty.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での違反報告が処理されました。\\nペナルティ: {penalty}'**
  String notificationViolationProcessedResolvedWithPenalty(
    Object eventName,
    Object penalty,
  );

  /// No description provided for @notificationViolationProcessedDismissedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での違反報告が調査の結果、却下されました。'**
  String notificationViolationProcessedDismissedMessage(Object eventName);

  /// No description provided for @notificationAppealSubmittedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」の違反報告に対する異議申立がありました。管理画面で確認してください。'**
  String notificationAppealSubmittedMessage(Object eventName);

  /// No description provided for @notificationAppealApprovedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での異議申立が承認され、違反記録が取り消されました。'**
  String notificationAppealApprovedMessage(Object eventName);

  /// No description provided for @notificationAppealRejectedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での異議申立が却下され、違反記録が維持されます。'**
  String notificationAppealRejectedMessage(Object eventName);

  /// No description provided for @notificationAppealWithResponseSuffix.
  ///
  /// In ja, this message translates to:
  /// **'\\n\\n運営からの回答:\\n{appealResponse}'**
  String notificationAppealWithResponseSuffix(Object appealResponse);

  /// No description provided for @notificationViolationDeletedToViolatedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での違反記録が運営により削除されました。'**
  String notificationViolationDeletedToViolatedMessage(Object eventName);

  /// No description provided for @notificationViolationDeletedToViolatedWithReason.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での違反記録が運営により削除されました。\\n理由: {reason}'**
  String notificationViolationDeletedToViolatedWithReason(
    Object eventName,
    Object reason,
  );

  /// No description provided for @notificationViolationDeletedToReporterMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」で報告された違反記録が運営により削除されました。'**
  String notificationViolationDeletedToReporterMessage(Object eventName);

  /// No description provided for @notificationViolationDeletedToOrganizerMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」の違反記録が削除されました。'**
  String notificationViolationDeletedToOrganizerMessage(Object eventName);

  /// No description provided for @notificationViolationDeletedToOrganizerWithReason.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」の違反記録が削除されました。\\n理由: {reason}'**
  String notificationViolationDeletedToOrganizerWithReason(
    Object eventName,
    Object reason,
  );

  /// No description provided for @notificationViolationDismissedToViolatedMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での違反記録が運営により却下されました。今後、この記録は違反として扱われません。'**
  String notificationViolationDismissedToViolatedMessage(Object eventName);

  /// No description provided for @notificationViolationDismissedToViolatedWithReason.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」での違反記録が運営により却下されました。今後、この記録は違反として扱われません。\\n理由: {reason}'**
  String notificationViolationDismissedToViolatedWithReason(
    Object eventName,
    Object reason,
  );

  /// No description provided for @notificationViolationDismissedToReporterMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」で報告された違反記録が運営により却下されました。調査の結果、違反に該当しないと判断されました。'**
  String notificationViolationDismissedToReporterMessage(Object eventName);

  /// No description provided for @notificationViolationDismissedToOrganizerMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」の違反記録が却下されました。'**
  String notificationViolationDismissedToOrganizerMessage(Object eventName);

  /// No description provided for @notificationViolationDismissedToOrganizerWithReason.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」の違反記録が却下されました。\\n理由: {reason}'**
  String notificationViolationDismissedToOrganizerWithReason(
    Object eventName,
    Object reason,
  );

  /// No description provided for @notificationEventCancellationApprovedMessage.
  ///
  /// In ja, this message translates to:
  /// **'参加が確定していたイベント「{eventName}」が主催者の都合により中止となりました。\\n\\n中止理由:\\n{reason}'**
  String notificationEventCancellationApprovedMessage(
    Object eventName,
    Object reason,
  );

  /// No description provided for @notificationEventCancellationPendingMessage.
  ///
  /// In ja, this message translates to:
  /// **'参加申込みをされていたイベント「{eventName}」が主催者の都合により中止となりました。\\n\\n中止理由:\\n{reason}'**
  String notificationEventCancellationPendingMessage(
    Object eventName,
    Object reason,
  );

  /// No description provided for @notificationEventCancellationManagerMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」の中止処理が完了しました。\\n\\n参加確定者: {participantCount}人\\n申込み待ち: {pendingCount}人\\n\\n全ての関係者に通知を送信しました。\\n\\n中止理由:\\n{reason}'**
  String notificationEventCancellationManagerMessage(
    Object eventName,
    Object participantCount,
    Object pendingCount,
    Object reason,
  );

  /// No description provided for @notificationEventReminderMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」が{timeText}に開始されます。'**
  String notificationEventReminderMessage(Object eventName, Object timeText);

  /// No description provided for @notificationEventReminderTimeHours.
  ///
  /// In ja, this message translates to:
  /// **'{hours}時間後'**
  String notificationEventReminderTimeHours(Object hours);

  /// No description provided for @notificationEventUpdateMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」が{updatedByUserName}により更新されました。\\n\\n変更内容：{changesSummary}\\n\\nタップして詳細を確認してください。'**
  String notificationEventUpdateMessage(
    Object changesSummary,
    Object eventName,
    Object updatedByUserName,
  );

  /// No description provided for @eventChangeSummaryCritical.
  ///
  /// In ja, this message translates to:
  /// **'重要な変更{count}件'**
  String eventChangeSummaryCritical(Object count);

  /// No description provided for @eventChangeSummaryModerate.
  ///
  /// In ja, this message translates to:
  /// **'変更{count}件'**
  String eventChangeSummaryModerate(Object count);

  /// No description provided for @eventChangeSummaryMinor.
  ///
  /// In ja, this message translates to:
  /// **'軽微な変更{count}件'**
  String eventChangeSummaryMinor(Object count);

  /// No description provided for @eventChangeDisplayFormat.
  ///
  /// In ja, this message translates to:
  /// **'{typeName}: 「{oldValue}」→「{newValue}」'**
  String eventChangeDisplayFormat(
    String typeName,
    String oldValue,
    String newValue,
  );

  /// No description provided for @eventChangeValueChanged.
  ///
  /// In ja, this message translates to:
  /// **'「{oldValue}」から「{newValue}」に変更されました'**
  String eventChangeValueChanged(String oldValue, String newValue);

  /// No description provided for @eventChangeDetailBullet.
  ///
  /// In ja, this message translates to:
  /// **'・{text}'**
  String eventChangeDetailBullet(String text);

  /// No description provided for @notificationNewFollowerMessage.
  ///
  /// In ja, this message translates to:
  /// **'{fromUserName}さんがあなたをフォローしました'**
  String notificationNewFollowerMessage(Object fromUserName);

  /// No description provided for @notificationEventDraftRevertedMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は主催者により下書き状態に変更されたため、参加が取り消されました。'**
  String notificationEventDraftRevertedMessage(Object eventName);

  /// No description provided for @notificationEventInviteMessage.
  ///
  /// In ja, this message translates to:
  /// **'{createdByName}さんが「{eventName}」に招待しました'**
  String notificationEventInviteMessage(Object createdByName, Object eventName);

  /// No description provided for @notificationEventWaitlistMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は満員となりました。あなたの申請はキャンセル待ち{waitlistPosition}番目として受付中です。参加者が辞退した場合、順番に承認いたします。'**
  String notificationEventWaitlistMessage(
    Object eventName,
    Object waitlistPosition,
  );

  /// No description provided for @notificationEventWaitlistRegisteredMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は満員のため、キャンセル待ち{waitlistPosition}番目として登録されました。参加者が辞退した場合、順番に承認いたします。'**
  String notificationEventWaitlistRegisteredMessage(
    Object eventName,
    Object waitlistPosition,
  );

  /// No description provided for @notificationEventFullMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は満員のため申込できませんでした'**
  String notificationEventFullMessage(Object eventName);

  /// No description provided for @notificationEventCapacityWarningMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」の参加者数が定員の{percentage}%に達しました（{currentCount}/{maxParticipants}人）'**
  String notificationEventCapacityWarningMessage(
    Object currentCount,
    Object eventName,
    Object maxParticipants,
    Object percentage,
  );

  /// No description provided for @notificationEventCapacityVacancyMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」で参加者の差し戻しにより空き枠が発生しました。キャンセル待ち{waitlistCount}名の承認をご検討ください。'**
  String notificationEventCapacityVacancyMessage(
    Object eventName,
    Object waitlistCount,
  );

  /// No description provided for @notificationParticipantCancelledMessage.
  ///
  /// In ja, this message translates to:
  /// **'イベント「{eventName}」で{userName}さんがキャンセルしました。\\n\\nキャンセル理由: {cancellationReason}'**
  String notificationParticipantCancelledMessage(
    Object cancellationReason,
    Object eventName,
    Object userName,
  );

  /// No description provided for @groupMemoDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'グループメモ - {groupName}'**
  String groupMemoDialogTitle(Object groupName);

  /// No description provided for @accountWithdrawalFailed.
  ///
  /// In ja, this message translates to:
  /// **'退会処理に失敗しました: {error}'**
  String accountWithdrawalFailed(Object error);

  /// No description provided for @participantDataFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'参加者データの取得に失敗しました: {error}'**
  String participantDataFetchFailed(Object error);

  /// No description provided for @imagesAvailableCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}個の画像が利用可能です'**
  String imagesAvailableCount(Object count);

  /// No description provided for @participantCountValueText.
  ///
  /// In ja, this message translates to:
  /// **'{current}/{max}人'**
  String participantCountValueText(Object current, Object max);

  /// No description provided for @mutualFollowFetchError.
  ///
  /// In ja, this message translates to:
  /// **'相互フォロー情報の取得に失敗しました: {error}'**
  String mutualFollowFetchError(Object error);

  /// No description provided for @imageProcessingError.
  ///
  /// In ja, this message translates to:
  /// **'画像の加工に失敗しました: {error}'**
  String imageProcessingError(Object error);

  /// No description provided for @daysRemainingText.
  ///
  /// In ja, this message translates to:
  /// **'残り{days}日'**
  String daysRemainingText(Object days);

  /// No description provided for @daysUntilStartText.
  ///
  /// In ja, this message translates to:
  /// **'開始まで{days}日'**
  String daysUntilStartText(Object days);

  /// No description provided for @errorFirebaseGeneric.
  ///
  /// In ja, this message translates to:
  /// **'Firebase: {message}'**
  String errorFirebaseGeneric(Object message);

  /// No description provided for @errorAuthGeneric.
  ///
  /// In ja, this message translates to:
  /// **'認証エラー: {message}'**
  String errorAuthGeneric(Object message);

  /// No description provided for @availableMutualFollowsCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}人の相互フォローから選択できます'**
  String availableMutualFollowsCount(Object count);

  /// No description provided for @paymentStatsFetchFailed.
  ///
  /// In ja, this message translates to:
  /// **'統計データの取得に失敗しました: {error}'**
  String paymentStatsFetchFailed(Object error);

  /// No description provided for @participantCountValue.
  ///
  /// In ja, this message translates to:
  /// **'{count}名'**
  String participantCountValue(Object count);

  /// No description provided for @participationFeeLabelWithAmount.
  ///
  /// In ja, this message translates to:
  /// **'参加費: ¥{amount}'**
  String participationFeeLabelWithAmount(Object amount);

  /// No description provided for @paymentEvidenceLabel.
  ///
  /// In ja, this message translates to:
  /// **'支払い証跡: {filename}'**
  String paymentEvidenceLabel(Object filename);

  /// No description provided for @paymentEvidenceDialogTitle.
  ///
  /// In ja, this message translates to:
  /// **'{name}の支払い証跡'**
  String paymentEvidenceDialogTitle(Object name);

  /// No description provided for @paymentProcessFailed.
  ///
  /// In ja, this message translates to:
  /// **'処理に失敗しました: {error}'**
  String paymentProcessFailed(Object error);

  /// No description provided for @matchReportLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'報告データの読み込みに失敗しました: {error}'**
  String matchReportLoadFailed(Object error);

  /// No description provided for @reporterLabelWithName.
  ///
  /// In ja, this message translates to:
  /// **'報告者: {name}'**
  String reporterLabelWithName(Object name);

  /// No description provided for @adminResponseWithContent.
  ///
  /// In ja, this message translates to:
  /// **'運営対応: {response}'**
  String adminResponseWithContent(Object response);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In ja, this message translates to:
  /// **'{minutes}分前'**
  String timeMinutesAgo(Object minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In ja, this message translates to:
  /// **'{hours}時間前'**
  String timeHoursAgo(Object hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In ja, this message translates to:
  /// **'{days}日前'**
  String timeDaysAgo(Object days);

  /// No description provided for @minCharsDetailError.
  ///
  /// In ja, this message translates to:
  /// **'{count}文字以上で詳細を記載してください'**
  String minCharsDetailError(Object count);

  /// No description provided for @reportedAtFormatted.
  ///
  /// In ja, this message translates to:
  /// **'報告日時: {dateTime}'**
  String reportedAtFormatted(Object dateTime);

  /// No description provided for @reporterFormatted.
  ///
  /// In ja, this message translates to:
  /// **'報告者: {name}'**
  String reporterFormatted(Object name);

  /// No description provided for @statusFormatted.
  ///
  /// In ja, this message translates to:
  /// **'ステータス: {status}'**
  String statusFormatted(Object status);

  /// No description provided for @errorFormatted.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String errorFormatted(Object error);

  /// No description provided for @countItems.
  ///
  /// In ja, this message translates to:
  /// **'{count}件'**
  String countItems(Object count);

  /// No description provided for @statusWithValue.
  ///
  /// In ja, this message translates to:
  /// **'ステータス: {status}'**
  String statusWithValue(Object status);

  /// No description provided for @applicationDateFormatted.
  ///
  /// In ja, this message translates to:
  /// **'申込日: {date}'**
  String applicationDateFormatted(Object date);

  /// No description provided for @eventDateFormatted.
  ///
  /// In ja, this message translates to:
  /// **'開催日: {date}'**
  String eventDateFormatted(Object date);

  /// No description provided for @maxParticipantsFormatted.
  ///
  /// In ja, this message translates to:
  /// **'最大参加者: {count}名'**
  String maxParticipantsFormatted(Object count);

  /// No description provided for @gameProfileSendMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への申請時に以下のプロフィール情報を送信します。'**
  String gameProfileSendMessage(Object eventName);

  /// No description provided for @minCharsResponseError.
  ///
  /// In ja, this message translates to:
  /// **'{count}文字以上で詳細な回答を記載してください'**
  String minCharsResponseError(Object count);

  /// No description provided for @appealProcessedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'異議申立を{status}しました。申立者に通知されます。'**
  String appealProcessedSuccess(Object status);

  /// No description provided for @fieldRequiredError.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は必須項目です'**
  String fieldRequiredError(Object fieldName);

  /// No description provided for @tagMaxReachedError.
  ///
  /// In ja, this message translates to:
  /// **'最大{maxTags}個までタグを追加できます'**
  String tagMaxReachedError(Object maxTags);

  /// No description provided for @tagTooLongError.
  ///
  /// In ja, this message translates to:
  /// **'タグは{maxLength}文字以内で入力してください'**
  String tagTooLongError(Object maxLength);

  /// No description provided for @tagCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'{count}/{max}個のタグ'**
  String tagCountLabel(Object count, Object max);

  /// No description provided for @watchOnPlatform.
  ///
  /// In ja, this message translates to:
  /// **'{platform} で配信を視聴'**
  String watchOnPlatform(Object platform);

  /// No description provided for @errorAuthUnknown.
  ///
  /// In ja, this message translates to:
  /// **'認証エラー: {message}'**
  String errorAuthUnknown(Object message);

  /// No description provided for @errorGameSearchFailed.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム検索に失敗しました: {error}'**
  String errorGameSearchFailed(Object error);

  /// No description provided for @errorDocumentCreate.
  ///
  /// In ja, this message translates to:
  /// **'ドキュメントの作成に失敗しました: {error}'**
  String errorDocumentCreate(Object error);

  /// No description provided for @errorDocumentUpdate.
  ///
  /// In ja, this message translates to:
  /// **'ドキュメントの更新に失敗しました: {error}'**
  String errorDocumentUpdate(Object error);

  /// No description provided for @errorDocumentSet.
  ///
  /// In ja, this message translates to:
  /// **'ドキュメントの設定に失敗しました: {error}'**
  String errorDocumentSet(Object error);

  /// No description provided for @errorDocumentDelete.
  ///
  /// In ja, this message translates to:
  /// **'ドキュメントの削除に失敗しました: {error}'**
  String errorDocumentDelete(Object error);

  /// No description provided for @errorDocumentGet.
  ///
  /// In ja, this message translates to:
  /// **'ドキュメントの取得に失敗しました: {error}'**
  String errorDocumentGet(Object error);

  /// No description provided for @errorCollectionGet.
  ///
  /// In ja, this message translates to:
  /// **'コレクションの取得に失敗しました: {error}'**
  String errorCollectionGet(Object error);

  /// No description provided for @errorQueryExec.
  ///
  /// In ja, this message translates to:
  /// **'クエリの実行に失敗しました: {error}'**
  String errorQueryExec(Object error);

  /// No description provided for @errorDocumentWatch.
  ///
  /// In ja, this message translates to:
  /// **'ドキュメントの監視設定に失敗しました: {error}'**
  String errorDocumentWatch(Object error);

  /// No description provided for @errorCollectionWatch.
  ///
  /// In ja, this message translates to:
  /// **'コレクションの監視設定に失敗しました: {error}'**
  String errorCollectionWatch(Object error);

  /// No description provided for @errorBatchExec.
  ///
  /// In ja, this message translates to:
  /// **'バッチ処理の実行に失敗しました: {error}'**
  String errorBatchExec(Object error);

  /// No description provided for @errorTransactionExec.
  ///
  /// In ja, this message translates to:
  /// **'トランザクションの実行に失敗しました: {error}'**
  String errorTransactionExec(Object error);

  /// No description provided for @errorUserIdDuplicateCheck.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーID重複チェックに失敗しました: {error}'**
  String errorUserIdDuplicateCheck(Object error);

  /// No description provided for @errorOfflineMode.
  ///
  /// In ja, this message translates to:
  /// **'オフラインモードの有効化に失敗しました: {error}'**
  String errorOfflineMode(Object error);

  /// No description provided for @errorOnlineMode.
  ///
  /// In ja, this message translates to:
  /// **'オンラインモードの復帰に失敗しました: {error}'**
  String errorOnlineMode(Object error);

  /// No description provided for @errorAvatarUpload.
  ///
  /// In ja, this message translates to:
  /// **'アバターのアップロードに失敗しました: {error}'**
  String errorAvatarUpload(Object error);

  /// No description provided for @errorAvatarDelete.
  ///
  /// In ja, this message translates to:
  /// **'アバターの削除に失敗しました: {error}'**
  String errorAvatarDelete(Object error);

  /// No description provided for @errorUploadGeneric.
  ///
  /// In ja, this message translates to:
  /// **'アップロードエラー: {message}'**
  String errorUploadGeneric(Object message);

  /// No description provided for @errorGroupGet.
  ///
  /// In ja, this message translates to:
  /// **'グループの取得に失敗しました: {error}'**
  String errorGroupGet(Object error);

  /// No description provided for @errorViolationReport.
  ///
  /// In ja, this message translates to:
  /// **'違反報告に失敗しました: {error}'**
  String errorViolationReport(Object error);

  /// No description provided for @errorViolationEdit.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の編集に失敗しました: {error}'**
  String errorViolationEdit(Object error);

  /// No description provided for @errorViolationProcess.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の処理に失敗しました: {error}'**
  String errorViolationProcess(Object error);

  /// No description provided for @errorViolationDismiss.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の却下に失敗しました: {error}'**
  String errorViolationDismiss(Object error);

  /// No description provided for @errorViolationStatusUpdate.
  ///
  /// In ja, this message translates to:
  /// **'違反記録のステータス更新に失敗しました: {error}'**
  String errorViolationStatusUpdate(Object error);

  /// No description provided for @errorEventViolationGet.
  ///
  /// In ja, this message translates to:
  /// **'イベント違反記録の取得に失敗しました: {error}'**
  String errorEventViolationGet(Object error);

  /// No description provided for @errorUserViolationHistory.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー違反履歴の取得に失敗しました: {error}'**
  String errorUserViolationHistory(Object error);

  /// No description provided for @errorPendingViolationGet.
  ///
  /// In ja, this message translates to:
  /// **'未処理違反記録の取得に失敗しました: {error}'**
  String errorPendingViolationGet(Object error);

  /// No description provided for @errorViolationStats.
  ///
  /// In ja, this message translates to:
  /// **'違反記録統計の取得に失敗しました: {error}'**
  String errorViolationStats(Object error);

  /// No description provided for @errorWarningHistory.
  ///
  /// In ja, this message translates to:
  /// **'警告履歴の取得に失敗しました: {error}'**
  String errorWarningHistory(Object error);

  /// No description provided for @errorViolationSearch.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の検索に失敗しました: {error}'**
  String errorViolationSearch(Object error);

  /// No description provided for @errorViolationWatch.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の監視に失敗しました: {error}'**
  String errorViolationWatch(Object error);

  /// No description provided for @errorViolationRiskCalc.
  ///
  /// In ja, this message translates to:
  /// **'違反リスクレベルの計算に失敗しました: {error}'**
  String errorViolationRiskCalc(Object error);

  /// No description provided for @errorViolationDelete.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の削除に失敗しました: {error}'**
  String errorViolationDelete(Object error);

  /// No description provided for @errorViolationRecover.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の復旧に失敗しました: {error}'**
  String errorViolationRecover(Object error);

  /// No description provided for @errorViolationBatchProcess.
  ///
  /// In ja, this message translates to:
  /// **'違反記録の一括処理に失敗しました: {error}'**
  String errorViolationBatchProcess(Object error);

  /// No description provided for @errorOrganizerViolationGet.
  ///
  /// In ja, this message translates to:
  /// **'運営者違反記録の取得に失敗しました: {error}'**
  String errorOrganizerViolationGet(Object error);

  /// No description provided for @errorAppealSubmit.
  ///
  /// In ja, this message translates to:
  /// **'異議申立の提出に失敗しました: {error}'**
  String errorAppealSubmit(Object error);

  /// No description provided for @errorAppealProcess.
  ///
  /// In ja, this message translates to:
  /// **'異議申立の処理に失敗しました: {error}'**
  String errorAppealProcess(Object error);

  /// No description provided for @errorProbationUpdate.
  ///
  /// In ja, this message translates to:
  /// **'猶予期間情報の更新に失敗しました: {error}'**
  String errorProbationUpdate(Object error);

  /// No description provided for @errorMatchResultGet.
  ///
  /// In ja, this message translates to:
  /// **'試合結果の取得に失敗しました: {error}'**
  String errorMatchResultGet(Object error);

  /// No description provided for @errorMatchResultCreate.
  ///
  /// In ja, this message translates to:
  /// **'試合結果の作成に失敗しました: {error}'**
  String errorMatchResultCreate(Object error);

  /// No description provided for @errorMatchResultUpdate.
  ///
  /// In ja, this message translates to:
  /// **'試合結果の更新に失敗しました: {error}'**
  String errorMatchResultUpdate(Object error);

  /// No description provided for @errorMatchResultDelete.
  ///
  /// In ja, this message translates to:
  /// **'試合結果の削除に失敗しました: {error}'**
  String errorMatchResultDelete(Object error);

  /// No description provided for @errorRankingCalc.
  ///
  /// In ja, this message translates to:
  /// **'ランキング計算に失敗しました: {error}'**
  String errorRankingCalc(Object error);

  /// No description provided for @errorEvidenceImageAdd.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像の追加に失敗しました: {error}'**
  String errorEvidenceImageAdd(Object error);

  /// No description provided for @errorEvidenceImageDelete.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像の削除に失敗しました: {error}'**
  String errorEvidenceImageDelete(Object error);

  /// No description provided for @errorEvidenceImageReplace.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像の置き換えに失敗しました: {error}'**
  String errorEvidenceImageReplace(Object error);

  /// No description provided for @errorEvidenceImageBatchReplace.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像の一括置き換えに失敗しました: {error}'**
  String errorEvidenceImageBatchReplace(Object error);

  /// No description provided for @errorEvidenceImageGet.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像の取得に失敗しました: {error}'**
  String errorEvidenceImageGet(Object error);

  /// No description provided for @errorReportSubmit.
  ///
  /// In ja, this message translates to:
  /// **'報告の送信に失敗しました: {error}'**
  String errorReportSubmit(Object error);

  /// No description provided for @errorReportStatusUpdate.
  ///
  /// In ja, this message translates to:
  /// **'報告状況の更新に失敗しました: {error}'**
  String errorReportStatusUpdate(Object error);

  /// No description provided for @errorReportGet.
  ///
  /// In ja, this message translates to:
  /// **'報告の取得に失敗しました: {error}'**
  String errorReportGet(Object error);

  /// No description provided for @errorReportListGet.
  ///
  /// In ja, this message translates to:
  /// **'報告一覧の取得に失敗しました: {error}'**
  String errorReportListGet(Object error);

  /// No description provided for @errorEventReportGet.
  ///
  /// In ja, this message translates to:
  /// **'イベント報告一覧の取得に失敗しました: {error}'**
  String errorEventReportGet(Object error);

  /// No description provided for @errorUserReportGet.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー報告の取得に失敗しました: {error}'**
  String errorUserReportGet(Object error);

  /// No description provided for @errorPendingReportGet.
  ///
  /// In ja, this message translates to:
  /// **'未処理報告の取得に失敗しました: {error}'**
  String errorPendingReportGet(Object error);

  /// No description provided for @errorEnhancedMatchResultGet.
  ///
  /// In ja, this message translates to:
  /// **'拡張試合結果の取得に失敗しました: {error}'**
  String errorEnhancedMatchResultGet(Object error);

  /// No description provided for @errorEnhancedMatchResultCreate.
  ///
  /// In ja, this message translates to:
  /// **'拡張試合結果の作成に失敗しました: {error}'**
  String errorEnhancedMatchResultCreate(Object error);

  /// No description provided for @errorEnhancedMatchResultUpdate.
  ///
  /// In ja, this message translates to:
  /// **'拡張試合結果の更新に失敗しました: {error}'**
  String errorEnhancedMatchResultUpdate(Object error);

  /// No description provided for @errorEnhancedMatchResultDelete.
  ///
  /// In ja, this message translates to:
  /// **'拡張試合結果の削除に失敗しました: {error}'**
  String errorEnhancedMatchResultDelete(Object error);

  /// No description provided for @errorEnhancedStatsCalc.
  ///
  /// In ja, this message translates to:
  /// **'拡張統計計算に失敗しました: {error}'**
  String errorEnhancedStatsCalc(Object error);

  /// No description provided for @errorLegacyResultConvert.
  ///
  /// In ja, this message translates to:
  /// **'レガシー結果の変換に失敗しました: {error}'**
  String errorLegacyResultConvert(Object error);

  /// No description provided for @errorPaymentRecordCreate.
  ///
  /// In ja, this message translates to:
  /// **'支払い記録の作成に失敗しました: {error}'**
  String errorPaymentRecordCreate(Object error);

  /// No description provided for @errorPaymentProofUpload.
  ///
  /// In ja, this message translates to:
  /// **'支払い証跡のアップロードに失敗しました: {error}'**
  String errorPaymentProofUpload(Object error);

  /// No description provided for @errorPaymentConfirmUpdate.
  ///
  /// In ja, this message translates to:
  /// **'支払い確認の更新に失敗しました: {error}'**
  String errorPaymentConfirmUpdate(Object error);

  /// No description provided for @errorPaymentRecordGet.
  ///
  /// In ja, this message translates to:
  /// **'支払い記録の取得に失敗しました: {error}'**
  String errorPaymentRecordGet(Object error);

  /// No description provided for @errorPaymentRealtimeWatch.
  ///
  /// In ja, this message translates to:
  /// **'リアルタイム支払い記録の監視に失敗しました: {error}'**
  String errorPaymentRealtimeWatch(Object error);

  /// No description provided for @errorParticipantPaymentGet.
  ///
  /// In ja, this message translates to:
  /// **'参加者の支払い記録取得に失敗しました: {error}'**
  String errorParticipantPaymentGet(Object error);

  /// No description provided for @errorPaymentStatsGet.
  ///
  /// In ja, this message translates to:
  /// **'支払い統計の取得に失敗しました: {error}'**
  String errorPaymentStatsGet(Object error);

  /// No description provided for @errorPaymentRecordDelete.
  ///
  /// In ja, this message translates to:
  /// **'支払い記録の削除に失敗しました: {error}'**
  String errorPaymentRecordDelete(Object error);

  /// No description provided for @errorPaymentStatusUpdate.
  ///
  /// In ja, this message translates to:
  /// **'支払いステータスの更新に失敗しました: {error}'**
  String errorPaymentStatusUpdate(Object error);

  /// No description provided for @errorUserDataUpdate.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーデータの更新に失敗しました: {error}'**
  String errorUserDataUpdate(Object error);

  /// No description provided for @errorUserDataGet.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーデータの取得に失敗しました: {error}'**
  String errorUserDataGet(Object error);

  /// No description provided for @errorCurrentUserDataGet.
  ///
  /// In ja, this message translates to:
  /// **'現在のユーザーデータの取得に失敗しました: {error}'**
  String errorCurrentUserDataGet(Object error);

  /// No description provided for @errorImageFormatUnsupported.
  ///
  /// In ja, this message translates to:
  /// **'サポートされていない画像形式です。{formats}のみ対応しています。'**
  String errorImageFormatUnsupported(Object formats);

  /// No description provided for @errorDeleteCheckFailed.
  ///
  /// In ja, this message translates to:
  /// **'削除可否の確認中にエラーが発生しました: {error}'**
  String errorDeleteCheckFailed(Object error);

  /// No description provided for @errorCapacityExceeded.
  ///
  /// In ja, this message translates to:
  /// **'定員を超過するため承認できません（現在 {current}/{max}人）'**
  String errorCapacityExceeded(Object current, Object max);

  /// No description provided for @errorNetworkConfirm.
  ///
  /// In ja, this message translates to:
  /// **'インターネット接続を確認してください: {error}'**
  String errorNetworkConfirm(Object error);

  /// No description provided for @errorInvalidResponse.
  ///
  /// In ja, this message translates to:
  /// **'レスポンスの形式が正しくありません: {error}'**
  String errorInvalidResponse(Object error);

  /// No description provided for @errorRequestFailed.
  ///
  /// In ja, this message translates to:
  /// **'リクエストが失敗しました: {error}'**
  String errorRequestFailed(Object error);

  /// No description provided for @matchRegistered.
  ///
  /// In ja, this message translates to:
  /// **'試合「{matchName}」を登録しました'**
  String matchRegistered(Object matchName);

  /// No description provided for @matchRegistrationFailed.
  ///
  /// In ja, this message translates to:
  /// **'試合の登録に失敗しました: {error}'**
  String matchRegistrationFailed(Object error);

  /// No description provided for @responseDate.
  ///
  /// In ja, this message translates to:
  /// **'対応日時: {dateTime}'**
  String responseDate(Object dateTime);

  /// Update failed message
  ///
  /// In ja, this message translates to:
  /// **'更新に失敗しました: {error}'**
  String updateFailedMessage(String error);

  /// No description provided for @resultSaveError.
  ///
  /// In ja, this message translates to:
  /// **'結果の保存に失敗しました: {error}'**
  String resultSaveError(Object error);

  /// No description provided for @imageLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'画像の読み込みに失敗しました: {error}'**
  String imageLoadFailed(Object error);

  /// No description provided for @cameraCaptureFailedError.
  ///
  /// In ja, this message translates to:
  /// **'カメラでの撮影に失敗しました: {error}'**
  String cameraCaptureFailedError(Object error);

  /// No description provided for @gallerySelectFailedError.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーからの選択に失敗しました: {error}'**
  String gallerySelectFailedError(Object error);

  /// No description provided for @imageUploadFailedError.
  ///
  /// In ja, this message translates to:
  /// **'画像のアップロードに失敗しました: {error}'**
  String imageUploadFailedError(Object error);

  /// No description provided for @imageDeleteFailedError.
  ///
  /// In ja, this message translates to:
  /// **'画像の削除に失敗しました: {error}'**
  String imageDeleteFailedError(Object error);

  /// No description provided for @imageReplaceFailedError.
  ///
  /// In ja, this message translates to:
  /// **'画像の置き換えに失敗しました: {error}'**
  String imageReplaceFailedError(Object error);

  /// No description provided for @replaceAllImagesConfirm.
  ///
  /// In ja, this message translates to:
  /// **'現在の{count}枚の画像を全て削除し、新しい画像に置き換えますか？\\n\\nこの操作は取り消せません。'**
  String replaceAllImagesConfirm(Object count);

  /// No description provided for @imageSelectFailedError.
  ///
  /// In ja, this message translates to:
  /// **'画像の選択に失敗しました: {error}'**
  String imageSelectFailedError(Object error);

  /// No description provided for @imageBatchReplaceFailedError.
  ///
  /// In ja, this message translates to:
  /// **'画像の一括置き換えに失敗しました: {error}'**
  String imageBatchReplaceFailedError(Object error);

  /// No description provided for @imageCountFormat.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚'**
  String imageCountFormat(int count);

  /// No description provided for @imagesUploadedCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の画像をアップロードしました'**
  String imagesUploadedCount(int count);

  /// No description provided for @imagesReplacedCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の新しい画像に置き換えました'**
  String imagesReplacedCount(int count);

  /// No description provided for @imagesBulkReplaceFailedError.
  ///
  /// In ja, this message translates to:
  /// **'画像の一括置き換えに失敗しました: {error}'**
  String imagesBulkReplaceFailedError(String error);

  /// No description provided for @maxUrlsReached.
  ///
  /// In ja, this message translates to:
  /// **'最大{maxUrls}個まで配信URLを追加できます'**
  String maxUrlsReached(Object maxUrls);

  /// No description provided for @dataLoadFailedError.
  ///
  /// In ja, this message translates to:
  /// **'データの取得に失敗しました: {error}'**
  String dataLoadFailedError(Object error);

  /// No description provided for @gameProfileLoadFailedError.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールの取得に失敗しました: {error}'**
  String gameProfileLoadFailedError(Object error);

  /// No description provided for @userDataLoadFailedError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーデータの取得に失敗しました: {error}'**
  String userDataLoadFailedError(Object error);

  /// No description provided for @gameDataLoadFailedError.
  ///
  /// In ja, this message translates to:
  /// **'ゲームデータの取得に失敗しました: {error}'**
  String gameDataLoadFailedError(Object error);

  /// No description provided for @profileSummaryRank.
  ///
  /// In ja, this message translates to:
  /// **'ランク: {rank}'**
  String profileSummaryRank(Object rank);

  /// No description provided for @profileSummaryLevel.
  ///
  /// In ja, this message translates to:
  /// **'レベル: {level}'**
  String profileSummaryLevel(Object level);

  /// No description provided for @profileSummaryStyle.
  ///
  /// In ja, this message translates to:
  /// **'スタイル: {styles}'**
  String profileSummaryStyle(Object styles);

  /// No description provided for @rankPosition.
  ///
  /// In ja, this message translates to:
  /// **'{rank}位'**
  String rankPosition(Object rank);

  /// No description provided for @userNumberName.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー{number}'**
  String userNumberName(Object number);

  /// No description provided for @imagesCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚'**
  String imagesCountLabel(Object count);

  /// No description provided for @existingImagesLabel.
  ///
  /// In ja, this message translates to:
  /// **'既存の画像 ({count}枚)'**
  String existingImagesLabel(Object count);

  /// No description provided for @newImagesLabel.
  ///
  /// In ja, this message translates to:
  /// **'追加する画像 ({count}枚)'**
  String newImagesLabel(Object count);

  /// No description provided for @cameraCaptureError.
  ///
  /// In ja, this message translates to:
  /// **'カメラでの撮影に失敗しました: {error}'**
  String cameraCaptureError(Object error);

  /// No description provided for @gallerySelectError.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーからの選択に失敗しました: {error}'**
  String gallerySelectError(Object error);

  /// No description provided for @imageDeletePartialError.
  ///
  /// In ja, this message translates to:
  /// **'一部の画像削除でエラーが発生しました: {error}'**
  String imageDeletePartialError(Object error);

  /// No description provided for @evidenceUploadError.
  ///
  /// In ja, this message translates to:
  /// **'エビデンス画像のアップロードに失敗しました: {error}'**
  String evidenceUploadError(Object error);

  /// No description provided for @resultSaveFailedError.
  ///
  /// In ja, this message translates to:
  /// **'結果の保存に失敗しました: {error}'**
  String resultSaveFailedError(Object error);

  /// No description provided for @imageLoadError.
  ///
  /// In ja, this message translates to:
  /// **'画像の読み込みに失敗しました: {error}'**
  String imageLoadError(Object error);

  /// No description provided for @imagesUploadedMessage.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の画像をアップロードしました'**
  String imagesUploadedMessage(Object count);

  /// No description provided for @imageUploadError.
  ///
  /// In ja, this message translates to:
  /// **'画像のアップロードに失敗しました: {error}'**
  String imageUploadError(Object error);

  /// No description provided for @imageDeleteError.
  ///
  /// In ja, this message translates to:
  /// **'画像の削除に失敗しました: {error}'**
  String imageDeleteError(Object error);

  /// No description provided for @imageReplaceError.
  ///
  /// In ja, this message translates to:
  /// **'画像の置き換えに失敗しました: {error}'**
  String imageReplaceError(Object error);

  /// No description provided for @replaceAllImagesConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'現在の{count}枚の画像を全て削除し、新しい画像に置き換えますか？\\n\\nこの操作は取り消せません。'**
  String replaceAllImagesConfirmMessage(Object count);

  /// No description provided for @imageSelectError.
  ///
  /// In ja, this message translates to:
  /// **'画像の選択に失敗しました: {error}'**
  String imageSelectError(Object error);

  /// No description provided for @imagesReplacedMessage.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の新しい画像に置き換えました'**
  String imagesReplacedMessage(Object count);

  /// No description provided for @batchReplaceError.
  ///
  /// In ja, this message translates to:
  /// **'画像の一括置き換えに失敗しました: {error}'**
  String batchReplaceError(Object error);

  /// No description provided for @imagesUploadedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の画像をアップロードしました'**
  String imagesUploadedSuccess(Object count);

  /// No description provided for @imageCountLabel.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚'**
  String imageCountLabel(Object count);

  /// No description provided for @imageBatchReplaceError.
  ///
  /// In ja, this message translates to:
  /// **'画像の一括置き換えに失敗しました: {error}'**
  String imageBatchReplaceError(Object error);

  /// No description provided for @imagesReplacedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'{count}枚の新しい画像に置き換えました'**
  String imagesReplacedSuccess(Object count);

  /// No description provided for @eventDeleteError.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました: {error}'**
  String eventDeleteError(Object error);

  /// No description provided for @createdDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'作成: {date}'**
  String createdDateLabel(Object date);

  /// No description provided for @completedDateLabel.
  ///
  /// In ja, this message translates to:
  /// **'完了: {date}'**
  String completedDateLabel(Object date);

  /// No description provided for @rankPositionFormat.
  ///
  /// In ja, this message translates to:
  /// **'{rank}位'**
  String rankPositionFormat(Object rank);

  /// No description provided for @pointsFormat.
  ///
  /// In ja, this message translates to:
  /// **'{points}点'**
  String pointsFormat(Object points);

  /// No description provided for @selectStatusPrompt.
  ///
  /// In ja, this message translates to:
  /// **'「{name}」のステータスを選択してください'**
  String selectStatusPrompt(Object name);

  /// No description provided for @statusChangeFailedError.
  ///
  /// In ja, this message translates to:
  /// **'ステータス変更に失敗しました: {error}'**
  String statusChangeFailedError(Object error);

  /// No description provided for @matchDeletedSuccess.
  ///
  /// In ja, this message translates to:
  /// **'試合「{name}」を削除しました'**
  String matchDeletedSuccess(Object name);

  /// No description provided for @matchDeleteFailedError.
  ///
  /// In ja, this message translates to:
  /// **'試合の削除に失敗しました: {error}'**
  String matchDeleteFailedError(Object error);

  /// No description provided for @matchResultSaveFailedError.
  ///
  /// In ja, this message translates to:
  /// **'試合結果の保存に失敗しました: {error}'**
  String matchResultSaveFailedError(Object error);

  /// No description provided for @validationPasswordMinLength.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは{minLength}文字以上で入力してください'**
  String validationPasswordMinLength(Object minLength);

  /// No description provided for @validationFieldRequired.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は必須です'**
  String validationFieldRequired(Object fieldName);

  /// No description provided for @validationUrlRequired.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}を入力してください'**
  String validationUrlRequired(Object fieldName);

  /// No description provided for @validationUrlInvalid.
  ///
  /// In ja, this message translates to:
  /// **'有効な{fieldName}を入力してください（http://またはhttps://で始まる）'**
  String validationUrlInvalid(Object fieldName);

  /// No description provided for @validationDateTimeRequired.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}を設定してください'**
  String validationDateTimeRequired(Object fieldName);

  /// No description provided for @validationDateTimeAfter.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は{minDate}以降に設定してください'**
  String validationDateTimeAfter(Object fieldName, Object minDate);

  /// No description provided for @validationDateTimeBefore.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は{maxDate}以前に設定してください'**
  String validationDateTimeBefore(Object fieldName, Object maxDate);

  /// No description provided for @validationTextMinLength.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は{minLength}文字以上で入力してください'**
  String validationTextMinLength(Object fieldName, Object minLength);

  /// No description provided for @validationTextMaxLength.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は{maxLength}文字以内で入力してください'**
  String validationTextMaxLength(Object fieldName, Object maxLength);

  /// No description provided for @validationImageFormat.
  ///
  /// In ja, this message translates to:
  /// **'対応している画像形式: {formats}'**
  String validationImageFormat(Object formats);

  /// No description provided for @validationListMinItems.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}を少なくとも{minItems}つ選択してください'**
  String validationListMinItems(Object fieldName, Object minItems);

  /// No description provided for @validationListMaxItems.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は{maxItems}個以下で選択してください'**
  String validationListMaxItems(Object fieldName, Object maxItems);

  /// No description provided for @validationNumberRangeRequired.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}を入力してください'**
  String validationNumberRangeRequired(Object fieldName);

  /// No description provided for @validationNumberRangeInvalid.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は数値で入力してください'**
  String validationNumberRangeInvalid(Object fieldName);

  /// No description provided for @validationNumberRangeMin.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は{min}以上で入力してください'**
  String validationNumberRangeMin(Object fieldName, Object min);

  /// No description provided for @validationNumberRangeMax.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は{max}以下で入力してください'**
  String validationNumberRangeMax(Object fieldName, Object max);

  /// No description provided for @validationHiraganaOnly.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}はひらがなのみで入力してください'**
  String validationHiraganaOnly(Object fieldName);

  /// No description provided for @validationKatakanaOnly.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}はカタカナのみで入力してください'**
  String validationKatakanaOnly(Object fieldName);

  /// No description provided for @validationAlphanumericOnly.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}は英数字のみで入力してください'**
  String validationAlphanumericOnly(Object fieldName);

  /// No description provided for @validationForbiddenContent.
  ///
  /// In ja, this message translates to:
  /// **'{fieldName}に不適切な内容が含まれています'**
  String validationForbiddenContent(Object fieldName);

  /// No description provided for @participantMatchCompletedAt.
  ///
  /// In ja, this message translates to:
  /// **'完了: {dateTime}'**
  String participantMatchCompletedAt(Object dateTime);

  /// No description provided for @participantMatchReportedAt.
  ///
  /// In ja, this message translates to:
  /// **'{dateTime} 報告'**
  String participantMatchReportedAt(Object dateTime);

  /// No description provided for @participantMatchUploaderLabel.
  ///
  /// In ja, this message translates to:
  /// **'アップロード者: {name}'**
  String participantMatchUploaderLabel(Object name);

  /// No description provided for @participantMatchUploadedAtLabel.
  ///
  /// In ja, this message translates to:
  /// **'アップロード日時: {dateTime}'**
  String participantMatchUploadedAtLabel(Object dateTime);

  /// No description provided for @participantMatchMatchLabel.
  ///
  /// In ja, this message translates to:
  /// **'試合: {name}'**
  String participantMatchMatchLabel(Object name);

  /// No description provided for @participantMatchParticipantsDialogLabel.
  ///
  /// In ja, this message translates to:
  /// **'参加者: {names}'**
  String participantMatchParticipantsDialogLabel(Object names);

  /// No description provided for @participantMatchReportFailed.
  ///
  /// In ja, this message translates to:
  /// **'報告の送信に失敗しました: {error}'**
  String participantMatchReportFailed(Object error);

  /// No description provided for @participantMatchAndMore.
  ///
  /// In ja, this message translates to:
  /// **'{names} 他{count}名'**
  String participantMatchAndMore(Object count, Object names);

  /// No description provided for @memberCountValue.
  ///
  /// In ja, this message translates to:
  /// **'{count}人'**
  String memberCountValue(Object count);

  /// No description provided for @defaultEventName.
  ///
  /// In ja, this message translates to:
  /// **'イベント'**
  String get defaultEventName;

  /// No description provided for @defaultApprovalMethod.
  ///
  /// In ja, this message translates to:
  /// **'自動承認'**
  String get defaultApprovalMethod;

  /// No description provided for @defaultLanguage.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get defaultLanguage;

  /// No description provided for @noEventsCreatedYet.
  ///
  /// In ja, this message translates to:
  /// **'まだイベントが作成されていません'**
  String get noEventsCreatedYet;

  /// No description provided for @createButtonLabel.
  ///
  /// In ja, this message translates to:
  /// **'作成'**
  String get createButtonLabel;

  /// No description provided for @eventCountFormat.
  ///
  /// In ja, this message translates to:
  /// **'{count}件のイベント'**
  String eventCountFormat(int count);

  /// No description provided for @collaboratorEventsTitle.
  ///
  /// In ja, this message translates to:
  /// **'共同編集者のイベント'**
  String get collaboratorEventsTitle;

  /// No description provided for @createdEventsTitle.
  ///
  /// In ja, this message translates to:
  /// **'作成したイベント'**
  String get createdEventsTitle;

  /// No description provided for @draftEventsTitle.
  ///
  /// In ja, this message translates to:
  /// **'下書き保存されたイベント'**
  String get draftEventsTitle;

  /// No description provided for @gameProfileFetchError.
  ///
  /// In ja, this message translates to:
  /// **'ゲームプロフィールの取得に失敗しました: {error}'**
  String gameProfileFetchError(String error);

  /// No description provided for @userDataFetchError.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーデータの取得に失敗しました: {error}'**
  String userDataFetchError(String error);

  /// No description provided for @gameDataFetchError.
  ///
  /// In ja, this message translates to:
  /// **'ゲームデータの取得に失敗しました: {error}'**
  String gameDataFetchError(String error);

  /// No description provided for @noGameProfileFound.
  ///
  /// In ja, this message translates to:
  /// **'このゲームのプロフィールが見つかりません'**
  String get noGameProfileFound;

  /// No description provided for @noGameProfileDetailMessage.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーがこのゲームのプロフィールを作成していないか、公開設定になっていない可能性があります。'**
  String get noGameProfileDetailMessage;

  /// No description provided for @validationEnterValidNumber.
  ///
  /// In ja, this message translates to:
  /// **'正しい数値を入力してください'**
  String get validationEnterValidNumber;

  /// No description provided for @validationEnterValidInteger.
  ///
  /// In ja, this message translates to:
  /// **'正しい整数を入力してください'**
  String get validationEnterValidInteger;

  /// No description provided for @validationPositiveNumberRequired.
  ///
  /// In ja, this message translates to:
  /// **'0以上の数値を入力してください'**
  String get validationPositiveNumberRequired;

  /// Firestore permission denied error
  ///
  /// In ja, this message translates to:
  /// **'Firestoreへのアクセス権限がありません。セキュリティルールを確認してください。'**
  String get firestorePermissionDeniedError;

  /// Firestore connection error
  ///
  /// In ja, this message translates to:
  /// **'Firestoreへの接続に失敗しました。ネットワーク接続を確認してください。'**
  String get firestoreConnectionError;

  /// Data fetch error
  ///
  /// In ja, this message translates to:
  /// **'データの取得に失敗しました: {error}'**
  String dataFetchError(String error);

  /// Event violation fetch error
  ///
  /// In ja, this message translates to:
  /// **'イベント違反記録の取得に失敗: {error}'**
  String eventViolationFetchError(String error);

  /// Capacity exceeded error keyword
  ///
  /// In ja, this message translates to:
  /// **'定員を超過'**
  String get capacityExceededError;

  /// Date format year month day
  ///
  /// In ja, this message translates to:
  /// **'{year}年{month}月{day}日'**
  String dateFormatYearMonthDay(int year, int month, int day);

  /// Full datetime format
  ///
  /// In ja, this message translates to:
  /// **'{year}年{month}月{day}日 {hour}:{minute}'**
  String dateTimeFormatFull(
    int year,
    int month,
    int day,
    String hour,
    String minute,
  );

  /// Rank position label
  ///
  /// In ja, this message translates to:
  /// **'{rank}位'**
  String rankPositionLabel(int rank);

  /// Skill level pro
  ///
  /// In ja, this message translates to:
  /// **'プロ'**
  String get skillLevelPro;

  /// Play style tank
  ///
  /// In ja, this message translates to:
  /// **'タンク'**
  String get playStyleTank;

  /// Play style attacker
  ///
  /// In ja, this message translates to:
  /// **'アタッカー'**
  String get playStyleAttacker;

  /// Play style support
  ///
  /// In ja, this message translates to:
  /// **'サポート'**
  String get playStyleSupport;

  /// Play style healer
  ///
  /// In ja, this message translates to:
  /// **'ヒーラー'**
  String get playStyleHealer;

  /// Play style communication
  ///
  /// In ja, this message translates to:
  /// **'交流'**
  String get playStyleCommunication;

  /// No description provided for @accountWithdrawalReauthMessage.
  ///
  /// In ja, this message translates to:
  /// **'アカウント退会のため、再認証が必要です'**
  String get accountWithdrawalReauthMessage;

  /// No description provided for @accountWithdrawalWarningMessage.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを退会すると、すべてのデータが削除されます。この操作は取り消せません。'**
  String get accountWithdrawalWarningMessage;

  /// No description provided for @appealReasonHint.
  ///
  /// In ja, this message translates to:
  /// **'不服申立ての理由を入力してください'**
  String get appealReasonHint;

  /// No description provided for @authTermsAgreementPrefix.
  ///
  /// In ja, this message translates to:
  /// **'サービス利用規約に同意する'**
  String get authTermsAgreementPrefix;

  /// No description provided for @cancelWaitlistConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちを取り消しますか？'**
  String get cancelWaitlistConfirmMessage;

  /// No description provided for @cannotBlockOperatorOrSponsorError.
  ///
  /// In ja, this message translates to:
  /// **'運営者またはスポンサーはブロックできません'**
  String get cannotBlockOperatorOrSponsorError;

  /// No description provided for @capacityExceededApprovalError.
  ///
  /// In ja, this message translates to:
  /// **'定員を超えているため承認できません'**
  String get capacityExceededApprovalError;

  /// No description provided for @collaborativeEventsFullDescription.
  ///
  /// In ja, this message translates to:
  /// **'他のユーザーと共同で運営するイベントの一覧です'**
  String get collaborativeEventsFullDescription;

  /// No description provided for @communityOtherHelperText.
  ///
  /// In ja, this message translates to:
  /// **'その他のコミュニティ名を入力'**
  String get communityOtherHelperText;

  /// No description provided for @communityOtherHint.
  ///
  /// In ja, this message translates to:
  /// **'コミュニティ名を入力'**
  String get communityOtherHint;

  /// No description provided for @contactHint.
  ///
  /// In ja, this message translates to:
  /// **'連絡先を入力してください'**
  String get contactHint;

  /// No description provided for @deleteViolationRecordWarning.
  ///
  /// In ja, this message translates to:
  /// **'この違反記録を削除しますか？この操作は取り消せません。'**
  String get deleteViolationRecordWarning;

  /// No description provided for @deletedDataList.
  ///
  /// In ja, this message translates to:
  /// **'削除されるデータ：イベント情報、参加者データ、試合結果など'**
  String get deletedDataList;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'サービスが一時的に利用できません'**
  String get errorServiceUnavailable;

  /// No description provided for @eventCancellationNoticeList.
  ///
  /// In ja, this message translates to:
  /// **'参加者への通知が送信されます'**
  String get eventCancellationNoticeList;

  /// No description provided for @eventCancellationReasonServerNetworkTrouble.
  ///
  /// In ja, this message translates to:
  /// **'サーバー/ネットワーク障害'**
  String get eventCancellationReasonServerNetworkTrouble;

  /// No description provided for @eventDateTooCloseForDeadline.
  ///
  /// In ja, this message translates to:
  /// **'開催日が申込期限に近すぎます'**
  String get eventDateTooCloseForDeadline;

  /// No description provided for @fullCapacityApprovalMessage.
  ///
  /// In ja, this message translates to:
  /// **'定員に達しています。承認すると定員を超過します。'**
  String get fullCapacityApprovalMessage;

  /// No description provided for @generalAnnouncementsDescription.
  ///
  /// In ja, this message translates to:
  /// **'全参加者への連絡事項'**
  String get generalAnnouncementsDescription;

  /// No description provided for @guideDeleteDesc.
  ///
  /// In ja, this message translates to:
  /// **'このガイドを削除します'**
  String get guideDeleteDesc;

  /// No description provided for @homeRecommendedEventsFetchError.
  ///
  /// In ja, this message translates to:
  /// **'おすすめイベントの取得に失敗しました'**
  String get homeRecommendedEventsFetchError;

  /// No description provided for @homeRegisterFavoriteGamesHint.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのゲームを登録するとおすすめが表示されます'**
  String get homeRegisterFavoriteGamesHint;

  /// No description provided for @homeUpcomingEventsFetchError.
  ///
  /// In ja, this message translates to:
  /// **'開催予定イベントの取得に失敗しました'**
  String get homeUpcomingEventsFetchError;

  /// No description provided for @noFavoriteGamesHint.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りのゲームがありません'**
  String get noFavoriteGamesHint;

  /// No description provided for @notificationViolationDismissedToReporterTitle.
  ///
  /// In ja, this message translates to:
  /// **'違反報告が却下されました'**
  String get notificationViolationDismissedToReporterTitle;

  /// No description provided for @participantCheckFailedMessage.
  ///
  /// In ja, this message translates to:
  /// **'参加者チェックに失敗しました'**
  String get participantCheckFailedMessage;

  /// No description provided for @participationCancelWarning.
  ///
  /// In ja, this message translates to:
  /// **'参加をキャンセルすると、再度申し込みが必要になります。'**
  String get participationCancelWarning;

  /// No description provided for @prizeDeliveryNote.
  ///
  /// In ja, this message translates to:
  /// **'賞品の配送に関する注意事項'**
  String get prizeDeliveryNote;

  /// No description provided for @prizeDisclaimer.
  ///
  /// In ja, this message translates to:
  /// **'賞品に関する免責事項'**
  String get prizeDisclaimer;

  /// No description provided for @prizeRecommendation.
  ///
  /// In ja, this message translates to:
  /// **'賞品のおすすめ設定'**
  String get prizeRecommendation;

  /// No description provided for @profileOrganizerEventsEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'運営イベントがありません'**
  String get profileOrganizerEventsEmptyHint;

  /// No description provided for @registerFavoriteAndCreateProfileText.
  ///
  /// In ja, this message translates to:
  /// **'お気に入りゲームを登録してプロフィールを作成'**
  String get registerFavoriteAndCreateProfileText;

  /// No description provided for @registrationReactivatedOnRepublish.
  ///
  /// In ja, this message translates to:
  /// **'再公開時に申込受付が再開されます'**
  String get registrationReactivatedOnRepublish;

  /// No description provided for @rejectionDescription.
  ///
  /// In ja, this message translates to:
  /// **'却下の説明'**
  String get rejectionDescription;

  /// No description provided for @revokeApprovalConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'承認を取り消しますか？'**
  String get revokeApprovalConfirmMessage;

  /// No description provided for @revokeRejectionConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'却下を取り消しますか？'**
  String get revokeRejectionConfirmMessage;

  /// No description provided for @selectFromMutualFollowsOrganizerDescription.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローから運営者を選択'**
  String get selectFromMutualFollowsOrganizerDescription;

  /// No description provided for @selectFromMutualFollowsSponsorDescription.
  ///
  /// In ja, this message translates to:
  /// **'相互フォローからスポンサーを選択'**
  String get selectFromMutualFollowsSponsorDescription;

  /// No description provided for @signOutConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'サインアウトしますか？'**
  String get signOutConfirmation;

  /// No description provided for @snsAccountDescription.
  ///
  /// In ja, this message translates to:
  /// **'SNSアカウント情報'**
  String get snsAccountDescription;

  /// No description provided for @userIdHelperText.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーIDは一度設定すると変更できません'**
  String get userIdHelperText;

  /// No description provided for @validationPasswordComplexity.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは大文字、小文字、数字を含む必要があります'**
  String get validationPasswordComplexity;

  /// No description provided for @validationPhoneInvalidWithExample.
  ///
  /// In ja, this message translates to:
  /// **'有効な電話番号を入力してください（例: 090-1234-5678）'**
  String get validationPhoneInvalidWithExample;

  /// No description provided for @validationRegistrationDeadlineBeforeEvent.
  ///
  /// In ja, this message translates to:
  /// **'申込期限はイベント開始前に設定してください'**
  String get validationRegistrationDeadlineBeforeEvent;

  /// No description provided for @eventCoinRewardK.
  ///
  /// In ja, this message translates to:
  /// **'{amount}kコイン'**
  String eventCoinRewardK(Object amount);

  /// No description provided for @eventExpRewardK.
  ///
  /// In ja, this message translates to:
  /// **'{amount}k経験値'**
  String eventExpRewardK(Object amount);

  /// No description provided for @selectAvatarImage.
  ///
  /// In ja, this message translates to:
  /// **'アバター画像を選択'**
  String get selectAvatarImage;

  /// No description provided for @takePhotoFromCamera.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮影'**
  String get takePhotoFromCamera;

  /// No description provided for @selectFromGalleryOption.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選択'**
  String get selectFromGalleryOption;

  /// No description provided for @adjustAvatar.
  ///
  /// In ja, this message translates to:
  /// **'アバターを調整'**
  String get adjustAvatar;

  /// No description provided for @hideKeyboard.
  ///
  /// In ja, this message translates to:
  /// **'キーボードを閉じる'**
  String get hideKeyboard;

  /// No description provided for @errorOccurredSimple.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get errorOccurredSimple;

  /// No description provided for @notificationTitleEventApplication.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加申込'**
  String get notificationTitleEventApplication;

  /// No description provided for @notificationMessageEventApplication.
  ///
  /// In ja, this message translates to:
  /// **'{applicantName}さんが「{eventName}」に参加申込をしました'**
  String notificationMessageEventApplication(
    String applicantName,
    String eventName,
  );

  /// No description provided for @notificationTitleEventApproved.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加承認'**
  String get notificationTitleEventApproved;

  /// No description provided for @notificationMessageEventApproved.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への参加が承認されました'**
  String notificationMessageEventApproved(String eventName);

  /// No description provided for @notificationMessageEventApprovedWithMessage.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への参加が承認されました\n管理者メッセージ: {adminMessage}'**
  String notificationMessageEventApprovedWithMessage(
    String eventName,
    String adminMessage,
  );

  /// No description provided for @notificationTitleEventRejected.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加申込結果'**
  String get notificationTitleEventRejected;

  /// No description provided for @notificationMessageEventRejected.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への参加申込が承認されませんでした'**
  String notificationMessageEventRejected(String eventName);

  /// No description provided for @notificationMessageEventRejectedWithReason.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への参加申込が承認されませんでした\n理由: {reason}'**
  String notificationMessageEventRejectedWithReason(
    String eventName,
    String reason,
  );

  /// No description provided for @notificationTitleEventPendingReverted.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加申込ステータス変更'**
  String get notificationTitleEventPendingReverted;

  /// No description provided for @notificationMessageEventPendingReverted.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への参加申込が申請中に戻されました'**
  String notificationMessageEventPendingReverted(String eventName);

  /// No description provided for @notificationMessageEventPendingRevertedWithReason.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への参加申込が申請中に戻されました\n理由: {reason}'**
  String notificationMessageEventPendingRevertedWithReason(
    String eventName,
    String reason,
  );

  /// No description provided for @notificationTitleEventWaitlist.
  ///
  /// In ja, this message translates to:
  /// **'イベント満員のお知らせ'**
  String get notificationTitleEventWaitlist;

  /// No description provided for @notificationMessageEventWaitlist.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は満員となりました。あなたの申請はキャンセル待ち{position}番目として受付中です。参加者が辞退した場合、順番に承認いたします。'**
  String notificationMessageEventWaitlist(String eventName, int position);

  /// No description provided for @notificationTitleEventWaitlistRegistered.
  ///
  /// In ja, this message translates to:
  /// **'イベント満員・キャンセル待ち登録完了'**
  String get notificationTitleEventWaitlistRegistered;

  /// No description provided for @notificationMessageEventWaitlistRegistered.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は満員のため、キャンセル待ち{position}番目として登録されました。参加者が辞退した場合、順番に承認いたします。'**
  String notificationMessageEventWaitlistRegistered(
    String eventName,
    int position,
  );

  /// No description provided for @notificationTitleEventPromotedFromWaitlist.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加承認（キャンセル待ちから昇格）'**
  String get notificationTitleEventPromotedFromWaitlist;

  /// No description provided for @notificationMessageEventPromotedFromWaitlist.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」への参加が承認されました。キャンセル待ちから正式な参加者に昇格いたします。'**
  String notificationMessageEventPromotedFromWaitlist(String eventName);

  /// No description provided for @notificationTitleEventFull.
  ///
  /// In ja, this message translates to:
  /// **'イベント満員'**
  String get notificationTitleEventFull;

  /// No description provided for @notificationMessageEventFull.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は満員のため申込できませんでした'**
  String notificationMessageEventFull(String eventName);

  /// No description provided for @notificationTitleEventCapacityWarning.
  ///
  /// In ja, this message translates to:
  /// **'イベント定員間近'**
  String get notificationTitleEventCapacityWarning;

  /// No description provided for @notificationMessageEventCapacityWarning.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」の参加者数が定員の{percentage}%に達しました（{currentCount}/{maxParticipants}人）'**
  String notificationMessageEventCapacityWarning(
    String eventName,
    int percentage,
    int currentCount,
    int maxParticipants,
  );

  /// No description provided for @notificationTitleEventSlotAvailable.
  ///
  /// In ja, this message translates to:
  /// **'イベント空き枠発生'**
  String get notificationTitleEventSlotAvailable;

  /// No description provided for @notificationMessageEventSlotAvailable.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」で参加者の差し戻しにより空き枠が発生しました。キャンセル待ち{waitlistCount}名の承認をご検討ください。'**
  String notificationMessageEventSlotAvailable(
    String eventName,
    int waitlistCount,
  );

  /// No description provided for @notificationTitleNewMatchReport.
  ///
  /// In ja, this message translates to:
  /// **'新しい試合報告'**
  String get notificationTitleNewMatchReport;

  /// No description provided for @notificationMessageNewMatchReport.
  ///
  /// In ja, this message translates to:
  /// **'「{matchName}」で{issueType}の報告がありました'**
  String notificationMessageNewMatchReport(String matchName, String issueType);

  /// No description provided for @notificationTitleEventInvite.
  ///
  /// In ja, this message translates to:
  /// **'イベントに招待されました'**
  String get notificationTitleEventInvite;

  /// No description provided for @notificationMessageEventInvite.
  ///
  /// In ja, this message translates to:
  /// **'{createdByName}さんが「{eventName}」に招待しました'**
  String notificationMessageEventInvite(String createdByName, String eventName);

  /// No description provided for @notificationTitleNewFollower.
  ///
  /// In ja, this message translates to:
  /// **'新しいフォロワー'**
  String get notificationTitleNewFollower;

  /// No description provided for @notificationMessageNewFollower.
  ///
  /// In ja, this message translates to:
  /// **'{fromUserName}さんがあなたをフォローしました'**
  String notificationMessageNewFollower(String fromUserName);

  /// No description provided for @notificationTitleEventDraftReverted.
  ///
  /// In ja, this message translates to:
  /// **'イベント参加取り消し'**
  String get notificationTitleEventDraftReverted;

  /// No description provided for @notificationMessageEventDraftReverted.
  ///
  /// In ja, this message translates to:
  /// **'「{eventName}」は主催者により下書き状態に変更されたため、参加が取り消されました。'**
  String notificationMessageEventDraftReverted(String eventName);

  /// No description provided for @defaultUserDisplayName.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー'**
  String get defaultUserDisplayName;

  /// No description provided for @autoApprovedFromWaitlistMessage.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル待ちから自動承認されました'**
  String get autoApprovedFromWaitlistMessage;

  /// No description provided for @shareTextEventDate.
  ///
  /// In ja, this message translates to:
  /// **'開催'**
  String get shareTextEventDate;

  /// No description provided for @shareTextGame.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム'**
  String get shareTextGame;

  /// No description provided for @shareTextParticipants.
  ///
  /// In ja, this message translates to:
  /// **'参加者'**
  String get shareTextParticipants;

  /// No description provided for @shareTextParticipantCount.
  ///
  /// In ja, this message translates to:
  /// **'{current}/{max}人'**
  String shareTextParticipantCount(int current, int max);

  /// No description provided for @shareTextPrizeAvailable.
  ///
  /// In ja, this message translates to:
  /// **'賞品あり'**
  String get shareTextPrizeAvailable;

  /// No description provided for @shareTextDetailsLink.
  ///
  /// In ja, this message translates to:
  /// **'詳細はこちら'**
  String get shareTextDetailsLink;

  /// No description provided for @shareTextProfileLink.
  ///
  /// In ja, this message translates to:
  /// **'プロフィールはこちら'**
  String get shareTextProfileLink;

  /// No description provided for @shareHashtagGameEvent.
  ///
  /// In ja, this message translates to:
  /// **'ゲームイベント'**
  String get shareHashtagGameEvent;

  /// No description provided for @shareHashtagLookingForGamers.
  ///
  /// In ja, this message translates to:
  /// **'ゲーム仲間募集'**
  String get shareHashtagLookingForGamers;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return L10nZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
    case 'ja':
      return L10nJa();
    case 'ko':
      return L10nKo();
    case 'zh':
      return L10nZh();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
