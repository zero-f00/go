import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../shared/widgets/participant_profile_card.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/violation_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../features/game_profile/providers/game_profile_provider.dart';
import '../../../data/models/violation_record_model.dart';
import '../../../data/repositories/user_repository.dart';

/// 参加者用参加者一覧画面
class ParticipantListViewScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const ParticipantListViewScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<ParticipantListViewScreen> createState() =>
      _ParticipantListViewScreenState();
}

class _ParticipantListViewScreenState
    extends ConsumerState<ParticipantListViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserRepository _userRepository = UserRepository();

  List<ParticipantProfileData> _participants = [];
  List<ParticipantProfileData> _filteredParticipants = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _gameId; // イベントに紐づくゲームID

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

      // ゲームIDを取得
      await _loadGameId();

      // ParticipationServiceから申込を取得
      final applications = await ParticipationService.getEventApplications(widget.eventId).first;

      // 承認済みの申込のみフィルタリング
      final approvedApplications = applications
          .where((app) => app.status == ParticipationStatus.approved)
          .toList();

      final participantData = <ParticipantProfileData>[];

      // 各申込に対してユーザー情報とゲームプロフィールを取得
      for (final application in approvedApplications) {
        try {
          // ユーザー情報を取得
          final userData = await _userRepository.getUserById(application.userId);
          if (userData == null) {
            continue;
          }

          // Firestoreから実際のゲームプロフィールを取得
          GameProfile? gameProfile;
          if (_gameId != null) {
            try {
              final gameProfileService = ref.read(gameProfileServiceProvider);
              gameProfile = await gameProfileService.getGameProfile(application.userId, _gameId!);
            } catch (e) {
              // ゲームプロフィールの取得エラーを無視
            }
          }

          // プロフィールが取得できない場合は基本情報のみで作成
          if (gameProfile == null && application.gameUsername != null) {
            gameProfile = GameProfile(
              id: '',
              gameId: _gameId ?? '',
              userId: application.userId,
              gameUsername: application.gameUsername!,
              gameUserId: application.gameUserId ?? '',
              skillLevel: null,
              playStyles: [],
              rankOrLevel: '',
              activityTimes: [],
              useInGameVC: false,
              voiceChatDetails: '',
              achievements: '',
              notes: '',
              isFavorite: false,
              isPublic: true,
              clan: '',
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
          }

          participantData.add(ParticipantProfileData(
            gameProfile: gameProfile,
            userData: userData,
            status: application.status,
            violations: violations,
            riskLevel: riskLevel,
          ));
        } catch (e) {
          // 個別参加者の処理エラーはスキップ
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
    final currentUser = ref.watch(currentFirebaseUserProvider);

    if (currentUser == null) {
      return Scaffold(
        body: AppGradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: '参加者一覧',
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
                title: '参加者一覧',
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
                            Container(
                              width: AppDimensions.iconXL,
                              height: AppDimensions.iconXL,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              ),
                              child: Icon(
                                Icons.person_search,
                                color: AppColors.accent,
                                size: AppDimensions.iconM,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacingL),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '参加者詳細',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontSizeL,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: AppDimensions.spacingXS),
                                  Text(
                                    'イベント参加者のプロフィール情報を確認',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontSizeS,
                                      color: AppColors.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
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
    return EventInfoCard(
      eventName: widget.eventName,
      eventId: widget.eventId,
      iconData: Icons.people,
      trailing: Container(
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
              '参加者がいません',
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
            onTap: () => _viewGameProfile(participant), // アバタータップ：ゲームプロフィール
            onUserTap: () => _viewUserProfile(participant), // カードタップ：ユーザープロフィール
          );
        },
      ),
    );
  }

  /// ゲームプロフィール画面に遷移
  void _viewGameProfile(ParticipantProfileData participant) {
    Navigator.of(context).pushNamed(
      '/game_profile_view',
      arguments: {
        'profile': participant.gameProfile,
        'userData': participant.userData,
        'gameName': null,
        'gameIconUrl': null,
      },
    );
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
      // エラーがあっても処理は続行
    }
  }

  /// ゲーム専用プロフィール画面に遷移
  void _viewUserProfile(ParticipantProfileData participant) {
    if (_gameId == null) {
      // ゲームIDが取得できていない場合は汎用プロフィール画面に遷移
      Navigator.of(context).pushNamed(
        '/user_profile',
        arguments: participant.userData.userId,
      );
      return;
    }

    try {
      // 既存のGameProfileをそのまま使用（ユーザーが設定した全ての詳細データを保持）
      // ゲームプロフィール画面に遷移
      Navigator.pushNamed(
        context,
        '/game_profile_view',
        arguments: {
          'profile': participant.gameProfile,
          'userData': participant.userData,
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
}

/// 参加者プロフィールデータ
class ParticipantProfileData {
  final GameProfile gameProfile;
  final UserData userData;
  final ParticipationStatus status;
  final List<ViolationRecord>? violations;
  final ViolationRiskLevel? riskLevel;

  ParticipantProfileData({
    required this.gameProfile,
    required this.userData,
    required this.status,
    this.violations,
    this.riskLevel,
  });
}