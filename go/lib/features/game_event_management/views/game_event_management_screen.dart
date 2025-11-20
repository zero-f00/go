import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_event.dart';
import '../view_models/game_event_management_view_model.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/event_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/auth_dialog.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../event_detail/views/event_detail_screen.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/generic_event_list_screen.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/participation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameEventManagementScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSearch;
  final VoidCallback? onNavigateToEventCreation;

  const GameEventManagementScreen({
    super.key,
    this.onNavigateToSearch,
    this.onNavigateToEventCreation,
  });

  @override
  ConsumerState<GameEventManagementScreen> createState() => _GameEventManagementScreenState();
}

class _GameEventManagementScreenState extends ConsumerState<GameEventManagementScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Go',
                showBackButton: false,
                showUserIcon: true,
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationBanner(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildActivitySummary(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildQuickActions(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildUpcomingEvents(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildRecommendedEvents(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildSocialSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 通知・お知らせバナー
  Widget _buildNotificationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.accent,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active,
              color: AppColors.textWhite,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'イベント開始まで30分！',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWhite,
                  ),
                ),
                SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'スプラトゥーン3 大会準備をお忘れなく',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingXS),
            decoration: BoxDecoration(
              color: AppColors.textWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: AppColors.textWhite,
              size: AppDimensions.iconM,
            ),
          ),
        ],
      ),
    );
  }

  // クイックアクション
  Widget _buildQuickActions() {
    return _buildSectionContainer(
      title: 'クイックアクション',
      icon: Icons.flash_on,
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                label: 'イベント作成',
                icon: Icons.add_circle_outline,
                onTap: () {
                  widget.onNavigateToEventCreation?.call();
                },
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                iconColor: AppColors.accent,
                textColor: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: QuickActionButton(
                label: 'イベント検索',
                icon: Icons.search,
                onTap: () {
                  widget.onNavigateToSearch?.call();
                },
                backgroundColor: AppColors.info.withValues(alpha: 0.1),
                iconColor: AppColors.info,
                textColor: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 共通セクションコンテナ（管理画面と同じスタイル）
  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.accent,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ...children,
        ],
      ),
    );
  }

  /// ログインダイアログを表示
  void _showLoginDialog(BuildContext context) {
    AuthDialog.show(context);
  }

  // 参加予定イベント
  Widget _buildUpcomingEvents() {
    final currentUserAsync = ref.watch(currentUserDataProvider);
    final authState = ref.watch(authStateProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null || !authState.hasValue || authState.value == null) {
          return _buildSectionContainer(
            title: '参加予定イベント',
            icon: Icons.schedule,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppDimensions.spacingL),
                child: Text(
                  'ログインしてください',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }

        return FutureBuilder<List<ParticipationApplication>>(
          future: ParticipationService.getUserApplications(user.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSectionContainer(
                title: '参加予定イベント',
                icon: Icons.schedule,
                children: [
                  const SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return _buildSectionContainer(
                title: '参加予定イベント',
                icon: Icons.schedule,
                children: [
                  EmptyStateView(
                    icon: Icons.error_outline,
                    title: 'エラーが発生しました',
                    message: '参加予定イベントの取得に失敗しました\nしばらくしてから再試行してください',
                  ),
                ],
              );
            }

            final applications = snapshot.data ?? [];
            // 承認済みのイベントのみを取得
            final approvedApplications = applications
                .where((app) => app.status == ParticipationStatus.approved)
                .toList();

            return _buildSectionContainer(
              title: '参加予定イベント',
              icon: Icons.schedule,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    if (approvedApplications.isNotEmpty)
                      TextButton(
                        onPressed: () => _navigateToApprovedEvents(approvedApplications),
                        child: const Text(
                          'すべて見る',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                if (approvedApplications.isEmpty)
                  EmptyStateView(
                    icon: Icons.event_available,
                    title: '参加予定のイベントはありません',
                    message: 'イベントに申し込んで承認されると\nこちらに表示されます',
                    onAction: () => widget.onNavigateToSearch?.call(),
                    actionLabel: 'イベントを探す',
                  )
                else
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: approvedApplications.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 320,
                          margin: const EdgeInsets.only(right: AppDimensions.spacingM),
                          child: _buildUpcomingEventCardFromApplication(approvedApplications[index]),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
      loading: () => _buildSectionContainer(
        title: '参加予定イベント',
        icon: Icons.schedule,
        children: [
          const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
      error: (error, stack) => _buildSectionContainer(
        title: '参加予定イベント',
        icon: Icons.schedule,
        children: [
          EmptyStateView(
            icon: Icons.error_outline,
            title: 'エラーが発生しました',
            message: 'ユーザー情報の取得に失敗しました\nしばらくしてから再試行してください',
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCardFromApplication(ParticipationApplication application) {
    return FutureBuilder<GameEvent?>(
      future: _getEventFromApplication(application),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            height: 240,
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: AppDimensions.iconL,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'イベント情報の取得に失敗',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppDimensions.fontSizeS,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final event = snapshot.data!;
        return EventCard(
          event: event,
          onTap: () => _showEventDetails(event),
        );
      },
    );
  }

  Future<GameEvent?> _getEventFromApplication(ParticipationApplication application) async {
    try {
      // まず gameEvents コレクションから取得を試みる
      final gameEventDoc = await FirebaseFirestore.instance
          .collection('gameEvents')
          .doc(application.eventId)
          .get();

      if (gameEventDoc.exists && gameEventDoc.data() != null) {
        // GameEventデータがある場合はそれを使用
        return GameEvent.fromFirestore(gameEventDoc.data()!, gameEventDoc.id);
      }

      // 次に events コレクションから取得を試みる
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(application.eventId)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        // EventデータをGameEventに変換
        final eventData = eventDoc.data()!;
        return _convertEventToGameEvent(eventData, application.eventId);
      }

      return null;
    } catch (e) {
      print('❌ Error fetching event for application: $e');
      return null;
    }
  }

  GameEvent _convertEventToGameEvent(Map<String, dynamic> eventData, String eventId) {
    return GameEvent(
      id: eventId,
      name: eventData['name'] ?? 'イベント',
      subtitle: eventData['subtitle'],
      description: eventData['description'] ?? '',
      type: _mapEventType(eventData['type']),
      status: GameEventStatus.active,
      startDate: (eventData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (eventData['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 2)),
      participantCount: (eventData['participantIds'] as List?)?.length ?? 0,
      maxParticipants: eventData['maxParticipants'] ?? 10,
      completionRate: 0.0,
      hasFee: eventData['hasFee'] ?? false,
      rewards: const <String, double>{},
      gameId: eventData['gameId'],
      gameName: eventData['gameName'],
      gameIconUrl: eventData['gameIconUrl'],
      imageUrl: eventData['imageUrl'],
      rules: eventData['rules'],
      registrationDeadline: (eventData['registrationDeadline'] as Timestamp?)?.toDate(),
      prizeContent: eventData['prizeContent'],
      contactInfo: eventData['contactInfo'],
      policy: eventData['policy'],
      additionalInfo: eventData['additionalInfo'],
      streamingUrl: eventData['streamingUrl'],
      minAge: eventData['minAge'],
      feeAmount: eventData['feeAmount']?.toDouble(),
      platforms: List<String>.from(eventData['platforms'] ?? []),
      approvalMethod: eventData['approvalMethod'] ?? 'manual',
      visibility: eventData['visibility'] ?? 'public',
      language: eventData['language'] ?? 'ja',
      hasAgeRestriction: eventData['hasAgeRestriction'] ?? false,
      hasStreaming: eventData['hasStreaming'] ?? false,
      eventTags: List<String>.from(eventData['eventTags'] ?? []),
      sponsors: List<String>.from(eventData['sponsors'] ?? []),
      managers: List<String>.from(eventData['managers'] ?? []),
      createdBy: eventData['createdBy'],
      createdByName: eventData['createdByName'],
    );
  }

  GameEventType _mapEventType(String? eventType) {
    switch (eventType) {
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


  void _navigateToApprovedEvents(List<ParticipationApplication> applications) {
    // 承認済みイベント一覧画面への遷移
    // TODO: 必要に応じて専用の画面を作成
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('承認済みイベント一覧画面は実装予定です'),
      ),
    );
  }

  void _showEventDetails(GameEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  // アクティビティ状況
  Widget _buildActivitySummary() {
    return _buildSectionContainer(
      title: 'あなたのアクティビティ',
      icon: Icons.analytics,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActivityItem(
                '今月の参加',
                '8回',
                Icons.event_available,
                AppColors.success,
              ),
            ),
            Expanded(
              child: _buildActivityItem(
                '獲得ポイント',
                '1,250pt',
                Icons.stars,
                AppColors.warning,
              ),
            ),
            Expanded(
              child: _buildActivityItem(
                'ストリーク',
                '5日連続',
                Icons.local_fire_department,
                AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: AppDimensions.iconM,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }


  // おすすめイベント
  Widget _buildRecommendedEvents() {
    print('🏠 _buildRecommendedEvents: Building recommended events widget');
    final currentUserAsync = ref.watch(currentUserDataProvider);
    final authState = ref.watch(authStateProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null || !authState.hasValue || authState.value == null) {
          return _buildSectionContainer(
            title: 'おすすめイベント',
            icon: Icons.recommend,
            children: [
              EmptyStateView(
                icon: Icons.login,
                title: 'ログインが必要です',
                message: 'おすすめイベントを表示するには\nログインしてください',
                onAction: () => _showLoginDialog(context),
                actionLabel: 'ログイン',
              ),
            ],
          );
        }

        // Firebase UIDを使用
        final firebaseUid = authState.value!.uid;
        final recommendedEventsAsync = ref.watch(recommendedEventsProvider(firebaseUid));

        return recommendedEventsAsync.when(
          data: (events) {
            print('🏠 _buildRecommendedEvents: Recommended events count: ${events.length}');

            return _buildSectionContainer(
              title: 'おすすめイベント',
              icon: Icons.recommend,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    TextButton(
                      onPressed: () => _navigateToAllEvents(),
                      child: const Text(
                        'もっと見る',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingM),
                    child: Text(
                      'お気に入りのゲームに関連するイベントがありません',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  ...events.take(3).map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                    child: EventCard(
                      event: event,
                      onTap: () => _showEventDetails(event),
                    ),
                  )),
              ],
            );
          },
          loading: () => _buildSectionContainer(
            title: 'おすすめイベント',
            icon: Icons.recommend,
            children: [
              const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
          error: (error, stack) {
            print('❌ _buildRecommendedEvents: Error loading recommended events: $error');
            return _buildSectionContainer(
              title: 'おすすめイベント',
              icon: Icons.recommend,
              children: [
                EmptyStateView(
                  icon: Icons.error_outline,
                  title: 'エラーが発生しました',
                  message: 'おすすめイベントの取得に失敗しました\nしばらくしてから再試行してください',
                ),
              ],
            );
          },
        );
      },
      loading: () => _buildSectionContainer(
        title: 'おすすめイベント',
        icon: Icons.recommend,
        children: [
          const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
      error: (error, stack) => _buildSectionContainer(
        title: 'おすすめイベント',
        icon: Icons.recommend,
        children: [
          EmptyStateView(
            icon: Icons.error_outline,
            title: 'エラーが発生しました',
            message: 'ユーザー情報の取得に失敗しました\nしばらくしてから再試行してください',
          ),
        ],
      ),
    );
  }


  // ソーシャル要素
  Widget _buildSocialSection() {
    final currentUserAsync = ref.watch(currentUserDataProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return _buildEmptyFriendsSection();
        }

        final friendEventsAsync = ref.watch(friendEventsProvider(user.userId));

        return friendEventsAsync.when(
          data: (friendEvents) {
            return _buildSectionContainer(
              title: 'フレンドの活動',
              icon: Icons.people,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/friends'),
                      child: const Text(
                        'フレンド管理',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                if (friendEvents.isNotEmpty) ...[
                  ...friendEvents.take(3).map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                    child: _buildFriendEventActivity(event),
                  )),
                ] else ...[
                  _buildNoFriendActivity(),
                ],
              ],
            );
          },
          loading: () => _buildLoadingFriendsSection(),
          error: (error, stackTrace) => _buildEmptyFriendsSection(),
        );
      },
      loading: () => _buildLoadingFriendsSection(),
      error: (error, stackTrace) => _buildEmptyFriendsSection(),
    );
  }

  Widget _buildEmptyFriendsSection() {
    return _buildSectionContainer(
      title: 'フレンドの活動',
      icon: Icons.people,
      children: [
        _buildNoFriendActivity(),
      ],
    );
  }

  Widget _buildLoadingFriendsSection() {
    return _buildSectionContainer(
      title: 'フレンドの活動',
      icon: Icons.people,
      children: [
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildFriendEventActivity(GameEvent event) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event,
            color: AppColors.primary,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                if (event.createdByName != null)
                  Text(
                    '${event.createdByName}さんが主催',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Text(
                    'フレンドが参加予定',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: AppDimensions.iconS,
            color: AppColors.textLight,
          ),
        ],
      ),
    );
  }

  Widget _buildNoFriendActivity() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: AppDimensions.iconXL,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          const Text(
            'フレンドの活動はまだありません',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Text(
            'フレンドを追加してイベント情報をシェアしよう！',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }





  void _navigateToAllEvents() {
    final state = ref.watch(gameEventManagementViewModelProvider);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GenericEventListScreen(
          title: 'すべてのイベント',
          events: state.events,
          onEventTap: (event) => _showEventDetails(event),
          emptyTitle: 'イベントがありません',
          emptyMessage: 'まだイベントが作成されていません。\n新しいイベントを作成してみましょう。',
          emptyIcon: Icons.event_note,
          searchHint: 'イベント名やゲーム名で検索...',
        ),
      ),
    );
  }




}