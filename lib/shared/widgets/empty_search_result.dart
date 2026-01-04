import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../l10n/app_localizations.dart';

/// 検索結果が見つからなかった場合の統一コンポーネント
class EmptySearchResult extends StatelessWidget {
  /// 表示するアイコン
  final IconData icon;

  /// メインタイトル
  final String title;

  /// 詳細メッセージ
  final String message;

  /// 検索クエリ（結果に含める場合）
  final String? searchQuery;

  const EmptySearchResult({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.searchQuery,
  });

  /// ユーザー検索結果なし用のファクトリコンストラクタ
  static EmptySearchResult user(BuildContext context, String searchQuery) {
    final l10n = L10n.of(context);
    return EmptySearchResult(
      icon: Icons.search_off,
      title: l10n.userNotFound,
      message: l10n.userNotFoundWithQuery(searchQuery),
      searchQuery: searchQuery,
    );
  }

  /// ゲーム検索結果なし用のファクトリコンストラクタ
  static EmptySearchResult game(BuildContext context, String searchQuery) {
    final l10n = L10n.of(context);
    return EmptySearchResult(
      icon: Icons.search_off,
      title: l10n.gameNotFound,
      message: l10n.gameNotFoundWithQuery(searchQuery),
      searchQuery: searchQuery,
    );
  }

  /// イベント検索結果なし用のファクトリコンストラクタ
  static EmptySearchResult event(BuildContext context, String searchQuery) {
    final l10n = L10n.of(context);
    return EmptySearchResult(
      icon: Icons.search_off,
      title: l10n.eventNotFound,
      message: l10n.eventNotFoundWithQuery(searchQuery),
      searchQuery: searchQuery,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXXL,
              color: AppColors.overlayMedium,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
