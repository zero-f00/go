import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_event.dart';
import '../../../shared/widgets/enhanced_activity_detail_dialog.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/compact_event_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../event_detail/views/event_detail_screen.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/generic_event_list_screen.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/participation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/utils/event_converter.dart';
import '../../../data/models/event_model.dart';
import '../../../shared/widgets/activity_stats_card.dart';
import '../../../shared/services/user_event_service.dart';
import '../../../shared/widgets/auth_dialog.dart';

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

class _GameEventManagementScreenState extends ConsumerState<GameEventManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
                      _buildActivitySummary(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildQuickActions(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildUpcomingEvents(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildRecommendedEvents(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildManagedEvents(),
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
                onTap: () => _handleEventCreation(),
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

        final firebaseUser = ref.read(currentFirebaseUserProvider);
        final userIdToUse = firebaseUser?.uid ?? user.userId;

        return FutureBuilder<List<ParticipationApplication>>(
          future: ParticipationService.getUserApplicationsWithBothIds(
            firebaseUid: firebaseUser?.uid,
            customUserId: user.userId,
          ),
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

            final approvedApplications = applications
                .where((app) => app.status == ParticipationStatus.approved)
                .toList();
            return FutureBuilder<List<GameEvent>>(
              future: _getUpcomingEventsFromApplications(approvedApplications),
              builder: (context, eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildUpcomingEventsLoading();
                }

                final upcomingEvents = eventSnapshot.data ?? [];
                return _buildUpcomingEventsContent(upcomingEvents, approvedApplications);
              },
            );
          },
        );
      },
      loading: () => _buildUpcomingEventsLoading(),
      error: (error, stack) => _buildUpcomingEventsError(),
    );
  }

  /// 開催日が近い順にソートされた参加予定イベントを取得
  Future<List<GameEvent>> _getUpcomingEventsFromApplications(List<ParticipationApplication> applications) async {
    if (applications.isEmpty) return [];

    final List<GameEvent> events = [];
    final now = DateTime.now();

    for (final application in applications) {
      final event = await _getEventFromApplication(application);
      if (event != null && event.startDate.isAfter(now.subtract(const Duration(days: 1)))) {
        events.add(event);
      }
    }

    events.sort((a, b) => a.startDate.compareTo(b.startDate));
    return events.take(3).toList();
  }

  /// 参加予定イベントのローディング状態
  Widget _buildUpcomingEventsLoading() {
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

  /// 参加予定イベントのエラー状態
  Widget _buildUpcomingEventsError() {
    return _buildSectionContainer(
      title: '参加予定イベント',
      icon: Icons.schedule,
      children: [
        EmptyStateView(
          icon: Icons.error_outline,
          title: 'エラーが発生しました',
          message: 'ユーザー情報の取得に失敗しました\nしばらくしてから再試行してください',
        ),
      ],
    );
  }

  /// 参加予定イベントのコンテンツ
  Widget _buildUpcomingEventsContent(List<GameEvent> upcomingEvents, List<ParticipationApplication> approvedApplications) {
    return _buildSectionContainer(
      title: '参加予定イベント',
      icon: Icons.schedule,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(),
            if (approvedApplications.isNotEmpty)
              TextButton.icon(
                onPressed: () => _navigateToEventCalendar(approvedApplications),
                icon: const Icon(
                  Icons.calendar_today,
                  size: AppDimensions.iconS,
                  color: AppColors.accent,
                ),
                label: const Text(
                  'カレンダーで見る',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        if (upcomingEvents.isEmpty)
          EmptyStateView(
            icon: Icons.event_available,
            title: '参加予定のイベントはありません',
            message: 'イベントに申し込んで承認されると\nこちらに表示されます',
            onAction: () => widget.onNavigateToSearch?.call(),
            actionLabel: 'イベントを探す',
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 320,
                  margin: const EdgeInsets.only(right: AppDimensions.spacingM),
                  child: CompactEventCard(
                    event: upcomingEvents[index],
                    onTap: () => _showEventDetails(upcomingEvents[index]),
                  ),
                );
              },
            ),
          ),
      ],
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
        final gameEvent = GameEvent.fromFirestore(gameEventDoc.data()!, gameEventDoc.id);
        // 下書きや非公開イベントは表示しない
        if (!_isEventVisibleInParticipatingList(gameEventDoc.data()!)) {
          return null;
        }
        return gameEvent;
      }

      // 次に events コレクションから取得を試みる
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(application.eventId)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        final eventData = eventDoc.data()!;
        // 下書きや非公開イベントは表示しない
        if (!_isEventVisibleInParticipatingList(eventData)) {
          return null;
        }
        final event = Event.fromFirestore(eventDoc);
        final gameEvent = await EventConverter.eventToGameEvent(event);
        return gameEvent;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 参加予定リストに表示すべきイベントかどうかを判定
  bool _isEventVisibleInParticipatingList(Map<String, dynamic> eventData) {
    final status = eventData['status'] as String?;
    final visibility = eventData['visibility'] as String?;

    // 下書き状態のイベントは表示しない
    if (status == 'draft') {
      return false;
    }

    // 非公開イベントは表示しない（プライベートまたは招待制の場合は表示）
    if (visibility == 'private') {
      return false;
    }

    // 公開済みまたは予約公開済みのイベントのみ表示
    return status == 'published' || status == 'scheduled';
  }

  /// カレンダー画面への遷移
  void _navigateToEventCalendar(List<ParticipationApplication> applications) {
    Navigator.of(context).pushNamed(
      '/event_calendar',
      arguments: {
        'applications': applications,
      },
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
    final currentUserAsync = ref.watch(currentUserDataProvider);
    final authState = ref.watch(authStateProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null || !authState.hasValue || authState.value == null) {
          return _buildSectionContainer(
            title: 'あなたのアクティビティ',
            icon: Icons.analytics,
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

        final firebaseUser = ref.read(currentFirebaseUserProvider);
        final userIdToUse = firebaseUser?.uid ?? user.userId;

        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            UserEventService.getUserActivityStats(userIdToUse),
            ParticipationService.getUserApplicationsWithBothIds(
              firebaseUid: firebaseUser?.uid,
              customUserId: user.userId,
            ),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSectionContainer(
                title: 'あなたのアクティビティ',
                icon: Icons.analytics,
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
                title: 'あなたのアクティビティ',
                icon: Icons.analytics,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingL),
                    child: Text(
                      'データの取得に失敗しました',
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

            final data = snapshot.data;
            if (data == null || data.length < 2) {
              return _buildSectionContainer(
                title: 'あなたのアクティビティ',
                icon: Icons.analytics,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(AppDimensions.spacingL),
                    child: Text(
                      'データを取得できませんでした',
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

            final hostingStats = data[0] as Map<String, int>;
            final applications = data[1] as List<dynamic>;
            final participationStats = UserEventService.calculateParticipationStats(applications);

            return _buildSectionContainer(
              title: 'あなたのアクティビティ',
              icon: Icons.analytics,
              children: [
                // 統計カードのグリッド表示
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: AppDimensions.spacingM,
                  mainAxisSpacing: AppDimensions.spacingM,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => EnhancedActivityDetailDialog(
                            title: '今月の参加イベント',
                            activityType: 'participating',
                            userId: userIdToUse,
                          ),
                        );
                      },
                      child: ActivityStatsCard(
                        title: '今月の参加',
                        value: '${participationStats['thisMonthApprovedApplications'] ?? 0}',
                        subtitle: '承認済みイベント',
                        icon: Icons.event_available,
                        iconColor: AppColors.success,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => EnhancedActivityDetailDialog(
                            title: '申し込み中のイベント',
                            activityType: 'pending',
                            userId: userIdToUse,
                          ),
                        );
                      },
                      child: ActivityStatsCard(
                        title: '申し込み中',
                        value: '${participationStats['pendingApplications'] ?? 0}',
                        subtitle: '承認待ち',
                        icon: Icons.schedule,
                        iconColor: AppColors.warning,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => EnhancedActivityDetailDialog(
                            title: '参加履歴',
                            activityType: 'total',
                            userId: userIdToUse,
                          ),
                        );
                      },
                      child: ActivityStatsCard(
                        title: '総参加数',
                        value: '${participationStats['approvedApplications'] ?? 0}',
                        subtitle: 'これまでに参加',
                        icon: Icons.emoji_events,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => EnhancedActivityDetailDialog(
                            title: '運営イベント',
                            activityType: 'hosting',
                            userId: userIdToUse,
                          ),
                        );
                      },
                      child: ActivityStatsCard(
                        title: '運営数',
                        value: '${hostingStats['totalManagedEvents'] ?? hostingStats['totalHostedEvents'] ?? 0}',
                        subtitle: '運営に携わったイベント',
                        icon: Icons.admin_panel_settings,
                        iconColor: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
      loading: () => _buildSectionContainer(
        title: 'あなたのアクティビティ',
        icon: Icons.analytics,
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
        title: 'あなたのアクティビティ',
        icon: Icons.analytics,
        children: [
          const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingL),
            child: Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }



  // おすすめイベント
  Widget _buildRecommendedEvents() {
    final currentUserAsync = ref.watch(currentUserDataProvider);
    final authState = ref.watch(authStateProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null || !authState.hasValue || authState.value == null) {
          return _buildSectionContainer(
            title: 'おすすめイベント',
            icon: Icons.recommend,
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

        final firebaseUid = authState.value!.uid;
        final recommendedEventsAsync = ref.watch(recommendedEventsProvider(firebaseUid));

        return recommendedEventsAsync.when(
          data: (events) {
            // お気に入りゲームの登録状況を確認
            final hasFavoriteGames = user.favoriteGameIds.isNotEmpty;

            return _buildSectionContainer(
              title: 'おすすめイベント',
              icon: Icons.recommend,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    if (events.isNotEmpty)
                      TextButton(
                        onPressed: () => _navigateToRecommendedEvents(events),
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
                  // お気に入りゲームの登録状況に応じて表示内容を変更
                  EmptyStateView(
                    icon: hasFavoriteGames ? Icons.event_busy : Icons.videogame_asset,
                    title: hasFavoriteGames
                      ? '該当するイベントが見つかりません'
                      : 'お気に入りのゲームを登録してください',
                    message: hasFavoriteGames
                      ? 'お気に入りゲームのイベントが\n現在開催されていません'
                      : 'お気に入りのゲームを登録すると\n関連するイベントをおすすめします',
                    onAction: () => hasFavoriteGames
                      ? widget.onNavigateToSearch?.call()
                      : _navigateToFavoriteGames(),
                    actionLabel: hasFavoriteGames
                      ? 'イベントを探す'
                      : 'お気に入りゲームを登録',
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: (events.length > 5) ? 5 : events.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 320,
                          margin: const EdgeInsets.only(right: AppDimensions.spacingM),
                          child: CompactEventCard(
                            event: events[index],
                            onTap: () => _showEventDetails(events[index]),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () {
            return _buildSectionContainer(
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
            );
          },
          error: (error, stack) {
            return _buildSectionContainer(
              title: 'おすすめイベント',
              icon: Icons.recommend,
              children: [
                EmptyStateView(
                  icon: Icons.error_outline,
                  title: 'エラーが発生しました',
                  message: 'おすすめイベントの取得に失敗しました\nしばらくしてから再試行してください\n\nエラー詳細: $error',
                ),
              ],
            );
          },
        );
      },
      loading: () {
        return _buildSectionContainer(
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
        );
      },
      error: (error, stack) {
        return _buildSectionContainer(
          title: 'おすすめイベント',
          icon: Icons.recommend,
          children: [
            EmptyStateView(
              icon: Icons.error_outline,
              title: 'エラーが発生しました',
              message: 'ユーザー情報の取得に失敗しました\nしばらくしてから再試行してください\n\nエラー詳細: $error',
            ),
          ],
        );
      },
    );
  }








  /// おすすめイベント一覧画面へ遷移
  void _navigateToRecommendedEvents(List<GameEvent> recommendedEvents) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GenericEventListScreen(
          title: 'おすすめイベント',
          events: recommendedEvents,
          onEventTap: (event) => _showEventDetails(event),
          emptyTitle: 'おすすめイベントがありません',
          emptyMessage: 'お気に入りのゲームを登録すると\n関連するイベントが表示されます。',
          emptyIcon: Icons.recommend,
          searchHint: 'イベント名やゲーム名で検索...',
        ),
      ),
    );
  }

  /// お気に入りゲーム画面へ遷移
  void _navigateToFavoriteGames() {
    Navigator.pushNamed(context, '/favorite-games');
  }

  Future<void> _handleEventCreation() async {
    final authState = ref.watch(authStateProvider);
    authState.when(
      data: (user) {
        if (user == null) {
          // ゲストユーザーの場合はログインダイアログを表示
          AuthDialog.show(context);
        } else {
          // サインイン済みの場合はイベント作成画面に遷移
          widget.onNavigateToEventCreation?.call();
        }
      },
      loading: () {
        // ローディング中は何もしない
      },
      error: (error, stack) {
        // エラー時はログインダイアログを表示
        AuthDialog.show(context);
      },
    );
  }

  /// 運営者イベントセクション
  Widget _buildManagedEvents() {
    final currentUserAsync = ref.watch(currentUserDataProvider);
    final authState = ref.watch(authStateProvider);


    return currentUserAsync.when(
      data: (user) {

        if (user == null || !authState.hasValue || authState.value == null) {
          return const SizedBox.shrink(); // ログインしていない場合は非表示
        }

        final firebaseUid = authState.value!.uid;
        final managedEventsAsync = ref.watch(managedEventsProvider(firebaseUid));


        return managedEventsAsync.when(
          data: (events) {
            for (final event in events) {
            }

            if (events.isEmpty) {
              return const SizedBox.shrink(); // 運営イベントがない場合は非表示
            }

            return _buildSectionContainer(
              title: '運営中のイベント',
              icon: Icons.admin_panel_settings,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    TextButton(
                      onPressed: () => _navigateToManagedEvents(events),
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
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: (events.length > 3) ? 3 : events.length, // 最大3件まで表示
                    itemBuilder: (context, index) {
                      return Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: AppDimensions.spacingM),
                        child: CompactEventCard(
                          event: events[index],
                          onTap: () => _showEventDetails(events[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () {
            return _buildManagedEventsLoading();
          },
          error: (error, stack) {
            return const SizedBox.shrink(); // エラー時は非表示
          },
        );
      },
      loading: () {
        return const SizedBox.shrink();
      },
      error: (error, stack) {
        return const SizedBox.shrink();
      },
    );
  }

  /// 運営者イベントのローディング状態
  Widget _buildManagedEventsLoading() {
    return _buildSectionContainer(
      title: '運営中のイベント',
      icon: Icons.admin_panel_settings,
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

  /// 運営者イベント一覧画面への遷移
  void _navigateToManagedEvents(List<GameEvent> events) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManagedEventsScreen(
          events: events,
        ),
      ),
    );
  }
}

/// 運営者イベント一覧画面
class ManagedEventsScreen extends ConsumerWidget {
  final List<GameEvent> events;

  const ManagedEventsScreen({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('運営中のイベント'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ログインが必要です'));
          }

          final allManagedEventsAsync = ref.watch(allManagedEventsProvider(user.uid));

          return allManagedEventsAsync.when(
            data: (allEvents) {
              return GenericEventListScreen(
                title: '運営中のイベント',
                events: allEvents,
                onEventTap: (event) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                ),
                emptyTitle: '運営中のイベントはありません',
                emptyMessage: 'イベントを作成すると\nこちらに表示されます。',
                emptyIcon: Icons.admin_panel_settings,
                searchHint: 'イベント名やゲーム名で検索...',
                showCreateButton: true,
                onCreatePressed: () {
                  Navigator.of(context).pushNamed('/management');
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました\n$error',
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('認証エラーが発生しました')),
      ),
    );
  }
}