import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ゲームプロフィール
class GameProfile extends Equatable {
  /// ドキュメントID（Firestore用）
  final String? id;

  /// ゲームID（shared_gamesコレクションを参照）
  final String gameId;

  /// プロフィールを所有するユーザーID
  final String userId;


  /// ゲーム内ユーザー名
  final String gameUsername;

  /// ゲーム内ユーザーID
  final String gameUserId;

  /// ゲーム歴
  final GameExperience? experience;

  /// プレイスタイル
  final List<PlayStyle> playStyles;

  /// ランクまたはレベル
  final String rankOrLevel;

  /// 活動時間帯
  final List<ActivityTime> activityTimes;

  /// ゲーム内ボイスチャット使用可否
  final bool useInGameVC;

  /// ボイスチャット詳細情報（Discord、ゲーム内VC等の自由記入）
  final String voiceChatDetails;

  /// 達成実績
  final String achievements;

  /// 自由入力・メモ
  final String notes;

  /// クラン名
  final String clan;

  /// お気に入り設定
  final bool isFavorite;

  /// プロフィールの公開設定
  final bool isPublic;

  /// ゲーム専用SNSアカウント情報
  final Map<String, String>? gameSocialLinks;

  /// プロフィール作成日時
  final DateTime createdAt;

  /// プロフィール更新日時
  final DateTime updatedAt;

  const GameProfile({
    this.id,
    required this.gameId,
    required this.userId,
    required this.gameUsername,
    required this.gameUserId,
    this.experience,
    this.playStyles = const [],
    this.rankOrLevel = '',
    this.activityTimes = const [],
    this.useInGameVC = false,
    this.voiceChatDetails = '',
    this.achievements = '',
    this.notes = '',
    this.clan = '',
    this.isFavorite = false,
    this.isPublic = true,
    this.gameSocialLinks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 新しいプロフィール作成
  factory GameProfile.create({
    required String gameId,
    required String userId,
    required String gameUsername,
    required String gameUserId,
    GameExperience? experience,
    List<PlayStyle> playStyles = const [],
    String rankOrLevel = '',
    List<ActivityTime> activityTimes = const [],
    bool useInGameVC = false,
    String voiceChatDetails = '',
    String achievements = '',
    String notes = '',
    String clan = '',
    bool isPublic = true,
    Map<String, String>? gameSocialLinks,
  }) {
    return GameProfile(
      gameId: gameId,
      userId: userId,
      gameUsername: gameUsername,
      gameUserId: gameUserId,
      experience: experience,
      playStyles: playStyles,
      rankOrLevel: rankOrLevel,
      activityTimes: activityTimes,
      useInGameVC: useInGameVC,
      voiceChatDetails: voiceChatDetails,
      achievements: achievements,
      notes: notes,
      clan: clan,
      isFavorite: false,
      isPublic: isPublic,
      gameSocialLinks: gameSocialLinks,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Firestoreから作成（サブコレクション対応）
  factory GameProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameProfile(
      id: doc.id,
      gameId: data['gameId'] as String,
      userId: data['userId'] as String,
      gameUsername: data['gameUsername'] as String,
      gameUserId: data['gameUserId'] as String,
      experience: data['experience'] != null
        ? GameExperience.values.firstWhere(
            (e) => e.name == data['experience'],
            orElse: () => GameExperience.beginner,
          )
        : null,
      playStyles: (data['playStyles'] as List?)
              ?.map((e) => PlayStyle.values.firstWhere(
                    (style) => style.name == e,
                    orElse: () => PlayStyle.casual,
                  ))
              .toList() ??
          [],
      rankOrLevel: data['rankOrLevel'] as String? ?? '',
      activityTimes: (data['activityTimes'] as List?)
              ?.map((e) => ActivityTime.values.firstWhere(
                    (time) => time.name == e,
                    orElse: () => ActivityTime.evening,
                  ))
              .toList() ??
          [],
      useInGameVC: data['useInGameVC'] as bool? ?? false,
      voiceChatDetails: data['voiceChatDetails'] as String? ?? '',
      achievements: data['achievements'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      clan: data['clan'] as String? ?? '',
      isFavorite: data['isFavorite'] as bool? ?? false,
      isPublic: data['isPublic'] as bool? ?? true,
      gameSocialLinks: (data['gameSocialLinks'] as Map<String, dynamic>?)?.cast<String, String>(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore保存用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'userId': userId,
      'gameUsername': gameUsername,
      'gameUserId': gameUserId,
      'experience': experience?.name,
      'playStyles': playStyles.map((style) => style.name).toList(),
      'rankOrLevel': rankOrLevel,
      'activityTimes': activityTimes.map((time) => time.name).toList(),
      'useInGameVC': useInGameVC,
      'voiceChatDetails': voiceChatDetails,
      'achievements': achievements,
      'notes': notes,
      'clan': clan,
      'isFavorite': isFavorite,
      'isPublic': isPublic,
      'gameSocialLinks': gameSocialLinks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }


  /// コピーを作成
  GameProfile copyWith({
    String? id,
    String? gameId,
    String? userId,
    String? gameUsername,
    String? gameUserId,
    GameExperience? experience,
    List<PlayStyle>? playStyles,
    String? rankOrLevel,
    List<ActivityTime>? activityTimes,
    bool? useInGameVC,
    String? voiceChatDetails,
    String? achievements,
    String? notes,
    String? clan,
    bool? isFavorite,
    bool? isPublic,
    Map<String, String>? gameSocialLinks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameProfile(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      userId: userId ?? this.userId,
      gameUsername: gameUsername ?? this.gameUsername,
      gameUserId: gameUserId ?? this.gameUserId,
      experience: experience ?? this.experience,
      playStyles: playStyles ?? this.playStyles,
      rankOrLevel: rankOrLevel ?? this.rankOrLevel,
      activityTimes: activityTimes ?? this.activityTimes,
      useInGameVC: useInGameVC ?? this.useInGameVC,
      voiceChatDetails: voiceChatDetails ?? this.voiceChatDetails,
      achievements: achievements ?? this.achievements,
      notes: notes ?? this.notes,
      clan: clan ?? this.clan,
      isFavorite: isFavorite ?? this.isFavorite,
      isPublic: isPublic ?? this.isPublic,
      gameSocialLinks: gameSocialLinks ?? this.gameSocialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// プロフィール要約を取得
  String get summary {
    final parts = <String>[];

    if (rankOrLevel.isNotEmpty) {
      parts.add('ランク: $rankOrLevel');
    }

    if (experience != null) {
      parts.add('歴: ${experience!.displayName}');
    }

    if (playStyles.isNotEmpty) {
      parts.add('スタイル: ${playStyles.map((s) => s.displayName).join('・')}');
    }

    return parts.join(' | ');
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        userId,
        gameUsername,
        gameUserId,
        experience,
        playStyles,
        rankOrLevel,
        activityTimes,
        useInGameVC,
        voiceChatDetails,
        achievements,
        notes,
        clan,
        isFavorite,
        isPublic,
        gameSocialLinks,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'GameProfile(id: $id, gameId: $gameId, gameUsername: $gameUsername)';
  }
}

/// ゲーム歴
enum GameExperience {
  beginner,    // 初心者
  intermediate, // 中級者
  advanced,    // 上級者
  expert,      // エキスパート
}

extension GameExperienceExtension on GameExperience {
  String get displayName {
    switch (this) {
      case GameExperience.beginner:
        return '初心者';
      case GameExperience.intermediate:
        return '中級者';
      case GameExperience.advanced:
        return '上級者';
      case GameExperience.expert:
        return 'エキスパート';
    }
  }

  String get description {
    switch (this) {
      case GameExperience.beginner:
        return '始めたばかり、基本的な操作を学習中';
      case GameExperience.intermediate:
        return '基本操作は慣れて、戦略を学習中';
      case GameExperience.advanced:
        return '高度な戦略やテクニックを習得済み';
      case GameExperience.expert:
        return 'プロレベル、他の人に教えられる';
    }
  }
}

/// プレイスタイル
enum PlayStyle {
  casual,      // カジュアル
  competitive, // 競技志向
  cooperative, // 協力プレイ
  solo,        // ソロプレイ
  social,      // 交流重視
  speedrun,    // スピードラン
  collector,   // コレクター
}

extension PlayStyleExtension on PlayStyle {
  String get displayName {
    switch (this) {
      case PlayStyle.casual:
        return 'カジュアル';
      case PlayStyle.competitive:
        return '競技志向';
      case PlayStyle.cooperative:
        return '協力プレイ';
      case PlayStyle.solo:
        return 'ソロプレイ';
      case PlayStyle.social:
        return '交流重視';
      case PlayStyle.speedrun:
        return 'スピードラン';
      case PlayStyle.collector:
        return 'コレクター';
    }
  }

  String get description {
    switch (this) {
      case PlayStyle.casual:
        return 'のんびり楽しくプレイ';
      case PlayStyle.competitive:
        return 'ランクマッチや大会を重視';
      case PlayStyle.cooperative:
        return 'チームで協力してプレイ';
      case PlayStyle.solo:
        return '一人でじっくりプレイ';
      case PlayStyle.social:
        return '他のプレイヤーとの交流を重視';
      case PlayStyle.speedrun:
        return '最短クリアを目指す';
      case PlayStyle.collector:
        return 'アイテムや実績の収集を重視';
    }
  }
}

/// 活動時間帯
enum ActivityTime {
  morning,   // 朝（6-12時）
  afternoon, // 昼（12-18時）
  evening,   // 夜（18-24時）
  night,     // 深夜（24-6時）
  weekend,   // 週末
  weekday,   // 平日
}

extension ActivityTimeExtension on ActivityTime {
  String get displayName {
    switch (this) {
      case ActivityTime.morning:
        return '朝（6-12時）';
      case ActivityTime.afternoon:
        return '昼（12-18時）';
      case ActivityTime.evening:
        return '夜（18-24時）';
      case ActivityTime.night:
        return '深夜（24-6時）';
      case ActivityTime.weekend:
        return '週末';
      case ActivityTime.weekday:
        return '平日';
    }
  }
}

