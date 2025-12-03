import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 通知のタイプ
enum NotificationType {
  friendRequest,       // フレンドリクエスト
  friendAccepted,      // フレンドリクエスト承認
  friendRejected,      // フレンドリクエスト拒否
  eventInvite,         // イベント招待
  eventReminder,       // イベントリマインダー
  eventApproved,       // イベント参加承認
  eventRejected,       // イベント参加拒否
  eventApplication,    // イベント申込み（運営側への通知）
  eventDraftReverted,  // イベント下書き化による参加取り消し
  violationReported,   // 違反報告
  violationProcessed,  // 違反処理完了
  violationDismissed,  // 違反却下
  violationDeleted,    // 違反削除
  appealSubmitted,     // 異議申立提出
  appealProcessed,     // 異議申立処理完了
  matchReport,         // 試合結果報告
  matchReportResponse, // 試合結果報告への回答
  system,              // システム通知
}

/// 通知データモデル
class NotificationData extends Equatable {
  /// ドキュメントID
  final String? id;

  /// 通知を受け取るユーザーID
  final String toUserId;

  /// 通知を送信したユーザーID（システム通知の場合はnull）
  final String? fromUserId;

  /// 通知のタイプ
  final NotificationType type;

  /// 通知のタイトル
  final String title;

  /// 通知の本文
  final String message;

  /// 読了フラグ
  final bool isRead;

  /// 通知作成日時
  final DateTime createdAt;

  /// 通知を読んだ日時
  final DateTime? readAt;

  /// 関連するデータ（フレンドリクエストID、イベントIDなど）
  final Map<String, dynamic>? data;

  const NotificationData({
    this.id,
    required this.toUserId,
    this.fromUserId,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  /// フレンドリクエスト通知を作成
  factory NotificationData.friendRequest({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String friendRequestId,
  }) {
    return NotificationData(
      toUserId: toUserId,
      fromUserId: fromUserId,
      type: NotificationType.friendRequest,
      title: 'フレンドリクエスト',
      message: '$fromUserNameさんからフレンドリクエストが届きました',
      createdAt: DateTime.now(),
      data: {
        'friendRequestId': friendRequestId,
        'fromUserName': fromUserName,
      },
    );
  }

  /// フレンドリクエスト承認通知を作成
  factory NotificationData.friendAccepted({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) {
    return NotificationData(
      toUserId: toUserId,
      fromUserId: fromUserId,
      type: NotificationType.friendAccepted,
      title: 'フレンドリクエスト承認',
      message: '$fromUserNameさんがフレンドリクエストを承認しました',
      createdAt: DateTime.now(),
      data: {
        'fromUserName': fromUserName,
      },
    );
  }

  /// フレンドリクエスト拒否通知を作成
  factory NotificationData.friendRejected({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) {
    return NotificationData(
      toUserId: toUserId,
      fromUserId: fromUserId,
      type: NotificationType.friendRejected,
      title: 'フレンドリクエスト拒否',
      message: '$fromUserNameさんがフレンドリクエストを拒否しました',
      createdAt: DateTime.now(),
      data: {
        'fromUserName': fromUserName,
      },
    );
  }

  /// イベント下書き化通知を作成
  factory NotificationData.eventDraftReverted({
    required String toUserId,
    required String eventId,
    required String eventName,
    required String organizerName,
  }) {
    return NotificationData(
      toUserId: toUserId,
      fromUserId: null, // システム通知として扱う
      type: NotificationType.eventDraftReverted,
      title: 'イベント参加取り消し',
      message: '「$eventName」は主催者により下書き状態に変更されたため、参加が取り消されました。',
      createdAt: DateTime.now(),
      data: {
        'eventId': eventId,
        'eventName': eventName,
        'organizerName': organizerName,
      },
    );
  }

  /// Firestoreドキュメントから作成
  factory NotificationData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationData(
      id: doc.id,
      toUserId: data['toUserId'] as String,
      fromUserId: data['fromUserId'] as String?,
      type: NotificationType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] as String,
      message: data['message'] as String,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      data: data['data'] as Map<String, dynamic>?,
    );
  }

  /// JSONから作成
  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'] as String?,
      toUserId: json['toUserId'] as String,
      fromUserId: json['fromUserId'] as String?,
      type: NotificationType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  /// Firestore保存用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
    };
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'type': type.name,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'data': data,
    };
  }

  /// 既読にマークしたコピーを作成
  NotificationData markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// コピーを作成
  NotificationData copyWith({
    String? id,
    String? toUserId,
    String? fromUserId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationData(
      id: id ?? this.id,
      toUserId: toUserId ?? this.toUserId,
      fromUserId: fromUserId ?? this.fromUserId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }

  /// 通知アイコンを取得
  String get iconName {
    switch (type) {
      case NotificationType.friendRequest:
        return 'person_add';
      case NotificationType.friendAccepted:
        return 'check_circle';
      case NotificationType.friendRejected:
        return 'cancel';
      case NotificationType.eventInvite:
        return 'event';
      case NotificationType.eventReminder:
        return 'schedule';
      case NotificationType.eventApproved:
        return 'check_circle';
      case NotificationType.eventRejected:
        return 'cancel';
      case NotificationType.eventApplication:
        return 'event_note';
      case NotificationType.eventDraftReverted:
        return 'event_busy';
      case NotificationType.violationReported:
        return 'report';
      case NotificationType.violationProcessed:
        return 'gavel';
      case NotificationType.violationDismissed:
        return 'cancel';
      case NotificationType.violationDeleted:
        return 'delete';
      case NotificationType.appealSubmitted:
        return 'help_outline';
      case NotificationType.appealProcessed:
        return 'verified';
      case NotificationType.matchReport:
        return 'report_problem';
      case NotificationType.matchReportResponse:
        return 'assignment_returned';
      case NotificationType.system:
        return 'info';
    }
  }

  /// 通知カテゴリの表示名を取得
  String get categoryDisplayName {
    switch (type) {
      case NotificationType.friendRequest:
      case NotificationType.friendAccepted:
      case NotificationType.friendRejected:
        return 'フレンド';
      case NotificationType.eventInvite:
      case NotificationType.eventReminder:
      case NotificationType.eventApproved:
      case NotificationType.eventRejected:
      case NotificationType.eventApplication:
      case NotificationType.eventDraftReverted:
        return 'イベント';
      case NotificationType.violationReported:
      case NotificationType.violationProcessed:
      case NotificationType.violationDismissed:
      case NotificationType.violationDeleted:
      case NotificationType.appealSubmitted:
      case NotificationType.appealProcessed:
        return '違反管理';
      case NotificationType.matchReport:
      case NotificationType.matchReportResponse:
        return '試合結果';
      case NotificationType.system:
        return 'システム';
    }
  }

  @override
  List<Object?> get props => [
        id,
        toUserId,
        fromUserId,
        type,
        title,
        message,
        isRead,
        createdAt,
        readAt,
        data,
      ];

  @override
  String toString() {
    return 'NotificationData(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}