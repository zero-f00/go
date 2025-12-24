import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// フォロー関係データモデル
/// フォローは片方向の関係（承認不要）
class Follow extends Equatable {
  /// ドキュメントID
  final String? id;

  /// フォローする人のユーザーID（カスタムID）
  final String followerId;

  /// フォローされる人のユーザーID（カスタムID）
  final String followeeId;

  /// フォロー開始日時
  final DateTime createdAt;

  const Follow({
    this.id,
    required this.followerId,
    required this.followeeId,
    required this.createdAt,
  });

  /// 新しいフォロー関係を作成
  factory Follow.create({
    required String followerId,
    required String followeeId,
  }) {
    return Follow(
      followerId: followerId,
      followeeId: followeeId,
      createdAt: DateTime.now(),
    );
  }

  /// Firestoreドキュメントから作成
  factory Follow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Follow(
      id: doc.id,
      followerId: data['followerId'] as String,
      followeeId: data['followeeId'] as String,
      createdAt: _parseDateTime(data['createdAt']),
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
      return DateTime.now();
    }
  }

  /// JSONから作成
  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String?,
      followerId: json['followerId'] as String,
      followeeId: json['followeeId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'followerId': followerId,
      'followeeId': followeeId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Firestore保存用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followeeId': followeeId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// コピーを作成
  Follow copyWith({
    String? id,
    String? followerId,
    String? followeeId,
    DateTime? createdAt,
  }) {
    return Follow(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followeeId: followeeId ?? this.followeeId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        followerId,
        followeeId,
        createdAt,
      ];

  @override
  String toString() {
    return 'Follow(id: $id, follower: $followerId, followee: $followeeId)';
  }
}
