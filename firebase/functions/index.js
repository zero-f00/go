const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Firebase Admin SDK初期化
admin.initializeApp();

/**
 * Firestore通知作成時に自動でプッシュ通知を送信
 */
exports.sendPushNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    try {
      const notificationData = snapshot.data();
      const { toUserId, title, message, type, data } = notificationData;

      console.log('🔔 Sending push notification to user:', toUserId);

      // ユーザーのFCMトークンを取得
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(toUserId)
        .get();

      if (!userDoc.exists) {
        console.log('❌ User not found:', toUserId);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('❌ FCM token not found for user:', toUserId);
        return;
      }

      console.log('📱 Using FCM token:', fcmToken.substring(0, 50) + '...');
      console.log('📝 Notification title:', title);
      console.log('📝 Notification body:', message);

      // プッシュ通知メッセージ構築
      const payload = {
        token: fcmToken,
        notification: {
          title: title,
          body: message,
        },
        data: {
          type: type,
          notificationId: context.params.notificationId,
          ...(data || {}),
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'go_notifications',
            priority: 'max',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: title,
                body: message,
              },
              badge: userData.unreadNotificationCount || 0,
              sound: 'default',
            },
          },
        },
      };

      // プッシュ通知送信
      const response = await admin.messaging().send(payload);
      console.log('✅ Push notification sent successfully:', response);

      return response;
    } catch (error) {
      console.error('❌ Error sending push notification:', error);
      throw error;
    }
  });

/**
 * 手動プッシュ通知送信用HTTP関数
 */
exports.sendManualPushNotification = functions.https.onCall(async (data, context) => {
  try {
    const { toUserId, title, message, type, notificationData } = data;

    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    console.log('🔔 Manual push notification request for user:', toUserId);

    // ユーザーのFCMトークンを取得
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(toUserId)
      .get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError('failed-precondition', 'FCM token not found');
    }

    // プッシュ通知送信
    const payload = {
      token: fcmToken,
      notification: {
        title: title,
        body: message,
      },
      data: {
        type: type || 'manual',
        ...(notificationData || {}),
      },
    };

    const response = await admin.messaging().send(payload);
    console.log('✅ Manual push notification sent:', response);

    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending manual push notification:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});