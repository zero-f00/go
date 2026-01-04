import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../l10n/app_localizations.dart';

/// ゲームプロフィール用SNS機能のミックスイン
mixin GameProfileSNSMixin {
  /// SNSアカウント情報（優先順位付き）
  Widget buildSocialLinksInfo({
    required BuildContext context,
    required GameProfile profile,
    required UserData? userData,
    required Widget Function({
      required String title,
      required IconData icon,
      required Widget child,
    }) buildSection,
    required L10n l10n,
  }) {
    // ゲーム専用SNSとグローバルSNSを統合
    final Map<String, String> effectiveSocialLinks = _getEffectiveSocialLinks(profile, userData);

    if (effectiveSocialLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    return buildSection(
      title: l10n.snsAccountsTitle,
      icon: Icons.share,
      child: Wrap(
        spacing: AppDimensions.spacingM,
        runSpacing: AppDimensions.spacingM,
        children: effectiveSocialLinks.entries
            .map((entry) => _buildSocialLinkButton(context, entry.key, entry.value, profile, l10n))
            .toList(),
      ),
    );
  }

  /// 有効なSNSリンクを取得（優先順位: ゲーム専用 > グローバル）
  Map<String, String> _getEffectiveSocialLinks(GameProfile profile, UserData? userData) {
    final Map<String, String> result = {};

    // まずグローバルSNSを追加
    if (userData?.socialLinks != null) {
      result.addAll(userData!.socialLinks!);
    }

    // ゲーム専用SNSで上書き（優先）
    if (profile.gameSocialLinks != null) {
      profile.gameSocialLinks!.forEach((key, value) {
        if (value.trim().isEmpty) {
          // 空文字の場合は削除（非表示）
          result.remove(key);
        } else {
          // 値がある場合は上書き
          result[key] = value;
        }
      });
    }

    return result;
  }

  /// SNSリンクボタンを構築
  Widget _buildSocialLinkButton(BuildContext context, String platform, String username, GameProfile profile, L10n l10n) {
    // プラットフォーム情報（ディープリンクとWebURL対応）
    final Map<String, Map<String, dynamic>> platformInfo = {
      'twitter': {
        'icon': Icons.close,
        'label': 'X',
        'color': const Color(0xFF1DA1F2),
        'deepLink': 'twitter://user?screen_name=$username',
        'webUrl': 'https://x.com/$username',
        'displayFormat': '@$username',
      },
      'tiktok': {
        'icon': Icons.music_note,
        'label': 'TikTok',
        'color': const Color(0xFFFF0050),
        'deepLink': null, // TikTokのディープリンクは複雑なため、Web優先
        'webUrl': 'https://www.tiktok.com/@$username',
        'displayFormat': '@$username',
      },
      'youtube': {
        'icon': Icons.play_circle_fill,
        'label': 'YouTube',
        'color': const Color(0xFFFF0000),
        'deepLink': 'youtube://www.youtube.com/@$username',
        'webUrl': 'https://youtube.com/@$username',
        'displayFormat': '@$username',
      },
      'instagram': {
        'icon': Icons.camera_alt,
        'label': 'Instagram',
        'color': const Color(0xFFE4405F),
        'deepLink': 'instagram://user?username=$username',
        'webUrl': 'https://instagram.com/$username',
        'displayFormat': '@$username',
      },
      'twitch': {
        'icon': Icons.videogame_asset,
        'label': 'Twitch',
        'color': const Color(0xFF9146FF),
        'deepLink': 'twitch://stream/$username',
        'webUrl': 'https://twitch.tv/$username',
        'displayFormat': username,
      },
      'discord': {
        'icon': Icons.chat,
        'label': 'Discord',
        'color': const Color(0xFF5865F2),
        'deepLink': null, // Discordの個別プロフィールURLは一般的ではない
        'webUrl': 'https://discord.com', // Discordのホームページにリダイレクト
        'displayFormat': username, // username#1234形式で表示
      },
    };

    final info = platformInfo[platform];
    if (info == null) return const SizedBox.shrink();

    // ゲーム専用かグローバルかを判定
    final bool isGameSpecific = profile.gameSocialLinks?.containsKey(platform) ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => platform == 'discord'
          ? _copyDiscordUsername(username, (success, message) {
              _showCopyResult(context, success, message, l10n);
            })
          : _openSocialProfile(
              deepLink: info['deepLink'] as String?,
              webUrl: info['webUrl'] as String,
              platform: platform,
            ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: (info['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: (info['color'] as Color).withValues(alpha: 0.3),
              width: isGameSpecific ? 2 : 1, // ゲーム専用は太いボーダー
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    info['icon'] as IconData,
                    color: info['color'] as Color,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        info['label'] as String,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: info['color'] as Color,
                        ),
                      ),
                      Text(
                        info['displayFormat'] as String,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeXS,
                          color: (info['color'] as Color).withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SNSプロフィールを開く（ディープリンク→Webフォールバック）
  Future<void> _openSocialProfile({
    required String? deepLink,
    required String webUrl,
    required String platform,
  }) async {
    try {
      // 1. ディープリンクを試行（アプリが利用可能な場合）
      if (deepLink != null) {
        final deepLinkUri = Uri.parse(deepLink);
        if (await canLaunchUrl(deepLinkUri)) {
          final launched = await launchUrl(
            deepLinkUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return;
        }
      }

      // 2. Webフォールバック
      final webUri = Uri.parse(webUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // 最終フォールバック：Webブラウザ内で開く
      try {
        final webUri = Uri.parse(webUrl);
        await launchUrl(
          webUri,
          mode: LaunchMode.inAppWebView,
        );
      } catch (fallbackError) {
        // 最終的にもフォールバックが失敗した場合は無視
      }
    }
  }

  /// Discord IDをクリップボードにコピー（コールバック付き）
  Future<void> _copyDiscordUsername(String discordId, [Function(bool, String)? onResult]) async {
    try {
      await Clipboard.setData(ClipboardData(text: discordId));
      onResult?.call(true, discordId);
    } catch (e) {
      onResult?.call(false, e.toString());
    }
  }

  /// コピー結果をトースト表示
  void _showCopyResult(BuildContext context, bool success, String message, L10n l10n) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              success
                ? l10n.discordIdCopied(message)
                : l10n.copyFailedWithError(message),
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: success ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

}