import '../../data/models/user_model.dart';

/// 退会ユーザー表示用のヘルパークラス
/// UI上で退会したユーザーを適切に表示するためのユーティリティ
class WithdrawnUserHelper {
  /// 退会ユーザー表示用の定数
  static const String withdrawnUserDisplayName = '退会したユーザー';
  static const String withdrawnUserDisplayId = 'withdrawn_user';

  /// ユーザーが退会済み（非アクティブ）かどうかを判定
  static bool isUserWithdrawn(UserData? userData) {
    return userData != null && !userData.isActive;
  }

  /// 表示用ユーザー名を取得
  /// 退会ユーザーの場合は「退会したユーザー」を返す
  static String getDisplayUsername(UserData? userData) {
    if (userData == null) return withdrawnUserDisplayName;
    return isUserWithdrawn(userData) ? withdrawnUserDisplayName : userData.username;
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

  /// ユーザー情報を退会ユーザー用にマスクした表示用データを作成
  static UserDisplayInfo getMaskedUserInfo(UserData? userData) {
    if (userData == null) {
      return UserDisplayInfo(
        username: withdrawnUserDisplayName,
        userId: withdrawnUserDisplayId,
        photoUrl: null,
        isWithdrawn: true,
      );
    }

    if (isUserWithdrawn(userData)) {
      return UserDisplayInfo(
        username: withdrawnUserDisplayName,
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