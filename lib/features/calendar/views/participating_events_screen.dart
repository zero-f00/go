import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/event_list_screen.dart';
import '../../../shared/services/participation_service.dart';
import '../../game_event_management/models/game_event.dart';
import '../../../shared/utils/event_converter.dart';
import '../../../data/models/event_model.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// 参加予定イベント画面
/// カレンダー/リスト表示切り替え機能を提供
class ParticipatingEventsScreen extends ConsumerStatefulWidget {
  /// ユーザーのFirebase UID
  final String firebaseUid;

  /// 初期表示するイベントリスト（オプション）
  final List<GameEvent>? initialEvents;

  const ParticipatingEventsScreen({
    super.key,
    required this.firebaseUid,
    this.initialEvents,
  });

  @override
  ConsumerState<ParticipatingEventsScreen> createState() =>
      _ParticipatingEventsScreenState();
}

class _ParticipatingEventsScreenState
    extends ConsumerState<ParticipatingEventsScreen> {
  List<GameEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEvents != null) {
      _events = widget.initialEvents!;
      _isLoading = false;
    } else {
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _fetchParticipatingEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<GameEvent>> _fetchParticipatingEvents() async {
    // 参加申請を取得
    final applications = await ParticipationService.getUserApplications(
      widget.firebaseUid,
    );

    // 承認済みの申請のみフィルタリング
    final approvedApplications = applications
        .where((app) => app.status == ParticipationStatus.approved)
        .toList();

    final List<GameEvent> events = [];
    final now = DateTime.now();

    for (final application in approvedApplications) {
      final event = await _getEventFromApplication(application);
      if (event != null) {
        // イベント開始時刻が未来のもののみ表示（開始時刻を過ぎたら参加予定から除外）
        if (event.startDate.isAfter(now)) {
          events.add(event);
        }
      }
    }

    // 開催日順でソート
    events.sort((a, b) => a.startDate.compareTo(b.startDate));

    return events;
  }

  Future<GameEvent?> _getEventFromApplication(
    ParticipationApplication application,
  ) async {
    try {
      // まず gameEvents コレクションから取得を試みる
      final gameEventDoc = await FirebaseFirestore.instance
          .collection('gameEvents')
          .doc(application.eventId)
          .get();

      if (gameEventDoc.exists && gameEventDoc.data() != null) {
        final data = gameEventDoc.data()!;
        if (!_isEventVisible(data)) {
          return null;
        }
        return GameEvent.fromFirestore(data, gameEventDoc.id);
      }

      // 次に events コレクションから取得を試みる
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(application.eventId)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        final data = eventDoc.data()!;
        if (!_isEventVisible(data)) {
          return null;
        }
        final event = Event.fromFirestore(eventDoc);
        return await EventConverter.eventToGameEvent(event);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isEventVisible(Map<String, dynamic> eventData) {
    final status = eventData['status'] as String?;
    final visibility = eventData['visibility'] as String?;

    if (status == 'draft') {
      return false;
    }

    if (visibility == 'private') {
      return false;
    }

    return status == 'published' || status == 'scheduled' || status == 'active';
  }

  Color _getEventStatusColor(GameEvent event) {
    switch (event.status) {
      case GameEventStatus.upcoming:
        return AppColors.info;
      case GameEventStatus.active:
        return AppColors.success;
      case GameEventStatus.published:
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return EventListScreen(
      title: l10n.participatingEvents,
      headerIcon: Icons.event_available,
      initialEvents: _events,
      onRefresh: _fetchParticipatingEvents,
      emptyMessage: l10n.noParticipatingEvents,
      emptySubMessage: l10n.tryJoinNewEvents,
      emptyIcon: Icons.event_available,
      listType: EventListType.participating,
      getEventStatusColor: _getEventStatusColor,
    );
  }
}
