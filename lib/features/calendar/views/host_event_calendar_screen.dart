import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/unified_calendar_widget.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/event_converter.dart';
import '../../../data/models/event_model.dart';
import '../../event_detail/views/event_detail_screen.dart';
import '../../game_event_management/models/game_event.dart';

class HostEventCalendarScreen extends ConsumerStatefulWidget {
  const HostEventCalendarScreen({super.key});

  @override
  ConsumerState<HostEventCalendarScreen> createState() => _HostEventCalendarScreenState();
}

class _HostEventCalendarScreenState extends ConsumerState<HostEventCalendarScreen> {
  // フィルター設定
  final Map<String, bool> _filters = {
    '公開済みイベント': true,
    '下書きイベント': true,
    '完了済みイベント': true,
  };

  // フィルター更新フラグ
  int _filterVersion = 0;

  /// 主催イベントを読み込み
  Future<Map<DateTime, List<GameEvent>>> _loadHostEvents() async {

    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) {
      throw Exception('ユーザーがログインしていません');
    }

    final events = <DateTime, List<GameEvent>>{};

    // 主催者として登録されているイベントを取得（createdBy、managerIds、sponsorsから）
    final queries = [
      // 作成者として
      FirebaseFirestore.instance
          .collection('events')
          .where('createdBy', isEqualTo: currentUser.uid),

      // 管理者として
      FirebaseFirestore.instance
          .collection('events')
          .where('managerIds', arrayContains: currentUser.uid),

      // スポンサーとして
      FirebaseFirestore.instance
          .collection('events')
          .where('sponsors', arrayContains: currentUser.uid),
    ];

    final Set<String> addedEventIds = {}; // 重複を避けるため

    for (final query in queries) {
      final snapshot = await query.get();

      for (final doc in snapshot.docs) {
        if (addedEventIds.contains(doc.id)) continue;
        addedEventIds.add(doc.id);

        final data = doc.data()!;

        // フィルターに基づいて表示するかどうかを決定
        final shouldShow = _shouldShowEvent(data);

        if (!shouldShow) {
          continue;
        }

        try {
          // EventモデルからGameEventモデルに変換
          final event = Event.fromFirestore(doc);
          final gameEvent = await EventConverter.eventToGameEvent(event);
          final date = _normalizeDate(gameEvent.startDate);

          if (events[date] == null) {
            events[date] = [];
          }
          events[date]!.add(gameEvent);
        } catch (e) {
          // エラーが発生したイベントはスキップ
          continue;
        }
      }
    }

    return events;
  }

  /// フィルター設定に基づいてイベントを表示するかどうかを判定
  bool _shouldShowEvent(Map<String, dynamic> data) {
    final status = data['status'] as String?;

    // EventStatusの値に基づく判定（eventsコレクションはEventStatusを使用）
    switch (status) {
      case 'published':
        return _filters['公開済みイベント'] ?? true;
      case 'draft':
        return _filters['下書きイベント'] ?? true;
      case 'completed':
      case 'cancelled':
        return _filters['完了済みイベント'] ?? true;
      default:
        return true; // 不明なステータスは表示
    }
  }

  /// 日付を正規化（時分秒を0にする）
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// フィルター変更時のコールバック
  void _onFiltersChanged(Map<String, bool> filters) {
    setState(() {
      _filters.addAll(filters);
      _filterVersion++; // フィルター更新をトリガー
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: '主催イベントカレンダー',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: UnifiedCalendarWidget(
                  key: ValueKey(_filterVersion), // フィルター変更時に再構築
                  title: '主催イベントカレンダー',
                  onLoadEvents: _loadHostEvents,
                  onEventTap: _navigateToEventDetail,
                  showFilters: true,
                  initialFilters: _filters,
                  onFiltersChanged: _onFiltersChanged,
                  getEventStatusColor: _getEventStatusColor,
                  normalizeDate: _normalizeDate,
                  emptyMessage: '選択した日にはイベントがありません',
                  emptyIcon: Icons.event_busy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// イベントステータスに基づく色を取得
  Color _getEventStatusColor(GameEvent event) {
    switch (event.status) {
      case GameEventStatus.draft:
        return AppColors.warning;
      case GameEventStatus.published:
        return AppColors.success;
      case GameEventStatus.upcoming:
        return AppColors.info;
      case GameEventStatus.active:
        return AppColors.success;
      case GameEventStatus.completed:
        return AppColors.textSecondary;
      case GameEventStatus.expired:
        return AppColors.error;
      case GameEventStatus.cancelled:
        return AppColors.error;
    }
  }




  /// イベント詳細画面に遷移
  void _navigateToEventDetail(GameEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

}