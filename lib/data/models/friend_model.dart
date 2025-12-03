import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// フレンドリクエストのステータス
enum FriendRequestStatus {
  pending,   // 承認待ち
  accepted,  // 承認済み
  rejected,  // 拒否
}

/// フレンドリクエストデータモデル
class FriendRequest extends Equatable {
  /// ドキュメントID
  final String? id;

  /// リクエスト送信者のユーザーID
  final String fromUserId;

  /// リクエスト受信者のユーザーID
  final String toUserId;

  /// リクエストのステータス
  final FriendRequestStatus status;

  /// リクエスト送信日時
  final DateTime createdAt;

  /// ステータス更新日時
  final DateTime updatedAt;

  /// メッセージ（任意）
  final String? message;

  const FriendRequest({
    this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.message,
  });

  /// 新しいフレンドリクエストを作成
  factory FriendRequest.create({
    required String fromUserId,
    required String toUserId,
    String? message,
  }) {
    final now = DateTime.now();
    return FriendRequest(
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: FriendRequestStatus.pending,
      createdAt: now,
      updatedAt: now,
      message: message,
    );
  }

  /// Firestoreドキュメントから作成
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      message: data['message'] as String?,
    );
  }

  /// 日時データを安全にパース
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else {
      // フォールバック: 現在時刻を返す
      print('⚠️ FriendRequest: Unexpected date format: $value, using current time');
      return DateTime.now();
    }
  }

  /// JSONから作成
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] as String?,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      message: json['message'] as String?,
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (message != null) 'message': message,
    };
  }

  /// ステータスを更新したコピーを作成
  FriendRequest updateStatus(FriendRequestStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// コピーを作成
  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? message,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      message: message ?? this.message,
    );
  }

  /// リクエストが承認済みかどうか
  bool get isAccepted => status == FriendRequestStatus.accepted;

  /// リクエストが承認待ちかどうか
  bool get isPending => status == FriendRequestStatus.pending;

  /// リクエストが拒否されたかどうか
  bool get isRejected => status == FriendRequestStatus.rejected;

  @override
  List<Object?> get props => [
        id,
        fromUserId,
        toUserId,
        status,
        createdAt,
        updatedAt,
        message,
      ];

  @override
  String toString() {
    return 'FriendRequest(id: $id, from: $fromUserId, to: $toUserId, status: $status)';
  }
}

/// フレンド関係データモデル
class Friendship extends Equatable {
  /// ドキュメントID
  final String? id;

  /// ユーザー1のID（アルファベット順で小さい方）
  final String user1Id;

  /// ユーザー2のID（アルファベット順で大きい方）
  final String user2Id;

  /// フレンド関係が成立した日時
  final DateTime createdAt;

  /// 最後に更新された日時
  final DateTime updatedAt;

  const Friendship({
    this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 新しいフレンド関係を作成
  factory Friendship.create({
    required String userId1,
    required String userId2,
  }) {
    final now = DateTime.now();
    // ユーザーIDをアルファベット順に並べる（一意性を保つため）
    final sortedIds = [userId1, userId2]..sort();

    return Friendship(
      user1Id: sortedIds[0],
      user2Id: sortedIds[1],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestoreドキュメントから作成
  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      user1Id: data['user1Id'] as String,
      user2Id: data['user2Id'] as String,
      createdAt: FriendRequest._parseDateTime(data['createdAt']),
      updatedAt: FriendRequest._parseDateTime(data['updatedAt']),
    );
  }

  /// JSONから作成
  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String?,
      user1Id: json['user1Id'] as String,
      user2Id: json['user2Id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 指定されたユーザーIDが含まれているかチェック
  bool containsUser(String userId) {
    return user1Id == userId || user2Id == userId;
  }

  /// 指定されたユーザーのフレンドのユーザーIDを取得
  String getFriendId(String userId) {
    if (user1Id == userId) return user2Id;
    if (user2Id == userId) return user1Id;
    throw ArgumentError('User $userId is not part of this friendship');
  }

  @override
  List<Object?> get props => [
        id,
        user1Id,
        user2Id,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Friendship(id: $id, user1: $user1Id, user2: $user2Id)';
  }
}