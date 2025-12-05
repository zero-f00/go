import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../data/models/enhanced_match_result_model.dart';
import '../../../shared/widgets/app_text_field.dart';

/// 拡張された結果入力ダイアログ
class EnhancedResultInputDialog extends ConsumerStatefulWidget {
  final String eventId;
  final List<String> participants; // 参加者ID一覧
  final Map<String, String> participantNames; // ID -> 表示名
  final bool isTeamMatch;
  final Function(EnhancedMatchResult) onResultSubmitted;

  const EnhancedResultInputDialog({
    super.key,
    required this.eventId,
    required this.participants,
    required this.participantNames,
    required this.isTeamMatch,
    required this.onResultSubmitted,
  });

  @override
  ConsumerState<EnhancedResultInputDialog> createState() =>
      _EnhancedResultInputDialogState();
}

class _EnhancedResultInputDialogState
    extends ConsumerState<EnhancedResultInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _matchNameController = TextEditingController();
  final _gameTitleController = TextEditingController();
  final _notesController = TextEditingController();

  ResultType _selectedResultType = ResultType.ranking;
  String? _matchFormat;
  bool _isLoading = false;

  // 結果データの保存用
  Map<String, int> _rankings = {}; // participantId -> rank
  Map<String, int> _scores = {}; // participantId -> score
  Map<String, WinLossResult> _winLossResults = {}; // participantId -> result
  Map<String, int> _times = {}; // participantId -> milliseconds
  Map<String, bool> _achievements = {}; // participantId -> achieved
  Map<String, String> _achievementRatings = {}; // participantId -> rating

  @override
  void initState() {
    super.initState();
    _initializeResultMaps();
  }

  void _initializeResultMaps() {
    for (final participantId in widget.participants) {
      _rankings[participantId] = 1;
      _scores[participantId] = 0;
      _winLossResults[participantId] = WinLossResult.draw;
      _times[participantId] = 0;
      _achievements[participantId] = false;
      _achievementRatings[participantId] = '';
    }
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _gameTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 800,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfo(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildResultTypeSelector(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildResultInput(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildNotes(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_score,
            color: AppColors.primary,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          const Expanded(
            child: Text(
              '試合結果入力',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _matchNameController,
          decoration: const InputDecoration(
            labelText: '試合名 *',
            hintText: '例: 準決勝、第3戦',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '試合名を入力してください';
            }
            return null;
          },
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextFormField(
          controller: _gameTitleController,
          decoration: const InputDecoration(
            labelText: 'ゲームタイトル',
            hintText: '例: スプラトゥーン3、ストリートファイター6',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        DropdownButtonFormField<String>(
          value: _matchFormat,
          decoration: const InputDecoration(
            labelText: '試合形式',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'tournament', child: Text('トーナメント')),
            DropdownMenuItem(value: 'league', child: Text('リーグ戦')),
            DropdownMenuItem(value: 'free', child: Text('フリー対戦')),
            DropdownMenuItem(value: 'practice', child: Text('練習試合')),
            DropdownMenuItem(value: 'other', child: Text('その他')),
          ],
          onChanged: (value) {
            setState(() {
              _matchFormat = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildResultTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '結果記録方式',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Wrap(
          spacing: AppDimensions.spacingM,
          runSpacing: AppDimensions.spacingM,
          children: ResultType.values.map((type) {
            final isSelected = _selectedResultType == type;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: AppDimensions.iconS,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedResultType = type;
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: AppDimensions.iconS,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  _selectedResultType.description,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultInput() {
    switch (_selectedResultType) {
      case ResultType.ranking:
        return _buildRankingInput();
      case ResultType.score:
        return _buildScoreInput();
      case ResultType.winLoss:
        return _buildWinLossInput();
      case ResultType.timeAttack:
        return _buildTimeInput();
      case ResultType.achievement:
        return _buildAchievementInput();
      case ResultType.custom:
        return _buildCustomInput();
    }
  }

  Widget _buildRankingInput() {
    final sortedParticipants = List<String>.from(widget.participants)
      ..sort((a, b) => (_rankings[a] ?? 999).compareTo(_rankings[b] ?? 999));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '順位入力',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...sortedParticipants.map((participantId) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    child: DropdownButtonFormField<int>(
                      value: _rankings[participantId],
                      decoration: const InputDecoration(
                        labelText: '順位',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                        ),
                      ),
                      items: List.generate(
                        widget.participants.length,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1}位'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _rankings[participantId] = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Text(
                      widget.participantNames[participantId] ?? participantId,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_rankings[participantId] == 1)
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: AppDimensions.iconM,
                    ),
                  if (_rankings[participantId] == 2)
                    Icon(
                      Icons.emoji_events,
                      color: Colors.grey[400],
                      size: AppDimensions.iconM,
                    ),
                  if (_rankings[participantId] == 3)
                    Icon(
                      Icons.emoji_events,
                      color: Colors.brown[400],
                      size: AppDimensions.iconM,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScoreInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'スコア入力',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...widget.participants.map((participantId) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.participantNames[participantId] ?? participantId,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: _scores[participantId]?.toString() ?? '0',
                      decoration: const InputDecoration(
                        labelText: 'スコア',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _scores[participantId] = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWinLossInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '勝敗入力',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...widget.participants.map((participantId) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.participantNames[participantId] ?? participantId,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ToggleButtons(
                    isSelected: [
                      _winLossResults[participantId] == WinLossResult.win,
                      _winLossResults[participantId] == WinLossResult.draw,
                      _winLossResults[participantId] == WinLossResult.loss,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _winLossResults[participantId] = WinLossResult.values[index];
                      });
                    },
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    selectedColor: Colors.white,
                    fillColor: AppColors.primary,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('勝利'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('引分'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('敗北'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTimeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タイム入力',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...widget.participants.map((participantId) {
          final minutes = (_times[participantId] ?? 0) ~/ 60000;
          final seconds = ((_times[participantId] ?? 0) % 60000) ~/ 1000;
          final milliseconds = (_times[participantId] ?? 0) % 1000;

          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantNames[participantId] ?? participantId,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: minutes.toString(),
                          decoration: const InputDecoration(
                            labelText: '分',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final min = int.tryParse(value) ?? 0;
                            setState(() {
                              _times[participantId] =
                                  min * 60000 +
                                  ((_times[participantId] ?? 0) % 60000);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: TextFormField(
                          initialValue: seconds.toString(),
                          decoration: const InputDecoration(
                            labelText: '秒',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final sec = int.tryParse(value) ?? 0;
                            setState(() {
                              final min = (_times[participantId] ?? 0) ~/ 60000;
                              final ms = (_times[participantId] ?? 0) % 1000;
                              _times[participantId] =
                                  min * 60000 + sec * 1000 + ms;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: TextFormField(
                          initialValue: milliseconds.toString(),
                          decoration: const InputDecoration(
                            labelText: 'ミリ秒',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final ms = int.tryParse(value) ?? 0;
                            setState(() {
                              final totalMs = (_times[participantId] ?? 0);
                              _times[participantId] =
                                  (totalMs ~/ 1000) * 1000 + ms;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAchievementInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '達成度入力',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        ...widget.participants.map((participantId) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantNames[participantId] ?? participantId,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Row(
                    children: [
                      Checkbox(
                        value: _achievements[participantId] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _achievements[participantId] = value ?? false;
                          });
                        },
                      ),
                      const Text('達成'),
                      const SizedBox(width: AppDimensions.spacingL),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _achievementRatings[participantId],
                          decoration: const InputDecoration(
                            labelText: '評価',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: '', child: Text('なし')),
                            DropdownMenuItem(value: 'S', child: Text('S')),
                            DropdownMenuItem(value: 'A', child: Text('A')),
                            DropdownMenuItem(value: 'B', child: Text('B')),
                            DropdownMenuItem(value: 'C', child: Text('C')),
                            DropdownMenuItem(value: '★★★', child: Text('★★★')),
                            DropdownMenuItem(value: '★★', child: Text('★★')),
                            DropdownMenuItem(value: '★', child: Text('★')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _achievementRatings[participantId] = value ?? '';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCustomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カスタム結果入力',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        const Text(
          '結果詳細は備考欄に記入してください',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return AppTextFieldMultiline(
      controller: _notesController,
      label: '備考',
      hintText: 'メモ、特記事項など',
      maxLines: 3,
      doneButtonText: '完了',
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusL),
          bottomRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
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
      ),
    );
  }

  Future<void> _submitResult() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 結果データを構築
      final results = widget.participants.map((participantId) {
        return ParticipantResult(
          participantId: participantId,
          rank: _selectedResultType == ResultType.ranking
              ? _rankings[participantId]
              : null,
          score: _selectedResultType == ResultType.score
              ? _scores[participantId]
              : null,
          winLossResult: _selectedResultType == ResultType.winLoss
              ? _winLossResults[participantId]
              : null,
          timeMillis: _selectedResultType == ResultType.timeAttack
              ? _times[participantId]
              : null,
          achievement: _selectedResultType == ResultType.achievement
              ? AchievementResult(
                  achieved: _achievements[participantId] ?? false,
                  rating: _achievementRatings[participantId]?.isNotEmpty == true
                      ? _achievementRatings[participantId]
                      : null,
                )
              : null,
        );
      }).toList();

      final now = DateTime.now();
      final matchResult = EnhancedMatchResult(
        eventId: widget.eventId,
        matchName: _matchNameController.text,
        resultType: _selectedResultType,
        results: results,
        isTeamMatch: widget.isTeamMatch,
        matchFormat: _matchFormat,
        gameTitle: _gameTitleController.text.isNotEmpty
            ? _gameTitleController.text
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      widget.onResultSubmitted(matchResult);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}