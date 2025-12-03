import 'package:cloud_firestore/cloud_firestore.dart';

/// イベントのステータス
enum EventStatus {
  draft,     // 下書き
  scheduled, // 予約公開
  published, // 公開中
  cancelled, // キャンセル
  completed, // 完了
}

/// イベントの公開設定
enum EventVisibility {
  public,    // パブリック
  private,   // プライベート
  inviteOnly // 招待制
}

/// イベントデータモデル
class Event {
  final String id;
  final String name;
  final String? subtitle;
  final String description;
  final String rules;
  final String? imageUrl;
  final String? gameId;
  final String? gameName; // 検索最適化用
  final List<String> platforms;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final int maxParticipants;
  final String? additionalInfo;
  final bool hasParticipationFee;
  final String? participationFeeText;
  final String? participationFeeSupplement;
  final bool hasPrize;
  final String? prizeContent;
  final List<String> sponsorIds;
  final List<String> managerIds;
  final List<String> blockedUserIds;
  final EventVisibility visibility;
  final List<String> eventTags;
  final String language;
  final String? contactInfo;
  final bool hasStreaming;
  final List<String> streamingUrls;
  final String? policy;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> participantIds; // 将来の参加機能用
  final EventStatus status;
  final String? eventPassword; // 招待制イベントのパスワード
  final DateTime? scheduledPublishAt; // 予約公開日時
  final String? cancellationReason; // 中止理由
  final DateTime? cancelledAt; // 中止日時

  const Event({
    required this.id,
    required this.name,
    this.subtitle,
    required this.description,
    required this.rules,
    this.imageUrl,
    this.gameId,
    this.gameName,
    required this.platforms,
    required this.eventDate,
    required this.registrationDeadline,
    required this.maxParticipants,
    this.additionalInfo,
    required this.hasParticipationFee,
    this.participationFeeText,
    this.participationFeeSupplement,
    required this.hasPrize,
    this.prizeContent,
    required this.sponsorIds,
    required this.managerIds,
    required this.blockedUserIds,
    required this.visibility,
    required this.eventTags,
    required this.language,
    this.contactInfo,
    required this.hasStreaming,
    this.streamingUrls = const [],
    this.policy,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.participantIds,
    required this.status,
    this.eventPassword,
    this.scheduledPublishAt,
    this.cancellationReason,
    this.cancelledAt,
  });

  /// Firestoreドキュメントから Event オブジェクトを作成
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Event(
      id: doc.id,
      name: data['name'] ?? '',
      subtitle: data['subtitle'],
      description: data['description'] ?? '',
      rules: data['rules'] ?? '',
      imageUrl: data['imageUrl'],
      gameId: data['gameId'],
      gameName: data['gameName'],
      platforms: List<String>.from(data['platforms'] ?? []),
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      registrationDeadline: (data['registrationDeadline'] as Timestamp).toDate(),
      maxParticipants: data['maxParticipants'] ?? 0,
      additionalInfo: data['additionalInfo'],
      hasParticipationFee: data['hasParticipationFee'] ?? false,
      participationFeeText: data['participationFeeText'],
      participationFeeSupplement: data['participationFeeSupplement'],
      hasPrize: data['hasPrize'] ?? false,
      prizeContent: data['prizeContent'],
      sponsorIds: List<String>.from(data['sponsorIds'] ?? []),
      managerIds: List<String>.from(data['managerIds'] ?? []),
      blockedUserIds: List<String>.from(data['blockedUserIds'] ?? []),
      visibility: _parseVisibility(data['visibility']),
      eventTags: List<String>.from(data['eventTags'] ?? []),
      language: data['language'] ?? '日本語',
      contactInfo: data['contactInfo'],
      hasStreaming: data['hasStreaming'] ?? false,
      streamingUrls: List<String>.from(data['streamingUrls'] ?? []),
      policy: data['policy'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      participantIds: List<String>.from(data['participantIds'] ?? []),
      status: _parseStatus(data['status']),
      eventPassword: data['eventPassword'],
      scheduledPublishAt: data['scheduledPublishAt'] != null
          ? (data['scheduledPublishAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Event オブジェクトをFirestoreドキュメント用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subtitle': subtitle,
      'description': description,
      'rules': rules,
      'imageUrl': imageUrl,
      'gameId': gameId,
      'gameName': gameName,
      'platforms': platforms,
      'eventDate': Timestamp.fromDate(eventDate),
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'maxParticipants': maxParticipants,
      'additionalInfo': additionalInfo,
      'hasParticipationFee': hasParticipationFee,
      'participationFeeText': participationFeeText,
      'participationFeeSupplement': participationFeeSupplement,
      'hasPrize': hasPrize,
      'prizeContent': prizeContent,
      'sponsorIds': sponsorIds,
      'managerIds': managerIds,
      'blockedUserIds': blockedUserIds,
      'visibility': visibility.name,
      'eventTags': eventTags,
      'language': language,
      'contactInfo': contactInfo,
      'hasStreaming': hasStreaming,
      'streamingUrls': streamingUrls,
      'policy': policy,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'participantIds': participantIds,
      'status': status.name,
      'eventPassword': eventPassword,
      'scheduledPublishAt': scheduledPublishAt != null
          ? Timestamp.fromDate(scheduledPublishAt!)
          : null,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
    };
  }

  /// 検索用のキーワードを生成（将来の検索機能用）
  List<String> generateSearchKeywords() {
    final keywords = <String>[];

    // イベント名を単語に分割
    keywords.addAll(_splitIntoKeywords(name));

    // サブタイトルがある場合
    if (subtitle != null && subtitle!.isNotEmpty) {
      keywords.addAll(_splitIntoKeywords(subtitle!));
    }

    // ゲーム名
    if (gameName != null && gameName!.isNotEmpty) {
      keywords.addAll(_splitIntoKeywords(gameName!));
    }

    // イベントタグ
    keywords.addAll(eventTags);

    // プラットフォーム
    keywords.addAll(platforms);

    // 言語
    keywords.add(language);

    // 重複を除去して小文字に変換
    return keywords.map((keyword) => keyword.toLowerCase()).toSet().toList();
  }

  /// 文字列を検索用キーワードに分割
  List<String> _splitIntoKeywords(String text) {
    // スペース、ハイフン、アンダースコアで分割
    return text
        .replaceAll(RegExp(r'[^\w\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Event オブジェクトをコピーして一部プロパティを更新
  Event copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? description,
    String? rules,
    String? imageUrl,
    String? gameId,
    String? gameName,
    List<String>? platforms,
    DateTime? eventDate,
    DateTime? registrationDeadline,
    int? maxParticipants,
    String? additionalInfo,
    bool? hasParticipationFee,
    String? participationFeeText,
    String? participationFeeSupplement,
    bool? hasPrize,
    String? prizeContent,
    List<String>? sponsorIds,
    List<String>? managerIds,
    List<String>? blockedUserIds,
    EventVisibility? visibility,
    List<String>? eventTags,
    String? language,
    String? contactInfo,
    bool? hasStreaming,
    List<String>? streamingUrls,
    String? policy,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? participantIds,
    EventStatus? status,
    String? eventPassword,
    String? cancellationReason,
    DateTime? cancelledAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      imageUrl: imageUrl ?? this.imageUrl,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      platforms: platforms ?? this.platforms,
      eventDate: eventDate ?? this.eventDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      hasParticipationFee: hasParticipationFee ?? this.hasParticipationFee,
      participationFeeText: participationFeeText ?? this.participationFeeText,
      participationFeeSupplement: participationFeeSupplement ?? this.participationFeeSupplement,
      hasPrize: hasPrize ?? this.hasPrize,
      prizeContent: prizeContent ?? this.prizeContent,
      sponsorIds: sponsorIds ?? this.sponsorIds,
      managerIds: managerIds ?? this.managerIds,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      visibility: visibility ?? this.visibility,
      eventTags: eventTags ?? this.eventTags,
      language: language ?? this.language,
      contactInfo: contactInfo ?? this.contactInfo,
      hasStreaming: hasStreaming ?? this.hasStreaming,
      streamingUrls: streamingUrls ?? this.streamingUrls,
      policy: policy ?? this.policy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participantIds: participantIds ?? this.participantIds,
      status: status ?? this.status,
      eventPassword: eventPassword ?? this.eventPassword,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  static EventVisibility _parseVisibility(dynamic value) {
    if (value == null) return EventVisibility.public;
    switch (value.toString()) {
      case 'private':
        return EventVisibility.private;
      case 'inviteOnly':
        return EventVisibility.inviteOnly;
      default:
        return EventVisibility.public;
    }
  }

  static EventStatus _parseStatus(dynamic value) {
    if (value == null) return EventStatus.draft;
    switch (value.toString()) {
      case 'scheduled':
        return EventStatus.scheduled;
      case 'published':
        return EventStatus.published;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.draft;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Event{id: $id, name: $name, eventDate: $eventDate, status: $status}';
  }
}


/// イベント作成・更新用の入力データクラス
class EventInput {
  final String name;
  final String? subtitle;
  final String description;
  final String rules;
  final String? gameId;
  final List<String> platforms;
  final DateTime eventDate;
  final DateTime registrationDeadline;
  final int maxParticipants;
  final String? additionalInfo;
  final bool hasParticipationFee;
  final String? participationFeeText;
  final String? participationFeeSupplement;
  final bool hasPrize;
  final String? prizeContent;
  final List<String> sponsorIds;
  final List<String> managerIds;
  final List<String> blockedUserIds;
  final EventVisibility visibility;
  final List<String> eventTags;
  final String language;
  final String? contactInfo;
  final bool hasStreaming;
  final List<String> streamingUrls;
  final String? policy;
  final String? eventPassword; // 招待制イベントのパスワード
  final EventStatus status; // イベントのステータス
  final DateTime? scheduledPublishAt; // 予約公開日時

  const EventInput({
    required this.name,
    this.subtitle,
    required this.description,
    required this.rules,
    this.gameId,
    required this.platforms,
    required this.eventDate,
    required this.registrationDeadline,
    required this.maxParticipants,
    this.additionalInfo,
    required this.hasParticipationFee,
    this.participationFeeText,
    this.participationFeeSupplement,
    required this.hasPrize,
    this.prizeContent,
    required this.sponsorIds,
    required this.managerIds,
    required this.blockedUserIds,
    required this.visibility,
    required this.eventTags,
    required this.language,
    this.contactInfo,
    required this.hasStreaming,
    this.streamingUrls = const [],
    this.policy,
    this.eventPassword,
    this.status = EventStatus.draft,
    this.scheduledPublishAt,
  });
}