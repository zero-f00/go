import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../data/models/match_result_model.dart';
import '../../../l10n/app_localizations.dart';

/// シンプルな結果入力タイプ
enum SimpleResultType {
  score,    // スコア制
  ranking,  // 順位制
  winLoss,  // 勝敗制
}

extension SimpleResultTypeExtension on SimpleResultType {
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

  // 選択された結果入力タイプ
  SimpleResultType _selectedResultType = SimpleResultType.score;

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
    final l10n = L10n.of(context);
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
              _buildHeader(l10n),
              const SizedBox(height: AppDimensions.spacingL),
              _buildMatchNameInput(l10n),
              const SizedBox(height: AppDimensions.spacingL),
              _buildResultTypeToggles(l10n),
              const SizedBox(height: AppDimensions.spacingL),
              Expanded(child: _buildResultInput(l10n)),
              const SizedBox(height: AppDimensions.spacingL),
              _buildNotesInput(l10n),
              const SizedBox(height: AppDimensions.spacingL),
              _buildActionButtons(l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー
  Widget _buildHeader(L10n l10n) {
    return Row(
      children: [
        Icon(
          Icons.sports_esports,
          color: AppColors.accent,
          size: AppDimensions.iconL,
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Text(
            l10n.matchResultInputTitle,
            style: const TextStyle(
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
  Widget _buildMatchNameInput(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.matchNameLabel,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextFormField(
          controller: _matchNameController,
          decoration: InputDecoration(
            hintText: l10n.matchNameHint,
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
              return l10n.matchNameValidation;
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 結果タイプトグル
  Widget _buildResultTypeToggles(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.resultTypeLabel,
          style: const TextStyle(
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
                              _getResultTypeDisplayName(type, l10n),
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.accent : AppColors.textDark,
                              ),
                            ),
                            Text(
                              _getResultTypeDescription(type, l10n),
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

  String _getResultTypeDisplayName(SimpleResultType type, L10n l10n) {
    switch (type) {
      case SimpleResultType.score:
        return l10n.resultTypeScore;
      case SimpleResultType.ranking:
        return l10n.resultTypeRanking;
      case SimpleResultType.winLoss:
        return l10n.resultTypeWinLoss;
    }
  }

  String _getResultTypeDescription(SimpleResultType type, L10n l10n) {
    switch (type) {
      case SimpleResultType.score:
        return l10n.resultTypeScoreDesc;
      case SimpleResultType.ranking:
        return l10n.resultTypeRankingDesc;
      case SimpleResultType.winLoss:
        return l10n.resultTypeWinLossDesc;
    }
  }

  /// 結果入力エリア
  Widget _buildResultInput(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.participantResultsLabel,
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
                return _buildParticipantResultInput(participantId, participantName, l10n);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 参加者の結果入力
  Widget _buildParticipantResultInput(String participantId, String participantName, L10n l10n) {
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
          _buildResultInputByType(participantId, l10n),
        ],
      ),
    );
  }

  /// 結果タイプ別の入力ウィジェット
  Widget _buildResultInputByType(String participantId, L10n l10n) {
    switch (_selectedResultType) {
      case SimpleResultType.score:
        return _buildScoreInput(participantId, l10n);
      case SimpleResultType.ranking:
        return _buildRankingInput(participantId, l10n);
      case SimpleResultType.winLoss:
        return _buildWinLossInput(participantId, l10n);
    }
  }

  /// スコア入力
  Widget _buildScoreInput(String participantId, L10n l10n) {
    return TextFormField(
      initialValue: _scores[participantId].toString(),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: l10n.scoreLabel,
        suffixText: l10n.pointsSuffix,
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
  Widget _buildRankingInput(String participantId, L10n l10n) {
    return DropdownButtonFormField<int>(
      value: _rankings[participantId],
      decoration: InputDecoration(
        labelText: l10n.rankLabel,
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
          child: Text(l10n.rankPosition(rank)),
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
  Widget _buildWinLossInput(String participantId, L10n l10n) {
    return DropdownButtonFormField<SimpleWinLossResult>(
      value: _winLossResults[participantId],
      decoration: InputDecoration(
        labelText: l10n.winLossInputLabel,
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
              Text(_getWinLossDisplayName(result, l10n)),
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

  String _getWinLossDisplayName(SimpleWinLossResult result, L10n l10n) {
    switch (result) {
      case SimpleWinLossResult.win:
        return l10n.winLabel;
      case SimpleWinLossResult.loss:
        return l10n.lossLabel;
      case SimpleWinLossResult.draw:
        return l10n.drawLabel;
    }
  }

  /// メモ入力
  Widget _buildNotesInput(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notesOptional,
          style: const TextStyle(
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
            hintText: l10n.matchDetailsHint,
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
  Widget _buildActionButtons(L10n l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
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
              : Text(
                  l10n.saveButton,
                  style: const TextStyle(
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

      final l10n = L10n.of(context);
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
        matchFormat: _getResultTypeDisplayName(_selectedResultType, l10n),
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
          content: Text(L10n.of(context).resultSaveError(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}