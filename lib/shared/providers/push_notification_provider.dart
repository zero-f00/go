import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/push_notification_service.dart';

/// PushNotificationService プロバイダー
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService.instance;
});

/// プッシュ通知初期化状態プロバイダー
final pushNotificationInitializedProvider = StateProvider<bool>((ref) {
  return false;
});

/// FCMトークンプロバイダー
final fcmTokenProvider = StateProvider<String?>((ref) {
  final service = ref.watch(pushNotificationServiceProvider);
  return service.fcmToken;
});

/// プッシュ通知初期化を実行するプロバイダー
final pushNotificationInitializerProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(pushNotificationServiceProvider);

  try {
    final success = await service.initialize();

    if (success) {
      ref.read(pushNotificationInitializedProvider.notifier).state = true;
      ref.read(fcmTokenProvider.notifier).state = service.fcmToken;
    }

    return success;
  } catch (e) {
    return false;
  }
});