import 'package:cloud_firestore/cloud_firestore.dart';

class GroupManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 指定イベントにグループが設定されているかチェック
  Future<bool> hasGroupsForEvent(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('event_groups')
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 指定イベントがチーム戦かどうかを判定
  Future<bool> isTeamMatchEvent(String eventId) async {
    try {
      return await hasGroupsForEvent(eventId);
    } catch (e) {
      return false;
    }
  }

  /// 指定イベントのグループIDリストを取得
  Future<List<String>> getEventGroupIds(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('event_groups')
          .where('eventId', isEqualTo: eventId)
          .get();

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('グループの取得に失敗しました: $e');
    }
  }

  /// グループ名を取得
  Future<String> getGroupName(String groupId) async {
    try {
      final doc = await _firestore
          .collection('event_groups')
          .doc(groupId)
          .get();

      if (doc.exists) {
        return doc.data()?['name'] as String? ?? 'グループ名未設定';
      } else {
        return '削除されたグループ';
      }
    } catch (e) {
      return '削除されたグループ';
    }
  }

  /// 複数のグループIDに対応するグループ名を一括取得
  Future<Map<String, String>> getGroupNames(List<String> groupIds) async {
    final Map<String, String> groupNames = {};

    try {
      for (final groupId in groupIds) {
        groupNames[groupId] = await getGroupName(groupId);
      }
      return groupNames;
    } catch (e) {
      // エラー時も各IDに対して削除されたグループ情報を設定
      for (final groupId in groupIds) {
        groupNames[groupId] = '削除されたグループ';
      }
      return groupNames;
    }
  }

  /// 指定グループのメンバーIDリストを取得
  Future<List<String>> getGroupMembers(String groupId) async {
    try {
      final doc = await _firestore
          .collection('event_groups')
          .doc(groupId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return List<String>.from(data['participants'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// 複数のユーザーIDに対応するユーザー名を一括取得（承認済み参加者のみ）
  Future<Map<String, String>> getUserNames(List<String> userIds) async {
    final Map<String, String> userNames = {};

    try {
      // 空のリストの場合は早期リターン
      if (userIds.isEmpty) {
        return userNames;
      }

      // まずevent_groupsコレクションからeventIdを取得する必要があるが、
      // このメソッドはeventIdなしで呼ばれているため、
      // より汎用的なアプローチとして、ユーザー詳細情報から表示名を取得
      for (final userId in userIds) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          // displayNameを優先的に使用
          final displayName = data['displayName'] as String? ?? 'ユーザー';
          userNames[userId] = displayName;
        } else {
          userNames[userId] = 'ユーザー';
        }
      }
      return userNames;
    } catch (e) {
      // エラー時は空のマップを返す
      return {};
    }
  }

  /// 指定イベントの承認済み参加者の表示名とゲーム内ユーザー名を一括取得
  Future<Map<String, Map<String, String>>> getApprovedParticipantNames(String eventId, List<String> userIds) async {
    final Map<String, Map<String, String>> participantInfo = {};

    try {
      if (userIds.isEmpty) {
        return participantInfo;
      }

      // 承認済みの参加申請を取得
      final applicationsQuery = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'approved')
          .get();

      // 承認済み参加者のみをフィルタリング
      final approvedUserIds = applicationsQuery.docs
          .where((doc) => userIds.contains(doc.data()['userId']))
          .map((doc) => doc.data())
          .toList();

      for (final appData in approvedUserIds) {
        final userId = appData['userId'] as String;
        participantInfo[userId] = {
          'displayName': appData['userDisplayName'] as String? ?? 'ユーザー',
          'gameUsername': appData['gameUsername'] as String? ?? userId,
        };
      }

      return participantInfo;
    } catch (e) {
      // エラー時は空のマップを返す
      return {};
    }
  }

  /// グループの詳細情報を取得
  Future<GroupDetail?> getGroupDetail(String groupId) async {
    try {
      final doc = await _firestore
          .collection('event_groups')
          .doc(groupId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return GroupDetail(
          id: groupId,
          name: data['name'] as String? ?? 'グループ名未設定',
          description: data['description'] as String? ?? '',
          participants: List<String>.from(data['participants'] ?? []),
          announcements: data['announcements'] as String? ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}

/// グループ詳細情報モデル
class GroupDetail {
  final String id;
  final String name;
  final String description;
  final List<String> participants;
  final String announcements;

  const GroupDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.participants,
    required this.announcements,
  });
}

