class AppStrings {
  AppStrings._();

  // App title
  static const String appTitle = 'Go - ゲームイベント管理';
  // User labels
  static const String guestUser = 'ゲストユーザー';

  // Screen titles
  static const String gameEventManagementTitle = 'ゲームイベント管理';

  // Tab labels
  static const String eventManagementTab = 'イベント管理';
  static const String analyticsTab = '分析データ';

  // Event type labels
  static const String dailyEvents = 'デイリー';
  static const String weeklyEvents = 'ウィークリー';
  static const String specialEvents = 'スペシャル';
  static const String seasonalEvents = 'シーズナル';

  // Event status labels
  static const String statusUpcoming = '開催予定';
  static const String statusActive = '開催中';
  static const String statusCompleted = '完了';
  static const String statusExpired = '期限切れ';

  // Quick action labels
  static const String createNew = '新規作成';
  static const String template = 'テンプレート';
  static const String batchOperation = '一括操作';

  // Statistics labels
  static const String participantCount = '参加者数';
  static const String completionRate = '達成率';
  static const String activeEvents = 'アクティブイベント';
  static const String totalParticipants = '総参加者数';
  static const String averageCompletion = '平均達成率';

  // Unit suffixes
  static const String peopleUnit = '人';
  static const String percentUnit = '%';
  static const String countUnit = '件';

  // Section titles
  static const String eventOverview = 'イベント概要';
  static const String participationTrend = '参加者推移';
  static const String eventTypeAnalysis = 'イベントタイプ別分析';
  static const String eventDetails = 'イベント詳細';
  static const String rewardList = '賞品一覧';

  // Common actions
  static const String edit = '編集';
  static const String close = '閉じる';
  static const String save = '保存';
  static const String cancel = 'キャンセル';

  // Menu items
  static const String menu = 'メニュー';
  static const String settings = '設定';
  static const String dataExport = 'データエクスポート';

  // Dialog titles
  static const String createEventDialog = '新規イベント作成';
  static const String templateDialog = 'テンプレート選択';
  static const String batchOperationDialog = '一括操作';

  // Placeholder messages
  static const String noEventsMessage = 'イベントはありません';
  static const String createEventSuggestion = '新しいイベントを作成しましょう';
  static const String chartPlaceholder = 'チャート表示エリア\n(実装時にはfl_chartライブラリを使用)';
  static const String featureNotImplemented = '機能を実装';

  // Premium label
  static const String premiumLabel = 'PRO';

  // Date format labels
  static const String startDateTime = '開始日時';
  static const String endDateTime = '終了日時';

  // Reward types
  static const String coinReward = 'コイン';
  static const String gemReward = 'ジェム';
  static const String expReward = '経験値';
  static const String rareItemReward = 'レアアイテム';
  static const String limitedCharacterReward = '限定キャラクター';
  static const String trophyReward = 'トロフィー';
  static const String titleReward = '称号';

  // Analysis labels
  static const String averageParticipation = '平均参加者';

  // Bottom navigation labels
  static const String homeTab = 'ホーム';
  static const String searchTab = '探す';
  static const String manageTab = '管理';
  static const String notificationTab = '通知';

  // Management screen tab labels
  static const String hostEventTab = '主催イベント管理';
  static const String participantEventTab = '参加イベント管理';

  // Event creation screen labels
  static const String createEventTitle = '新規イベント作成';
  static const String basicInfoSection = '基本情報';
  static const String eventNameLabel = 'イベント名';
  static const String eventNameHint = 'イベント名を入力してください';
  static const String subtitleLabel = 'サブタイトル';
  static const String subtitleHint = 'サブタイトルを入力（任意）';
  static const String descriptionLabel = 'イベント詳細説明';
  static const String descriptionHint = 'イベントの詳細な説明を入力してください';
  static const String rulesLabel = 'ルール';
  static const String rulesHint = 'イベントのルールを入力してください';
  static const String imageLabel = 'イベント画像';
  static const String addImageButton = '画像を追加';

  static const String scheduleSection = '開催設定';
  static const String eventDateLabel = '開催日時';
  static const String registrationDeadlineLabel = '申込期限';

  static const String gameSettingsSection = 'ゲーム・参加設定';
  static const String gameSelectionLabel = 'ゲーム選択';
  static const String platformLabel = '対象プラットフォーム';
  static const String maxParticipantsLabel = '最大参加者数';
  static const String additionalInfoLabel = '追加情報・注意事項';
  static const String additionalInfoHint = '参加条件、ルール補足、注意事項などを入力してください';
  static const String approvalMethodLabel = '参加承認方式';

  // Event tag labels
  static const String eventTagsLabel = 'イベントタグ';
  static const String eventTagsHint = 'タグを入力してEnter';
  static const String addTagButton = 'タグ追加';
  static const String removeTagButton = 'タグ削除';

  static const String prizeSection = '賞品';
  static const String hasPrizeLabel = '賞品あり';
  static const String prizeContentLabel = '賞品内容';
  static const String sponsorsLabel = 'スポンサー';

  static const String managementSection = '運営・管理';
  static const String managersLabel = '管理者・運営メンバー';

  static const String categorySection = '公開設定';
  static const String visibilityLabel = '公開範囲';
  static const String languageLabel = '言語設定';

  // 招待機能関連
  static const String invitationSection = '招待設定';
  static const String eventPasswordLabel = 'イベントパスワード';
  static const String eventPasswordHint = '参加に必要なパスワードを設定してください';
  static const String inviteMembersLabel = '招待メンバー';
  static const String invitePasswordRequired = '招待制イベントはパスワードの設定が必須です';

  static const String externalSection = '外部連携';
  static const String contactLabel = 'コミュニティ・その他';
  static const String streamingLabel = '配信予定';
  static const String streamingUrlLabel = '配信URL';
  static const String streamingUrlHint = 'YouTube、Twitch等の配信URLを入力してください';

  static const String otherSection = 'その他';
  static const String ageRestrictionLabel = '年齢制限';
  static const String minAgeLabel = '最低年齢';
  static const String minAgeHint = '参加可能な最低年齢を入力してください';
  static const String policyLabel = 'キャンセル・変更ポリシー';

  static const String createEventButton = 'イベントを作成';
  static const String saveDraftButton = '下書き保存';

  // Platform options
  static const String iosLabel = 'iOS';
  static const String androidLabel = 'Android';

  // Firestore error messages
  static const String firestorePermissionDenied = 'データベースへのアクセス権限がありません';
  static const String firestoreNotFound = 'データが見つかりませんでした';
  static const String firestoreAlreadyExists = 'すでに存在するデータです';
  static const String firestoreNetworkError = 'ネットワークエラーが発生しました。インターネット接続を確認してください';
  static const String firestoreUnknownError = 'データベースエラーが発生しました';

  // User profile screen
  static const String userProfile = 'プロフィール';

}