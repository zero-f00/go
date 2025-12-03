import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../data/models/match_result_model.dart';
import '../../../shared/services/group_management_service.dart';

/// 試合登録ダイアログ
class MatchRegistrationDialog extends ConsumerStatefulWidget {
  final String eventId;
  final bool isTeamEvent;
  final List<String> participants; // グループIDまたはユーザーID
  final Function(MatchResult) onMatchRegistered;
  final Map<String, String>? participantNames; // participantId -> 表示名（任意）

  const MatchRegistrationDialog({
    super.key,
    required this.eventId,
    required this.isTeamEvent,
    required this.participants,
    required this.onMatchRegistered,
    this.participantNames,
  });

  @override
  ConsumerState<MatchRegistrationDialog> createState() =>
      _MatchRegistrationDialogState();
}

class _MatchRegistrationDialogState
    extends ConsumerState<MatchRegistrationDialog> {
  final _matchNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> _selectedParticipants = [];
  bool _isLoading = false;
  Map<String, String> _participantNames = {}; // participantId -> 表示名
  final GroupManagementService _groupService = GroupManagementService();

  @override
  void initState() {
    super.initState();
    // デフォルトで2人/2チームを選択
    if (widget.participants.length >= 2) {
      _selectedParticipants.addAll(widget.participants.take(2));
    }
    _loadParticipantNames();
  }

  /// 参加者名を読み込み
  Future<void> _loadParticipantNames() async {
    if (widget.participantNames != null) {
      // 親画面から参加者名が提供されている場合はそれを使用
      setState(() {
        _participantNames = Map.from(widget.participantNames!);
      });
    } else if (widget.isTeamEvent) {
      // チーム戦の場合はグループ名を取得
      final groupNames = await _groupService.getGroupNames(widget.participants);
      setState(() {
        _participantNames = groupNames;
      });
    } else {
      // 個人戦の場合はユーザー名を取得（フォールバックとしてIDを使用）
      setState(() {
        for (final participantId in widget.participants) {
          _participantNames[participantId] = participantId;
        }
      });
    }
  }


  @override
  void dispose() {
    _matchNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogHeader(),
                const SizedBox(height: AppDimensions.spacingL),
                _buildMatchNameField(),
                const SizedBox(height: AppDimensions.spacingM),
                _buildParticipantSelector(),
                const SizedBox(height: AppDimensions.spacingXL),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ダイアログヘッダー
  Widget _buildDialogHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '試合を追加',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: AppColors.textDark,
        ),
      ],
    );
  }

  /// 試合名入力フィールド
  Widget _buildMatchNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '試合名',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextFormField(
          controller: _matchNameController,
          decoration: InputDecoration(
            hintText: '試合名を入力',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '試合名を入力してください';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 参加者選択
  Widget _buildParticipantSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.isTeamEvent ? '参加チーム（グループ）' : '参加者',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedParticipants.length == widget.participants.length) {
                    // 全て選択されている場合は全て解除
                    _selectedParticipants.clear();
                  } else {
                    // 全て選択されていない場合は全て選択
                    _selectedParticipants = List.from(widget.participants);
                  }
                });
              },
              child: Text(
                _selectedParticipants.length == widget.participants.length
                    ? '解除'
                    : '選択',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.participants.length,
            itemBuilder: (context, index) {
              final participantId = widget.participants[index];
              final isSelected = _selectedParticipants.contains(participantId);

              return Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
                child: Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(_participantNames[participantId] ?? participantId),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedParticipants.add(participantId);
                            } else {
                              _selectedParticipants.remove(participantId);
                            }
                          });
                        },
                        dense: true,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_selectedParticipants.length < 2) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            '少なくとも2つの${widget.isTeamEvent ? 'チーム（グループ）' : '参加者'}を選択してください',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }


  /// アクションボタン
  Widget _buildActionButtons() {
    return Row(
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
            text: _isLoading ? '登録中...' : '試合を登録',
            onPressed: _isLoading || _selectedParticipants.length < 2
                ? null
                : _registerMatch,
          ),
        ),
      ],
    );
  }

  /// 試合を登録
  Future<void> _registerMatch() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParticipants.length < 2) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final match = MatchResult(
        eventId: widget.eventId,
        matchName: _matchNameController.text.trim(),
        participants: List.from(_selectedParticipants),
        scores: {}, // 初期は空
        createdAt: now,
        updatedAt: now,
        isTeamMatch: widget.isTeamEvent,
        status: MatchStatus.inProgress, // 新規作成時は進行中に設定
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onMatchRegistered(match);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合「${_matchNameController.text.trim()}」を登録しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合の登録に失敗しました: $e'),
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