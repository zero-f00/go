import 'package:cloud_firestore/cloud_firestore.dart';

class GameEvent {
  final String id;
  final String name;
  final String? subtitle;
  final String description;
  final GameEventType type;
  final GameEventStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final int maxParticipants;
  final double completionRate;
  final bool isPremium;
  final bool hasFee;
  final Map<String, double> rewards;
  final String? gameId;
  final String? gameName;
  final String? gameIconUrl;
  final String? imageUrl;

  // イベント作成画面の追加項目
  final String? rules;
  final DateTime? registrationDeadline;
  final DateTime? participationCancelDeadline; // ユーザーキャンセル期限
  final String? prizeContent;
  final String? contactInfo;
  final String? policy;
  final String? additionalInfo;
  final List<String> streamingUrls;
  final int? minAge;
  final double? feeAmount;
  final String? feeText; // 参加費テキスト（自由入力対応）
  final String? feeSupplement;
  final List<String> platforms;
  final String approvalMethod;
  final String visibility;
  final String language;
  final bool hasAgeRestriction;
  final bool hasStreaming;
  final List<String> eventTags;
  final List<String> sponsors;
  final List<String> managers;
  final List<String> blockedUsers;

  // 招待制イベント用
  final String? eventPassword;
  final List<String> invitedUserIds;

  // 主催者情報
  final String? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? lastUpdatedBy;
  final String? lastUpdatedByName;

  // 中止情報
  final String? cancellationReason;
  final DateTime? cancelledAt;

  const GameEvent({
    required this.id,
    required this.name,
    this.subtitle,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
    required this.maxParticipants,
    required this.completionRate,
    this.isPremium = false,
    this.hasFee = false,
    this.rewards = const {},
    this.gameId,
    this.gameName,
    this.gameIconUrl,
    this.imageUrl,
    this.rules,
    this.registrationDeadline,
    this.participationCancelDeadline,
    this.prizeContent,
    this.contactInfo,
    this.policy,
    this.additionalInfo,
    this.streamingUrls = const [],
    this.minAge,
    this.feeAmount,
    this.feeText,
    this.feeSupplement,
    this.platforms = const [],
    this.approvalMethod = '自動承認',
    this.visibility = 'パブリック',
    this.language = '日本語',
    this.hasAgeRestriction = false,
    this.hasStreaming = false,
    this.eventTags = const [],
    this.sponsors = const [],
    this.managers = const [],
    this.blockedUsers = const [],
    this.eventPassword,
    this.invitedUserIds = const [],
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.lastUpdatedBy,
    this.lastUpdatedByName,
    this.cancellationReason,
    this.cancelledAt,
  });

  /// FirestoreドキュメントからGameEventを作成
  factory GameEvent.fromFirestore(Map<String, dynamic> data, String documentId) {

    final gameEvent = GameEvent(
      id: documentId,
      name: data['name'] as String? ?? '',
      subtitle: data['subtitle'] as String?,
      description: data['description'] as String? ?? '',
      type: GameEventType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GameEventType.special,
      ),
      status: GameEventStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GameEventStatus.upcoming,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 1)),
      participantCount: data['participantCount'] as int? ?? 0,
      maxParticipants: data['maxParticipants'] as int? ?? 100,
      completionRate: (data['completionRate'] as num?)?.toDouble() ?? 0.0,
      isPremium: data['isPremium'] as bool? ?? false,
      hasFee: data['hasFee'] as bool? ?? false,
      rewards: Map<String, double>.from(data['rewards'] as Map<String, dynamic>? ?? {}),
      gameId: data['gameId'] as String?,
      gameName: data['gameName'] as String?,
      gameIconUrl: data['gameIconUrl'] as String?,
      imageUrl: data['imageUrl'] as String?,
      rules: data['rules'] as String?,
      registrationDeadline: (data['registrationDeadline'] as Timestamp?)?.toDate(),
      prizeContent: data['prizeContent'] as String?,
      contactInfo: data['contactInfo'] as String?,
      policy: data['policy'] as String?,
      additionalInfo: data['additionalInfo'] as String?,
      streamingUrls: List<String>.from(data['streamingUrls'] as List<dynamic>? ?? []),
      minAge: data['minAge'] as int?,
      feeAmount: (data['feeAmount'] as num?)?.toDouble(),
      feeText: data['feeText'] as String?,
      feeSupplement: data['feeSupplement'] as String?,
      platforms: List<String>.from(data['platforms'] as List<dynamic>? ?? []),
      approvalMethod: data['approvalMethod'] as String? ?? '自動承認',
      visibility: _parseVisibility(data['visibility']),
      language: data['language'] as String? ?? '日本語',
      hasAgeRestriction: data['hasAgeRestriction'] as bool? ?? false,
      hasStreaming: data['hasStreaming'] as bool? ?? false,
      eventTags: List<String>.from(data['eventTags'] as List<dynamic>? ?? []),
      sponsors: List<String>.from(data['sponsorIds'] as List<dynamic>? ?? []),
      managers: List<String>.from(data['managerIds'] as List<dynamic>? ?? []),
      blockedUsers: List<String>.from(data['blockedUserIds'] as List<dynamic>? ?? []),
      eventPassword: data['eventPassword'] as String?,
      invitedUserIds: List<String>.from(data['invitedUserIds'] as List<dynamic>? ?? []),
      createdBy: data['createdBy'] as String?,
      createdByName: data['createdByName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      lastUpdatedBy: data['lastUpdatedBy'] as String?,
      lastUpdatedByName: data['lastUpdatedByName'] as String?,
      cancellationReason: data['cancellationReason'] as String?,
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
    );

    return gameEvent;
  }

  /// 満員かどうかを判定
  bool get isFull => participantCount >= maxParticipants;

  /// 申込期限が切れているかどうかを判定
  bool get isRegistrationExpired =>
    registrationDeadline != null && DateTime.now().isAfter(registrationDeadline!);

  /// 申込期限まで残り日数を取得
  int? get daysUntilRegistrationDeadline {
    if (registrationDeadline == null) return null;
    final now = DateTime.now();
    if (now.isAfter(registrationDeadline!)) return 0;
    return registrationDeadline!.difference(now).inDays;
  }

  /// visibilityの英語表記を日本語表記に変換
  static String _parseVisibility(dynamic value) {
    if (value == null) return 'パブリック';
    switch (value.toString()) {
      case 'inviteOnly':
      case '招待制':
        return '招待制';
      case 'private':
      case 'プライベート':
        return 'プライベート';
      case 'public':
      case 'パブリック':
      default:
        return 'パブリック';
    }
  }
}

enum GameEventType {
  daily,
  weekly,
  special,
  seasonal;

  String get displayName {
    switch (this) {
      case GameEventType.daily:
        return 'デイリー';
      case GameEventType.weekly:
        return 'ウィークリー';
      case GameEventType.special:
        return 'スペシャル';
      case GameEventType.seasonal:
        return 'シーズナル';
    }
  }
}

enum GameEventStatus {
  draft,
  published,
  upcoming,
  active,
  completed,
  expired,
  cancelled;

  String get displayName {
    switch (this) {
      case GameEventStatus.draft:
        return '下書き';
      case GameEventStatus.published:
        return '公開済み';
      case GameEventStatus.upcoming:
        return '開催予定';
      case GameEventStatus.active:
        return '開催中';
      case GameEventStatus.completed:
        return '完了';
      case GameEventStatus.expired:
        return '期限切れ';
      case GameEventStatus.cancelled:
        return '中止';
    }
  }
}