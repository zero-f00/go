import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../l10n/app_localizations.dart';
import 'event_service.dart';
import 'image_upload_service.dart';

/// アプリケーション全体のエラーハンドリングサービス
class ErrorHandlerService {
  /// ユーザーフレンドリーなエラーメッセージを生成（多言語対応版）
  static String getLocalizedErrorMessage(BuildContext context, dynamic error) {
    final l10n = L10n.of(context);
    if (error == null) return l10n.errorUnknown;

    // カスタム例外の処理
    if (error is EventServiceException) {
      return error.message;
    }
    if (error is ImageUploadException) {
      return error.message;
    }

    // Firebase Firestore エラーの処理
    if (error is FirebaseException) {
      return _handleFirebaseErrorLocalized(context, error);
    }

    // Firebase Auth エラーの処理
    if (error is FirebaseAuthException) {
      return _handleAuthErrorLocalized(context, error);
    }

    // 一般的なエラーの処理
    final errorString = error.toString();

    if (errorString.contains('network') || errorString.contains('internet')) {
      return l10n.errorNetwork;
    }

    if (errorString.contains('permission')) {
      return l10n.errorPermission;
    }

    if (errorString.contains('timeout')) {
      return l10n.errorTimeout;
    }

    // デフォルトメッセージ
    return l10n.errorUnexpected;
  }

  /// ユーザーフレンドリーなエラーメッセージを生成（後方互換性のため維持）
  @Deprecated('Use getLocalizedErrorMessage instead for i18n support')
  static String getErrorMessage(dynamic error) {
    if (error == null) return '不明なエラーが発生しました';

    // カスタム例外の処理
    if (error is EventServiceException) {
      return error.message;
    }
    if (error is ImageUploadException) {
      return error.message;
    }

    // Firebase Firestore エラーの処理
    if (error is FirebaseException) {
      return _handleFirebaseError(error);
    }

    // Firebase Auth エラーの処理
    if (error is FirebaseAuthException) {
      return _handleAuthError(error);
    }

    // 一般的なエラーの処理
    final errorString = error.toString();

    if (errorString.contains('network') || errorString.contains('internet')) {
      return 'ネットワーク接続を確認してください';
    }

    if (errorString.contains('permission')) {
      return 'アクセス権限がありません';
    }

    if (errorString.contains('timeout')) {
      return '通信がタイムアウトしました。もう一度お試しください';
    }

    // デフォルトメッセージ
    return '予期しないエラーが発生しました。しばらく時間をおいてから再度お試しください';
  }

  /// Firebase関連エラーのメッセージを生成（多言語対応版）
  static String _handleFirebaseErrorLocalized(BuildContext context, FirebaseException error) {
    final l10n = L10n.of(context);
    switch (error.code) {
      case 'permission-denied':
        return l10n.errorPermission;
      case 'unavailable':
        return l10n.errorServiceUnavailable;
      case 'deadline-exceeded':
        return l10n.errorTimeout;
      case 'resource-exhausted':
        return l10n.errorResourceExhausted;
      case 'failed-precondition':
        return l10n.errorDataInconsistency;
      case 'aborted':
        return l10n.errorAborted;
      case 'out-of-range':
        return l10n.errorOutOfRange;
      case 'unimplemented':
        return l10n.errorNotImplemented;
      case 'internal':
        return l10n.errorInternal;
      case 'data-loss':
        return l10n.errorDataLoss;
      default:
        return l10n.errorFirebaseGeneric(error.message ?? l10n.errorUnknown);
    }
  }

  /// Firebase関連エラーのメッセージを生成（後方互換性のため維持）
  static String _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'アクセス権限がありません';
      case 'unavailable':
        return 'サービスが一時的に利用できません。しばらく時間をおいてから再度お試しください';
      case 'deadline-exceeded':
        return '通信がタイムアウトしました。もう一度お試しください';
      case 'resource-exhausted':
        return 'サービスの利用上限に達しています。しばらく時間をおいてからお試しください';
      case 'failed-precondition':
        return 'データの整合性に問題があります。アプリを再起動してお試しください';
      case 'aborted':
        return '処理が中断されました。もう一度お試しください';
      case 'out-of-range':
        return '入力値が範囲外です';
      case 'unimplemented':
        return 'この機能は現在利用できません';
      case 'internal':
        return 'サーバー内部エラーが発生しました';
      case 'data-loss':
        return 'データの破損が検出されました';
      default:
        return 'Firebase: ${error.message ?? "不明なエラー"}';
    }
  }

  /// Firebase Auth エラーのメッセージを生成（多言語対応版）
  static String _handleAuthErrorLocalized(BuildContext context, FirebaseAuthException error) {
    final l10n = L10n.of(context);
    switch (error.code) {
      case 'user-not-found':
        return l10n.errorUserNotFound;
      case 'wrong-password':
        return l10n.errorWrongPassword;
      case 'user-disabled':
        return l10n.errorUserDisabled;
      case 'too-many-requests':
        return l10n.errorTooManyRequests;
      case 'operation-not-allowed':
        return l10n.errorOperationNotAllowed;
      case 'invalid-email':
        return l10n.errorInvalidEmail;
      case 'email-already-in-use':
        return l10n.errorEmailAlreadyInUse;
      case 'weak-password':
        return l10n.errorWeakPassword;
      case 'network-request-failed':
        return l10n.errorNetwork;
      default:
        return l10n.errorAuthGeneric(error.message ?? l10n.errorUnknown);
    }
  }

  /// Firebase Auth エラーのメッセージを生成（後方互換性のため維持）
  static String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'ユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが正しくありません';
      case 'user-disabled':
        return 'このユーザーアカウントは無効化されています';
      case 'too-many-requests':
        return 'リクエスト数が上限に達しました。しばらく時間をおいてからお試しください';
      case 'operation-not-allowed':
        return 'この認証方法は許可されていません';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードが脆弱です。より強力なパスワードを設定してください';
      case 'network-request-failed':
        return 'ネットワーク接続を確認してください';
      default:
        return '認証エラー: ${error.message ?? "不明なエラー"}';
    }
  }

  /// エラーダイアログを表示
  static void showErrorDialog(BuildContext context, dynamic error, {String? title}) {
    final l10n = L10n.of(context);
    final errorMessage = getLocalizedErrorMessage(context, error);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          title ?? l10n.errorDialogTitle,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w700,
            color: AppColors.error,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
            ),
            if (_shouldShowRetryButton(error)) ...[
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.errorRetryHint,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// リトライボタンを表示すべきかどうかを判定
  static bool _shouldShowRetryButton(dynamic error) {
    if (error is FirebaseException) {
      return ['unavailable', 'deadline-exceeded', 'aborted', 'internal'].contains(error.code);
    }
    if (error is FirebaseAuthException) {
      return ['too-many-requests', 'network-request-failed'].contains(error.code);
    }
    return false;
  }

  /// エラー付きスナックバーを表示
  static void showErrorSnackBar(BuildContext context, dynamic error) {
    final l10n = L10n.of(context);
    final errorMessage = getLocalizedErrorMessage(context, error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: AppDimensions.iconS,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: _shouldShowRetryButton(error)
            ? SnackBarAction(
                label: l10n.retryButtonText,
                textColor: Colors.white,
                onPressed: () {
                  // リトライ処理は呼び出し元で実装
                },
              )
            : null,
      ),
    );
  }

  /// 成功メッセージのスナックバーを表示
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: AppDimensions.iconS,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 情報メッセージのスナックバーを表示
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: AppDimensions.iconS,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// エラーをログに記録
  static void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    // リリースビルドではログ出力しない
  }

  /// 操作の成功をログに記録
  static void logSuccess(String operation, [String? details]) {
    // リリースビルドではログ出力しない
  }
}

/// エラーハンドリング付きで非同期操作を実行するヘルパー関数
class SafeOperation {
  /// エラーハンドリング付きで非同期操作を実行
  static Future<T?> execute<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String? operationName,
    bool showErrorDialog = true,
    bool showErrorSnackBar = false,
    Function(dynamic)? onError,
    Function(T)? onSuccess,
  }) async {
    try {
      final result = await operation();

      if (operationName != null) {
        ErrorHandlerService.logSuccess(operationName);
      }

      if (onSuccess != null) {
        onSuccess(result);
      }

      return result;
    } catch (error, stackTrace) {
      if (operationName != null) {
        ErrorHandlerService.logError(operationName, error, stackTrace);
      }

      if (context.mounted) {
        if (showErrorDialog) {
          ErrorHandlerService.showErrorDialog(context, error);
        } else if (showErrorSnackBar) {
          ErrorHandlerService.showErrorSnackBar(context, error);
        }
      }

      if (onError != null) {
        onError(error);
      }

      return null;
    }
  }

  /// 複数の操作を順次実行（エラー時は中断）
  static Future<List<T>> executeSequential<T>({
    required List<Future<T> Function()> operations,
    required BuildContext context,
    String? operationName,
    bool showErrorDialog = true,
    Function(dynamic, int)? onError,
    Function(List<T>)? onSuccess,
  }) async {
    final results = <T>[];

    for (int i = 0; i < operations.length; i++) {
      final result = await execute<T>(
        operation: operations[i],
        context: context,
        operationName: operationName != null ? '$operationName (${i + 1}/${operations.length})' : null,
        showErrorDialog: showErrorDialog,
        onError: onError != null ? (error) => onError(error, i) : null,
      );

      if (result == null) {
        return results; // エラー時は現在までの結果を返す
      }

      results.add(result);
    }

    if (onSuccess != null) {
      onSuccess(results);
    }

    return results;
  }
}