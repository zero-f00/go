import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/participation_service.dart';
import '../../features/game_event_management/models/game_event.dart';

// ApplicationStatusをParticipationStatusのエイリアスとして定義
typedef ApplicationStatus = ParticipationStatus;

class ActivityDetailDialog extends StatefulWidget {
  final String title;
  final String activityType;
  final String userId;

  const ActivityDetailDialog({
    super.key,
    required this.title,
    required this.activityType,
    required this.userId,
  });

  @override
  State<ActivityDetailDialog> createState() => _ActivityDetailDialogState();
}

class _ActivityDetailDialogState extends State<ActivityDetailDialog> {
  Future<List<GameEvent>>? _managedEventsFuture;

  @override
  void initState() {
    super.initState();
    // 運営イベントの場合のみFutureをキャッシュ
    if (widget.activityType == 'hosting') {
      _managedEventsFuture = _getManagedEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 500,
          maxWidth: 400,
        ),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForType(widget.activityType),
                  color: _getColorForType(widget.activityType),
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const Divider(height: AppDimensions.spacingXL),
            Expanded(
              child: _buildActivityContent(widget.activityType),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'pending':
        return Icons.schedule;
      case 'participating':
        return Icons.event_available;
      case 'hosting':
        return Icons.admin_panel_settings;
      case 'total':
        return Icons.emoji_events;
      default:
        return Icons.analytics;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'pending':
        return AppColors.warning;
      case 'participating':
        return AppColors.success;
      case 'hosting':
        return AppColors.info;
      case 'total':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildActivityContent(String type) {
    switch (type) {
      case 'pending':
        return _buildPendingApplications();
      case 'participating':
        return _buildParticipatingEvents();
      case 'hosting':
        return _buildHostingEvents();
      case 'total':
        return _buildTotalParticipation();
      default:
        return const Center(
          child: Text('データがありません'),
        );
    }
  }

  Widget _buildPendingApplications() {
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplications(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '申し込み中のイベントはありません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final pendingApps = snapshot.data!
            .where((app) => app.status == ParticipationStatus.pending)
            .toList();

        if (pendingApps.isEmpty) {
          return const Center(
            child: Text(
              '承認待ちの申し込みはありません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: pendingApps.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final app = pendingApps[index];
            return _buildApplicationTile(context, app);
          },
        );
      },
    );
  }

  Widget _buildParticipatingEvents() {
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplications(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '参加中のイベントはありません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final now = DateTime.now();
        final thisMonth = snapshot.data!
            .where((app) =>
              app.status == ParticipationStatus.approved &&
              app.appliedAt.year == now.year &&
              app.appliedAt.month == now.month)
            .toList();

        if (thisMonth.isEmpty) {
          return const Center(
            child: Text(
              '今月参加するイベントはありません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: thisMonth.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final app = thisMonth[index];
            return _buildApplicationTile(context, app);
          },
        );
      },
    );
  }

  Widget _buildHostingEvents() {
    return FutureBuilder<List<GameEvent>>(
      future: _managedEventsFuture ??= _getManagedEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'エラーが発生しました: ${snapshot.error}',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '運営中のイベントはありません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final event = snapshot.data![index];
            return _buildEventTile(context, event);
          },
        );
      },
    );
  }

  Future<List<GameEvent>> _getManagedEvents() async {
    try {
      final events = <GameEvent>[];
      final eventIds = <String>{};
      final now = DateTime.now();

      // 複数のクエリを並列実行
      final futures = <Future>[
        // 1. 作成者として作成したイベントを取得
        FirebaseFirestore.instance
            .collection('events')
            .where('createdBy', isEqualTo: widget.userId)
            .get(),

        // 2. 管理者として参加しているイベントを取得
        FirebaseFirestore.instance
            .collection('events')
            .where('managerIds', arrayContains: widget.userId)
            .get(),

        // 3. スポンサーとして参加しているイベントを取得
        FirebaseFirestore.instance
            .collection('events')
            .where('sponsorIds', arrayContains: widget.userId)
            .get(),

        // 4. gameEventsコレクションからも取得
        FirebaseFirestore.instance
            .collection('gameEvents')
            .where('createdBy', isEqualTo: widget.userId)
            .get(),
      ];

      final results = await Future.wait(futures.map((future) async {
        try {
          return await future;
        } catch (e) {
          return null;
        }
      }));

      // 結果を処理
      for (final result in results) {
        if (result == null) continue;

        final querySnapshot = result as QuerySnapshot;
        for (final doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final startDate = (data['startDate'] as Timestamp?)?.toDate();

            // 未来のイベントまたは24時間以内に終了したイベントのみを対象
            if (startDate != null && startDate.isAfter(now.subtract(const Duration(hours: 24)))) {
              final event = _createGameEventFromFirestore(doc);
              if (!eventIds.contains(event.id)) {
                events.add(event);
                eventIds.add(event.id);
              }
            }
          } catch (e) {
            // 個別イベントの処理エラーは無視して続行
          }
        }
      }

      // 開催日時順にソート
      events.sort((a, b) => a.startDate.compareTo(b.startDate));

      return events;
    } catch (e) {
      return [];
    }
  }

  GameEvent _createGameEventFromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameEvent(
      id: doc.id,
      name: data['name'] ?? 'イベント',
      description: data['description'] ?? '',
      type: _parseEventType(data['type']),
      status: _parseEventStatus(data['status']),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantCount: data['participantCount'] ?? 0,
      maxParticipants: data['maxParticipants'] ?? 0,
      completionRate: (data['completionRate'] ?? 0).toDouble(),
      gameId: data['gameId'] ?? '',
      gameName: data['gameName'] ?? '',
      platforms: List<String>.from(data['platforms'] ?? []),
      registrationDeadline: data['registrationDeadline'] != null
          ? (data['registrationDeadline'] as Timestamp).toDate()
          : null,
      approvalMethod: data['approvalMethod'] ?? '自動承認',
      visibility: data['visibility'] ?? 'public',
      language: data['language'] ?? '日本語',
      hasAgeRestriction: data['hasAgeRestriction'] ?? false,
      hasStreaming: data['hasStreaming'] ?? false,
      eventTags: List<String>.from(data['eventTags'] ?? []),
      sponsors: List<String>.from(data['sponsors'] ?? []),
      managers: List<String>.from(data['managers'] ?? []),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
    );
  }

  Widget _buildTotalParticipation() {
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplications(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              '参加履歴がありません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final approvedApps = snapshot.data!
            .where((app) => app.status == ParticipationStatus.approved)
            .toList()
          ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        return ListView.separated(
          itemCount: approvedApps.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final app = approvedApps[index];
            return _buildApplicationTile(context, app);
          },
        );
      },
    );
  }

  Widget _buildApplicationTile(BuildContext context, ParticipationApplication app) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(app.status),
        child: Icon(
          _getStatusIcon(app.status),
          color: Colors.white,
          size: AppDimensions.iconS,
        ),
      ),
      title: FutureBuilder<String>(
        future: _getEventName(app.eventId),
        builder: (context, snapshot) {
          return Text(
            snapshot.data ?? 'イベント名を取得中...',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ステータス: ${_getStatusText(app.status)}',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: _getStatusColor(app.status),
            ),
          ),
          Text(
            '申込日: ${_formatDate(app.appliedAt)}',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: () {
        Navigator.of(context).pushNamed(
          '/event_detail',
          arguments: app.eventId,
        );
      },
    );
  }

  Widget _buildEventTile(BuildContext context, GameEvent event) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.accent,
        child: const Icon(
          Icons.event,
          color: Colors.white,
          size: AppDimensions.iconS,
        ),
      ),
      title: Text(
        event.name,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '開催日: ${_formatDate(event.startDate)}',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '最大参加者: ${event.maxParticipants}名',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: () {
        Navigator.of(context).pushNamed(
          '/event_detail',
          arguments: event.id,
        );
      },
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.waitlisted:
        return AppColors.info;
      case ApplicationStatus.approved:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule;
      case ApplicationStatus.waitlisted:
        return Icons.queue;
      case ApplicationStatus.approved:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ApplicationStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return '承認待ち';
      case ApplicationStatus.waitlisted:
        return 'キャンセル待ち';
      case ApplicationStatus.approved:
        return '承認済み';
      case ApplicationStatus.rejected:
        return '拒否';
      case ApplicationStatus.cancelled:
        return 'キャンセル済み';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  GameEventType _parseEventType(dynamic value) {
    switch (value?.toString()) {
      case 'daily':
        return GameEventType.daily;
      case 'weekly':
        return GameEventType.weekly;
      case 'special':
        return GameEventType.special;
      case 'seasonal':
        return GameEventType.seasonal;
      default:
        return GameEventType.daily;
    }
  }

  GameEventStatus _parseEventStatus(dynamic value) {
    switch (value?.toString()) {
      case 'upcoming':
        return GameEventStatus.upcoming;
      case 'active':
        return GameEventStatus.active;
      case 'completed':
        return GameEventStatus.completed;
      case 'expired':
        return GameEventStatus.expired;
      case 'cancelled':
        return GameEventStatus.cancelled;
      default:
        return GameEventStatus.upcoming;
    }
  }

  Future<String> _getEventName(String eventId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ?? 'イベント';
      }
      return 'イベント';
    } catch (e) {
      return 'イベント';
    }
  }
}