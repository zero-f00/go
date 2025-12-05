# ユーザー退会機能の設計・実装資料

## 概要

本資料は、イベント管理アプリケーションにおけるユーザー退会機能の実装に向けた包括的な設計ドキュメントです。現在の実装を詳細に分析し、個人情報保護法に準拠しながらデータ整合性を保つための段階的削除アプローチを提案しています。

## 法的背景と要件

### 個人情報保護法上の要件

1. **努力義務としての削除**
   - 利用目的がなくなった個人データは「遅滞なく消去するよう努める」（努力義務）
   - 完全な物理削除が法的に必須ではない

2. **合理的な保持目的**
   - 不正利用対策・トラブル対応・法定保存等の合理的目的があれば一定期間の保持は可能
   - ただし、保持期間・目的・方法を明確に定める必要がある

3. **プライバシーポリシーでの明記**
   - 退会後のデータ取り扱い（保持期間・目的・可視状態）を明示する義務

## 現在の課題

### 主要な懸念事項

1. **データ整合性の問題**
   - ユーザーが削除された後、他のユーザーが関連情報にアクセスできなくなる
   - イベント情報、プロフィール、参加履歴などが失われる

2. **UI表示の問題**
   - ユーザーIDが削除されると、FirebaseコレクションIDが直接表示される可能性
   - 削除されたユーザーの参照で画面が壊れる可能性

3. **個人情報保護上の問題**
   - 利用目的のない個人データの継続保持はリスク
   - 本人識別可能な情報の適切な匿名化が必要

4. **複雑なデータ関連性**
   - ユーザーが作成・関与したデータが多岐にわたる
   - 完全削除すると他のユーザーの体験に影響

## 現在のデータ構造分析

### 1. UserDataモデル (`lib/data/models/user_model.dart`)

**現在の実装（確認済み）:**
```dart
class UserData extends Equatable {
  final String id;              // Firebase Auth UID（line 8）
  final String userId;          // カスタムユーザーID（line 11）
  final String username;        // 表示名（line 14）
  final String email;           // メールアドレス（line 17）
  final String? bio;            // 自己紹介（line 20）
  final String? contact;        // 連絡先情報（line 23）
  final List<String> favoriteGameIds; // お気に入りゲーム（line 26）
  final String? photoUrl;       // プロフィール画像URL（line 29）
  final DateTime createdAt;     // アカウント作成日（line 32）
  final DateTime updatedAt;     // 最終更新日（line 35）
  final bool isSetupCompleted;  // 初回設定完了フラグ（line 38）
  final bool isActive;          // アクティブ状態（line 41）✅
  final bool showHostedEvents;  // 主催イベント表示設定（line 44）
  final bool showParticipatingEvents; // 参加予定イベント表示設定（line 46）
  final bool showManagedEvents; // 共同編集者イベント表示設定（line 49）
  final bool showParticipatedEvents; // 過去参加済みイベント表示設定（line 52）
}
```

**重要な既存機能:**
- `isActive`フラグが既に実装済み（line 41, デフォルト値: true）✅
- バリデーション機能あり
- JSON変換機能完備（fromFirestore, toJson）
- **追加フィールドは不要**: 退会時完結型のため、既存フィールドで十分

### 2. Eventモデル (`lib/data/models/event_model.dart`)

```dart
class Event {
  final String createdBy;        // イベント作成者
  final List<String> managerIds; // 運営者リスト
  final List<String> participantIds; // 参加者リスト
  final EventStatus status;      // draft, published, cancelled, completed
  // ... その他のフィールド
}
```

**データ関連性:**
- イベント作成者: `createdBy`
- 共同運営者: `managerIds`
- 参加者: `participantIds`

### 3. ParticipationApplicationモデル (`lib/shared/services/participation_service.dart`)

```dart
class ParticipationApplication {
  final String userId;          // 申込みユーザー
  final String eventId;         // イベントID
  final ApplicationStatus status; // pending, approved, rejected
  // ... その他のフィールド
}
```

### 4. その他の関連モデル

- **FriendRequestモデル**: `fromUserId`, `toUserId`
- **GameProfileモデル**: `userId`との関連
- **NotificationDataモデル**: `toUserId`, `fromUserId`

## 推奨削除戦略: 段階的削除＋匿名化アプローチ

### 基本方針

1. **法的コンプライアンス重視**
   - 個人情報保護法に準拠した段階的削除
   - 合理的な保持目的がある期間のみデータを保持

2. **退会時完結型プロセス**
   - **即時削除**: 個人識別情報（名前、メール、画像等）
   - **匿名化保持**: システム整合性に必要なデータ（永続保持）
   - **運用負荷なし**: 退会処理ですべて完了

3. **既存の`isActive`フラグを活用**
   - 新しいフィールドを追加せずに済む
   - 既存のコードとの互換性を保つ

4. **透明性の確保**
   - プライバシーポリシーでの明確な記載
   - ユーザーへの十分な説明

### 実装段階

#### フェーズ1: Firebase Auth削除 + 個人情報匿名化

```dart
// 退会時完結型ユーザー削除処理
Future<void> deactivateUser(String userId) async {
  final user = FirebaseAuth.instance.currentUser;
  final anonymizedUsername = 'deleted_user_${DateTime.now().millisecondsSinceEpoch}';

  try {
    // Step 1: Firebase Authentication アカウントの削除
    if (user != null && user.uid == userId) {
      await user.delete(); // Firebase Authから完全削除
      print('Firebase Auth user deleted: $userId');
    }

    // Step 2: Firestoreユーザーデータの匿名化（退会時完結）
    await _firestore.collection('users').doc(userId).update({
      'isActive': false,
      'updatedAt': Timestamp.now(),
      // 個人識別情報の即座削除
      'username': anonymizedUsername,
      'email': null, // 個人識別情報なので即座削除
      'bio': null,
      'contact': null,
      'photoUrl': null,
    });

    // Step 3: Firebase Storage内のプロフィール画像削除
    await _deleteUserImages(userId);

    // Step 4: セッション無効化
    await FirebaseAuth.instance.signOut();

  } catch (e) {
    print('Error during user deactivation: $e');
    rethrow;
  }
}

String generateAnonymizedId(String originalUserId) {
  // 元のユーザーIDをハッシュ化して匿名ID生成
  final bytes = utf8.encode('${originalUserId}_${DateTime.now().millisecondsSinceEpoch}');
  return crypto.sha256.convert(bytes).toString().substring(0, 16);
}

// Firebase Storage画像削除
Future<void> _deleteUserImages(String userId) async {
  try {
    // プロフィール画像
    await FirebaseStorage.instance.ref('profile_images/$userId').delete();
    print('Profile image deleted for user: $userId');
  } catch (e) {
    // ファイルが存在しない場合のエラーハンドリング
    print('Profile image not found or already deleted: $e');
  }
}
```

#### フェーズ2: 表示レイヤーでの退会ユーザー制御

### **退会ユーザー表示方針**

**基本方針**: 退会ユーザーは「退会したユーザー」として表示し、個人情報へのアクセスを完全遮断

#### **表示制御の実装**
```dart
// 退会ユーザーの統一表示
String getDisplayUsername(UserData? user) {
  if (user == null || !user.isActive) {
    return '退会したユーザー'; // 統一された匿名表示
  }
  return user.username;
}

String? getDisplayPhotoUrl(UserData? user) {
  if (user == null || !user.isActive) {
    return null; // デフォルトアバターを表示
  }
  return user.photoUrl;
}

// プロフィールへのアクセス制御
Widget buildUserProfileLink(UserData? user) {
  if (user == null || !user.isActive) {
    // タップ不可のグレーアウト表示
    return Text(
      '退会したユーザー',
      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
    );
  }

  // 通常のプロフィールリンク
  return GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/user_profile', arguments: user.userId),
    child: Text(
      user.username,
      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
    ),
  );
}
```

#### **各画面での具体的表示**

**1. イベント詳細画面 - 参加者リスト**
```dart
// 表示例
Widget buildParticipantsList() {
  return Column(
    children: participants.map((participant) {
      return ListTile(
        leading: CircleAvatar(
          backgroundImage: participant.isActive && participant.photoUrl != null
              ? NetworkImage(participant.photoUrl!)
              : null,
          backgroundColor: participant.isActive ? Colors.blue : Colors.grey,
          child: participant.isActive
              ? null
              : Icon(Icons.person, color: Colors.white54),
        ),
        title: buildUserProfileLink(participant),
        subtitle: Text(participant.isActive ? '参加者' : '（退会済み）'),
      );
    }).toList(),
  );
}
```

**2. イベント詳細画面 - 運営者情報**
```dart
// 運営者表示
運営者: getDisplayUsername(organizer)  // 「退会したユーザー」または実名
共同運営:
  - 田中太郎
  - 退会したユーザー
  - 山田花子
```

**3. 参加申込み一覧（運営者向け）**
```dart
参加申込み:
✅ 承認済み: 佐藤次郎
❌ 拒否: 退会したユーザー
⏳ 待機中: 鈴木三郎
```

#### **表示方針の理由**

1. **透明性の確保**
   - 参加者数の変動理由を明確化
   - イベント運営者の状況把握を支援

2. **プライバシー保護**
   - 個人特定情報は完全削除
   - プロフィールアクセスは不可

3. **システム整合性**
   - データの不整合を回避
   - 履歴の連続性を維持

4. **法的コンプライアンス**
   - 「退会したユーザー」は個人情報ではない
   - 合理的なサービス運営に必要な表示

#### フェーズ3: 関連データのクリーンアップ

```dart
// 参加申請の処理
Future<void> cleanupParticipationApplications(String userId) async {
  final applications = await _firestore
      .collection('participationApplications')
      .where('userId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .get();

  for (final doc in applications.docs) {
    await doc.reference.update({'status': 'withdrawn'});
  }
}

// フレンドリクエストの処理
Future<void> cleanupFriendRequests(String userId) async {
  // 送信済みリクエストをキャンセル
  final sentRequests = await _firestore
      .collection('friendRequests')
      .where('fromUserId', isEqualTo: userId)
      .where('status', isEqualTo: 'pending')
      .get();

  for (final doc in sentRequests.docs) {
    await doc.reference.update({'status': 'cancelled'});
  }
}
```

#### フェーズ4: イベント管理権限の移譲と匿名化

```dart
// イベント作成者が削除される場合の処理
Future<void> handleEventOwnershipTransfer(String deletedUserId, String anonymizedId) async {
  final ownedEvents = await _firestore
      .collection('events')
      .where('createdBy', isEqualTo: deletedUserId)
      .where('status', isEqualTo: 'published')
      .get();

  for (final doc in ownedEvents.docs) {
    final event = Event.fromFirestore(doc);

    if (event.managerIds.isNotEmpty) {
      // 最初の運営者に権限移譲
      await doc.reference.update({
        'createdBy': event.managerIds.first,
        'managerIds': event.managerIds.where((id) => id != event.managerIds.first).toList(),
        'originalCreator': anonymizedId, // 統計目的で匿名化IDを保持
      });
    } else {
      // 運営者がいない場合はイベントを下書きに戻し、匿名化
      await doc.reference.update({
        'status': 'draft',
        'createdBy': anonymizedId, // 匿名化IDに置換
      });
    }
  }
}


## Firebase Authアカウント削除の重要な考慮事項

### 削除のタイミング
```dart
// Firebase AuthとFirestoreは独立したサービスのため、
// 適切なセキュリティルールがあれば削除順序の制約はない

Future<void> userWithdrawalProcess(String userId) async {
  // 1. Firestoreデータを匿名化
  await anonymizeFirestoreData(userId);

  // 2. Firebase Storageファイルを削除
  await deleteStorageFiles(userId);

  // 3. Firebase Authアカウントを削除
  await FirebaseAuth.instance.currentUser?.delete();
}
```

### 再認証の必要性
```dart
// Firebase Auth削除前に再認証が必要な場合がある
Future<void> reauthenticateAndDelete() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // 機密性の高い操作のため、再認証が要求される可能性
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // 再認証が必要
        await _showReauthenticationDialog();
        await user.delete(); // 再認証後に削除実行
      }
    }
  }
}
```

## Firestoreセキュリティルールの更新

```javascript
// users コレクション - 現在の実装と推奨変更
// 現在の実装（firestore.rules:8-27）
match /users/{userId} {
  // 自分のデータの読み書き
  allow read, write: if request.auth != null && request.auth.uid == userId;

  // ⚠️現在：全ユーザーデータが読み取り可能（ゲスト含む）
  allow read: if true;
}

// 推奨変更：退会ユーザーアクセス制限
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;

  // アクティブユーザーのみ読み取り可能に変更
  allow read: if resource.data.isActive == true;
}

// events コレクション - 削除ユーザーは操作不可
match /events/{eventId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null &&
               (request.auth.uid == resource.data.createdBy ||
                request.auth.uid in resource.data.managerIds) &&
               // 削除ユーザーチェック
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isActive == true;
}

// gameProfiles コレクション - アクティブユーザーのみアクセス可
match /gameProfiles/{profileId} {
  allow read: if request.auth != null &&
              get(/databases/$(database)/documents/users/$(resource.data.userId)).data.isActive == true;
  allow write: if request.auth != null &&
               request.auth.uid == resource.data.userId &&
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isActive == true;
}
```

## 画像ファイルの処理

### Firebase Storage対応

```dart
// プロフィール画像の削除
Future<void> deleteUserImages(String userId) async {
  try {
    // プロフィール画像
    await _storage.ref('profile_images/$userId').delete();
  } catch (e) {
    // ファイルが存在しない場合のエラーハンドリング
  }

  // イベント画像は他の運営者が使用している可能性があるため削除しない
}
```

## データ分類と保持戦略

### データ分類による保持判断

#### 即時削除対象（個人識別情報）

**Firebase Authentication**
- **Authユーザーアカウント** → 即座に削除（`user.delete()`）
- **メールアドレス、パスワード、プロバイダー情報** → Firebase側で自動削除
- **理由**: 認証情報は個人識別情報の最たるもの、利用目的終了

**Firestoreユーザーデータ**
- **ユーザー名、メールアドレス、自己紹介、連絡先**
- **プロフィール画像、個人が特定できる画像**
- **理由**: 個人情報保護法上の個人情報に該当、利用目的終了

**Firebase Storage**
- **プロフィール画像ファイル** → 物理削除
- **理由**: 個人識別可能な画像データ

#### 匿名化保持対象（システム整合性・統計用）

**Firestoreのシステムデータ（永続保持）**
- **匿名化されたイベント参加履歴**
- **匿名化されたフレンド関係データ**
- **匿名化された統計データ**
- **Firebase UID** → 匿名化IDにマッピングして保持
- **理由**: システム整合性維持、不正利用防止、サービス改善

#### 退会時削除対象
- **ゲームプロフィール詳細情報**（退会時に即座削除）
- **未読通知履歴**（退会時に即座削除）
- **個人を特定できる参加申込み情報**（匿名化して保持）
- **理由**: 退会時に処理完了、運用負荷なし

### 合理的保持期間の根拠

```dart
// 保持期間設定の考え方
class DataRetentionPolicy {
  static const Duration ANONYMIZED_DATA_RETENTION = Duration(days: 365);
  static const String RETENTION_PURPOSE = 'システム整合性維持・不正利用防止・統計分析';

  // 退会処理時の保持期間設定
  static DateTime getScheduledDeletionDate() {
    return DateTime.now().add(ANONYMIZED_DATA_RETENTION);
  }

  // 保持目的の明確化
  static String getRetentionReason() {
    return '''
    退会後データ保持の目的:
    1. システム整合性維持（他ユーザーへの影響防止）
    2. 不正利用・なりすまし防止
    3. 紛争・トラブル対応
    4. サービス改善のための統計分析
    保持期間: 退会から1年間
    ''';
  }
}
```

## 通知機能の対応

### 通知データ処理方針

- **個人通知（退会ユーザー宛）**: 即座に削除（閲覧者不在のため保持不要）
- **個人通知（他ユーザー宛）**: 退会ユーザー関連部分を匿名化
- **システム通知**: 必要に応じて匿名化処理

```dart
// 削除されたユーザーに関する通知の処理
Future<void> cleanupNotifications(String userId) async {
  // 退会ユーザー宛ての通知履歴を全削除（過去の受信通知含む）
  final toUserNotifications = await _firestore
      .collection('notifications')
      .where('toUserId', isEqualTo: userId)
      .get();

  for (final doc in toUserNotifications.docs) {
    await doc.reference.delete();
    // 削除対象:
    // - イベント申込承認/拒否通知
    // - フレンドリクエスト通知
    // - システムお知らせ
    // - 過去の未読・既読全通知
    // 理由: 閲覧者不在 + 個人情報保護
  }

  // 削除されたユーザーからの通知は送信者名を匿名化
  final fromUserNotifications = await _firestore
      .collection('notifications')
      .where('fromUserId', isEqualTo: userId)
      .get();

  for (final doc in fromUserNotifications.docs) {
    await doc.reference.update({
      'fromUserId': null,
      'data.fromUserName': '退会したユーザー',
    });
  }
}
```

## 実装チェックリスト

### 必須実装項目

- [ ] ユーザー削除API エンドポイント
- [ ] `isActive`フラグによるソフト削除
- [ ] 表示レイヤーでの削除ユーザー処理
- [ ] 参加申請のクリーンアップ
- [ ] フレンド関係のクリーンアップ
- [ ] 通知データの処理
- [ ] プロフィール画像の削除
- [ ] イベント管理権限の移譲

### セキュリティ・プライバシー

- [ ] Firestoreセキュリティルールの更新
- [ ] 個人情報の即座削除
- [ ] データ最小化の実施
- [ ] GDPR準拠の確認

### テスト項目

- [ ] 削除ユーザーの表示テスト
- [ ] イベント管理権限移譲テスト
- [ ] データ整合性テスト
- [ ] セキュリティルールテスト

## 実装上の注意点

1. **トランザクション処理**
   - 複数のコレクション更新時はFirestore Transactionを使用

2. **エラーハンドリング**
   - 部分的な削除失敗時のロールバック戦略

3. **パフォーマンス**
   - 大量データの削除時はバッチ処理を活用

4. **監査ログ**
   - 削除操作のログ記録（管理者用）

## プライバシーポリシー記載例

```
第X条（退会後のデータ取り扱い）

1. ユーザーが退会された場合、以下の通りデータを処理いたします：

即時削除対象：
- お名前、メールアドレス、自己紹介、連絡先情報
- プロフィール画像、その他個人を特定できる情報

匿名化保持対象（永続保持）：
- システム整合性維持のため、匿名化された参加履歴
- 不正利用防止のため、匿名化された行動ログ
- サービス改善のため、匿名化された統計データ

2. 匿名化保持データは、元の個人を特定することができない形で処理され、
   以下の目的にのみ使用されます：
   - システムの安定稼働とデータ整合性の維持
   - 不正利用・なりすまし行為の防止
   - 紛争・トラブルが発生した際の対応
   - サービス品質向上のための統計分析

3. 退会処理は通常即座に完了し、個人を特定できる情報は全て削除されます。

4. 匿名化されたデータは個人特定不可能なため、継続的にサービス改善に活用されます。
```

## 本人からの削除・利用停止請求への対応

```dart
// 個人情報保護法に基づく削除・利用停止請求への対応
class PersonalDataRequestHandler {

  // 本人確認後の個人データ開示
  Future<Map<String, dynamic>> disclosePersonalData(String userId) async {
    final userData = await userRepository.getUserById(userId);
    if (userData == null || !userData.isActive) {
      return {'status': 'already_deleted', 'message': '該当するデータは既に削除されています'};
    }

    return {
      'personalData': {
        'username': userData.username,
        'email': userData.email,
        'bio': userData.bio,
        'contact': userData.contact,
        'createdAt': userData.createdAt.toIso8601String(),
      },
      'anonymizedData': {
        'eventParticipation': 'イベント参加履歴（匿名化済み）',
        'statistics': '統計データ（匿名化済み）',
      }
    };
  }

  // 利用停止請求への対応
  Future<bool> handleDataUsageStopRequest(String userId, List<String> targetDataTypes) async {
    // 個人識別情報の利用停止（即時削除）
    if (targetDataTypes.contains('personal_identifiable')) {
      await deactivateUser(userId);
      return true;
    }

    // 匿名化済みデータの利用停止（技術的に本人特定不可能なため対応困難）
    if (targetDataTypes.contains('anonymized_statistics')) {
      return false; // 匿名化済みのため個人への影響なし
    }

    return false;
  }
}
```

## 現在実装の問題点と対応

### ⚠️ **発見した問題点**

#### 1. 現在の`deleteUser`メソッドは危険
**場所**: `/lib/data/repositories/user_repository.dart:199-209`

```dart
// 現在の実装（問題あり）
Future<void> deleteUser(String userId) async {
  await _firestore.deleteDocument('users/$userId'); // ← 即座に物理削除
  await _userService.clearAllUserData();
}
```

**問題**:
- 即座にFirestoreから物理削除してしまう
- 法的リスク（個人情報保護法違反の可能性）
- UI破綻（他ユーザーからの参照エラー）
- データ整合性の破綻

#### 2. UserDataモデルの不足フィールド
現在の`UserData`には退会機能に必要な以下フィールドが不足：
- `deactivatedAt` (退会日時)
- `anonymizedId` (匿名化ID)

### ✅ **既存実装で良い部分**
- `isActive`フラグは既に実装済み（`user_model.dart:41`）
- ユーザー検索で`isActive`チェックが実装済み（`user_repository.dart:228,245,266`）
- **⚠️注意**: 現在のFirestoreセキュリティルールでは`isActive`フィルタリングなし（`firestore.rules:16 allow read: if true`）

## コスト最小化の実装戦略

### **フェーズ1: 最優先対応（必須）**

#### UserDataモデル拡張
```dart
class UserData extends Equatable {
  // 既存フィールド...
  final bool isActive;

  // 新規追加（必須）
  final DateTime? deactivatedAt;        // 退会日時
  final String? anonymizedId;           // 匿名化ID（システム整合性用）
}
```

#### 安全な削除メソッド実装
```dart
// UserRepositoryに追加
Future<void> deactivateUser(String userId) async {
  // 現在の危険な deleteUser() を置き換える

  // 1. Firebase Auth削除
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser?.uid == userId) {
    await currentUser!.delete();
  }

  // 2. Firestoreデータ匿名化（物理削除せず）
  final anonymizedId = _generateAnonymizedId(userId);
  await _firestore.updateDocument('users/$userId', {
    'isActive': false,
    'deactivatedAt': FieldValue.serverTimestamp(),
    'username': 'deleted_user_${DateTime.now().millisecondsSinceEpoch}',
    'email': null,
    'bio': null,
    'contact': null,
    'photoUrl': null,
    'anonymizedId': anonymizedId,
  });

  // 3. 関連データの同時処理（退会時に完結）
  await _cleanupRelatedData(userId, anonymizedId);

  // 4. Storage画像削除
  await _deleteUserImages(userId);
}

// 危険な deleteUser() は削除または非推奨にする
@deprecated
Future<void> deleteUser(String userId) async {
  throw Exception('deleteUser is deprecated. Use deactivateUser instead.');
}
```

### **フェーズ2: 関連データ処理（退会時実行）**

```dart
// 退会時に実行する関連データ処理
Future<void> _cleanupRelatedData(String userId, String anonymizedId) async {
  // ゲームプロフィール削除
  await _deleteGameProfiles(userId);

  // 未読通知削除
  await _deleteUnreadNotifications(userId);

  // 参加申込みの匿名化
  await _anonymizeParticipationApplications(userId, anonymizedId);

  // フレンドリクエストの匿名化
  await _anonymizeFriendRequests(userId, anonymizedId);

  // イベント管理権限の処理
  await _handleEventOwnership(userId, anonymizedId);
}
```

### **実装完了後のメリット**
- 運用負荷ゼロ（自動完結）
- 法的コンプライアンス確保
- システム安定性維持

## 緊急対応の必要性

**現在の`deleteUser`メソッドは即座に修正が必要**
- 法的コンプライアンス違反のリスク
- システム障害のリスク
- データ損失のリスク

**推奨対応順序（実装の優先度）**:
1. **緊急**: `UserData`モデル拡張（必須フィールド2つ追加）
2. **緊急**: `deactivateUser`メソッド実装（退会時完結型処理）
3. **緊急**: 既存`deleteUser`の無効化（`@deprecated`で安全化）
4. **緊急**: 関連データ処理実装（`_cleanupRelatedData`メソッド）
5. **中期**: Firestoreセキュリティルール更新（`isActive`フィルタリング追加）

**実装確認事項**:
- 現在のコード: `user_repository.dart:199-209`の`deleteUser`は即座修正要
- 現在のコード: `user_model.dart`には新フィールド2つが不足（`deactivatedAt`, `anonymizedId`）
- 現在のコード: `firestore.rules:16`でゲストユーザーも全データ読み取り可能

**退会時完結のメリット**:
- 運用負荷ゼロ（管理作業なし）
- 法的要件即座充足（個人情報即座削除）
- システム整合性維持（匿名化データ永続保持）

---

**作成日**: 2025-12-05
**対象バージョン**: Flutter 3.x, Firebase Firestore
**最終更新**: 退会時完結型の設計に変更（運用負荷ゼロ）