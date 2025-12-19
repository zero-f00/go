import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../../data/models/notification_model.dart';
import 'auth_provider.dart';

/// NotificationService プロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// 未読通知数をリアルタイムで監視するプロバイダー
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final currentUser = ref.watch(currentFirebaseUserProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  // 認証されていない場合は0を返す
  if (currentUser == null) {
    return Stream.value(0);
  }

  try {
    return notificationService.watchUnreadNotificationCount(currentUser.uid);
  } catch (e) {
    return Stream.value(0);
  }
});

/// 未読通知があるかどうかを判定するプロバイダー
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

  return unreadCountAsync.when(
    data: (count) => count > 0,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// ユーザーの通知一覧をリアルタイムで監視するプロバイダー
final userNotificationsProvider = StreamProvider<List<NotificationData>>((ref) {
  final currentUser = ref.watch(currentFirebaseUserProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  // 認証されていない場合は空のリストを返す
  if (currentUser == null) {
    return Stream.value(<NotificationData>[]);
  }

  try {
    return notificationService.watchUserNotifications(currentUser.uid);
  } catch (e) {
    return Stream.value(<NotificationData>[]);
  }
});