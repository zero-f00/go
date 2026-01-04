import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../data/models/match_result_model.dart';
import '../../../l10n/app_localizations.dart';

/// 勝敗結果
enum MultiWinLossResult {
  win,   // 勝ち
  loss,  // 負け
  draw,  // 引き分け
}

extension MultiWinLossResultExtension on MultiWinLossResult {
  String getDisplayName(BuildContext context) {
    final l10n = L10n.of(context);
    switch (this) {
      case MultiWinLossResult.win:
        return l10n.winLabel;
      case MultiWinLossResult.loss:
        return l10n.lossLabel;
      case MultiWinLossResult.draw:
        return l10n.drawLabel;
    }
  }

  Color get color {
    switch (this) {
      case MultiWinLossResult.win:
        return AppColors.success;
      case MultiWinLossResult.loss:
        return AppColors.error;
      case MultiWinLossResult.draw:
        return AppColors.warning;
    }
  }
}

/// 複数結果タイプ対応の結果入力ダイアログ
class MultiResultInputDialog extends StatefulWidget {
  final String eventId;
  final bool isTeamMatch;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Function(MatchResult) onResultSubmitted;

  const MultiResultInputDialog({
    super.key,
    required this.eventId,
    required this.isTeamMatch,
    required this.participants,
    required this.participantNames,
    required this.onResultSubmitted,
  });

  @override
  State<MultiResultInputDialog> createState() => _MultiResultInputDialogState();
}

class _MultiResultInputDialogState extends State<MultiResultInputDialog> {
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
  Map<String, MultiWinLossResult> _winLossResults = {}; // participantId -> result

  @override
  void initState() {
    super.initState();
    _initializeResultData();
  }

  void _initializeResultData() {
    for (final participantId in widget.participants) {
      _scores[participantId] = 0;
      _rankings[participantId] = 1;
      _winLossResults[participantId] = MultiWinLossResult.draw;
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
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
    final l10n = L10n.of(context);
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
  Widget _buildMatchNameInput() {
    final l10n = L10n.of(context);
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
  Widget _buildResultTypeToggles() {
    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recordInfoToRecord,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          l10n.checkRequiredInfo,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textDark.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildToggleOption(
                l10n.scorePointsLabel,
                l10n.scorePointsDesc,
                Icons.score,
                _useScore,
                (value) => setState(() => _useScore = value ?? false),
              ),
              _buildToggleOption(
                l10n.rankingPositionLabel,
                l10n.rankingPositionDesc,
                Icons.emoji_events,
                _useRanking,
                (value) => setState(() => _useRanking = value ?? false),
              ),
              _buildToggleOption(
                l10n.winLossResultLabel,
                l10n.winLossResultDesc,
                Icons.sports_score,
                _useWinLoss,
                (value) => setState(() => _useWinLoss = value ?? false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// トグルオプション
  Widget _buildToggleOption(
    String title,
    String description,
    IconData icon,
    bool value,
    void Function(bool?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textDark.withValues(alpha: 0.7),
          ),
        ),
        secondary: Icon(
          icon,
          color: value ? AppColors.accent : AppColors.textDark.withValues(alpha: 0.5),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  /// 結果入力エリア
  Widget _buildResultInput() {
    final l10n = L10n.of(context);
    if (!_useScore && !_useRanking && !_useWinLoss) {
      return Center(
        child: Text(
          l10n.selectAtLeastOneInfo,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark.withValues(alpha: 0.7),
          ),
        ),
      );
    }

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
          const SizedBox(height: AppDimensions.spacingM),
          Column(
            children: [
              if (_useScore) ...[
                _buildScoreInput(participantId),
                const SizedBox(height: AppDimensions.spacingM),
              ],
              if (_useRanking) ...[
                _buildRankingInput(participantId),
                const SizedBox(height: AppDimensions.spacingM),
              ],
              if (_useWinLoss) ...[
                _buildWinLossInput(participantId),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// スコア入力
  Widget _buildScoreInput(String participantId) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Icon(
          Icons.score,
          color: AppColors.accent,
          size: AppDimensions.iconS,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: TextFormField(
            initialValue: _scores[participantId].toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.scorePointsLabel,
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
          ),
        ),
      ],
    );
  }

  /// 順位入力
  Widget _buildRankingInput(String participantId) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Icon(
          Icons.emoji_events,
          color: AppColors.accent,
          size: AppDimensions.iconS,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: DropdownButtonFormField<int>(
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
          ),
        ),
      ],
    );
  }

  /// 勝敗入力
  Widget _buildWinLossInput(String participantId) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Icon(
          Icons.sports_score,
          color: AppColors.accent,
          size: AppDimensions.iconS,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: DropdownButtonFormField<MultiWinLossResult>(
            value: _winLossResults[participantId],
            decoration: InputDecoration(
              labelText: l10n.winLossResultLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
            ),
            items: MultiWinLossResult.values.map((result) {
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
                    Text(result.getDisplayName(context)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _winLossResults[participantId] = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  /// メモ入力
  Widget _buildNotesInput() {
    final l10n = L10n.of(context);
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
  Widget _buildActionButtons() {
    final l10n = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
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
    final l10n = L10n.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (!_useScore && !_useRanking && !_useWinLoss) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectAtLeastOneInfo),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 複数の結果タイプを統合したスコアを計算
      Map<String, int> scores = {};
      String? winner;
      List<String> resultTypes = [];

      // 使用されている結果タイプを記録
      if (_useScore) resultTypes.add(l10n.resultTypeScoreLabel);
      if (_useRanking) resultTypes.add(l10n.resultTypeRankLabel);
      if (_useWinLoss) resultTypes.add(l10n.resultTypeWinLossLabel);

      // 各参加者の統合スコアを計算
      for (final participantId in widget.participants) {
        int totalScore = 0;

        // スコアがある場合はそのまま加算
        if (_useScore) {
          totalScore += _scores[participantId] ?? 0;
        }

        // 順位がある場合は順位ボーナスを追加（1位=100点、2位=80点、3位=60点...）
        if (_useRanking) {
          final rank = _rankings[participantId] ?? widget.participants.length;
          final rankBonus = math.max(0, 120 - (rank * 20));
          totalScore += rankBonus;
        }

        // 勝敗結果がある場合はボーナスを追加
        if (_useWinLoss) {
          final result = _winLossResults[participantId] ?? MultiWinLossResult.draw;
          switch (result) {
            case MultiWinLossResult.win:
              totalScore += 50;
              break;
            case MultiWinLossResult.draw:
              totalScore += 25;
              break;
            case MultiWinLossResult.loss:
              totalScore += 0;
              break;
          }
        }

        scores[participantId] = totalScore;
      }

      // 勝者を決定
      if (_useWinLoss) {
        // 勝敗結果が記録されている場合は勝者を優先
        final winners = _winLossResults.entries
            .where((entry) => entry.value == MultiWinLossResult.win)
            .toList();
        if (winners.isNotEmpty) {
          winner = winners.first.key;
        }
      } else if (_useRanking) {
        // 順位が記録されている場合は1位を勝者とする
        final firstPlace = _rankings.entries
            .where((entry) => entry.value == 1)
            .toList();
        if (firstPlace.isNotEmpty) {
          winner = firstPlace.first.key;
        }
      } else if (_useScore && scores.isNotEmpty) {
        // スコアのみの場合は最高スコアの参加者を勝者とする
        final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
        winner = scores.entries
            .where((entry) => entry.value == maxScore)
            .first.key;
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
        matchFormat: resultTypes.join(' + '),
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
          content: Text(l10n.resultSaveError(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}