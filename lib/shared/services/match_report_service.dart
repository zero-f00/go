import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// 試合報告の状況
enum MatchReportStatus {
  submitted('submitted', '報告済み'),
  reviewing('reviewing', '確認中'),
  resolved('resolved', '解決済み'),
  rejected('rejected', '却下');

  const MatchReportStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static MatchReportStatus fromString(String value) {
    return MatchReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MatchReportStatus.submitted,
    );
  }
}

/// 試合報告モデル
class MatchReport {
  final String? id;
  final String matchId;
  final String reporterId;
  final String issueType;
  final String description;
  final MatchReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminResponse;
  final String? adminId;

  const MatchReport({
    this.id,
    required this.matchId,
    required this.reporterId,
    required this.issueType,
    required this.description,
    this.status = MatchReportStatus.submitted,
    required this.createdAt,
    required this.updatedAt,
    this.adminResponse,
    this.adminId,
  });

  factory MatchReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchReport(
      id: doc.id,
      matchId: data['matchId'] as String,
      reporterId: data['reporterId'] as String,
      issueType: data['issueType'] as String,
      description: data['description'] as String,
      status: MatchReportStatus.fromString(data['status'] as String? ?? 'submitted'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      adminResponse: data['adminResponse'] as String?,
      adminId: data['adminId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'reporterId': reporterId,
      'issueType': issueType,
      'description': description,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (adminResponse != null) 'adminResponse': adminResponse,
      if (adminId != null) 'adminId': adminId,
    };
  }

  MatchReport copyWith({
    String? id,
    String? matchId,
    String? reporterId,
    String? issueType,
    String? description,
    MatchReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
    String? adminId,
  }) {
    return MatchReport(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      reporterId: reporterId ?? this.reporterId,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
    );
  }
}

/// 試合報告管理サービス
class MatchReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'match_reports';

  /// 試合報告を送信
  Future<String> submitMatchReport({
    required String matchId,
    required String reporterId,
    required String issueType,
    required String description,
    required String eventId,
    required String matchName,
  }) async {
    try {
      final now = DateTime.now();
      final report = MatchReport(
        matchId: matchId,
        reporterId: reporterId,
        issueType: issueType,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(report.toFirestore());

      // 運営に通知を送信
      await _notifyAdmins(
        reportId: docRef.id,
        matchId: matchId,
        matchName: matchName,
        issueType: issueType,
        eventId: eventId,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('報告の送信に失敗しました: $e');
    }
  }

  /// 運営による報告対応（状況更新）
  Future<void> updateReportStatus({
    required String reportId,
    required MatchReportStatus status,
    required String adminId,
    String? adminResponse,
  }) async {
    try {
      final updateData = {
        'status': status.value,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'adminId': adminId,
        if (adminResponse != null) 'adminResponse': adminResponse,
      };

      await _firestore
          .collection(_collection)
          .doc(reportId)
          .update(updateData);

      // 報告者に対応完了を通知
      final report = await getReportById(reportId);
      if (report != null) {
        await _notifyReporter(report);
      }
    } catch (e) {
      throw Exception('報告状況の更新に失敗しました: $e');
    }
  }

  /// 報告詳細を取得
  Future<MatchReport?> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reportId).get();
      if (doc.exists) {
        return MatchReport.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('報告の取得に失敗しました: $e');
    }
  }

  /// 試合の報告一覧を取得
  Future<List<MatchReport>> getMatchReports(String matchId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('matchId', isEqualTo: matchId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MatchReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('報告一覧の取得に失敗しました: $e');
    }
  }

  /// ユーザーの報告一覧を取得
  Future<List<MatchReport>> getUserReports(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('reporterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MatchReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('ユーザー報告の取得に失敗しました: $e');
    }
  }

  /// 運営向け未処理報告を取得
  Future<List<MatchReport>> getPendingReports() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', whereIn: ['submitted', 'reviewing'])
          .orderBy('createdAt', descending: false) // 古い順
          .get();

      return querySnapshot.docs
          .map((doc) => MatchReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('未処理報告の取得に失敗しました: $e');
    }
  }

  /// 運営に新規報告を通知
  Future<void> _notifyAdmins({
    required String reportId,
    required String matchId,
    required String matchName,
    required String issueType,
    required String eventId,
  }) async {
    try {
      // 運営ユーザーのリストを取得（簡単な実装例）
      final adminUsers = await _getEventAdmins(eventId);

      for (final adminId in adminUsers) {
        await NotificationService.sendNotification(
          toUserId: adminId,
          title: '新しい試合報告',
          message: '「$matchName」で$issueTypeの報告がありました',
          type: 'match_report',
          data: {
            'reportId': reportId,
            'matchId': matchId,
            'action': 'review_report',
          },
        );
      }

      // 運営ダッシュボードにリアルタイム通知も送信
      await _firestore.collection('admin_notifications').add({
        'type': 'match_report',
        'eventId': eventId,
        'reportId': reportId,
        'matchId': matchId,
        'matchName': matchName,
        'issueType': issueType,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      // 運営通知の送信エラーは報告送信をブロックしない
      // 通知エラーは報告送信をブロックしない
    }
  }

  /// 報告者に対応完了を通知
  Future<void> _notifyReporter(MatchReport report) async {
    try {
      String message;
      String title;

      switch (report.status) {
        case MatchReportStatus.reviewing:
          title = '報告を確認中';
          message = 'ご報告いただいた問題を確認しています';
          break;
        case MatchReportStatus.resolved:
          title = '報告が解決されました';
          message = 'ご報告いただいた問題が解決されました';
          break;
        case MatchReportStatus.rejected:
          title = '報告について';
          message = 'ご報告いただいた内容を確認しましたが、修正の必要がないと判断いたします';
          break;
        default:
          return;
      }

      await NotificationService.sendNotification(
        toUserId: report.reporterId,
        title: title,
        message: message,
        type: 'match_report_response',
        data: {
          'reportId': report.id!,
          'matchId': report.matchId,
          'status': report.status.value,
          'action': 'view_report_status',
        },
      );
    } catch (e) {
      // 報告者通知の送信エラーは再試行しない
    }
  }

  /// イベントの運営ユーザーIDリストを取得
  Future<List<String>> _getEventAdmins(String eventId) async {
    try {
      // TODO: 実際のイベント運営者取得ロジックを実装
      // 例: events/{eventId}/adminsコレクションから取得
      final querySnapshot = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('admins')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      // 運営者リスト取得エラー
      return [];
    }
  }

  /// 報告状況をリアルタイムで監視
  Stream<List<MatchReport>> watchUserReports(String userId) {
    return _firestore
        .collection(_collection)
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchReport.fromFirestore(doc))
            .toList());
  }

  /// 運営向け未処理報告をリアルタイムで監視
  Stream<List<MatchReport>> watchPendingReports() {
    return _firestore
        .collection(_collection)
        .where('status', whereIn: ['submitted', 'reviewing'])
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchReport.fromFirestore(doc))
            .toList());
  }
}