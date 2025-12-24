# Firestore インデックス管理

## 概要

Firestoreの複合インデックスを管理するドキュメントです。
実際のインデックス定義は `firestore.indexes.json` に記述し、`firebase deploy --only firestore` でデプロイします。

## デプロイ方法

```bash
# Firestoreルール＋インデックスをデプロイ
firebase deploy --only firestore

# インデックスのみデプロイ
firebase deploy --only firestore:indexes
```

## 複合インデックス一覧

| コレクション | フィールド構成 | 説明 |
|-------------|---------------|------|
| events | createdBy(昇順), createdAt(降順) | ユーザー作成イベント一覧 |
| events | createdBy(昇順), startDate(昇順) | 運営者イベント取得（開始日昇順） |
| events | createdBy(昇順), startDate(降順) | 運営者イベント取得（開始日降順） |
| events | gameId(昇順), status(昇順), visibility(昇順) | ゲーム別公開イベント |
| events | gameId(昇順), eventDate(昇順) | ゲーム別イベント日付順 |
| events | status(昇順), visibility(昇順), eventDate(昇順) | 公開イベント日付順一覧 |
| events | status(昇順), eventDate(昇順) | イベントリマインダー用 |
| events | participantIds(配列), status(昇順), startDate(昇順) | 参加予定イベント |
| events | participantIds(配列), status(昇順), endDate(降順) | 過去参加済みイベント |
| events | managerIds(配列), startDate(降順) | 共同編集者イベント一覧 |
| gameEvents | createdBy(昇順), startDate(降順) | 主催者イベント |
| gameEvents | managerIds(配列), startDate(降順) | 共同編集者イベント |
| follows | followerId(昇順), followeeId(昇順) | フォロー関係存在確認 |
| follows | followerId(昇順), createdAt(降順) | フォロー中一覧 |
| follows | followeeId(昇順), createdAt(降順) | フォロワー一覧 |
| notifications | toUserId(昇順), createdAt(降順) | ユーザー通知一覧 |
| notifications | toUserId(昇順), isRead(昇順) | 未読通知取得 |
| notifications | toUserId(昇順), isRead(昇順), createdAt(降順) | 未読通知一覧 |
| participationApplications | eventId(昇順), appliedAt(降順) | イベント別参加申請一覧 |
| participationApplications | userId(昇順), appliedAt(降順) | ユーザー別参加申請一覧 |
| participationApplications | eventId(昇順), status(昇順) | イベント別ステータス付き申請 |
| event_applications | eventId(昇順), status(昇順), appliedAt(降順) | イベント別ステータス付き参加申請 |
| event_applications | eventId(昇順), appliedAt(降順) | イベント別参加申請一覧 |
| event_groups | eventId(昇順), createdAt(昇順) | イベント別グループ一覧 |
| event_groups | eventId(昇順), participants(配列) | グループ参加者検索 |
| match_results | eventId(昇順), createdAt(降順) | イベント別試合結果一覧 |
| violations | eventId(昇順), reportedAt(降順) | イベント別違反記録 |
| violations | violatedUserId(昇順), reportedAt(降順) | ユーザー別違反記録 |
| violations | reportedByUserId(昇順), reportedAt(降順) | 報告者別違反記録 |
| violations | eventId(昇順), status(昇順), reportedAt(降順) | イベント別ステータス付き違反記録 |
| violations | eventId(昇順), severity(昇順), reportedAt(降順) | イベント別重要度付き違反記録 |
| match_reports | matchId(昇順), createdAt(降順) | 試合別報告一覧 |
| match_reports | reporterId(昇順), createdAt(降順) | 報告者別報告一覧 |
| match_reports | status(昇順), createdAt(昇順) | 運営向け未処理報告 |
| admin_notifications | eventId(昇順), createdAt(降順) | イベント別運営通知 |
| admin_notifications | isRead(昇順), createdAt(降順) | 未読運営通知 |

## 単一フィールドインデックス

Firestoreはデフォルトで単一フィールドインデックスを自動作成します。
以下は明示的に設定が必要なもののみ記載:

| コレクション | フィールド | 用途 |
|-------------|------------|------|
| shared_games | game.name | ゲーム名検索 |
| shared_games | usageCount | 使用回数ソート |
| shared_games | lastAccessedAt | 最終アクセスソート |
| event_groups | eventId | イベント別グループ検索 |

## クエリパターン例

### イベント検索
```dart
// ユーザー作成イベント一覧
eventsCollection
  .where('createdBy', isEqualTo: userId)
  .orderBy('createdAt', descending: true)

// 公開イベント一覧
eventsCollection
  .where('status', isEqualTo: 'published')
  .where('visibility', isEqualTo: 'public')
  .orderBy('eventDate', descending: false)

// 参加予定イベント
eventsCollection
  .where('participantIds', arrayContains: userId)
  .where('status', whereIn: ['upcoming', 'active'])
  .orderBy('startDate', descending: false)
```

### フォロー検索
```dart
// フォロー関係確認
followsCollection
  .where('followerId', isEqualTo: currentUserId)
  .where('followeeId', isEqualTo: targetUserId)

// フォロー中一覧
followsCollection
  .where('followerId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)

// フォロワー一覧
followsCollection
  .where('followeeId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
```

### 通知検索
```dart
// ユーザー通知一覧
notificationsCollection
  .where('toUserId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)

// 未読通知
notificationsCollection
  .where('toUserId', isEqualTo: userId)
  .where('isRead', isEqualTo: false)
```

### グループ管理
```dart
// イベント別グループ一覧（メモリ内ソート使用）
eventGroupsCollection
  .where('eventId', isEqualTo: eventId)
  // メモリ内でソート: ..sort((a, b) => a.createdAt.compareTo(b.createdAt))
```

### 試合報告管理
```dart
// 試合別報告一覧
matchReportsCollection
  .where('matchId', isEqualTo: matchId)
  .orderBy('createdAt', descending: true)

// 報告者別報告一覧
matchReportsCollection
  .where('reporterId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)

// 運営向け未処理報告
matchReportsCollection
  .where('status', whereIn: ['submitted', 'reviewing'])
  .orderBy('createdAt', descending: false)
```

### 運営通知
```dart
// イベント別運営通知
adminNotificationsCollection
  .where('eventId', isEqualTo: eventId)
  .orderBy('createdAt', descending: true)

// 未読運営通知
adminNotificationsCollection
  .where('isRead', isEqualTo: false)
  .orderBy('createdAt', descending: true)
```

## インデックス追加手順

1. `firestore.indexes.json` にインデックス定義を追加
2. このファイルの一覧表を更新
3. `firebase deploy --only firestore:indexes` でデプロイ

## 注意事項

- インデックスは書き込みコストを増加させるため、必要最小限に
- 使用されていないインデックスは定期的に見直し・削除
- 新しいクエリ実装時は、エラーログのインデックス作成リンクを活用

## 更新履歴

| 日付 | 変更内容 |
|------|----------|
| 2024-11-15 | 初期作成 |
| 2024-11-16 | フレンド機能用インデックス追加 |
| 2024-11-19 | participationApplicationsインデックス追加 |
| 2024-11-21 | managerIds関連インデックス追加 |
| 2024-11-25 | gameEventsコレクション用インデックス追加 |
| 2024-11-26 | event_applicationsインデックス追加 |
| 2024-11-27 | match_results, violationsインデックス追加 |
| 2025-12-02 | event_groups複合クエリをメモリ内ソートに変更 |
| 2025-12-08 | イベントリマインダー用インデックス追加 |
| 2025-12-11 | firestore.indexes.json作成、ドキュメント整理 |
| 2025-12-18 | match_reports、admin_notificationsインデックス追加 |
| 2025-12-24 | フレンド機能廃止に伴いfollowsインデックス追加、friendRequests/friendshipsインデックス削除 |
