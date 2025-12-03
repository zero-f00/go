import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar_from_id.dart';
import '../../../data/models/event_group_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/game_profile_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 参加者用グループ閲覧画面
class ParticipantGroupViewScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const ParticipantGroupViewScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<ParticipantGroupViewScreen> createState() =>
      _ParticipantGroupViewScreenState();
}

class _ParticipantGroupViewScreenState
    extends ConsumerState<ParticipantGroupViewScreen> with SingleTickerProviderStateMixin {
  final UserRepository _userRepository = UserRepository();
  Map<String, UserData> _userDataCache = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _commonDescription = ''; // 全体連絡事項
  String? _gameId; // イベントに紐づくゲームID
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 全体連絡事項を取得
      await _loadCommonDescription();

      // ゲームIDを取得
      await _loadGameId();

      // 少し遅延させてローディング状態を表示
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      setState(() {
        _errorMessage = 'データの読み込みに失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 全体連絡事項を取得
  Future<void> _loadCommonDescription() async {
    try {
      final commonDescDoc = await FirebaseFirestore.instance
          .collection('event_group_settings')
          .doc(widget.eventId)
          .get();

      String commonDesc = '';
      if (commonDescDoc.exists) {
        commonDesc = commonDescDoc.data()?['commonDescription'] ?? '';
      }

      setState(() {
        _commonDescription = commonDesc;
      });
    } catch (e) {
      print('Error loading common description: $e');
      // エラーがあっても処理は続行
    }
  }

  /// ゲームIDを取得
  Future<void> _loadGameId() async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      String? gameId;
      if (eventDoc.exists) {
        gameId = eventDoc.data()?['gameId'] as String?;
      }

      setState(() {
        _gameId = gameId;
      });
    } catch (e) {
      print('Error loading game ID: $e');
      // エラーがあっても処理は続行
    }
  }

  /// ユーザーデータを取得してキャッシュ
  Future<UserData?> _getUserData(String userId) async {
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId];
    }

    try {
      final userData = await _userRepository.getUserById(userId);
      if (userData != null) {
        _userDataCache[userId] = userData;
      }
      return userData;
    } catch (e) {
      print('Error getting user data for $userId: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentFirebaseUserProvider);

    if (currentUser == null) {
      return Scaffold(
        body: AppGradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: 'グループ情報',
                  showBackButton: true,
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'ログインが必要です',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'グループ情報',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              _buildEventInfo(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(AppDimensions.spacingL),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingL),
                        child: Row(
                          children: [
                            Icon(
                              Icons.group,
                              color: AppColors.accent,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            const Text(
                              'グループ情報',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textDark,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppDimensions.fontSizeM,
                          ),
                          tabs: const [
                            Tab(text: '自分のグループ'),
                            Tab(text: '全グループ'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMyGroupContent(currentUser.uid),
                                _buildAllGroupsContent(),
                              ],
                            ),
                      ),
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
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_esports,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.eventName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'チーム戦イベント',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyGroupContent(String userId) {
    return StreamBuilder<EventGroup?>(
      stream: GroupService.getUserGroup(widget.eventId, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('データの取得に失敗しました: ${snapshot.error}');
        }

        final group = snapshot.data;
        if (group == null) {
          return _buildNoGroupState();
        }

        return _buildGroupDetails(group, showSensitiveInfo: true);
      },
    );
  }

  Widget _buildAllGroupsContent() {
    return StreamBuilder<List<EventGroup>>(
      stream: GroupService.getEventGroups(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorState('データの取得に失敗しました: ${snapshot.error}');
        }

        final groups = snapshot.data ?? [];
        if (groups.isEmpty) {
          return _buildNoGroupsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          itemCount: groups.length + (_commonDescription.isNotEmpty ? 1 : 0), // 全体連絡事項分を追加
          itemBuilder: (context, index) {
            // 全体連絡事項を最初に表示
            if (_commonDescription.isNotEmpty && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingL),
                child: _buildCommonDescriptionSection(),
              );
            }

            // グループデータのインデックスを調整
            final groupIndex = _commonDescription.isNotEmpty ? index - 1 : index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              child: _buildGroupCard(groups[groupIndex], showSensitiveInfo: false),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            'エラーが発生しました',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            message,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoGroupState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            'グループが割り当てられていません',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            '運営からの案内をお待ちください',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoGroupsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            'グループが作成されていません',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            '運営からの案内をお待ちください',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupDetails(EventGroup group, {bool showSensitiveInfo = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 全体連絡事項セクション（最上位に表示）
          if (_commonDescription.isNotEmpty) ...[
            _buildCommonDescriptionSection(),
            const SizedBox(height: AppDimensions.spacingL),
          ],
          _buildGroupHeader(group),
          if (showSensitiveInfo) ...[
            const SizedBox(height: AppDimensions.spacingM),
            if (group.description.isNotEmpty) _buildDescriptionSection(group),
            if (group.announcements.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingM),
              _buildAnnouncementsSection(group),
            ],
          ],
          const SizedBox(height: AppDimensions.spacingM),
          _buildMembersSection(group),
        ],
      ),
    );
  }

  Widget _buildGroupCard(EventGroup group, {bool showSensitiveInfo = false}) {
    return InkWell(
      onTap: () => _showGroupMembersDialog(group),
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.group,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '${group.participants.length}名のメンバー',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // メンバーアバター表示
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: group.participants.length > 5 ? 5 : group.participants.length,
              itemBuilder: (context, index) {
                if (index == 4 && group.participants.length > 5) {
                  return Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: AppDimensions.spacingXS),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '+${group.participants.length - 4}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeXS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.only(right: AppDimensions.spacingXS),
                  child: UserAvatarFromId(
                    userId: group.participants[index],
                    size: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    iconColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),
          // 連絡事項表示（全グループ一覧でも表示）
          if (group.announcements.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.groups,
                    color: AppColors.warning,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'グループ連絡',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          group.announcements,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildGroupHeader(EventGroup group) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              Icons.group,
              color: AppColors.accent,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeXL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  '${group.participants.length}名のグループ',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(EventGroup group) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.info,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'グループ説明',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            group.description,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection(EventGroup group) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups,
                color: AppColors.warning,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'グループ連絡',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            group.announcements,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(EventGroup group) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppColors.accent,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'メンバー (${group.participants.length}名)',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ...group.participants.map((userId) => _buildMemberRow(userId)),
        ],
      ),
    );
  }

  Widget _buildMemberRow(String userId) {
    return GestureDetector(
      onTap: () => _navigateToUserProfile(userId),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
        padding: const EdgeInsets.all(AppDimensions.spacingS),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.border),
        ),
        child: FutureBuilder<UserData?>(
          future: _getUserData(userId),
          builder: (context, snapshot) {
            final userData = snapshot.data;
            return Row(
              children: [
                UserAvatarFromId(
                  userId: userId,
                  size: 32,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  iconColor: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData?.displayName ?? 'ユーザー',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (userData?.bio?.isNotEmpty == true) ...[
                        Text(
                          userData!.bio!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconS,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ゲーム専用プロフィール画面に遷移
  Future<void> _navigateToUserProfile(String userId) async {
    if (_gameId == null) {
      // ゲームIDが取得できていない場合は汎用プロフィール画面に遷移
      Navigator.of(context).pushNamed(
        '/user_profile',
        arguments: userId,
      );
      return;
    }

    try {
      // ユーザーデータを取得
      final userData = await _getUserData(userId);
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー情報が見つかりません')),
        );
        return;
      }

      // GameProfileオブジェクトを作成（運営側と同じロジック）
      final gameProfile = GameProfile(
        userId: userId,
        gameId: _gameId!,
        gameUsername: userData.username,
        gameUserId: userData.username,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rankOrLevel: '', // 基本情報のみ
        achievements: '',
        notes: '',
      );

      // ゲームプロフィール画面に遷移
      Navigator.pushNamed(
        context,
        '/game_profile_view',
        arguments: {
          'profile': gameProfile,
          'userData': userData,
          'gameName': null,
          'gameIconUrl': null,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ゲームプロフィールの表示に失敗しました: $e')),
      );
    }
  }

  /// 全体連絡事項セクション
  Widget _buildCommonDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign,
                color: AppColors.primary,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '全体連絡事項',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            _commonDescription,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// グループメンバー表示ダイアログを表示
  void _showGroupMembersDialog(EventGroup group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: AppColors.accent,
                      size: AppDimensions.iconL,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),

                Text(
                  '${group.participants.length}名のメンバー',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // メンバーリスト
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: group.participants.length,
                    itemBuilder: (context, index) {
                      final userId = group.participants[index];
                      return _buildMemberItem(userId);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// メンバーアイテムを構築
  Widget _buildMemberItem(String userId) {
    return FutureBuilder<UserData?>(
      future: _getUserData(userId),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final displayName = userData?.displayName ?? 'ユーザー$userId';

        return InkWell(
          onTap: () {
            Navigator.of(context).pop(); // ダイアログを閉じる
            _navigateToUserProfile(userId); // ゲームプロフィールに遷移
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                UserAvatarFromId(
                  userId: userId,
                  size: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  iconColor: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (userData?.bio?.isNotEmpty == true) ...[
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          userData!.bio!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: AppDimensions.iconS,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}