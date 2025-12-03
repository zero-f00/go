import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/utils/event_converter.dart';
import 'event_detail_screen.dart';

/// EventDetailScreen用のラッパー
/// eventId（String）からGameEventを取得してEventDetailScreenに渡す
class EventDetailWrapper extends StatelessWidget {
  final String eventId;

  const EventDetailWrapper({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: FutureBuilder(
            future: _loadEventDetails(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(context, snapshot.error.toString());
              }

              if (snapshot.hasData) {
                return EventDetailScreen(
                  event: snapshot.data!,
                  fromOperationsDashboard: true, // 運営ダッシュボードからの遷移として扱う
                );
              }

              return _buildErrorState(context, 'イベントが見つかりませんでした');
            },
          ),
        ),
      ),
    );
  }

  Future<dynamic> _loadEventDetails() async {
    try {
      // EventServiceからEventを取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        throw Exception('イベントが見つかりませんでした');
      }

      // EventをGameEventに変換
      final gameEvent = await EventConverter.eventToGameEvent(event);

      return gameEvent;
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'エラーが発生しました',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              error,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}