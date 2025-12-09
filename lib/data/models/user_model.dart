import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ユーザーデータモデル
/// Firestoreとの連携とアプリ内でのユーザー情報管理を担当
class UserData extends Equatable {
  /// 一意のユーザーID（Firebase Auth UID）
  final String id;

  /// ユーザーが設定するカスタムユーザーID（検索用）
  final String userId;

  /// ユーザー名（表示名）
  final String username;

  /// メールアドレス
  final String email;

  /// 自己紹介
  final String? bio;

  /// 連絡先情報
  final String? contact;

  /// お気に入りゲームのIDリスト（shared_gamesコレクションを参照）
  final List<String> favoriteGameIds;

  /// プロフィール画像URL
  final String? photoUrl;

  /// アカウント作成日
  final DateTime createdAt;

  /// 最終更新日
  final DateTime updatedAt;

  /// 初回設定完了フラグ（廃止予定：userIdの有無で判定）
  final bool isSetupCompleted;

  /// アカウントアクティブ状態
  final bool isActive;

  /// プロフィールで主催イベントを表示するかどうか
  final bool showHostedEvents;

  /// プロフィールで参加予定イベントを表示するかどうか
  final bool showParticipatingEvents;

  /// プロフィールで共同編集者イベントを表示するかどうか
  final bool showManagedEvents;

  /// プロフィールで過去参加済みイベントを表示するかどうか
  final bool showParticipatedEvents;

  /// 利用規約に同意したかどうか
  final bool termsAccepted;

  /// 同意した利用規約のバージョン
  final String? termsVersion;

  /// 利用規約に同意した日時
  final DateTime? termsAcceptedAt;

  const UserData({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    this.bio,
    this.contact,
    this.favoriteGameIds = const [],
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isSetupCompleted = false,
    this.isActive = true,
    this.showHostedEvents = true,
    this.showParticipatingEvents = true,
    this.showManagedEvents = true,
    this.showParticipatedEvents = true,
    this.termsAccepted = false,
    this.termsVersion,
    this.termsAcceptedAt,
  });

  /// 新規ユーザー作成用ファクトリ
  factory UserData.create({
    required String id,
    required String userId,
    required String username,
    required String email,
    String? bio,
    String? photoUrl,
  }) {
    final now = DateTime.now();
    return UserData(
      id: id,
      userId: userId,
      username: username,
      email: email,
      bio: bio,
      photoUrl: photoUrl,
      createdAt: now,
      updatedAt: now,
      isSetupCompleted: false,
    );
  }

  /// Firestoreドキュメントから UserData を作成
  factory UserData.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('ユーザーデータが見つかりません');
    }

    return UserData.fromJson(data, doc.id);
  }

  /// JSONから UserData を作成
  factory UserData.fromJson(Map<String, dynamic> json, [String? documentId]) {
    return UserData(
      id: documentId ?? json['id'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      contact: json['contact'] as String?,
      favoriteGameIds: (json['favoriteGameIds'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      photoUrl: json['photoUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isSetupCompleted: json['isSetupCompleted'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      showHostedEvents: json['showHostedEvents'] as bool? ?? true,
      showParticipatingEvents: json['showParticipatingEvents'] as bool? ?? true,
      showManagedEvents: json['showManagedEvents'] as bool? ?? true,
      showParticipatedEvents: json['showParticipatedEvents'] as bool? ?? true,
      termsAccepted: json['termsAccepted'] as bool? ?? false,
      termsVersion: json['termsVersion'] as String?,
      termsAcceptedAt: json['termsAcceptedAt'] != null
          ? (json['termsAcceptedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestoreへのデータ保存用JSON変換
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'bio': bio,
      'contact': contact,
      'favoriteGameIds': favoriteGameIds,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isSetupCompleted': isSetupCompleted,
      'isActive': isActive,
      'showHostedEvents': showHostedEvents,
      'showParticipatingEvents': showParticipatingEvents,
      'showManagedEvents': showManagedEvents,
      'showParticipatedEvents': showParticipatedEvents,
      'termsAccepted': termsAccepted,
      'termsVersion': termsVersion,
      'termsAcceptedAt': termsAcceptedAt != null
          ? Timestamp.fromDate(termsAcceptedAt!)
          : null,
    };
  }

  /// データ更新用のコピーメソッド
  UserData copyWith({
    String? userId,
    String? username,
    String? email,
    String? bio,
    String? contact,
    List<String>? favoriteGameIds,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSetupCompleted,
    bool? isActive,
    bool? showHostedEvents,
    bool? showParticipatingEvents,
    bool? showManagedEvents,
    bool? showParticipatedEvents,
    bool? termsAccepted,
    String? termsVersion,
    DateTime? termsAcceptedAt,
  }) {
    return UserData(
      id: id, // IDは変更不可
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      contact: contact ?? this.contact,
      favoriteGameIds: favoriteGameIds ?? this.favoriteGameIds,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // 更新時は自動的に現在時刻
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      isActive: isActive ?? this.isActive,
      showHostedEvents: showHostedEvents ?? this.showHostedEvents,
      showParticipatingEvents: showParticipatingEvents ?? this.showParticipatingEvents,
      showManagedEvents: showManagedEvents ?? this.showManagedEvents,
      showParticipatedEvents: showParticipatedEvents ?? this.showParticipatedEvents,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      termsVersion: termsVersion ?? this.termsVersion,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
    );
  }

  /// バリデーション
  String? validate() {
    if (username.trim().isEmpty) {
      return 'ユーザー名を入力してください';
    }
    if (username.length < 2 || username.length > 50) {
      return 'ユーザー名は2文字以上50文字以下で入力してください';
    }
    if (userId.trim().isEmpty) {
      return 'ユーザーIDを入力してください';
    }
    if (userId.length < 3 || userId.length > 20) {
      return 'ユーザーIDは3文字以上20文字以下で入力してください';
    }
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(userId)) {
      return 'ユーザーIDは英字で始まり、英数字とアンダーバーのみ使用してください';
    }
    if (email.trim().isEmpty) {
      return 'メールアドレスが必要です';
    }
    if (bio != null && bio!.length > 500) {
      return '自己紹介は500文字以内で入力してください';
    }
    if (contact != null && contact!.length > 200) {
      return '連絡先情報は200文字以内で入力してください';
    }
    if (favoriteGameIds.length > 10) {
      return 'お気に入りゲームは最大10個まで登録できます';
    }

    return null; // バリデーション成功
  }

  /// バリデーション結果が有効かどうか
  bool get isValid => validate() == null;

  /// 初回設定が完了しているかどうか（userIdの有無で判定）
  bool get isSetupCompleteBasedOnUserId => userId.trim().isNotEmpty;

  /// 表示用の短縮ユーザー名
  String get displayName {
    if (username.length > 20) {
      return '${username.substring(0, 17)}...';
    }
    return username;
  }

  /// お気に入りゲーム数
  int get favoriteGamesCount => favoriteGameIds.length;

  @override
  List<Object?> get props => [
        id,
        userId,
        username,
        email,
        bio,
        contact,
        favoriteGameIds,
        photoUrl,
        createdAt,
        updatedAt,
        isSetupCompleted,
        isActive,
        showHostedEvents,
        showParticipatingEvents,
        showManagedEvents,
        showParticipatedEvents,
        termsAccepted,
        termsVersion,
        termsAcceptedAt,
      ];

  @override
  String toString() {
    return 'UserData{id: $id, userId: $userId, username: $username, email: $email}';
  }
}

/// ユーザーデータ更新用のリクエストクラス
class UpdateUserRequest {
  final String? username;
  final String? userId;
  final String? bio;
  final String? contact;
  final List<String>? favoriteGameIds;
  final String? photoUrl;
  final bool? isSetupCompleted;
  final bool? showHostedEvents;
  final bool? showParticipatingEvents;
  final bool? showManagedEvents;
  final bool? showParticipatedEvents;
  final bool? termsAccepted;
  final String? termsVersion;
  final DateTime? termsAcceptedAt;

  const UpdateUserRequest({
    this.username,
    this.userId,
    this.bio,
    this.contact,
    this.favoriteGameIds,
    this.photoUrl,
    this.isSetupCompleted,
    this.showHostedEvents,
    this.showParticipatingEvents,
    this.showManagedEvents,
    this.showParticipatedEvents,
    this.termsAccepted,
    this.termsVersion,
    this.termsAcceptedAt,
  });

  /// 更新するデータがあるかどうか
  bool get hasUpdates =>
      username != null ||
      userId != null ||
      bio != null ||
      contact != null ||
      favoriteGameIds != null ||
      photoUrl != null ||
      isSetupCompleted != null ||
      showHostedEvents != null ||
      showParticipatingEvents != null ||
      showManagedEvents != null ||
      showParticipatedEvents != null ||
      termsAccepted != null ||
      termsVersion != null ||
      termsAcceptedAt != null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (username != null) data['username'] = username;
    if (userId != null) data['userId'] = userId;
    if (bio != null) data['bio'] = bio;
    if (contact != null) data['contact'] = contact;
    if (favoriteGameIds != null) {
      data['favoriteGameIds'] = favoriteGameIds;
    }
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (isSetupCompleted != null) data['isSetupCompleted'] = isSetupCompleted;
    if (showHostedEvents != null) data['showHostedEvents'] = showHostedEvents;
    if (showParticipatingEvents != null) {
      data['showParticipatingEvents'] = showParticipatingEvents;
    }
    if (showManagedEvents != null) {
      data['showManagedEvents'] = showManagedEvents;
    }
    if (showParticipatedEvents != null) {
      data['showParticipatedEvents'] = showParticipatedEvents;
    }
    if (termsAccepted != null) data['termsAccepted'] = termsAccepted;
    if (termsVersion != null) data['termsVersion'] = termsVersion;
    if (termsAcceptedAt != null) {
      data['termsAcceptedAt'] = Timestamp.fromDate(termsAcceptedAt!);
    }

    // 更新日時は自動設定
    data['updatedAt'] = Timestamp.now();

    return data;
  }
}