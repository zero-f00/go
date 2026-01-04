import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

enum EventManagementType {
  /// 作成したイベント
  createdEvents,

  /// 共同編集者のイベント
  collaborativeEvents,

  /// 下書き保存されたイベント
  draftEvents,

  /// 過去のイベント履歴
  pastEvents,
}

extension EventManagementTypeExtension on EventManagementType {
  /// アイコンを取得
  IconData get icon {
    switch (this) {
      case EventManagementType.createdEvents:
        return Icons.event;
      case EventManagementType.collaborativeEvents:
        return Icons.group;
      case EventManagementType.draftEvents:
        return Icons.drafts;
      case EventManagementType.pastEvents:
        return Icons.history;
    }
  }

  /// 画面タイトルを取得（L10n対応）
  String getTitle(BuildContext context) {
    final l10n = L10n.of(context);
    switch (this) {
      case EventManagementType.createdEvents:
        return l10n.createdEvents;
      case EventManagementType.collaborativeEvents:
        return l10n.collaborativeEvents;
      case EventManagementType.draftEvents:
        return l10n.draftEvents;
      case EventManagementType.pastEvents:
        return l10n.pastEventHistory;
    }
  }

  /// 画面タイトルを取得（後方互換性のため維持）
  /// @deprecated 代わりに getTitle(context) を使用してください
  String get title {
    switch (this) {
      case EventManagementType.createdEvents:
        return '作成したイベント';
      case EventManagementType.collaborativeEvents:
        return '共同編集者のイベント';
      case EventManagementType.draftEvents:
        return '下書き保存されたイベント';
      case EventManagementType.pastEvents:
        return '過去のイベント履歴';
    }
  }

  /// 画面の説明文を取得（L10n対応）
  String getDescription(BuildContext context) {
    final l10n = L10n.of(context);
    switch (this) {
      case EventManagementType.createdEvents:
        return l10n.createdEventsFullDescription;
      case EventManagementType.collaborativeEvents:
        return l10n.collaborativeEventsFullDescription;
      case EventManagementType.draftEvents:
        return l10n.draftEventsFullDescription;
      case EventManagementType.pastEvents:
        return l10n.pastEventsFullDescription;
    }
  }

  /// 画面の説明文を取得（後方互換性のため維持）
  /// @deprecated 代わりに getDescription(context) を使用してください
  String get description {
    switch (this) {
      case EventManagementType.createdEvents:
        return '自分が作成したイベントの一覧です。編集や削除、複製が可能です。';
      case EventManagementType.collaborativeEvents:
        return '編集権限を持つイベントの一覧です。他のユーザーと共同で管理できます。';
      case EventManagementType.draftEvents:
        return '一時保存されたイベントの一覧です。編集を続行して公開できます。';
      case EventManagementType.pastEvents:
        return '終了したイベントの一覧です。統計情報や参加者データを確認できます。';
    }
  }

  /// 空の状態メッセージを取得（L10n対応）
  String getEmptyMessage(BuildContext context) {
    final l10n = L10n.of(context);
    switch (this) {
      case EventManagementType.createdEvents:
        return l10n.noCreatedEvents;
      case EventManagementType.collaborativeEvents:
        return l10n.noCollaborativeEvents;
      case EventManagementType.draftEvents:
        return l10n.noDraftEvents;
      case EventManagementType.pastEvents:
        return l10n.noPastEvents;
    }
  }

  /// 空の状態メッセージを取得（後方互換性のため維持）
  /// @deprecated 代わりに getEmptyMessage(context) を使用してください
  String get emptyMessage {
    switch (this) {
      case EventManagementType.createdEvents:
        return 'まだイベントを作成していません';
      case EventManagementType.collaborativeEvents:
        return '共同編集できるイベントがありません';
      case EventManagementType.draftEvents:
        return '下書き保存されたイベントがありません';
      case EventManagementType.pastEvents:
        return '過去のイベントがありません';
    }
  }

  /// 空の状態の詳細メッセージを取得（L10n対応）
  String getEmptyDetailMessage(BuildContext context) {
    final l10n = L10n.of(context);
    switch (this) {
      case EventManagementType.createdEvents:
        return l10n.noCreatedEventsDetail;
      case EventManagementType.collaborativeEvents:
        return l10n.noCollaborativeEventsDetail;
      case EventManagementType.draftEvents:
        return l10n.noDraftEventsDetail;
      case EventManagementType.pastEvents:
        return l10n.noPastEventsDetail;
    }
  }

  /// 空の状態の詳細メッセージを取得（後方互換性のため維持）
  /// @deprecated 代わりに getEmptyDetailMessage(context) を使用してください
  String get emptyDetailMessage {
    switch (this) {
      case EventManagementType.createdEvents:
        return '「新規作成」ボタンから最初のイベントを作成しましょう';
      case EventManagementType.collaborativeEvents:
        return '他のユーザーから編集権限の招待を受けた場合、ここに表示されます';
      case EventManagementType.draftEvents:
        return 'イベント作成時に下書き保存を利用すると、ここに表示されます';
      case EventManagementType.pastEvents:
        return 'イベントが終了すると、ここに履歴として表示されます';
    }
  }
}
