import 'package:flutter/material.dart';
import '../../../shared/widgets/event_list_screen.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../game_event_management/models/game_event.dart';

/// おすすめイベント画面
/// 共通コンポーネントEventListScreenを使用
class RecommendedEventsScreen extends StatelessWidget {
  /// 初期表示するイベントリスト
  final List<GameEvent> initialEvents;

  /// ユーザーのFirebase UID
  final String firebaseUid;

  const RecommendedEventsScreen({
    super.key,
    required this.initialEvents,
    required this.firebaseUid,
  });

  @override
  Widget build(BuildContext context) {
    return EventListScreen(
      title: 'おすすめイベント',
      headerIcon: Icons.recommend,
      initialEvents: initialEvents,
      onRefresh: () async {
        // RecommendationServiceから最新データを取得
        final stream = RecommendationService.getRecommendedEvents(firebaseUid);
        return await stream.first;
      },
      emptyMessage: 'おすすめイベントがありません',
      emptySubMessage: 'お気に入りのゲームを登録すると\n関連するイベントが表示されます',
      emptyIcon: Icons.recommend,
      listType: EventListType.recommended,
    );
  }
}
