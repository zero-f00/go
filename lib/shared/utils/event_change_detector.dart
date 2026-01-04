import '../../data/models/event_model.dart';
import '../../l10n/app_localizations.dart';

/// イベント変更の種類
enum EventChangeType {
  // 重要な変更（参加者に通知すべき）
  eventDate,
  registrationDeadline,
  maxParticipants,
  hasParticipationFee,
  participationFeeText,
  rules,
  eventTags,
  contactInfo,
  visibility,
  eventPassword,
  platforms,
  gameId,
  status,

  // 重要度中の変更
  name,
  subtitle,
  description,
  additionalInfo,
  hasStreaming,
  streamingUrls,
  policy,
  managerIds,
  imageUrl,
  language,
  blockedUserIds,
  sponsorIds,

  // 軽微な変更
  hasPrize,
  prizeContent,
  participationFeeSupplement,
  gameName;

  /// ローカライズされた表示名を取得
  /// [l10n]がnullの場合は英語のデフォルト名を返す
  String getLocalizedName([L10n? l10n]) {
    if (l10n == null) {
      return _getDefaultName();
    }
    switch (this) {
      case EventChangeType.eventDate:
        return l10n.eventChangeTypeEventDate;
      case EventChangeType.registrationDeadline:
        return l10n.eventChangeTypeRegistrationDeadline;
      case EventChangeType.maxParticipants:
        return l10n.eventChangeTypeMaxParticipants;
      case EventChangeType.hasParticipationFee:
        return l10n.eventChangeTypeHasParticipationFee;
      case EventChangeType.participationFeeText:
        return l10n.eventChangeTypeParticipationFeeText;
      case EventChangeType.rules:
        return l10n.eventChangeTypeRules;
      case EventChangeType.eventTags:
        return l10n.eventChangeTypeEventTags;
      case EventChangeType.contactInfo:
        return l10n.eventChangeTypeContactInfo;
      case EventChangeType.visibility:
        return l10n.eventChangeTypeVisibility;
      case EventChangeType.eventPassword:
        return l10n.eventChangeTypeEventPassword;
      case EventChangeType.platforms:
        return l10n.eventChangeTypePlatforms;
      case EventChangeType.gameId:
        return l10n.eventChangeTypeGameId;
      case EventChangeType.status:
        return l10n.eventChangeTypeStatus;
      case EventChangeType.name:
        return l10n.eventChangeTypeName;
      case EventChangeType.subtitle:
        return l10n.eventChangeTypeSubtitle;
      case EventChangeType.description:
        return l10n.eventChangeTypeDescription;
      case EventChangeType.additionalInfo:
        return l10n.eventChangeTypeAdditionalInfo;
      case EventChangeType.hasStreaming:
        return l10n.eventChangeTypeHasStreaming;
      case EventChangeType.streamingUrls:
        return l10n.eventChangeTypeStreamingUrls;
      case EventChangeType.policy:
        return l10n.eventChangeTypePolicy;
      case EventChangeType.managerIds:
        return l10n.eventChangeTypeManagerIds;
      case EventChangeType.imageUrl:
        return l10n.eventChangeTypeImageUrl;
      case EventChangeType.language:
        return l10n.eventChangeTypeLanguage;
      case EventChangeType.blockedUserIds:
        return l10n.eventChangeTypeBlockedUserIds;
      case EventChangeType.sponsorIds:
        return l10n.eventChangeTypeSponsorIds;
      case EventChangeType.hasPrize:
        return l10n.eventChangeTypeHasPrize;
      case EventChangeType.prizeContent:
        return l10n.eventChangeTypePrizeContent;
      case EventChangeType.participationFeeSupplement:
        return l10n.eventChangeTypeParticipationFeeSupplement;
      case EventChangeType.gameName:
        return l10n.eventChangeTypeGameName;
    }
  }

  /// デフォルトの英語名を取得
  String _getDefaultName() {
    switch (this) {
      case EventChangeType.eventDate:
        return 'Event Date';
      case EventChangeType.registrationDeadline:
        return 'Registration Deadline';
      case EventChangeType.maxParticipants:
        return 'Max Participants';
      case EventChangeType.hasParticipationFee:
        return 'Has Participation Fee';
      case EventChangeType.participationFeeText:
        return 'Participation Fee';
      case EventChangeType.rules:
        return 'Rules';
      case EventChangeType.eventTags:
        return 'Event Tags';
      case EventChangeType.contactInfo:
        return 'Contact Info';
      case EventChangeType.visibility:
        return 'Visibility';
      case EventChangeType.eventPassword:
        return 'Event Password';
      case EventChangeType.platforms:
        return 'Platforms';
      case EventChangeType.gameId:
        return 'Game';
      case EventChangeType.status:
        return 'Status';
      case EventChangeType.name:
        return 'Name';
      case EventChangeType.subtitle:
        return 'Subtitle';
      case EventChangeType.description:
        return 'Description';
      case EventChangeType.additionalInfo:
        return 'Additional Info';
      case EventChangeType.hasStreaming:
        return 'Has Streaming';
      case EventChangeType.streamingUrls:
        return 'Streaming URLs';
      case EventChangeType.policy:
        return 'Policy';
      case EventChangeType.managerIds:
        return 'Managers';
      case EventChangeType.imageUrl:
        return 'Image';
      case EventChangeType.language:
        return 'Language';
      case EventChangeType.blockedUserIds:
        return 'Blocked Users';
      case EventChangeType.sponsorIds:
        return 'Sponsors';
      case EventChangeType.hasPrize:
        return 'Has Prize';
      case EventChangeType.prizeContent:
        return 'Prize Content';
      case EventChangeType.participationFeeSupplement:
        return 'Fee Supplement';
      case EventChangeType.gameName:
        return 'Game Name';
    }
  }

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
  /// 変更の説明用キー（ローカライズ時に解決）
  final EventChangeDescriptionKey descriptionKey;

  const EventChange({
    required this.type,
    this.oldValue,
    this.newValue,
    required this.descriptionKey,
  });

  /// 変更の表示用テキストを生成（ローカライズ対応）
  /// [l10n]がnullの場合は英語のデフォルトテキストを返す
  String getDisplayText([L10n? l10n]) {
    final typeName = type.getLocalizedName(l10n);
    final localizedOldValue = _localizeValue(l10n, oldValue);
    final localizedNewValue = _localizeValue(l10n, newValue);
    if (l10n != null) {
      return l10n.eventChangeDisplayFormat(typeName, localizedOldValue, localizedNewValue);
    }
    return '$typeName: $localizedOldValue → $localizedNewValue';
  }

  /// 変更の詳細説明を生成（ローカライズ対応）
  /// [l10n]がnullの場合は英語のデフォルトテキストを返す
  String getDetailText([L10n? l10n]) {
    final localizedOldValue = _localizeValue(l10n, oldValue);
    final localizedNewValue = _localizeValue(l10n, newValue);
    if (l10n != null) {
      return l10n.eventChangeValueChanged(localizedOldValue, localizedNewValue);
    }
    return '$localizedOldValue → $localizedNewValue';
  }

  /// 値をローカライズ
  String _localizeValue(L10n? l10n, String? value) {
    if (value == null) {
      return l10n?.eventChangeNotSet ?? 'Not set';
    }
    // 特殊キーをローカライズ
    switch (value) {
      case '_yes':
        return l10n?.eventChangeYes ?? 'Yes';
      case '_no':
        return l10n?.eventChangeNo ?? 'No';
      case '_visibility_public':
        return l10n?.visibilityPublic ?? 'Public';
      case '_visibility_private':
        return l10n?.visibilityPrivate ?? 'Private';
      case '_visibility_inviteOnly':
        return l10n?.visibilityInviteOnly ?? 'Invite Only';
      case '_status_draft':
        return l10n?.eventStatusDraft ?? 'Draft';
      case '_status_published':
        return l10n?.eventStatusPublished ?? 'Published';
      case '_status_cancelled':
        return l10n?.eventStatusCancelled ?? 'Cancelled';
      case '_status_completed':
        return l10n?.eventStatusCompleted ?? 'Completed';
      default:
        return value;
    }
  }
}

/// 変更説明のキー
enum EventChangeDescriptionKey {
  valueChanged,
  listAdded,
  listRemoved,
  listAddedAndRemoved,
  orderChanged;
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

  /// 変更のサマリーテキストを生成（ローカライズ対応）
  /// [l10n]がnullの場合は英語のデフォルトテキストを返す
  String generateSummaryText([L10n? l10n]) {
    if (hasNoChanges) {
      return l10n?.eventChangeSummaryNoChanges ?? 'No changes';
    }

    final summaryParts = <String>[];

    if (hasCriticalChanges) {
      final criticalCount = changes.where((c) => c.type.isCritical).length;
      summaryParts.add(l10n?.eventChangeSummaryCritical(criticalCount) ?? '$criticalCount critical changes');
    }

    if (hasModerateChanges) {
      final moderateCount = changes.where((c) => c.type.isModerate).length;
      summaryParts.add(l10n?.eventChangeSummaryModerate(moderateCount) ?? '$moderateCount moderate changes');
    }

    if (hasMinorChanges) {
      final minorCount = changes.where((c) => !c.type.isCritical && !c.type.isModerate).length;
      summaryParts.add(l10n?.eventChangeSummaryMinor(minorCount) ?? '$minorCount minor changes');
    }

    return summaryParts.join(l10n?.listSeparator ?? ', ');
  }

  /// 変更の詳細テキストを生成（ローカライズ対応）
  /// [l10n]がnullの場合は英語のデフォルトテキストを返す
  String generateDetailText([L10n? l10n]) {
    if (hasNoChanges) {
      return l10n?.eventChangeSummaryNoChanges ?? 'No changes';
    }

    // 重要度順にソート（重要 > 中程度 > 軽微）
    final sortedChanges = List<EventChange>.from(changes);
    sortedChanges.sort((a, b) {
      if (a.type.isCritical && !b.type.isCritical) return -1;
      if (!a.type.isCritical && b.type.isCritical) return 1;
      if (a.type.isModerate && !b.type.isModerate && !b.type.isCritical) return -1;
      if (!a.type.isModerate && b.type.isModerate && !a.type.isCritical) return 1;
      return 0;
    });

    final details = sortedChanges.map((change) {
      final displayText = change.getDisplayText(l10n);
      return l10n?.eventChangeDetailBullet(displayText) ?? '• $displayText';
    }).toList();
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
  /// 注意: oldValue/newValueにはローカライズ用のプレースホルダーキーを格納
  static void _checkStringChange(
    List<EventChange> changes,
    EventChangeType type,
    String? oldValue,
    String? newValue,
  ) {
    if (oldValue != newValue) {
      // 未設定の場合はnullを渡し、表示時にローカライズ
      final oldIsEmpty = oldValue?.isEmpty == true;
      final newIsEmpty = newValue?.isEmpty == true;

      // 長い文字列は省略表示
      String? oldDisplayTruncated;
      String? newDisplayTruncated;

      if (!oldIsEmpty && oldValue != null) {
        oldDisplayTruncated = oldValue.length > 50 ? '${oldValue.substring(0, 47)}...' : oldValue;
      }
      if (!newIsEmpty && newValue != null) {
        newDisplayTruncated = newValue.length > 50 ? '${newValue.substring(0, 47)}...' : newValue;
      }

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplayTruncated,
        newValue: newDisplayTruncated,
        descriptionKey: EventChangeDescriptionKey.valueChanged,
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
      final oldDisplay = oldValue != null ? _formatDateTime(oldValue) : null;
      final newDisplay = newValue != null ? _formatDateTime(newValue) : null;

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        descriptionKey: EventChangeDescriptionKey.valueChanged,
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
        descriptionKey: EventChangeDescriptionKey.valueChanged,
      ));
    }
  }

  /// ブール値の変更をチェック
  /// 注意: oldValue/newValueにはローカライズ用のキー（_yes/_no）を格納し、表示時に解決
  static void _checkBoolChange(
    List<EventChange> changes,
    EventChangeType type,
    bool oldValue,
    bool newValue,
  ) {
    if (oldValue != newValue) {
      // ブール値はキーとして保存し、表示時にローカライズ
      final oldDisplay = oldValue ? '_yes' : '_no';
      final newDisplay = newValue ? '_yes' : '_no';

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        descriptionKey: EventChangeDescriptionKey.valueChanged,
      ));
    }
  }

  /// 列挙型の変更をチェック
  /// 注意: 列挙型の値名を格納し、表示時にローカライズ
  static void _checkEnumChange<T extends Enum>(
    List<EventChange> changes,
    EventChangeType type,
    T oldValue,
    T newValue,
  ) {
    if (oldValue != newValue) {
      // 列挙型のキーを格納（表示時にローカライズ）
      final oldDisplay = _getEnumKey(oldValue);
      final newDisplay = _getEnumKey(newValue);

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        descriptionKey: EventChangeDescriptionKey.valueChanged,
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
      final oldDisplay = oldList.isEmpty ? null : oldList.join(', ');
      final newDisplay = newList.isEmpty ? null : newList.join(', ');

      final descriptionKey = _getListChangeDescriptionKey(oldList, newList);

      changes.add(EventChange(
        type: type,
        oldValue: oldDisplay,
        newValue: newDisplay,
        descriptionKey: descriptionKey,
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

  /// リスト変更の説明キーを取得
  static EventChangeDescriptionKey _getListChangeDescriptionKey<T>(List<T> oldList, List<T> newList) {
    final added = newList.where((item) => !oldList.contains(item)).toList();
    final removed = oldList.where((item) => !newList.contains(item)).toList();

    if (added.isNotEmpty && removed.isNotEmpty) {
      return EventChangeDescriptionKey.listAddedAndRemoved;
    } else if (added.isNotEmpty) {
      return EventChangeDescriptionKey.listAdded;
    } else if (removed.isNotEmpty) {
      return EventChangeDescriptionKey.listRemoved;
    }
    return EventChangeDescriptionKey.orderChanged;
  }

  /// 日時をフォーマット
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 列挙型のキーを取得（ローカライズ用）
  static String _getEnumKey<T extends Enum>(T value) {
    if (value is EventVisibility) {
      switch (value) {
        case EventVisibility.public:
          return '_visibility_public';
        case EventVisibility.private:
          return '_visibility_private';
        case EventVisibility.inviteOnly:
          return '_visibility_inviteOnly';
      }
    }
    if (value is EventStatus) {
      switch (value) {
        case EventStatus.draft:
          return '_status_draft';
        case EventStatus.published:
          return '_status_published';
        case EventStatus.cancelled:
          return '_status_cancelled';
        case EventStatus.completed:
          return '_status_completed';
      }
    }
    return value.name;
  }
}

/// EventChangeの表示用ヘルパー拡張
extension EventChangeDisplayExtension on EventChange {
  /// ローカライズされた古い値を取得
  String getLocalizedOldValue(L10n l10n) {
    return _localizeValue(l10n, oldValue);
  }

  /// ローカライズされた新しい値を取得
  String getLocalizedNewValue(L10n l10n) {
    return _localizeValue(l10n, newValue);
  }

  String _localizeValue(L10n l10n, String? value) {
    if (value == null) {
      return l10n.eventChangeNotSet;
    }
    // 特殊キーをローカライズ
    switch (value) {
      case '_yes':
        return l10n.eventChangeYes;
      case '_no':
        return l10n.eventChangeNo;
      case '_visibility_public':
        return l10n.visibilityPublic;
      case '_visibility_private':
        return l10n.visibilityPrivate;
      case '_visibility_inviteOnly':
        return l10n.visibilityInviteOnly;
      case '_status_draft':
        return l10n.eventStatusDraft;
      case '_status_published':
        return l10n.eventStatusPublished;
      case '_status_cancelled':
        return l10n.eventStatusCancelled;
      case '_status_completed':
        return l10n.eventStatusCompleted;
      default:
        return value;
    }
  }
}