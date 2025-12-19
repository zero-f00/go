import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/services/participation_service.dart';

/// イベントグループのモデル
class EventGroup {
  final String id;
  final String eventId;
  final String name;
  final String description;
  final List<String> participants;
  final String announcements; // グループ用連絡事項
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventGroup({
    required this.id,
    required this.eventId,
    required this.name,
    required this.description,
    required this.participants,
    required this.announcements,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EventGroup(
      id: doc.id,
      eventId: data['eventId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      announcements: (data['announcements']?.toString() ?? '').trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'name': name,
      'description': description,
      'participants': participants,
      'announcements': announcements,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  EventGroup copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    List<String>? participants,
    String? announcements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventGroup(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      announcements: announcements ?? this.announcements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 承認済み参加者のモデル
class ApprovedParticipant {
  final String userId;
  final String displayName;
  final String gameUsername;
  final Map<String, dynamic>? gameProfileData;
  final ParticipationApplication application;

  const ApprovedParticipant({
    required this.userId,
    required this.displayName,
    required this.gameUsername,
    this.gameProfileData,
    required this.application,
  });

  ApprovedParticipant copyWith({
    String? userId,
    String? displayName,
    String? gameUsername,
    Map<String, dynamic>? gameProfileData,
    ParticipationApplication? application,
  }) {
    return ApprovedParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      gameUsername: gameUsername ?? this.gameUsername,
      gameProfileData: gameProfileData ?? this.gameProfileData,
      application: application ?? this.application,
    );
  }
}

/// グループサービス
class GroupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// イベントのグループ一覧を取得
  static Stream<List<EventGroup>> getEventGroups(String eventId) {
    return _firestore
        .collection('event_groups')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventGroup.fromFirestore(doc))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  /// ユーザーが所属するグループを取得
  static Stream<EventGroup?> getUserGroup(String eventId, String userId) {
    return _firestore
        .collection('event_groups')
        .where('eventId', isEqualTo: eventId)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty
            ? EventGroup.fromFirestore(snapshot.docs.first)
            : null);
  }

  /// 特定のグループを取得
  static Future<EventGroup?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection('event_groups').doc(groupId).get();
      if (doc.exists) {
        return EventGroup.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// グループを作成
  static Future<String?> createGroup(EventGroup group) async {
    try {
      final docRef = await _firestore.collection('event_groups').add(group.toFirestore());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// グループを更新
  static Future<bool> updateGroup(EventGroup group) async {
    try {
      await _firestore.collection('event_groups').doc(group.id).update(group.toFirestore());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// グループを削除
  /// グループが削除可能かチェック（関連戦績の有無確認）
  static Future<bool> canDeleteGroup(String groupId) async {
    try {
      // 関連する戦績データを確認
      final matchResults = await _firestore
          .collection('match_results')
          .where('participants', arrayContains: groupId)
          .limit(1)
          .get();

      return matchResults.docs.isEmpty;
    } catch (e) {
      return false; // 安全側に倒す
    }
  }

  /// 関連する戦績数を取得
  static Future<int> getRelatedMatchCount(String groupId) async {
    try {
      final matchResults = await _firestore
          .collection('match_results')
          .where('participants', arrayContains: groupId)
          .get();

      return matchResults.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> deleteGroup(String groupId) async {
    try {
      await _firestore.collection('event_groups').doc(groupId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}