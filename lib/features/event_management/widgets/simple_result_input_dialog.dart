import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../data/models/match_result_model.dart';

/// シンプルな結果入力タイプ
enum SimpleResultType {
  score,    // スコア制
  ranking,  // 順位制
  winLoss,  // 勝敗制
}

extension SimpleResultTypeExtension on SimpleResultType {
  String get displayName {
    switch (this) {
      case SimpleResultType.score:
        return 'スコア制';
      case SimpleResultType.ranking:
        return '順位制';
      case SimpleResultType.winLoss:
        return '勝敗制';
    }
  }

  String get description {
    switch (this) {
      case SimpleResultType.score:
        return '各参加者のスコアを記録';
      case SimpleResultType.ranking:
        return '各参加者の順位を記録（1位、2位、3位...)';
      case SimpleResultType.winLoss:
        return '各参加者の勝敗を記録';
    }
  }

  IconData get icon {
    switch (this) {
      case SimpleResultType.score:
        return Icons.score;
      case SimpleResultType.ranking:
        return Icons.emoji_events;
      case SimpleResultType.winLoss:
        return Icons.sports_score;
    }
  }
}

/// 勝敗結果
enum SimpleWinLossResult {
  win,   // 勝ち
  loss,  // 負け
  draw,  // 引き分け
}

extension SimpleWinLossResultExtension on SimpleWinLossResult {
  String get displayName {
    switch (this) {
      case SimpleWinLossResult.win:
        return '勝ち';
      case SimpleWinLossResult.loss:
        return '負け';
      case SimpleWinLossResult.draw:
        return '引き分け';
    }
  }

  Color get color {
    switch (this) {
      case SimpleWinLossResult.win:
        return AppColors.success;
      case SimpleWinLossResult.loss:
        return AppColors.error;
      case SimpleWinLossResult.draw:
        return AppColors.warning;
    }
  }
}

/// シンプル結果入力ダイアログ
class SimpleResultInputDialog extends StatefulWidget {
  final String eventId;
  final bool isTeamMatch;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Function(MatchResult) onResultSubmitted;

  const SimpleResultInputDialog({
    super.key,
    required this.eventId,
    required this.isTeamMatch,
    required this.participants,
    required this.participantNames,
    required this.onResultSubmitted,
  });

  @override
  State<SimpleResultInputDialog> createState() => _SimpleResultInputDialogState();
}

class _SimpleResultInputDialogState extends State<SimpleResultInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _matchNameController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _useScore = true;
  bool _useRanking = true;
  bool _useWinLoss = true;

  // 結果データの保存用
  Map<String, int> _scores = {}; // participantId -> score
  Map<String, int> _rankings = {}; // participantId -> rank
  Map<String, SimpleWinLossResult> _winLossResults = {}; // participantId -> result

  @override
  void initState() {
    super.initState();
    _initializeResultData();
  }

  void _initializeResultData() {
    for (final participantId in widget.participants) {
      _scores[participantId] = 0;
      _rankings[participantId] = 1;
      _winLossResults[participantId] = SimpleWinLossResult.draw;
    }
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildMatchNameInput(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildResultTypeToggles(),
              const SizedBox(height: AppDimensions.spacingL),
              Expanded(child: _buildResultInput()),
              const SizedBox(height: AppDimensions.spacingL),
              _buildNotesInput(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.sports_esports,
          color: AppColors.accent,
          size: AppDimensions.iconL,
        ),
        const SizedBox(width: AppDimensions.spacingM),
        const Expanded(
          child: Text(
            '試合結果入力',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXL,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: AppColors.textDark.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// 試合名入力
  Widget _buildMatchNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
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
            hintText: '例: 第1回トーナメント決勝',
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(color: AppColors.accent),
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

  /// 結果タイプトグル
  Widget _buildResultTypeToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '記録方式',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: SimpleResultType.values.map((type) {
              final isSelected = _selectedResultType == type;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedResultType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type.icon,
                        color: isSelected ? AppColors.accent : AppColors.textDark.withValues(alpha: 0.7),
                        size: AppDimensions.iconM,
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.accent : AppColors.textDark,
                              ),
                            ),
                            Text(
                              type.description,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.textDark.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<SimpleResultType>(
                        value: type,
                        groupValue: _selectedResultType,
                        onChanged: (value) {
                          setState(() {
                            _selectedResultType = value!;
                          });
                        },
                        activeColor: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 結果入力エリア
  Widget _buildResultInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '参加者の結果',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              itemCount: widget.participants.length,
              itemBuilder: (context, index) {
                final participantId = widget.participants[index];
                final participantName = widget.participantNames[participantId] ?? participantId;
                return _buildParticipantResultInput(participantId, participantName);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 参加者の結果入力
  Widget _buildParticipantResultInput(String participantId, String participantName) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            participantName,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          _buildResultInputByType(participantId),
        ],
      ),
    );
  }

  /// 結果タイプ別の入力ウィジェット
  Widget _buildResultInputByType(String participantId) {
    switch (_selectedResultType) {
      case SimpleResultType.score:
        return _buildScoreInput(participantId);
      case SimpleResultType.ranking:
        return _buildRankingInput(participantId);
      case SimpleResultType.winLoss:
        return _buildWinLossInput(participantId);
    }
  }

  /// スコア入力
  Widget _buildScoreInput(String participantId) {
    return TextFormField(
      initialValue: _scores[participantId].toString(),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'スコア',
        suffixText: '点',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
      ),
      onChanged: (value) {
        _scores[participantId] = int.tryParse(value) ?? 0;
      },
    );
  }

  /// 順位入力
  Widget _buildRankingInput(String participantId) {
    return DropdownButtonFormField<int>(
      value: _rankings[participantId],
      decoration: InputDecoration(
        labelText: '順位',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
      ),
      items: List.generate(widget.participants.length, (index) {
        final rank = index + 1;
        return DropdownMenuItem(
          value: rank,
          child: Text('${rank}位'),
        );
      }),
      onChanged: (value) {
        setState(() {
          _rankings[participantId] = value!;
        });
      },
    );
  }

  /// 勝敗入力
  Widget _buildWinLossInput(String participantId) {
    return DropdownButtonFormField<SimpleWinLossResult>(
      value: _winLossResults[participantId],
      decoration: InputDecoration(
        labelText: '結果',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
      ),
      items: SimpleWinLossResult.values.map((result) {
        return DropdownMenuItem(
          value: result,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: result.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(result.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _winLossResults[participantId] = value!;
        });
      },
    );
  }

  /// メモ入力
  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'メモ（任意）',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '試合の詳細や特記事項',
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
      ],
    );
  }

  /// アクションボタン
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitResult,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingM,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '保存',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  /// 結果を送信
  void _submitResult() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 既存のMatchResultモデルに変換
      Map<String, int> scores = {};
      String? winner;

      switch (_selectedResultType) {
        case SimpleResultType.score:
          scores = Map.from(_scores);
          // スコアが最も高い参加者を勝者とする
          final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
          winner = scores.entries
              .where((entry) => entry.value == maxScore)
              .first.key;
          break;

        case SimpleResultType.ranking:
          // 順位を逆転したスコアとして保存（1位=参加者数点、2位=参加者数-1点...）
          final participantCount = widget.participants.length;
          for (final entry in _rankings.entries) {
            scores[entry.key] = participantCount - entry.value + 1;
          }
          // 1位の参加者を勝者とする
          winner = _rankings.entries
              .where((entry) => entry.value == 1)
              .first.key;
          break;

        case SimpleResultType.winLoss:
          // 勝ち=3点、引き分け=1点、負け=0点
          for (final entry in _winLossResults.entries) {
            switch (entry.value) {
              case SimpleWinLossResult.win:
                scores[entry.key] = 3;
                break;
              case SimpleWinLossResult.draw:
                scores[entry.key] = 1;
                break;
              case SimpleWinLossResult.loss:
                scores[entry.key] = 0;
                break;
            }
          }
          // 勝利者を設定（複数いる場合は最初の一人）
          final winners = _winLossResults.entries
              .where((entry) => entry.value == SimpleWinLossResult.win)
              .toList();
          if (winners.isNotEmpty) {
            winner = winners.first.key;
          }
          break;
      }

      final now = DateTime.now();
      final matchResult = MatchResult(
        eventId: widget.eventId,
        matchName: _matchNameController.text.trim(),
        participants: List.from(widget.participants),
        winner: winner,
        scores: scores,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
        isTeamMatch: widget.isTeamMatch,
        matchFormat: _selectedResultType.displayName,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      widget.onResultSubmitted(matchResult);
      Navigator.of(context).pop();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('結果の保存中にエラーが発生しました: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}