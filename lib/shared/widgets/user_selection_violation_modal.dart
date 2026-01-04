import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/participation_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import 'violation_report_dialog.dart';
import 'user_avatar_from_id.dart';

/// ユーザー選択付き違反報告モーダル
/// 参加者一覧からユーザーを選択して違反報告を行う統合コンポーネント
class UserSelectionViolationModal extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final VoidCallback? onViolationReported;

  const UserSelectionViolationModal({
    super.key,
    required this.eventId,
    required this.eventName,
    this.onViolationReported,
  });

  /// モーダルを表示する静的メソッド
  static void show({
    required BuildContext context,
    required String eventId,
    required String eventName,
    VoidCallback? onViolationReported,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => UserSelectionViolationModal(
          eventId: eventId,
          eventName: eventName,
          onViolationReported: onViolationReported,
        )._buildContent(context, scrollController),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        AppDimensions.spacingM,
        AppDimensions.spacingL,
        AppDimensions.spacingL + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: SingleChildScrollView(controller: scrollController, child: this),
    );
  }

  @override
  ConsumerState<UserSelectionViolationModal> createState() =>
      _UserSelectionViolationModalState();
}

class _UserSelectionViolationModalState
    extends ConsumerState<UserSelectionViolationModal> {
  List<ParticipationApplication> _participants = <ParticipationApplication>[];
  Map<String, UserData> _userDataCache = <String, UserData>{};
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipants() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 参加者データ取得開始

      // 承認済み参加者を取得
      final applicationsStream = ParticipationService.getEventApplications(
        widget.eventId,
      );
      final List<ParticipationApplication> applications =
          await applicationsStream.first;
      final List<ParticipationApplication> approvedApplications = applications
          .where((app) => app.status == ParticipationStatus.approved)
          .toList();

      // 承認済み参加者数を取得

      // ユーザーデータを取得
      final userRepository = UserRepository();
      for (final application in approvedApplications) {
        try {
          final userData =
              await userRepository.getUserById(application.userId) ??
              await userRepository.getUserByCustomId(application.userId);
          if (userData != null) {
            _userDataCache[application.userId] = userData;
          }
        } catch (e) {
          // ユーザーデータ取得エラー
        }
      }


      if (mounted) {
        setState(() {
          _participants = approvedApplications;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 参加者データ取得エラー
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<ParticipationApplication> get _filteredParticipants {
    if (_searchQuery.isEmpty) return _participants;

    return _participants.where((participant) {
      final userData = _userDataCache[participant.userId];
      final displayName =
          userData?.displayName ?? participant.userDisplayName;
      final username = userData?.username ?? '';

      return displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: AppDimensions.spacingM),
        _buildSearchField(),
        const SizedBox(height: AppDimensions.spacingM),
        _buildContent(),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Icon(Icons.report, color: AppColors.error, size: AppDimensions.iconM),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.violatorSelectionTitle,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                l10n.violatorSelectionDescription,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    final l10n = L10n.of(context);
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: l10n.searchParticipant,
        hintText: l10n.searchByNameOrId,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        filled: true,
        fillColor: AppColors.backgroundLight,
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildContent() {
    final l10n = L10n.of(context);
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: AppDimensions.iconXL,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.participantDataFetchFailed(_errorMessage!),
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: AppDimensions.fontSizeM,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              ElevatedButton(
                onPressed: _loadParticipants,
                child: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    final filteredParticipants = _filteredParticipants;

    if (filteredParticipants.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: AppDimensions.iconXL,
                color: AppColors.textLight,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                _searchQuery.isEmpty ? l10n.noApprovedParticipantsShort : l10n.noSearchResultsShort,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppDimensions.fontSizeL,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 400,
      child: ListView.builder(
        itemCount: filteredParticipants.length,
        itemBuilder: (context, index) {
          return _buildParticipantCard(filteredParticipants[index]);
        },
      ),
    );
  }

  Widget _buildParticipantCard(ParticipationApplication participant) {
    final userData = _userDataCache[participant.userId];
    final displayName =
        userData?.displayName ?? participant.userDisplayName;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: UserAvatarFromId(
          userId: participant.userId,
          size: 40,
          backgroundColor: AppColors.backgroundLight,
          iconColor: AppColors.textSecondary,
          borderColor: AppColors.borderLight,
          borderWidth: 1,
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: AppDimensions.fontSizeM,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (participant.gameUsername != null &&
                participant.gameUsername!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: AppDimensions.spacingXS),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  participant.gameUsername!,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            L10n.of(context).reportButton,
            style: TextStyle(
              color: AppColors.error,
              fontSize: AppDimensions.fontSizeS,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => _selectUserForViolationReport(
          participant.userId,
          displayName,
          participant.gameUsername,
        ),
      ),
    );
  }

  void _selectUserForViolationReport(
    String userId,
    String userName,
    String? gameUsername,
  ) {
    Navigator.pop(context); // モーダルを閉じる
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ViolationReportDialog(
        eventId: widget.eventId,
        eventName: widget.eventName,
        violatedUserId: userId,
        violatedUserName: userName,
        violatedUserGameUsername: gameUsername,
      ),
    ).then((result) {
      // 違反報告が完了したらコールバックを呼ぶ
      if (result == true && widget.onViolationReported != null) {
        widget.onViolationReported!();
      }
    });
  }
}
