# Firestore 複合インデックス管理

## 概要

このファイルではプロジェクトで使用するFirestoreの複合インデックスを管理します。
新しいクエリを実装する際は、必要なインデックスをここに記録してください。

## インデックス一覧

### 複合インデックス（Firebase Console > インデックス > 複合 タブ）

**設定手順**: Firebase Console → Firestore → インデックス → **複合** タブで設定

| コレクションID | フィールド1 | 順序1 | フィールド2 | 順序2 | フィールド3 | 順序3 | スコープ | インデックスID | ステータス | 説明 |
|---------------|------------|------|-----------|------|-----------|------|----------|---------------|-----------|------|
| events | createdBy | 昇順 | createdAt | 降順 | - | - | コレクション | 要作成 | **未作成** | ユーザー作成イベント一覧 |
| friendRequests | fromUserId | 昇順 | toUserId | 昇順 | - | - | コレクション | 必須作成 | 未作成 | フレンドリクエスト存在確認 |
| friendRequests | toUserId | 昇順 | status | 昇順 | createdAt | 降順 | コレクション | 必須作成 | 未作成 | 受信リクエスト一覧 |
| friendRequests | fromUserId | 昇順 | status | 昇順 | createdAt | 降順 | コレクション | 必須作成 | 未作成 | 送信リクエスト一覧 |
| friendships | user1Id | 昇順 | user2Id | 昇順 | - | - | コレクション | 必須作成 | 未作成 | フレンド関係確認 |
| notifications | toUserId | 昇順 | createdAt | 降順 | - | - | コレクション | 必須作成 | **要作成** | ユーザー通知一覧 |
| events | status | 昇順 | visibility | 昇順 | eventDate | 昇順 | コレクション | 要作成 | **未作成** | 公開イベント日付順一覧 |
| events | gameId | 昇順 | status | 昇順 | visibility | 昇順 | コレクション | 要作成 | **未作成** | ゲーム別公開イベント |
| events | createdBy | 昇順 | startDate | 昇順 | - | - | コレクション | 作成済み | **作成済み** | 運営者イベント取得（RecommendationService.getManagedEvents使用） |
| events | participantIds | 配列 | status | 昇順 | startDate | 昇順 | コレクション | 要作成 | **未作成** | 参加予定イベント（UserEventService使用） |
| events | participantIds | 配列 | status | 昇順 | endDate | 降順 | コレクション | 要作成 | **新規作成** | 過去参加済みイベント（UserEventService.getUserParticipatedEvents使用） |
| events | managerIds | 配列 | startDate | 降順 | - | - | コレクション | **🔥緊急作成🔥** | **要即時対応** | 共同編集者イベント一覧（UserEventService使用）- プロフィール画面運営イベント表示で必須 |
| gameEvents | createdBy | 昇順 | startDate | 降順 | - | - | コレクション | **🔥緊急作成🔥** | **要即時対応** | gameEventsコレクション主催者イベント（UserEventService使用） |
| gameEvents | managerIds | 配列 | startDate | 降順 | - | - | コレクション | **🔥緊急作成🔥** | **要即時対応** | gameEventsコレクション共同編集者イベント（UserEventService使用） |
| participationApplications | eventId | 昇順 | appliedAt | 降順 | - | - | コレクション | 必須作成 | **未作成** | イベント別参加申請一覧（ParticipationService使用） |
| participationApplications | userId | 昇順 | appliedAt | 降順 | - | - | コレクション | 緊急作成 | **未作成** | ユーザー別参加申請一覧（ホーム画面おすすめイベント用） |
| event_applications | eventId | 昇順 | status | 昇順 | appliedAt | 降順 | コレクション | **🔥緊急作成🔥** | **要即時対応** | イベント別ステータス付き参加申請（違反報告用ユーザー選択） |
| event_applications | eventId | 昇順 | appliedAt | 降順 | - | - | コレクション | 必須作成 | **未作成** | イベント別参加申請一覧（新形式） |
| violations | eventId | 昇順 | reportedAt | 降順 | - | - | コレクション | 必須作成 | **未作成** | イベント別違反記録一覧（ViolationService使用） |
| violations | violatedUserId | 昇順 | reportedAt | 降順 | - | - | コレクション | 必須作成 | **未作成** | ユーザー別違反記録一覧（ViolationService使用） |
| violations | reportedByUserId | 昇順 | reportedAt | 降順 | - | - | コレクション | 必須作成 | **未作成** | 報告者別違反記録一覧（ViolationService使用） |
| violations | eventId | 昇順 | status | 昇順 | reportedAt | 降順 | コレクション | 必須作成 | **未作成** | イベント別ステータス付き違反記録（ViolationService使用） |
| violations | eventId | 昇順 | severity | 昇順 | reportedAt | 降順 | コレクション | 必須作成 | **未作成** | イベント別重要度付き違反記録（ViolationService使用） |
| match_results | eventId | 昇順 | createdAt | 降順 | - | - | コレクション | 必須作成 | **未作成** | イベント別試合結果一覧（MatchResultService使用） |

### 単一フィールドインデックス（Firebase Console > インデックス > 単一フィールド タブ）

**設定手順**: Firebase Console → Firestore → インデックス → **単一フィールド** タブで設定

**重要な設定項目**:
1. **クエリの範囲（スコープ）の選択** - 必須選択:
   - **コレクション**: 特定のコレクション内のクエリ用（推奨）
   - **コレクション グループ**: 同じコレクション ID を持つすべてのコレクションを対象とするクエリ用（通常不要）

2. **インデックスの有効/無効** - 各フィールドに対して必須選択:
   - **有効にする**: そのフィールドでクエリを実行する場合はチェックを入れる
   - **無効にする**: そのフィールドでクエリを実行しない場合はチェックを外す

| コレクション | フィールド | 順序 | スコープ | 有効/無効 | 目的 | ステータス |
|-------------|------------|------|----------|-----------|------|-----------|
| shared_games | game.name | 昇順 | **コレクション** | **有効** | 範囲検索対応 | 要設定 |
| shared_games | usageCount | 降順 | **コレクション** | **有効** | ソート最適化 | 要設定 |
| shared_games | lastAccessedAt | 降順 | **コレクション** | **有効** | ソート最適化 | 要設定 |
| event_groups | eventId | 昇順 | **コレクション** | **有効** | イベント別グループ検索 | デフォルトで有効 |

**設定時の注意事項**:
- **クエリの範囲**: 必ず選択が必要です。このプロジェクトでは **「コレクション」** を選択してください
- **チェックボックス**: インデックスを有効にする場合は必ずチェックを入れてください
- 上記の表で「**有効**」となっているフィールドは、Firebase Console でチェックを入れて有効化してください

### 予定/検討中のインデックス

| コレクションID | フィールド1 | 順序1 | フィールド2 | 順序2 | フィールド3 | 順序3 | スコープ | 説明 | 必要性 | 実装予定 |
|---------------|------------|------|-----------|------|-----------|------|----------|------|--------|----------|
| events | type | 昇順 | status | 昇順 | publishedAt | 降順 | コレクション | タイプ別イベント一覧 | 中 | 未定 |
| events | createdBy | 昇順 | status | 昇順 | updatedAt | 降順 | コレクション | ユーザー別作成イベント（状態付き） | 中 | v1.2 |

## インデックスが必要なクエリパターン

### ユーザー検索
```dart
// username での部分一致検索（単一フィールドインデックスで対応）
usersCollection
  .where('username', isGreaterThanOrEqualTo: query)
  .where('username', isLessThan: query + '\uf8ff')

// userId での部分一致検索（単一フィールドインデックスで対応）
usersCollection
  .where('userId', isGreaterThanOrEqualTo: query)
  .where('userId', isLessThan: query + '\uf8ff')

// 注意: isActiveのチェックはクライアント側で実施
```

### フレンド検索
```dart
// フレンド関係確認
friendshipsCollection
  .where('user1Id', isEqualTo: userId1)
  .where('user2Id', isEqualTo: userId2)

// フレンドリクエスト存在確認
friendRequestsCollection
  .where('fromUserId', isEqualTo: fromUserId)
  .where('toUserId', isEqualTo: toUserId)

// 受信リクエスト一覧
friendRequestsCollection
  .where('toUserId', isEqualTo: userId)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)

// 送信リクエスト一覧
friendRequestsCollection
  .where('fromUserId', isEqualTo: userId)
  .where('status', isEqualTo: 'pending')
  .orderBy('createdAt', descending: true)
```

### イベント検索
```dart
// 公開イベント一覧（status別、eventId順）
eventsCollection
  .where('status', isEqualTo: 'published')
  .orderBy('eventId', descending: true)

// ユーザー作成イベント一覧（作成者別、作成日順）
eventsCollection
  .where('createdBy', isEqualTo: userId)
  .orderBy('createdAt', descending: true)

// ゲームイベント（作成者別、開始日順）
eventsCollection
  .where('createdBy', isEqualTo: userId)
  .orderBy('startDate', descending: true)

// 参加予定イベント
eventsCollection
  .where('participantIds', arrayContains: userId)
  .where('status', whereIn: ['upcoming', 'active'])
  .orderBy('startDate', descending: false)

// 共同編集者イベント
eventsCollection
  .where('managerIds', arrayContains: userId)
  .orderBy('startDate', descending: true)
```


### 新しく発見された重要クエリ

```dart
// 公開イベント検索（status + visibility + 日付順）
eventsCollection
  .where('status', isEqualTo: 'published')
  .where('visibility', isEqualTo: 'public')
  .orderBy('eventDate', descending: false)

// ゲーム別公開イベント検索
eventsCollection
  .where('gameId', isEqualTo: gameId)
  .where('status', isEqualTo: 'published')
  .where('visibility', isEqualTo: 'public')
  .orderBy('eventDate', descending: false)

// 共有ゲーム名前検索（単一フィールドインデックスで対応）
sharedGamesCollection
  .where('game.name', isGreaterThanOrEqualTo: searchName)
  .where('game.name', isLessThanOrEqualTo: searchName + '\uf8ff')

// 使用回数順ゲーム取得（単一フィールドインデックスで対応）
sharedGamesCollection
  .orderBy('usageCount', descending: true)

// 最終アクセス順ゲーム取得（単一フィールドインデックスで対応）
sharedGamesCollection
  .orderBy('lastAccessedAt', descending: true)

// 注意: 複合条件はアプリ側フィルタリング実装のため複合インデックス不要

```

### 通知検索
```dart
// ユーザー通知一覧（受信者別、作成日順）
notificationsCollection
  .where('toUserId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)

// 未読通知数取得
notificationsCollection
  .where('toUserId', isEqualTo: userId)
  .where('isRead', isEqualTo: false)

// 全て既読マーク用
notificationsCollection
  .where('toUserId', isEqualTo: userId)
  .where('isRead', isEqualTo: false)
```

### 試合結果検索
```dart
// イベント別試合結果一覧
matchResultsCollection
  .where('eventId', isEqualTo: eventId)
  .orderBy('createdAt', descending: true)
```

### グループ管理検索
```dart
// イベント別グループ一覧（メモリ内ソート使用）
eventGroupsCollection
  .where('eventId', isEqualTo: eventId)
  // .orderBy('createdAt')  // 複合インデックス回避のため削除
  // メモリ内で以下のようにソート:
  // ..sort((a, b) => a.createdAt.compareTo(b.createdAt))
```

### 違反記録検索
```dart
// イベント別違反記録一覧
violationsCollection
  .where('eventId', isEqualTo: eventId)
  .orderBy('reportedAt', descending: true)

// ユーザー別違反記録一覧
violationsCollection
  .where('violatedUserId', isEqualTo: userId)
  .orderBy('reportedAt', descending: true)

// 報告者別違反記録一覧
violationsCollection
  .where('reportedByUserId', isEqualTo: reporterId)
  .orderBy('reportedAt', descending: true)

// ステータス別違反記録
violationsCollection
  .where('eventId', isEqualTo: eventId)
  .where('status', isEqualTo: status)
  .orderBy('reportedAt', descending: true)

// 重要度別違反記録
violationsCollection
  .where('eventId', isEqualTo: eventId)
  .where('severity', isEqualTo: severity)
  .orderBy('reportedAt', descending: true)

// 運営者が報告した違反で特定ユーザーの履歴取得
violationsCollection
  .where('violatedUserId', isEqualTo: userId)
  .where('reportedByUserId', isEqualTo: reporterId)
  .orderBy('reportedAt', descending: true)
```

## インデックス設定手順

### 複合インデックスの追加
1. **Firebase Console での追加**
   - Firestore Database → インデックス → **複合** タブ → 作成
   - コレクション、フィールド、順序を設定
   - 作成ボタンをクリック

### 単一フィールドインデックスの追加
1. **Firebase Console での追加**
   - Firestore Database → インデックス → **単一フィールド** タブ
   - コレクション、フィールドを選択
   - **クエリの範囲**: 「コレクション」を選択（コレクション グループは通常不要）
   - **インデックスの設定**: 該当フィールドのチェックボックスにチェックを入れて有効化
   - 順序（昇順/降順）を設定
   - 保存ボタンをクリック

2. **このファイルの更新**
   - 上記テーブルに新しいインデックス情報を追加
   - クエリパターンの例も追加

3. **コード実装**
   - 該当するクエリを実装
   - エラーログからインデックスリンクが提供される場合はそれを使用

## インデックス削除時の注意

- 削除前に該当クエリが使用されていないことを確認
- 削除後は必ずこのファイルからも記録を削除
- 本番環境では特に慎重に実施

## パフォーマンス考慮事項

- インデックスは書き込みコストを増加させる
- 必要最小限のインデックスのみを作成
- 使用されていないインデックスは定期的に見直し・削除

## 緊急作成が必要なインデックス

以下のインデックスは各機能で**必須**です。Firebase Consoleで作成してください：

### 最重要：プロフィール画面イベント表示用（**超緊急！現在エラー発生中**）
**🔥 events(createdBy, startDate)**
- 用途: `getUserHostedEvents()`メソッド - ユーザー主催イベント表示
- クエリ: `eventsCollection.where('createdBy', isEqualTo: userId).orderBy('startDate', descending: true)`
- **エラーURL**: https://console.firebase.google.com/v1/r/project/go-mobile-cb9f1/firestore/indexes?create_composite=Ck5wcm9qZWN0cy9nby1tb2JpbGUtY2I5ZjEvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL2V2ZW50cy9pbmRleGVzL18QARoNCgljcmVhdGVkQnkQARoNCglzdGFydERhdGUQAhoMCghfX25hbWVfXxAC
- **ステータス**: 超緊急作成

### フレンド機能用

### 最重要：必ず作成が必要
1. **friendRequests(fromUserId, toUserId)**
   - 用途: `_getExistingRequest(fromUserId, toUserId)`メソッド
   - クエリ: `friendRequestsCollection.where('fromUserId', isEqualTo: fromUserId).where('toUserId', isEqualTo: toUserId)`

2. **friendships(user1Id, user2Id)**
   - 用途: `areFriends(userId1, userId2)`メソッド
   - クエリ: `friendshipsCollection.where('user1Id', isEqualTo: sortedIds[0]).where('user2Id', isEqualTo: sortedIds[1])`

3. **friendRequests(toUserId, status, createdAt)**
   - 用途: `getIncomingRequests(userId)`メソッド
   - クエリ: `friendRequestsCollection.where('toUserId', isEqualTo: userId).where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true)`

4. **friendRequests(fromUserId, status, createdAt)**
   - 用途: `getOutgoingRequests(userId)`メソッド
   - クエリ: `friendRequestsCollection.where('fromUserId', isEqualTo: userId).where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true)`

### 通知機能用（**緊急！現在エラー発生中**）
5. **🔥 notifications(toUserId, createdAt)**
   - 用途: `getUserNotifications(userId)`メソッド
   - クエリ: `notificationsCollection.where('toUserId', isEqualTo: userId).orderBy('createdAt', descending: true)`
   - **エラーURL**: https://console.firebase.google.com/v1/r/project/go-mobile-cb9f1/firestore/indexes?create_composite=ClVwcm9qZWN0cy9nby1tb2JpbGUtY2I5ZjEvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL25vdGlmaWNhdGlvbnMvaW5kZXhlcy9fEAEaDAoIdG9Vc2VySWQQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC
   - **ステータス**: 要緊急作成

6. **notifications(toUserId, isRead)**
   - 用途: `getUnreadNotifications(userId)`メソッド、未読通知数取得
   - クエリ: `notificationsCollection.where('toUserId', isEqualTo: userId).where('isRead', isEqualTo: false)`
   - **ステータス**: 必須作成

### フレンド削除用（将来必要）
7. **friendships(user1Id, user2Id)**
   - 用途: `removeFriend(userId1, userId2)`メソッド
   - クエリ: `friendshipsCollection.where('user1Id', isEqualTo: smallerId).where('user2Id', isEqualTo: biggerId)`

**これらが作成されていないとpermission-deniedエラーやfailed-preconditionエラーが発生します。**

## 削除推奨インデックス

以下のインデックスはコードベースで使用されていないため、削除を推奨：

1. **events (status, eventId)** - CICAgJim14AK
2. **events (eventId, status)** - CICAgJiUpoMK
3. **event_drafts (authorId, updatedAt)** - CICAgJjF9oIK
4. **users (isActive, username)** - CICAgOjXh4EK
5. **users (isActive, userId)** - CICAgOi3kJAK

### 参加申し込み機能用インデックス
```dart
// イベント別参加申請一覧（参加者管理画面用）
participationApplicationsCollection
  .where('eventId', isEqualTo: eventId)
  .orderBy('appliedAt', descending: true)
```

## 更新履歴

| 日付 | 変更内容 | 担当者 | 備考 |
|------|----------|--------|------|
| 2024-11-15 | 初期作成、基本インデックス記録 | Claude | ユーザー検索・イベント管理用 |
| 2024-11-15 | events(createdBy, createdAt)インデックス追加 | Claude | ユーザー作成イベント取得で必要 |
| 2024-11-15 | インデックス記述形式を修正（各フィールドの順序を個別記載） | Claude | 複合インデックスの正確な記述のため |
| 2024-11-16 | フレンド機能用複合インデックス追加 | Claude | FriendService permission-denied エラー対応 |
| 2024-11-17 | フレンド機能インデックスを必須作成に変更、Firestoreルール修正 | Claude | クエリベース権限チェックに変更 |
| 2024-11-17 | Firestoreルールをシンプルな権限設定に変更 | Claude | permission-deniedエラー解決のため一時的に権限拡張 |
| 2024-11-17 | 実際のクエリパターン分析と詳細ガイド作成 | Claude | FriendServiceの実装を分析し正確なインデックス要件を特定 |
| 2024-11-17 | FriendRequest Timestampバグ修正後のインデックス検証完了 | Claude | 承認・拒否機能正常性確認、notification未読取得用インデックス追加 |
| 2024-11-17 | 全実装クエリパターン分析・インデックス資料包括更新 | Claude | events,shared_games,gameEventsの未記載複合インデックス7つ特定・追加 |
| 2024-11-17 | shared_games複合インデックス要件修正 | Claude | 単一フィールド推奨判定、不要な複合インデックス3つを単一推奨に変更 |
| 2024-11-17 | コードベース詳細確認による資料最適化 | Claude | 未使用インデックスの削除、invitationsコレクション追加、実装と資料の整合性確保 |
| 2024-11-19 | participationApplications複合インデックス追加 | Claude | 参加者管理画面でfailed-preconditionエラー対応 |
| 2024-11-19 | gameProfilesIndex複合インデックス4つ追加 | Claude | ゲームプロフィール検索機能で必要な複合インデックス |
| 2024-11-19 | gameProfilesIndexコレクション削除 | Claude | シンプル化により検索機能削除、users/{userId}/gameProfilesのみ使用 |
| 2024-11-21 | gameEvents(managers, startDate)複合インデックス追加 | Claude | ユーザープロフィール画面の共同編集者イベント表示機能で必要 |
| 2024-11-21 | events(managerIds, startDate)複合インデックス追加、gameEvents削除 | Claude | コレクション統一によりeventsコレクションに変更 |
| 2024-11-25 | participatedEvents用インデックス追加、managerIdsインデックス緊急対応 | Claude | プロフィール画面機能拡張・運営イベント表示修正 |
| 2024-11-25 | gameEventsコレクション用インデックス追加 | Claude | 2つのコレクション（events/gameEvents）対応のためgameEvents用インデックス追加 |
| 2024-11-26 | event_applications複合インデックス追加 | Claude | 違反報告機能用ユーザー選択モーダルで必要なインデックス追加 |
| 2024-11-27 | match_results複合インデックス追加、event_groups単一フィールドへ移動 | Claude | 試合結果管理は複合インデックス、グループ管理は単一フィールドで十分 |
| 2025-12-02 | event_groups複合クエリをメモリ内ソートに変更 | Claude | グループ情報画面エラー対応、orderBy削除で複合インデックス要件回避 |