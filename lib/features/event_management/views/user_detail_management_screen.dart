import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/participant_profile_card.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/violation_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/violation_record_model.dart';
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
    extends ConsumerState<UserDetailManagementScreen> {
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
    _loadParticipantDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipantDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });


      // ParticipationServiceから申込を取得
      final applications = await ParticipationService.getEventApplications(widget.eventId).first;

      final participantData = <ParticipantProfileData>[];

      // 各申込に対してユーザー情報とゲームプロフィールを取得
      for (final application in applications) {
        try {

          // ユーザー情報を取得
          final userData = await _userRepository.getUserById(application.userId);
          if (userData == null) {
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
              skillLevel: data['skillLevel'] != null
                ? SkillLevel.values.firstWhere(
                    (e) => e.name == data['skillLevel'],
                    orElse: () => SkillLevel.beginner,
                  )
                : SkillLevel.beginner,
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
              skillLevel: SkillLevel.beginner,
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
            continue;
          }

          // 違反履歴を取得
          List<ViolationRecord>? violations;
          ViolationRiskLevel? riskLevel;

          try {
            final currentUser = ref.read(currentFirebaseUserProvider);
            if (currentUser != null) {
              final violationService = ref.read(violationServiceProvider);

              // このユーザーの違反履歴を取得（運営者が報告したもの）
              violations = await violationService.getUserViolationHistory(
                userId: application.userId,
                reporterId: currentUser.uid,
              );

              // リスクレベルを計算
              riskLevel = await violationService.calculateUserRiskLevel(
                userId: application.userId,
                reporterId: currentUser.uid,
              );
            }
          } catch (e) {
            // 違反履歴の取得エラーがあっても続行
            debugPrint('違反履歴の取得エラー: $e');
          }

          participantData.add(ParticipantProfileData(
            gameProfile: gameProfile,
            userData: userData,
            status: application.status, // 直接ParticipationStatusを使用
            violations: violations,
            riskLevel: riskLevel,
          ));

        } catch (e) {
          // 個別参加者の処理エラーはスキップ
          debugPrint('参加者データ取得エラー: $e');
        }
      }

      if (mounted) {
        setState(() {
          _participants = participantData;
          _filteredParticipants = participantData;
          _isLoading = false;
        });
      }

    } catch (e) {
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
                              Icons.person_search,
                              color: AppColors.accent,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            const Text(
                              'ユーザー詳細管理',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSearchBar(),
                      Expanded(
                        child: _buildParticipantListTab(),
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
          prefixIcon: Icon(Icons.search, color: AppColors.textDark),
          suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  _filterParticipants('');
                },
                icon: Icon(Icons.clear, color: AppColors.textDark),
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
                color: AppColors.textDark,
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
            violations: participant.violations,
            riskLevel: participant.riskLevel,
            onTap: () => _viewUserProfile(participant), // アバタータップ：ユーザープロフィール
            onUserTap: () => _viewGameProfile(participant), // カードタップ：ゲームプロフィール
          );
        },
      ),
    );
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
  final List<ViolationRecord>? violations; // 違反履歴
  final ViolationRiskLevel? riskLevel; // リスクレベル

  ParticipantProfileData({
    required this.gameProfile,
    required this.userData,
    required this.status,
    this.violations,
    this.riskLevel,
  });
}