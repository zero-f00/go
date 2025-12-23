import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/user_model.dart';
import 'deep_link_service.dart';

/// ユーザープロフィール共有サービス
/// SNSやメッセージアプリでユーザープロフィール情報を共有する機能を提供
class UserProfileShareService {
  /// ユーザープロフィールを共有できるかどうかを判定
  static bool canShareUserProfile(UserData user) {
    // 非アクティブユーザーは共有不可
    if (!user.isActive) return false;
    // 初期設定未完了ユーザーは共有不可
    if (!user.isSetupCompleted && user.userId.trim().isEmpty) return false;
    return true;
  }

  /// ユーザープロフィールを共有する
  /// [sharePositionOrigin] はiPadでシェアシートの表示位置を指定するために必要
  static Future<void> shareUserProfile(
    UserData user, {
    Rect? sharePositionOrigin,
  }) async {
    if (!canShareUserProfile(user)) {
      if (kDebugMode) {
        print(
          'UserProfileShareService: Cannot share this user profile (isActive: ${user.isActive}, userId: ${user.userId})',
        );
      }
      return;
    }

    try {
      final shareText = _buildShareText(user);
      await Share.share(shareText, sharePositionOrigin: sharePositionOrigin);
    } catch (e) {
      if (kDebugMode) {
        print('UserProfileShareService: Share error - $e');
      }
      rethrow;
    }
  }

  /// 共有用テキストを生成
  static String _buildShareText(UserData user) {
    final buffer = StringBuffer();

    // ユーザー名
    buffer.writeln('【${user.username}】');
    buffer.writeln();

    // ユーザーID
    buffer.writeln('🆔 @${user.userId}');

    // 自己紹介（存在する場合）
    if (user.bio != null && user.bio!.isNotEmpty) {
      buffer.writeln();
      final bio =
          user.bio!.length > 100
              ? '${user.bio!.substring(0, 100)}...'
              : user.bio!;
      buffer.writeln(bio);
    }

    buffer.writeln();

    // プロフィール詳細URL
    final profileUrl = DeepLinkService.generateUserShareUrl(user.userId);
    buffer.writeln('▼ プロフィールはこちら');
    buffer.writeln(profileUrl);
    buffer.writeln();

    // ハッシュタグ
    buffer.write('#Go. #ゲーム仲間募集');

    return buffer.toString();
  }
}
