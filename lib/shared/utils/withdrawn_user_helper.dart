import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../l10n/app_localizations.dart';

/// 退会ユーザー表示用のヘルパークラス
/// UI上で退会したユーザーを適切に表示するためのユーティリティ
class WithdrawnUserHelper {
  /// 退会ユーザー表示用のデフォルト表示ID
  static const String withdrawnUserDisplayId = 'withdrawn_user';

  /// ユーザーが退会済み（非アクティブ）かどうかを判定
  static bool isUserWithdrawn(UserData? userData) {
    return userData != null && !userData.isActive;
  }

  /// 退会ユーザーの表示名を取得（L10n対応版）
  static String getWithdrawnDisplayName(BuildContext context) {
    return L10n.of(context).withdrawnUserDisplayName;
  }

  /// 表示用ユーザー名を取得（L10n対応版）
  /// 退会ユーザーの場合はローカライズされた「退会したユーザー」を返す
  static String getDisplayUsername(BuildContext context, UserData? userData) {
    if (userData == null) return getWithdrawnDisplayName(context);
    return isUserWithdrawn(userData) ? getWithdrawnDisplayName(context) : userData.username;
  }

  /// 表示用ユーザーIDを取得
  /// 退会ユーザーの場合は「withdrawn_user」を返す
  static String getDisplayUserId(UserData? userData) {
    if (userData == null) return withdrawnUserDisplayId;
    return isUserWithdrawn(userData) ? withdrawnUserDisplayId : userData.userId;
  }

  /// 表示用アバターURLを取得
  /// 退会ユーザーの場合はnullを返す（デフォルトアイコン表示）
  static String? getDisplayAvatarUrl(UserData? userData) {
    if (userData == null || isUserWithdrawn(userData)) return null;
    return userData.photoUrl;
  }

  /// ユーザー情報を退会ユーザー用にマスクした表示用データを作成（L10n対応版）
  static UserDisplayInfo getMaskedUserInfo(BuildContext context, UserData? userData) {
    final withdrawnDisplayName = getWithdrawnDisplayName(context);

    if (userData == null) {
      return UserDisplayInfo(
        username: withdrawnDisplayName,
        userId: withdrawnUserDisplayId,
        photoUrl: null,
        isWithdrawn: true,
      );
    }

    if (isUserWithdrawn(userData)) {
      return UserDisplayInfo(
        username: withdrawnDisplayName,
        userId: withdrawnUserDisplayId,
        photoUrl: null,
        isWithdrawn: true,
      );
    }

    return UserDisplayInfo(
      username: userData.username,
      userId: userData.userId,
      photoUrl: userData.photoUrl,
      isWithdrawn: false,
    );
  }
}

/// 表示用ユーザー情報クラス
class UserDisplayInfo {
  final String username;
  final String userId;
  final String? photoUrl;
  final bool isWithdrawn;

  const UserDisplayInfo({
    required this.username,
    required this.userId,
    this.photoUrl,
    required this.isWithdrawn,
  });
}
