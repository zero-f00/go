import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';
import 'user_avatar.dart';

class UserSearchDialog extends StatefulWidget {
  final Function(UserData) onUserSelected;
  final String title;
  final String? description;

  const UserSearchDialog({
    super.key,
    required this.onUserSelected,
    required this.title,
    this.description,
  });

  static Future<UserData?> show(
    BuildContext context, {
    required Function(UserData) onUserSelected,
    String? title,
    String? description,
  }) async {
    final l10n = L10n.of(context);
    return showDialog<UserData>(
      context: context,
      barrierDismissible: true,
      builder: (context) => UserSearchDialog(
        onUserSelected: onUserSelected,
        title: title ?? l10n.userSearchTitle,
        description: description,
      ),
    );
  }

  @override
  State<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<UserSearchDialog> {
  final _searchController = TextEditingController();
  final _userRepository = UserRepository();
  List<UserData> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    final l10n = L10n.of(context);
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _userRepository.searchUsers(query, limit: 10);

      setState(() {
        _searchResults = results;
        _isLoading = false;
        if (results.isEmpty) {
          _errorMessage = l10n.userNotFoundError;
        }
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = l10n.userSearchError;
        _searchResults = [];
      });
    }
  }

  void _selectUser(UserData user) {
    widget.onUserSelected(user);
    Navigator.of(context).pop(user);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  _buildSearchField(),
                  Expanded(
                    child: _buildSearchResults(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppColors.accent,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    widget.description!,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _performSearch(),
        decoration: InputDecoration(
          hintText: l10n.userSearchHint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppDimensions.fontSizeM,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.accent,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _errorMessage = null;
                    });
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: AppDimensions.fontSizeM,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final l10n = L10n.of(context);
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              size: AppDimensions.iconXXL,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.enterUsernameOrId,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.searchingText,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              size: AppDimensions.iconXXL,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.userNotFoundError,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(UserData user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Material(
        color: AppColors.backgroundTransparent,
        child: InkWell(
          onTap: () => _selectUser(user),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                UserAvatar(
                  size: AppDimensions.iconXL,
                  avatarUrl: user.photoUrl,
                  backgroundColor: AppColors.overlayMedium,
                  iconColor: AppColors.textSecondary,
                  borderColor: AppColors.accent.withValues(alpha: 0.3),
                  borderWidth: 1,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '@${user.userId}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          user.bio!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.person_add,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}