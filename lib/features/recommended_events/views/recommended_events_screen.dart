import 'package:flutter/material.dart';
import '../../../shared/widgets/event_list_screen.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../game_event_management/models/game_event.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = L10n.of(context);
    return EventListScreen(
      title: l10n.recommendedEventsTitle,
      headerIcon: Icons.recommend,
      initialEvents: initialEvents,
      onRefresh: () async {
        // RecommendationServiceから最新データを取得
        final stream = RecommendationService.getRecommendedEvents(firebaseUid);
        return await stream.first;
      },
      emptyMessage: l10n.noRecommendedEvents,
      emptySubMessage: l10n.registerFavoriteGamesHint,
      emptyIcon: Icons.recommend,
      listType: EventListType.recommended,
    );
  }
}
