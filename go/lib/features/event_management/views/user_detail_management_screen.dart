import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/participant_profile_card.dart';
import '../../../shared/services/participation_service.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

/// ユーザー詳細管理画面
class UserDetailManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const UserDetailManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<UserDetailManagementScreen> createState() =>
      _UserDetailManagementScreenState();
}

class _UserDetailManagementScreenState
    extends ConsumerState<UserDetailManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // リポジトリ
  final UserRepository _userRepository = UserRepository();

  // データ
  List<ParticipantProfileData> _participants = [];
  List<ParticipantProfileData> _filteredParticipants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadParticipantDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipantDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔄 UserDetailManagement: Loading applications for event: ${widget.eventId}');

      // ParticipationServiceから申込を取得
      final applications = await ParticipationService.getEventApplications(widget.eventId).first;
      print('✅ UserDetailManagement: Found ${applications.length} applications');

      final participantData = <ParticipantProfileData>[];

      // 各申込に対してユーザー情報とゲームプロフィールを取得
      for (final application in applications) {
        try {
          print('🔄 UserDetailManagement: Processing application ${application.id}');
          print('   userId: ${application.userId}');
          print('   status: ${application.status.name}');

          // ユーザー情報を取得
          final userData = await _userRepository.getUserById(application.userId);
          if (userData == null) {
            print('⚠️ UserDetailManagement: User not found: ${application.userId}');
            continue;
          }

          // ゲームプロフィールを取得（gameProfileDataから）
          GameProfile? gameProfile;
          if (application.gameProfileData != null) {
            // Map<String, dynamic>からGameProfileを作成
            final data = application.gameProfileData!;
            gameProfile = GameProfile(
              id: data['id'] as String? ?? '',
              gameId: data['gameId'] as String? ?? '',
              userId: application.userId,
              gameUsername: data['gameUsername'] as String? ?? application.gameUsername ?? '',
              gameUserId: data['gameUserId'] as String? ?? application.gameUserId ?? '',
              experience: data['experience'] != null
                ? GameExperience.values.firstWhere(
                    (e) => e.name == data['experience'],
                    orElse: () => GameExperience.beginner,
                  )
                : GameExperience.beginner,
              playStyles: (data['playStyles'] as List?)
                      ?.map((e) => PlayStyle.values.firstWhere(
                            (style) => style.name == e,
                            orElse: () => PlayStyle.casual,
                          ))
                      .toList() ??
                  [],
              rankOrLevel: data['rankOrLevel'] as String? ?? '',
              activityTimes: (data['activityTimes'] as List?)
                      ?.map((e) => ActivityTime.values.firstWhere(
                            (time) => time.name == e,
                            orElse: () => ActivityTime.evening,
                          ))
                      .toList() ??
                  [],
              useInGameVC: data['useInGameVC'] as bool? ?? false,
              voiceChatDetails: data['voiceChatDetails'] as String? ?? '',
              achievements: data['achievements'] as String? ?? '',
              notes: data['notes'] as String? ?? '',
              isFavorite: data['isFavorite'] as bool? ?? false,
              isPublic: data['isPublic'] as bool? ?? true,
              createdAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
              updatedAt: data['updatedAt'] != null
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
            );
          } else if (application.gameUsername != null) {
            // 基本的なゲームプロフィールを作成
            gameProfile = GameProfile(
              id: '',
              gameId: '', // デフォルトのゲームID
              userId: application.userId,
              gameUsername: application.gameUsername!,
              gameUserId: application.gameUserId ?? '',
              experience: GameExperience.beginner,
              playStyles: [],
              rankOrLevel: '',
              activityTimes: [],
              useInGameVC: false,
              voiceChatDetails: '',
              achievements: '',
              notes: '',
              isFavorite: false,
              isPublic: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }

          if (gameProfile == null) {
            print('⚠️ UserDetailManagement: Game profile not available for user: ${application.userId}');
            continue;
          }

          participantData.add(ParticipantProfileData(
            gameProfile: gameProfile,
            userData: userData,
            status: application.status, // 直接ParticipationStatusを使用
          ));

          print('✅ UserDetailManagement: Successfully processed ${userData.displayName}');
        } catch (e) {
          print('❌ UserDetailManagement: Error processing application ${application.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _participants = participantData;
          _filteredParticipants = participantData;
          _isLoading = false;
        });
      }

      print('✅ UserDetailManagement: Loaded ${participantData.length} participant profiles');
    } catch (e) {
      print('❌ UserDetailManagement: Error loading participant details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '参加者情報の読み込みに失敗しました: $e';
        });
      }
    }
  }


  void _filterParticipants(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredParticipants = _participants;
      } else {
        _filteredParticipants = _participants.where((participant) =>
          participant.userData.username.toLowerCase().contains(query.toLowerCase()) ||
          participant.gameProfile.gameUsername.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
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
                title: 'ユーザー詳細管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              _buildEventInfo(),
              _buildSearchBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildParticipantListTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// イベント情報
  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.people,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              widget.eventName,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: AppDimensions.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              '${_participants.length}名',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 検索バー
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: TextField(
        controller: _searchController,
        onChanged: _filterParticipants,
        decoration: InputDecoration(
          hintText: 'ユーザー名やゲームIDで検索...',
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _filterParticipants('');
                },
                icon: Icon(Icons.clear, color: AppColors.textSecondary),
              )
            : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.cardBackground,
        ),
      ),
    );
  }

  /// タブバー
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppDimensions.fontSizeM,
        ),
        tabs: const [
          Tab(text: '参加者一覧'),
          Tab(text: '分析'),
        ],
      ),
    );
  }

  /// 参加者一覧タブ
  Widget _buildParticipantListTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            ElevatedButton(
              onPressed: _loadParticipantDetails,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_filteredParticipants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'まだ参加者はいません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: ListView.builder(
        itemCount: _filteredParticipants.length,
        itemBuilder: (context, index) {
          final participant = _filteredParticipants[index];
          return ParticipantProfileCard(
            profile: participant.gameProfile,
            userData: participant.userData,
            status: participant.status,
            onTap: () => _viewUserProfile(participant), // アバタータップ：ユーザープロフィール
            onUserTap: () => _viewGameProfile(participant), // カードタップ：ゲームプロフィール
          );
        },
      ),
    );
  }



  /// 分析タブ
  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalParticipants = _participants.length;
    final approvedCount = _participants.where((p) => p.status == ParticipationStatus.approved).length;
    final pendingCount = _participants.where((p) => p.status == ParticipationStatus.pending).length;
    final experiencedUsers = _participants.where((p) =>
      p.gameProfile.experience == GameExperience.advanced ||
      p.gameProfile.experience == GameExperience.expert
    ).length;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          _buildAnalyticsCard(
            '総申込者数',
            '$totalParticipants名',
            Icons.people,
            AppColors.info,
          ),
          _buildAnalyticsCard(
            '承認済み',
            '$approvedCount名',
            Icons.check_circle,
            AppColors.success,
          ),
          _buildAnalyticsCard(
            '承認待ち',
            '$pendingCount名',
            Icons.access_time,
            AppColors.warning,
          ),
          _buildAnalyticsCard(
            '上級者数',
            '$experiencedUsers名',
            Icons.workspace_premium,
            AppColors.accent,
          ),
        ],
      ),
    );
  }

  /// 分析カード
  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXL,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ヘルパーメソッド
  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    if (days < 30) {
      return '${days}日';
    } else if (days < 365) {
      return '${(days / 30).floor()}ヶ月';
    } else {
      return '${(days / 365).floor()}年';
    }
  }

  /// アクションメソッド
  void _viewGameProfile(ParticipantProfileData participant) {
    // ゲームプロフィール閲覧画面に遷移
    Navigator.of(context).pushNamed(
      '/game_profile_view',
      arguments: {
        'profile': participant.gameProfile,
        'userData': participant.userData,
        'gameName': null, // イベントから取得可能であれば設定
        'gameIconUrl': null,
      },
    );
  }

  void _viewUserProfile(ParticipantProfileData participant) {
    // ユーザープロフィール詳細画面に遷移
    Navigator.of(context).pushNamed(
      '/user_profile',
      arguments: participant.userData.userId,
    );
  }
}

/// 参加者プロフィールデータ
class ParticipantProfileData {
  final GameProfile gameProfile;
  final UserData userData;
  final ParticipationStatus status; // participation_service.dartのParticipationStatus

  ParticipantProfileData({
    required this.gameProfile,
    required this.userData,
    required this.status,
  });
}