import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/participation_service.dart';
import '../../features/game_event_management/models/game_event.dart';

// ApplicationStatusをParticipationStatusのエイリアスとして定義
typedef ApplicationStatus = ParticipationStatus;

class ActivityDetailDialog extends StatelessWidget {
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
                  _getIconForType(activityType),
                  color: _getColorForType(activityType),
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Text(
                    title,
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
              child: _buildActivityContent(activityType),
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
      future: ParticipationService.getUserApplications(userId),
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
      future: ParticipationService.getUserApplications(userId),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('hostId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final event = GameEvent(
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
            return _buildEventTile(context, event);
          },
        );
      },
    );
  }

  Widget _buildTotalParticipation() {
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplications(userId),
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
      case ApplicationStatus.approved:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ParticipationStatus.rejected:
        return AppColors.textSecondary;  // canceledは存在しないのでrejectedで代用
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule;
      case ApplicationStatus.approved:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ParticipationStatus.rejected:
        return Icons.cancel;  // canceledは存在しないのでrejectedで代用
    }
  }

  String _getStatusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return '承認待ち';
      case ApplicationStatus.approved:
        return '承認済み';
      case ApplicationStatus.rejected:
        return '拒否';
      case ParticipationStatus.rejected:
        return '拒否';  // canceledは存在しないのでrejectedで代用
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