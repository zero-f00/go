import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../data/models/match_result_model.dart';
import '../../../shared/services/group_management_service.dart';
import '../../../shared/widgets/user_avatar_from_id.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/image_upload_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// スコア種別データクラス
class ScoreType {
  final String id;
  final String name;
  final String unit;
  final ScoreTargetType targetType;

  ScoreType({
    required this.id,
    required this.name,
    required this.unit,
    required this.targetType,
  });
}

/// スコア対象タイプ
enum ScoreTargetType {
  team,       // チーム/グループ単位
  individual, // 個人単位
}

/// 試合結果入力画面
class MatchResultInputScreen extends ConsumerStatefulWidget {
  final MatchResult match;
  final Function(MatchResult) onResultSubmitted;

  const MatchResultInputScreen({
    super.key,
    required this.match,
    required this.onResultSubmitted,
  });

  @override
  ConsumerState<MatchResultInputScreen> createState() =>
      _MatchResultInputScreenState();
}

class _MatchResultInputScreenState
    extends ConsumerState<MatchResultInputScreen> {
  final _formKey = GlobalKey<FormState>();

  Map<String, TextEditingController> _teamScoreControllers = {};
  Map<String, TextEditingController> _individualScoreControllers = {};
  Map<String, TextEditingController> _rankingControllers = {};

  // 運営メモ用コントローラー
  final _adminPublicNotesController = TextEditingController();
  final _adminPrivateNotesController = TextEditingController();

  bool _isLoading = false;
  Map<String, String> _participantNames = {}; // participantId -> 表示名
  final GroupManagementService _groupService = GroupManagementService();

  // ドラッグ&ドロップ用の順位リスト
  List<String> _rankedParticipants = [];

  // 動的スコア種別管理
  List<ScoreType> _scoreTypes = [];
  Map<String, Map<String, TextEditingController>> _dynamicScoreControllers = {};

  // 個人スコア管理（チーム戦時）
  Map<String, List<String>> _teamMembers = {}; // teamId -> [memberId1, memberId2...]
  Map<String, String> _memberNames = {}; // memberId -> 表示名

  // エビデンス画像管理
  List<File> _selectedEvidenceImages = [];
  List<String> _existingEvidenceImages = [];
  List<String> _deletedEvidenceImages = []; // 削除対象の既存画像URL
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeRanking();
    _initializeScoreTypes();
    _initializeControllers();
    _loadParticipantNames();
    _initializeEvidenceImages();
    _initializeAdminNotes();
  }

  /// エビデンス画像の初期化
  void _initializeEvidenceImages() {
    _existingEvidenceImages = List.from(widget.match.evidenceImages);
  }

  /// 運営メモの初期化
  void _initializeAdminNotes() {
    _adminPublicNotesController.text = widget.match.adminPublicNotes ?? '';
    _adminPrivateNotesController.text = widget.match.adminPrivateNotes ?? '';
  }

  /// 順位を初期化（編集時は勝者情報から推定）
  void _initializeRanking() {
    _rankedParticipants = List.from(widget.match.participants);

    // 編集時：勝者を1位に移動
    if (widget.match.winner != null) {
      final winner = widget.match.winner!;
      if (_rankedParticipants.contains(winner)) {
        _rankedParticipants.remove(winner);
        _rankedParticipants.insert(0, winner);
      }
    }
  }

  /// スコア種別を初期化
  void _initializeScoreTypes() {
    _scoreTypes = [];

    // 編集時で既存のスコアデータがある場合はデフォルトスコア種別を作成
    if (widget.match.scores.isNotEmpty) {
      if (widget.match.isTeamMatch) {
        // チーム戦の場合はチーム対象のスコア
        _scoreTypes.add(ScoreType(
          id: 'default_score',
          name: 'スコア',
          unit: '点',
          targetType: ScoreTargetType.team,
        ));
      } else {
        // 個人戦の場合は個人対象のスコア（scoresに保存されているが個人対象として扱う）
        _scoreTypes.add(ScoreType(
          id: 'default_individual_score',
          name: 'スコア',
          unit: '点',
          targetType: ScoreTargetType.individual,
        ));
      }
    }

    // 編集時で既存の個人スコアデータがある場合は個人スコア種別を作成（チーム戦のみ）
    if (widget.match.isTeamMatch &&
        widget.match.individualScores != null &&
        widget.match.individualScores!.isNotEmpty) {
      _scoreTypes.add(ScoreType(
        id: 'default_individual_score',
        name: '個人スコア',
        unit: '点',
        targetType: ScoreTargetType.individual,
      ));
    }
  }

  /// 参加者名を読み込み
  Future<void> _loadParticipantNames() async {
    if (widget.match.isTeamMatch) {
      // チーム戦の場合はグループ名を取得
      final groupNames = await _groupService.getGroupNames(widget.match.participants);
      setState(() {
        _participantNames = groupNames;
        _updateRankingControllers(); // 初期順位も設定
      });
    } else {
      // 個人戦の場合は承認済み参加者のユーザー名を取得
      _loadIndividualParticipants();
    }
  }

  /// チームメンバーを読み込み
  Future<void> _loadTeamMembers() async {
    if (!widget.match.isTeamMatch) return;

    try {
      // チーム戦の場合は実際のチームメンバーを取得
      final allMemberIds = <String>[];

      for (final teamId in widget.match.participants) {
        final members = await _groupService.getGroupMembers(teamId);
        _teamMembers[teamId] = members;
        allMemberIds.addAll(members);
      }

      // 承認済み参加者の表示名とゲーム内ユーザー名を一括取得
      if (allMemberIds.isNotEmpty) {
        final participantInfo = await _groupService.getApprovedParticipantNames(
          widget.match.eventId,
          allMemberIds
        );

        // ゲーム内ユーザー名を優先的に使用し、なければ表示名を使用
        for (final entry in participantInfo.entries) {
          final userId = entry.key;
          final info = entry.value;
          _memberNames[userId] = info['gameUsername'] ?? info['displayName'] ?? 'ユーザー';
        }
      }
    } catch (e) {
      // エラーが発生した場合はダミーデータを使用
      // チームメンバー取得エラー
      for (int i = 0; i < widget.match.participants.length; i++) {
        final teamId = widget.match.participants[i];
        _teamMembers[teamId] = ['${teamId}_user1', '${teamId}_user2'];
        _memberNames['${teamId}_user1'] = 'ユーザー1';
        _memberNames['${teamId}_user2'] = 'ユーザー2';
      }
    }

    // スコアコントローラーを再初期化
    setState(() {
      _initializeScoreControllers();
    });
  }

  /// 個人戦の参加者情報を読み込み
  Future<void> _loadIndividualParticipants() async {
    try {
      // 承認済み参加者の表示名とゲーム内ユーザー名を一括取得
      final participantInfo = await _groupService.getApprovedParticipantNames(
        widget.match.eventId,
        widget.match.participants
      );

      setState(() {
        // ゲーム内ユーザー名を優先的に使用し、なければ表示名を使用
        _participantNames = participantInfo.map((userId, info) => MapEntry(
          userId,
          info['gameUsername'] ?? info['displayName'] ?? 'ユーザー'
        ));
        _updateRankingControllers(); // 初期順位も設定
      });
    } catch (e) {
      // エラーが発生した場合はダミーデータを使用
      // 個人戦参加者取得エラー
      setState(() {
        for (int i = 0; i < widget.match.participants.length; i++) {
          final participantId = widget.match.participants[i];
          _participantNames[participantId] = 'ユーザー${i + 1}';
        }
        _updateRankingControllers(); // 初期順位も設定
      });
    }
  }


  void _initializeControllers() {
    // チーム戦の場合は実際のメンバーを設定
    if (widget.match.isTeamMatch) {
      _loadTeamMembers();
    }

    // 動的スコアコントローラーの初期化
    _initializeScoreControllers();

    // レガシー用チーム/個人スコアコントローラー（互換性のため維持）
    for (final participantId in widget.match.participants) {
      _teamScoreControllers[participantId] = TextEditingController(
        text: widget.match.scores[participantId]?.toString() ?? '',
      );

      // 順位コントローラー（既存の勝者情報から推定）
      String rankText = '';
      if (widget.match.winner == participantId) {
        rankText = '1';
      }
      _rankingControllers[participantId] = TextEditingController(text: rankText);
    }

    // チーム戦の場合は個人スコアも初期化（レガシー）
    if (widget.match.isTeamMatch) {
      for (final teamId in widget.match.participants) {
        final members = _teamMembers[teamId] ?? [];
        for (final userId in members) {
          _individualScoreControllers[userId] = TextEditingController(
            text: widget.match.individualScores?[userId]?.toString() ?? '',
          );
        }
      }
    }
  }

  /// スコアコントローラーを初期化
  void _initializeScoreControllers() {
    for (final scoreType in _scoreTypes) {
      _dynamicScoreControllers[scoreType.id] = {};

      if (scoreType.targetType == ScoreTargetType.team) {
        // チーム/グループ単位の場合
        for (final participantId in widget.match.participants) {
          // 編集時は既存のスコア値を設定
          String existingScore = '';
          if (scoreType.id == 'default_score' && widget.match.scores.containsKey(participantId)) {
            existingScore = widget.match.scores[participantId]!.toString();
          }
          _dynamicScoreControllers[scoreType.id]![participantId] = TextEditingController(text: existingScore);
        }
      } else {
        // 個人単位の場合
        if (widget.match.isTeamMatch) {
          // チーム戦では各チームのメンバーに対してコントローラーを作成
          for (final teamId in widget.match.participants) {
            final members = _teamMembers[teamId] ?? [];
            for (final memberId in members) {
              // 編集時は既存の個人スコア値を設定
              String existingScore = '';
              if (scoreType.id == 'default_individual_score' &&
                  widget.match.individualScores != null &&
                  widget.match.individualScores!.containsKey(memberId)) {
                existingScore = widget.match.individualScores![memberId]!.toString();
              }
              _dynamicScoreControllers[scoreType.id]![memberId] = TextEditingController(text: existingScore);
            }
          }
        } else {
          // 個人戦では参加者に対してコントローラーを作成
          for (final participantId in widget.match.participants) {
            // 編集時は既存のスコア値を設定（個人戦での個人スコア種別）
            String existingScore = '';
            if (scoreType.id == 'default_individual_score' && widget.match.scores.containsKey(participantId)) {
              existingScore = widget.match.scores[participantId]!.toString();
            }
            _dynamicScoreControllers[scoreType.id]![participantId] = TextEditingController(text: existingScore);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    // 動的スコアコントローラーを破棄
    for (final scoreTypeControllers in _dynamicScoreControllers.values) {
      for (final controller in scoreTypeControllers.values) {
        controller.dispose();
      }
    }

    for (final controller in _teamScoreControllers.values) {
      controller.dispose();
    }
    for (final controller in _individualScoreControllers.values) {
      controller.dispose();
    }
    for (final controller in _rankingControllers.values) {
      controller.dispose();
    }
    _adminPublicNotesController.dispose();
    _adminPrivateNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppHeader(
                  title: widget.match.isCompleted ? '試合結果編集' : '試合結果入力',
                  showBackButton: true,
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMatchInfo(),
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildRankingSection(),
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildScoreSection(),
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildEvidenceImageSection(),
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildAdminNotesSection(),
                        const SizedBox(height: AppDimensions.spacingXL),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 試合情報カード
  Widget _buildMatchInfo() {
    return Container(
      width: double.infinity,
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
                Icons.sports_esports,
                color: AppColors.accent,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.match.matchName,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: widget.match.isTeamMatch
                            ? AppColors.info.withValues(alpha: 0.1)
                            : AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        widget.match.isTeamMatch ? 'チーム戦' : '個人戦',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: widget.match.isTeamMatch
                              ? AppColors.info
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// 順位付けセクション
  Widget _buildRankingSection() {
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
                Icons.emoji_events,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '順位付け',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Text(
            'カードをドラッグ&ドロップして順位を決定してください',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.drag_indicator,
                  color: AppColors.info,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Text(
                  '上が1位、下が最下位',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rankedParticipants.length,
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final String participant = _rankedParticipants.removeAt(oldIndex);
                _rankedParticipants.insert(newIndex, participant);
                _updateRankingControllers();
              });
            },
            itemBuilder: (context, index) {
              final participantId = _rankedParticipants[index];
              final rank = index + 1;

              return Container(
                key: Key(participantId),
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                child: _buildRankingCard(participantId, rank),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 順位カード
  Widget _buildRankingCard(String participantId, int rank) {
    Color rankColor;
    IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = AppColors.warning;
        rankIcon = Icons.looks_one;
        break;
      case 2:
        rankColor = AppColors.textSecondary;
        rankIcon = Icons.looks_two;
        break;
      case 3:
        rankColor = AppColors.secondary;
        rankIcon = Icons.looks_3;
        break;
      default:
        rankColor = AppColors.textLight;
        rankIcon = Icons.radio_button_unchecked;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showUserProfileModal(participantId),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: rank <= 3 ? rankColor.withValues(alpha: 0.3) : AppColors.border,
          width: rank <= 3 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ドラッグハンドル
          Icon(
            Icons.drag_handle,
            color: AppColors.textLight,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),

          // 順位アイコン
          Container(
            width: AppDimensions.iconL + 4,
            height: AppDimensions.iconL + 4,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              rankIcon,
              color: rankColor,
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),

          // ユーザーアイコン
          UserAvatarFromId(
            userId: participantId,
            size: 40,
            backgroundColor: AppColors.overlayLight,
            iconColor: AppColors.textSecondary,
            borderColor: AppColors.border,
            borderWidth: 1,
          ),
          const SizedBox(width: AppDimensions.spacingM),

          // 参加者名
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _participantNames[participantId] ?? participantId,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '$rank位', // TODO: イベント設定から順位単位を取得
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: rankColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 優勝カップアイコン（1位のみ）
          if (rank == 1) ...[
            Icon(
              Icons.emoji_events,
              color: AppColors.warning,
              size: AppDimensions.iconM,
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }

  /// ユーザープロフィールモーダルを表示
  void _showUserProfileModal(String participantId) {
    final userName = _participantNames[participantId] ?? participantId;

    UserActionModal.show(
      context: context,
      eventId: widget.match.eventId,
      eventName: widget.match.matchName,
      userId: participantId,
      userName: userName,
    );
  }

  /// ランキングコントローラーを更新
  void _updateRankingControllers() {
    for (int i = 0; i < _rankedParticipants.length; i++) {
      final participantId = _rankedParticipants[i];
      final rank = i + 1;
      if (_rankingControllers.containsKey(participantId)) {
        _rankingControllers[participantId]!.text = rank.toString();
      }
    }
  }

  /// スコア種別追加ダイアログを表示
  void _showAddScoreTypeDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    ScoreTargetType selectedTargetType = ScoreTargetType.team;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final screenHeight = MediaQuery.of(context).size.height;
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final maxDialogHeight = screenHeight - keyboardHeight - 100;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: maxDialogHeight,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 固定ヘッダー
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusM),
                        topRight: Radius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'スコア種別を追加',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeL,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // スクロール可能なコンテンツ
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'スコア名',
                              hintText: 'キル数、ポイント、ダメージなど',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: '単位',
                              hintText: 'キル、ポイント、HPなど',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          const Text(
                            '対象',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          RadioListTile<ScoreTargetType>(
                            title: const Text('グループ'),
                            subtitle: const Text('チーム単位のスコア'),
                            value: ScoreTargetType.team,
                            groupValue: selectedTargetType,
                            onChanged: (value) {
                              setState(() {
                                selectedTargetType = value!;
                              });
                            },
                            dense: true,
                          ),
                          RadioListTile<ScoreTargetType>(
                            title: const Text('個人'),
                            subtitle: const Text('個人単位のスコア'),
                            value: ScoreTargetType.individual,
                            groupValue: selectedTargetType,
                            onChanged: (value) {
                              setState(() {
                                selectedTargetType = value!;
                              });
                            },
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 固定ボタンエリア
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border(
                        top: BorderSide(color: AppColors.border),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(AppDimensions.radiusM),
                        bottomRight: Radius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton.secondary(
                            text: 'キャンセル',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Expanded(
                          child: AppButton.primary(
                            text: '追加',
                            onPressed: () {
                              if (nameController.text.trim().isNotEmpty &&
                                  unitController.text.trim().isNotEmpty) {
                                _addScoreType(
                                  nameController.text.trim(),
                                  unitController.text.trim(),
                                  selectedTargetType,
                                );
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// スコア種別を追加
  void _addScoreType(String name, String unit, ScoreTargetType targetType) {
    final id = 'score_${DateTime.now().millisecondsSinceEpoch}';
    final scoreType = ScoreType(
      id: id,
      name: name,
      unit: unit,
      targetType: targetType,
    );

    setState(() {
      _scoreTypes.add(scoreType);
      _dynamicScoreControllers[id] = {};

      if (targetType == ScoreTargetType.team) {
        // チーム/グループ単位の場合
        for (final participantId in widget.match.participants) {
          _dynamicScoreControllers[id]![participantId] = TextEditingController();
        }
      } else {
        // 個人単位の場合
        if (widget.match.isTeamMatch) {
          // チーム戦では各チームのメンバーに対してコントローラーを作成
          for (final teamId in widget.match.participants) {
            final members = _teamMembers[teamId] ?? [];
            for (final memberId in members) {
              _dynamicScoreControllers[id]![memberId] = TextEditingController();
            }
          }
        } else {
          // 個人戦では参加者に対してコントローラーを作成
          for (final participantId in widget.match.participants) {
            _dynamicScoreControllers[id]![participantId] = TextEditingController();
          }
        }
      }
    });
  }

  /// スコア種別を削除
  void _removeScoreType(String scoreTypeId) {
    setState(() {
      // コントローラーを破棄
      final controllers = _dynamicScoreControllers[scoreTypeId];
      if (controllers != null) {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      }
      _dynamicScoreControllers.remove(scoreTypeId);

      // スコア種別を削除
      _scoreTypes.removeWhere((scoreType) => scoreType.id == scoreTypeId);
    });
  }

  /// スコア入力セクション
  Widget _buildScoreSection() {
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
                Icons.score,
                color: AppColors.secondary,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'スコア入力',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  '任意',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _showAddScoreTypeDialog,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.accent,
                tooltip: 'スコア種別を追加',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Text(
            'スコア種別を追加して複数の評価軸で記録できます',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          if (_scoreTypes.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXL),
              child: Column(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: AppDimensions.iconXL,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  const Text(
                    'スコア種別を追加してください',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  const Text(
                    'キル数、ポイント、ダメージなど\nお好みの評価軸を設定できます',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._scoreTypes.map((scoreType) {
              return _buildScoreTypeSection(scoreType);
            }),
        ],
      ),
    );
  }

  /// スコア種別セクション
  Widget _buildScoreTypeSection(ScoreType scoreType) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                scoreType.name,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scoreType.targetType == ScoreTargetType.team
                      ? AppColors.info.withValues(alpha: 0.1)
                      : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  scoreType.targetType == ScoreTargetType.team ? 'グループ' : '個人',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: scoreType.targetType == ScoreTargetType.team
                        ? AppColors.info
                        : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              IconButton(
                onPressed: () => _removeScoreType(scoreType.id),
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.error,
                iconSize: AppDimensions.iconS,
                tooltip: '削除',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          if (scoreType.targetType == ScoreTargetType.team)
            ..._buildTeamScoreInputs(scoreType)
          else
            ..._buildIndividualScoreInputs(scoreType),
        ],
      ),
    );
  }

  /// チーム/グループスコア入力
  List<Widget> _buildTeamScoreInputs(ScoreType scoreType) {
    return widget.match.participants.map((participantId) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                _participantNames[participantId] ?? participantId,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _dynamicScoreControllers[scoreType.id]![participantId],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textLight,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingS,
                    vertical: AppDimensions.spacingS,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              scoreType.unit,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 個人スコア入力
  List<Widget> _buildIndividualScoreInputs(ScoreType scoreType) {
    if (widget.match.isTeamMatch) {
      // チーム戦の場合はチームごとに個人スコアを表示
      return widget.match.participants.map((teamId) {
        final members = _teamMembers[teamId] ?? [];
        if (members.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // チーム名ヘッダー
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusM),
                    topRight: Radius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: AppColors.secondary,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      _participantNames[teamId] ?? teamId,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              // メンバーの個人スコア入力
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Column(
                  children: members.map((memberId) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              _memberNames[memberId] ?? memberId,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _dynamicScoreControllers[scoreType.id]![memberId],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: const TextStyle(
                                  fontSize: AppDimensions.fontSizeS,
                                  color: AppColors.textLight,
                                ),
                                filled: true,
                                fillColor: AppColors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spacingS,
                                  vertical: AppDimensions.spacingS,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Text(
                            scoreType.unit,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList();
    } else {
      // 個人戦の場合は通常の個人スコア表示
      return widget.match.participants.map((participantId) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  _participantNames[participantId] ?? participantId,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _dynamicScoreControllers[scoreType.id]![participantId],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: AppDimensions.spacingS,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                scoreType.unit,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        );
      }).toList();
    }
  }


  /// チーム別個人スコア表示
  Widget _buildTeamIndividualScores(String teamId) {
    // そのチームのメンバーのコントローラーを取得
    final teamMemberControllers = _individualScoreControllers.entries
        .where((entry) => entry.key.startsWith('${teamId}_'))
        .toList();

    if (teamMemberControllers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // チーム名ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusM),
                topRight: Radius.circular(AppDimensions.radiusM),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.group,
                  color: AppColors.info,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  _participantNames[teamId] ?? teamId,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          // メンバーの個人スコア入力
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Column(
              children: teamMemberControllers.map((entry) {
                final userId = entry.key;
                final userDisplayName = userId.split('_').last; // member1, member2など

                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          userDisplayName, // TODO: 実際のユーザー名に変換
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.textLight,
                            ),
                            filled: true,
                            fillColor: AppColors.cardBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                              borderSide: BorderSide(color: AppColors.accent, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingS,
                              vertical: AppDimensions.spacingS,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      const Text(
                        '点', // TODO: イベント設定からスコア単位を取得
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }



  /// 下部アクションエリア
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                text: 'キャンセル',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: AppButton.primary(
                text: _isLoading
                  ? (widget.match.isCompleted ? '更新中...' : '保存中...')
                  : (widget.match.isCompleted ? '結果を更新' : '結果を保存'),
                onPressed: _isLoading ? null : _submitResult,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// エビデンス画像セクション
  Widget _buildEvidenceImageSection() {
    final currentUser = ref.watch(currentFirebaseUserProvider);
    final displayName = ref.watch(displayNameProvider);

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
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
                Icons.image,
                color: AppColors.info,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'エビデンス画像',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (_selectedEvidenceImages.isNotEmpty || _existingEvidenceImages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingS,
                    vertical: AppDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_selectedEvidenceImages.length + _existingEvidenceImages.length}枚',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            '試合の証拠となる画像をアップロードできます',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // 画像追加ボタン
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              text: '画像を追加',
              icon: Icons.add_photo_alternate,
              onPressed: _showImageSourceDialog,
            ),
          ),

          // 既存画像の表示
          if (_existingEvidenceImages.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              '既存の画像 (${_existingEvidenceImages.length}枚)',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppDimensions.spacingS,
                mainAxisSpacing: AppDimensions.spacingS,
                childAspectRatio: 1,
              ),
              itemCount: _existingEvidenceImages.length,
              itemBuilder: (context, index) {
                final imageUrl = _existingEvidenceImages[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(color: AppColors.info),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.cardBackground,
                            child: Icon(
                              Icons.broken_image,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                        ),
                        Positioned(
                          top: AppDimensions.spacingXS,
                          right: AppDimensions.spacingXS,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          // 新規追加画像の表示
          if (_selectedEvidenceImages.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              '追加する画像 (${_selectedEvidenceImages.length}枚)',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppDimensions.spacingS,
                mainAxisSpacing: AppDimensions.spacingS,
                childAspectRatio: 1,
              ),
              itemCount: _selectedEvidenceImages.length,
              itemBuilder: (context, index) {
                final imageFile = _selectedEvidenceImages[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: AppDimensions.spacingXS,
                          right: AppDimensions.spacingXS,
                          child: GestureDetector(
                            onTap: () => _removeSelectedImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// 画像選択ダイアログを表示
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'エビデンス画像の追加',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    text: 'カメラ',
                    icon: Icons.camera_alt,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _takePicture();
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: AppButton.secondary(
                    text: 'ギャラリー',
                    icon: Icons.photo_library,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImagesFromGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }

  /// カメラで撮影
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        setState(() {
          _selectedEvidenceImages.clear(); // 既存の選択画像をクリア
          _selectedEvidenceImages.add(File(photo.path));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('写真を撮影しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('カメラでの撮影に失敗しました: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// ギャラリーから画像を選択
  Future<void> _pickImagesFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedEvidenceImages.clear(); // 既存の選択画像をクリア
          _selectedEvidenceImages.add(File(image.path));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を選択しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ギャラリーからの選択に失敗しました: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// 選択された画像を削除
  void _removeSelectedImage(int index) {
    setState(() {
      _selectedEvidenceImages.removeAt(index);
    });
  }

  /// 既存画像を削除
  void _removeExistingImage(int index) {
    setState(() {
      final removedImageUrl = _existingEvidenceImages.removeAt(index);
      _deletedEvidenceImages.add(removedImageUrl);
    });
  }

  /// 運営メモセクション
  Widget _buildAdminNotesSection() {
    return Container(
      width: double.infinity,
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
                Icons.admin_panel_settings,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '運営メモ',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            '試合結果に関する運営側のメモを記入できます',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // 公開メモ（ユーザー閲覧可能）
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: AppColors.info,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      '公開メモ（ユーザー閲覧可能）',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  '参加者が閲覧できるメモです。試合の詳細や特記事項を記入してください。',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                TextFormField(
                  controller: _adminPublicNotesController,
                  decoration: InputDecoration(
                    hintText: '例：接続不良により再戦を実施、MVP賞を追加授与など...',
                    hintStyle: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide(color: AppColors.info, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
                  ),
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // プライベートメモ（運営者のみ）
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility_off,
                      color: AppColors.warning,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      'プライベートメモ（運営者のみ閲覧可能）',
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
                  '運営者のみが閲覧できる内部メモです。参加者には表示されません。',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                TextFormField(
                  controller: _adminPrivateNotesController,
                  decoration: InputDecoration(
                    hintText: '例：参加者Aから異議申し立てあり、要確認事項など...',
                    hintStyle: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textLight,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      borderSide: BorderSide(color: AppColors.warning, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
                  ),
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 結果を提出
  Future<void> _submitResult() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 順位を収集して勝者を決定
      final rankings = <String, int>{};
      String? winner;
      int bestRank = 999;

      for (final entry in _rankingControllers.entries) {
        final rankText = entry.value.text.trim();
        if (rankText.isNotEmpty) {
          final rank = int.tryParse(rankText);
          if (rank != null && rank > 0) {
            rankings[entry.key] = rank;
            // 1位（最小の数値）が勝者
            if (rank < bestRank) {
              bestRank = rank;
              winner = entry.key;
            }
          }
        }
      }

      // 動的スコアを収集
      final scores = <String, int>{};
      final extendedScores = <String, Map<String, int>>{}; // 拡張スコア情報

      // メインスコアの取得（チーム対象または個人戦での個人対象）
      ScoreType? primaryScoreType;
      if (widget.match.isTeamMatch) {
        // チーム戦：チーム対象のスコア種別を探す
        final teamScoreTypes = _scoreTypes.where((type) => type.targetType == ScoreTargetType.team);
        if (teamScoreTypes.isNotEmpty) {
          primaryScoreType = teamScoreTypes.first;
        }
      } else {
        // 個人戦：個人対象のスコア種別を探す（個人戦でもscoresに保存）
        final individualScoreTypes = _scoreTypes.where((type) => type.targetType == ScoreTargetType.individual);
        if (individualScoreTypes.isNotEmpty) {
          primaryScoreType = individualScoreTypes.first;
        }
      }

      if (primaryScoreType != null) {
        for (final entry in _dynamicScoreControllers[primaryScoreType.id]?.entries ?? <String, TextEditingController>{}.entries) {
          final scoreText = entry.value.text.trim();
          if (scoreText.isNotEmpty) {
            final score = int.tryParse(scoreText);
            if (score != null) {
              scores[entry.key] = score;
            }
          } else if (rankings.containsKey(entry.key)) {
            // スコアが入力されていない場合は順位からスコアを生成
            final rank = rankings[entry.key]!;
            scores[entry.key] = math.max(0, 110 - rank * 10);
          }
        }
      } else {
        // 対象のスコア種別がない場合は順位からスコアを生成
        for (final entry in rankings.entries) {
          final rank = entry.value;
          scores[entry.key] = math.max(0, 110 - rank * 10);
        }
      }

      // 全スコア種別の情報を収集
      for (final scoreType in _scoreTypes) {
        final scoreTypeScores = <String, int>{};
        final controllers = _dynamicScoreControllers[scoreType.id];
        if (controllers != null) {
          for (final entry in controllers.entries) {
            final scoreText = entry.value.text.trim();
            if (scoreText.isNotEmpty) {
              final score = int.tryParse(scoreText);
              if (score != null) {
                scoreTypeScores[entry.key] = score;
              }
            }
          }
        }
        if (scoreTypeScores.isNotEmpty) {
          extendedScores[scoreType.id] = scoreTypeScores;
        }
      }

      // 個人スコアを収集（チーム戦の場合のみ）
      Map<String, int>? individualScores;

      if (widget.match.isTeamMatch) {
        // チーム戦でのみ個人スコアを別途収集
        final individualScoreTypes = _scoreTypes.where(
          (type) => type.targetType == ScoreTargetType.individual,
        );

        if (individualScoreTypes.isNotEmpty) {
          individualScores = {};

          for (final scoreType in individualScoreTypes) {
            final controllers = _dynamicScoreControllers[scoreType.id];
            if (controllers != null) {
              for (final entry in controllers.entries) {
                final scoreText = entry.value.text.trim();
                if (scoreText.isNotEmpty) {
                  final score = int.tryParse(scoreText);
                  if (score != null) {
                    individualScores[entry.key] = score;
                  }
                }
              }
            }
          }

          // レガシー個人スコアコントローラーからも収集（下位互換性）
          for (final entry in _individualScoreControllers.entries) {
            final score = int.tryParse(entry.value.text.trim());
            if (score != null) {
              individualScores[entry.key] = score;
            }
          }

          // 空の場合はnullにする
          if (individualScores.isEmpty) {
            individualScores = null;
          }
        } else {
          // 動的スコアシステムに個人対象がない場合でも、レガシーシステムから収集
          if (_individualScoreControllers.isNotEmpty) {
            individualScores = {};
            for (final entry in _individualScoreControllers.entries) {
              final score = int.tryParse(entry.value.text.trim());
              if (score != null) {
                individualScores[entry.key] = score;
              }
            }
            // 空の場合はnullにする
            if (individualScores.isEmpty) {
              individualScores = null;
            }
          }
        }
      }
      // 個人戦の場合、個人対象のスコアはscoresに既に保存されているので、individualScores は null


      // エビデンス画像処理
      final List<String> allEvidenceImages = [..._existingEvidenceImages]; // 既存の画像URL（削除された分は除外済み）

      // 削除された画像をFirebase Storageから削除
      if (_deletedEvidenceImages.isNotEmpty) {
        try {
          final currentUser = ref.read(currentFirebaseUserProvider);
          if (currentUser != null) {
            // ローカルファイルパス（新規追加画像のパス）を除外して、Firebase URLのみ削除対象とする
            final urlsToDelete = _deletedEvidenceImages
                .where((url) => url.startsWith('http') || url.startsWith('gs://'))
                .toList();

            if (urlsToDelete.isNotEmpty) {
              // 削除対象の画像をStorageから削除
              await ImageUploadService.deleteMultipleEvidenceImages(urlsToDelete);
            }
          }
        } catch (e) {
          // 削除エラーは警告程度に留める（処理は継続）
          // エビデンス画像の削除でエラーが発生
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('一部の画像削除でエラーが発生しました: $e'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
        }
      }

      // 新規選択された画像をアップロード
      if (_selectedEvidenceImages.isNotEmpty) {
        try {
          // 現在のユーザーIDを取得
          final currentUser = ref.read(currentFirebaseUserProvider);
          if (currentUser == null) {
            throw Exception('ユーザーが認証されていません');
          }

          // 新規選択された画像をFirebase Storageにアップロード
          final uploadResults = await ImageUploadService.uploadMultipleEvidenceImages(
            _selectedEvidenceImages,
            widget.match.eventId,
            widget.match.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
            currentUser.uid,
            onProgress: (completed, total) {
              // TODO: プログレス表示の実装が必要な場合はここで処理
            },
          );

          // アップロードされた画像のダウンロードURLを追加
          allEvidenceImages.addAll(uploadResults.map((result) => result.downloadUrl));

        } catch (e) {
          // アップロードエラー時はユーザーに通知
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('エビデンス画像のアップロードに失敗しました: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          // エラー時は処理を中止
          return;
        }
      }

      // 更新されたMatchResultを作成
      final updatedMatch = widget.match.copyWith(
        scores: scores,
        individualScores: individualScores,
        winner: winner,
        evidenceImages: allEvidenceImages,
        adminPublicNotes: _adminPublicNotesController.text.trim().isNotEmpty
            ? _adminPublicNotesController.text.trim()
            : null,
        adminPrivateNotes: _adminPrivateNotesController.text.trim().isNotEmpty
            ? _adminPrivateNotesController.text.trim()
            : null,
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.of(context).pop(updatedMatch);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('結果の保存に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}