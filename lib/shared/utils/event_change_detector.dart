import '../../data/models/event_model.dart';

/// イベント変更の種類
enum EventChangeType {
  // 重要な変更（参加者に通知すべき）
  eventDate('開催日時'),
  registrationDeadline('申込み締切'),
  maxParticipants('最大参加者数'),
  hasParticipationFee('参加費'),
  participationFeeText('参加費詳細'),
  rules('ルール'),
  eventTags('イベントタグ'),
  contactInfo('連絡先'),
  visibility('公開設定'),
  eventPassword('イベントパスワード'),
  platforms('対応プラットフォーム'),
  gameId('ゲーム'),
  status('イベントステータス'),

  // 重要度中の変更
  name('イベント名'),
  subtitle('サブタイトル'),
  description('説明'),
  additionalInfo('追加情報'),
  hasStreaming('配信'),
  streamingUrls('配信URL'),
  policy('ポリシー'),
  managerIds('共同編集者'),
  imageUrl('イベント画像'),
  language('言語設定'),
  blockedUserIds('ブロックユーザー'),
  sponsorIds('スポンサー'),

  // 軽微な変更
  hasPrize('賞品'),
  prizeContent('賞品内容'),
  participationFeeSupplement('参加費補足'),
  gameName('ゲーム名');

  const EventChangeType(this.displayName);
  final String displayName;

  /// 重要な変更かどうかを判定
  bool get isCritical {
    switch (this) {
      case EventChangeType.eventDate:
      case EventChangeType.registrationDeadline:
      case EventChangeType.maxParticipants:
      case EventChangeType.hasParticipationFee:
      case EventChangeType.participationFeeText:
      case EventChangeType.rules:
      case EventChangeType.contactInfo:
      case EventChangeType.visibility:
      case EventChangeType.eventPassword:
      case EventChangeType.platforms:
      case EventChangeType.gameId:
      case EventChangeType.status:
      case EventChangeType.eventTags:
        return true;
      default:
        return false;
    }
  }

  /// 中程度の重要度かどうかを判定
  bool get isModerate {
    switch (this) {
      case EventChangeType.name:
      case EventChangeType.subtitle:
      case EventChangeType.description:
      case EventChangeType.additionalInfo:
      case EventChangeType.hasStreaming:
      case EventChangeType.streamingUrls:
      case EventChangeType.policy:
      case EventChangeType.managerIds:
      case EventChangeType.imageUrl:
      case EventChangeType.language:
      case EventChangeType.blockedUserIds:
      case EventChangeType.sponsorIds:
        return true;
      default:
        return false;
    }
  }
}

/// イベント変更情報
class EventChange {
  final EventChangeType type;
  final String? oldValue;
  final String? newValue;
  final String description;

  const EventChange({
    required this.type,
    this.oldValue,
    this.newValue,
    required this.description,
  });

  /// 変更の表示用テキストを生成
  String get displayText {
    if (oldValue == null || newValue == null) {
      return '${type.displayName}: $description';
    }
    return '${type.displayName}: 「$oldValue」→「$newValue」';
  }

  /// 変更の詳細説明を生成
  String get detailText {
    return description;
  }
}

/// イベント変更検知結果
class EventChangeResult {
  final List<EventChange> changes;
  final bool hasCriticalChanges;
  final bool hasModerateChanges;
  final bool hasMinorChanges;

  const EventChangeResult({
    required this.changes,
    required this.hasCriticalChanges,
    required this.hasModerateChanges,
    required this.hasMinorChanges,
  });

  /// 変更がないかどうか
  bool get hasNoChanges => changes.isEmpty;

  /// 通知すべき変更があるかどうか
  bool get shouldNotify => hasCriticalChanges || hasModerateChanges;

  /// 変更のサマリーテキストを生成
  String generateSummaryText() {
    if (hasNoChanges) return '変更はありません';

    final summaryParts = <String>[];

    if (hasCriticalChanges) {
      final criticalCount = changes.where((c) => c.type.isCritical).length;
      summaryParts.add('重要な変更${criticalCount}件');
    }

    if (hasModerateChanges) {
      final moderateCount = changes.where((c) => c.type.isModerate).length;
      summaryParts.add('変更${moderateCount}件');
    }

    if (hasMinorChanges) {
      final minorCount = changes.where((c) => !c.type.isCritical && !c.type.isModerate).length;
      summaryParts.add('軽微な変更${minorCount}件');
    }

    return summaryParts.join('、');
  }

  /// 変更の詳細テキストを生成
  String generateDetailText() {
    if (hasNoChanges) return '変更はありません。';

    // 重要度順にソート（重要 > 中程度 > 軽微）
    final sortedChanges = List<EventChange>.from(changes);
    sortedChanges.sort((a, b) {
      if (a.type.isCritical && !b.type.isCritical) return -1;
      if (!a.type.isCritical && b.type.isCritical) return 1;
      if (a.type.isModerate && !b.type.isModerate && !b.type.isCritical) return -1;
      if (!a.type.isModerate && b.type.isModerate && !a.type.isCritical) return 1;
      return 0;
    });

    final details = sortedChanges.map((change) => '・${change.displayText}').toList();
    return details.join('\n');
  }
}

/// イベント変更検知ユーティリティ
class EventChangeDetector {
  /// 二つのイベントを比較して変更を検知
  static EventChangeResult detectChanges(Event oldEvent, Event newEvent) {
    final changes = <EventChange>[];

    // 各フィールドの変更をチェック
    _checkStringChange(changes, EventChangeType.name, oldEvent.name, newEvent.name);
    _checkStringChange(changes, EventChangeType.subtitle, oldEvent.subtitle, newEvent.subtitle);
    _checkStringChange(changes, EventChangeType.description, oldEvent.description, newEvent.description);
    _checkStringChange(changes, EventChangeType.rules, oldEvent.rules, newEvent.rules);
    _checkStringChange(changes, EventChangeType.additionalInfo, oldEvent.additionalInfo, newEvent.additionalInfo);
    _checkStringChange(changes, EventChangeType.contactInfo, oldEvent.contactInfo, newEvent.contactInfo);
    _checkStringChange(changes, EventChangeType.policy, oldEvent.policy, newEvent.policy);
    _checkStringChange(changes, EventChangeType.participationFeeText, oldEvent.participationFeeText, newEvent.participationFeeText);
    _checkStringChange(changes, EventChangeType.participationFeeSupplement, oldEvent.participationFeeSupplement, newEvent.participationFeeSupplement);
    _checkStringChange(changes, EventChangeType.prizeContent, oldEvent.prizeContent, newEvent.prizeContent);
    _checkStringChange(changes, EventChangeType.eventPassword, oldEvent.eventPassword, newEvent.eventPassword);
    _checkStringChange(changes, EventChangeType.imageUrl, oldEvent.imageUrl, newEvent.imageUrl);
    _checkStringChange(changes, EventChangeType.gameId, oldEvent.gameId, newEvent.gameId);
    _checkStringChange(changes, EventChangeType.gameName, oldEvent.gameName, newEvent.gameName);
    _checkStringChange(changes, EventChangeType.language, oldEvent.language, newEvent.language);

    // 日時の変更
    _checkDateTimeChange(changes, EventChangeType.eventDate, oldEvent.eventDate, newEvent.eventDate);
    _checkDateTimeChange(changes, EventChangeType.registrationDeadline, oldEvent.registrationDeadline, newEvent.registrationDeadline);

    // 数値の変更
    _checkIntChange(changes, EventChangeType.maxParticipants, oldEvent.maxParticipants, newEvent.maxParticipants);

    // ブール値の変更
    _checkBoolChange(changes, EventChangeType.hasParticipationFee, oldEvent.hasParticipationFee, newEvent.hasParticipationFee);
    _checkBoolChange(changes, EventChangeType.hasPrize, oldEvent.hasPrize, newEvent.hasPrize);
    _checkBoolChange(changes, EventChangeType.hasStreaming, oldEvent.hasStreaming, newEvent.hasStreaming);

    // 列挙型の変更
    _checkEnumChange(changes, EventChangeType.visibility, oldEvent.visibility, newEvent.visibility);
    _checkEnumChange(changes, EventChangeType.status, oldEvent.status, newEvent.status);

    // リストの変更
    _checkListChange(changes, EventChangeType.platforms, oldEvent.platforms, newEvent.platforms);
    _checkListChange(changes, EventChangeType.eventTags, oldEvent.eventTags, newEvent.eventTags);
    _checkListChange(changes, EventChangeType.streamingUrls, oldEvent.streamingUrls, newEvent.streamingUrls);
    _checkListChange(changes, EventChangeType.managerIds, oldEvent.managerIds, newEvent.managerIds);
    _checkListChange(changes, EventChangeType.sponsorIds, oldEvent.sponsorIds, newEvent.sponsorIds);
    _checkListChange(changes, EventChangeType.blockedUserIds, oldEvent.blockedUserIds, newEvent.blockedUserIds);

    // 変更レベルを分析
    final hasCritical = changes.any((c) => c.type.isCritical);
    final hasModerate = changes.any((c) => c.type.isModerate);
    final hasMinor = changes.any((c) => !c.type.isCritical && !c.type.isModerate);

    return EventChangeResult(
      changes: changes,
      hasCriticalChanges: hasCritical,
      hasModerateChanges: hasModerate,
      hasMinorChanges: hasMinor,
    );
  }

  /// 文字列の変更をチェック
  static void _checkStringChange(
    List<EventChange> changes,
    EventChangeType type,
    String? oldValue,
    String? newValue,
  ) {
    if (oldValue != newValue) {
      final oldDisplay = oldValue?.isEmpty == true ? '（未設定）' : oldValue ?? '（未設定）';
      final newDisplay = newValue?.isEmpty == true ? '（未設定）' : newValue ?? '（未設定）';

      // 長い文字列は省略表示
      final oldDisplayTruncated = oldDisplay.length > 50 ? '${oldDisplay.substring(0, 47)}...' : oldDisplay;
      final newDisplayTruncated = newDisplay.length > 50 ? '${newDisplay.substring(0, 47)}...' : newDisplay;

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplayTruncated,
        newValue: newDisplayTruncated,
        description: '「$oldDisplayTruncated」から「$newDisplayTruncated」に変更されました',
      ));
    }
  }

  /// 日時の変更をチェック
  static void _checkDateTimeChange(
    List<EventChange> changes,
    EventChangeType type,
    DateTime? oldValue,
    DateTime? newValue,
  ) {
    if (oldValue != newValue) {
      final oldDisplay = oldValue != null ? _formatDateTime(oldValue) : 'なし';
      final newDisplay = newValue != null ? _formatDateTime(newValue) : 'なし';

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        description: '「$oldDisplay」から「$newDisplay」に変更されました',
      ));
    }
  }

  /// 整数の変更をチェック
  static void _checkIntChange(
    List<EventChange> changes,
    EventChangeType type,
    int oldValue,
    int newValue,
  ) {
    if (oldValue != newValue) {
      changes.add(EventChange(
        type: type,
        oldValue: oldValue.toString(),
        newValue: newValue.toString(),
        description: '「$oldValue」から「$newValue」に変更されました',
      ));
    }
  }

  /// ブール値の変更をチェック
  static void _checkBoolChange(
    List<EventChange> changes,
    EventChangeType type,
    bool oldValue,
    bool newValue,
  ) {
    if (oldValue != newValue) {
      final oldDisplay = oldValue ? 'あり' : 'なし';
      final newDisplay = newValue ? 'あり' : 'なし';

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        description: '「$oldDisplay」から「$newDisplay」に変更されました',
      ));
    }
  }

  /// 列挙型の変更をチェック
  static void _checkEnumChange<T extends Enum>(
    List<EventChange> changes,
    EventChangeType type,
    T oldValue,
    T newValue,
  ) {
    if (oldValue != newValue) {
      final oldDisplay = _formatEnumValue(oldValue);
      final newDisplay = _formatEnumValue(newValue);

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        description: '「$oldDisplay」から「$newDisplay」に変更されました',
      ));
    }
  }

  /// リストの変更をチェック
  static void _checkListChange<T>(
    List<EventChange> changes,
    EventChangeType type,
    List<T> oldList,
    List<T> newList,
  ) {
    // リストの長さや内容が異なる場合
    if (oldList.length != newList.length || !_listsEqual(oldList, newList)) {
      final oldDisplay = oldList.isEmpty ? '（未設定）' : oldList.join(', ');
      final newDisplay = newList.isEmpty ? '（未設定）' : newList.join(', ');

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        description: _generateListChangeDescription(oldList, newList),
      ));
    }
  }

  /// リストの等価性をチェック
  static bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  /// リスト変更の説明文を生成
  static String _generateListChangeDescription<T>(List<T> oldList, List<T> newList) {
    final added = newList.where((item) => !oldList.contains(item)).toList();
    final removed = oldList.where((item) => !newList.contains(item)).toList();

    final parts = <String>[];
    if (added.isNotEmpty) {
      parts.add('追加: ${added.join(', ')}');
    }
    if (removed.isNotEmpty) {
      parts.add('削除: ${removed.join(', ')}');
    }

    if (parts.isEmpty) {
      return '順序が変更されました';
    }

    return parts.join('、');
  }

  /// 日時をフォーマット
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 列挙型の表示名を取得
  static String _formatEnumValue<T extends Enum>(T value) {
    if (value is EventVisibility) {
      switch (value) {
        case EventVisibility.public:
          return 'パブリック';
        case EventVisibility.private:
          return 'プライベート';
        case EventVisibility.inviteOnly:
          return '招待制';
      }
    }
    if (value is EventStatus) {
      switch (value) {
        case EventStatus.draft:
          return '下書き';
        case EventStatus.published:
          return '公開中';
        case EventStatus.cancelled:
          return '中止';
        case EventStatus.completed:
          return '完了';
      }
    }
    return value.name;
  }
}