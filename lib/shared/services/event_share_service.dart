import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/game_event_management/models/game_event.dart';
import 'deep_link_service.dart';

/// イベント共有サービス
/// SNSやメッセージアプリでイベント情報を共有する機能を提供
class EventShareService {
  /// 本番環境かどうか（開発環境ではシェア機能を無効化）
  static const bool _isProduction =
      String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev') == 'prod';

  /// イベントを共有できるかどうかを判定
  static bool canShareEvent(GameEvent event) {
    // TODO: シェア機能の動作確認完了後、以下のコメントを解除して開発環境でのシェアを無効化する
    // 開発環境ではシェア機能を無効化
    // 開発用Firebaseのイベントは本番go-webで参照できないため
    // if (!_isProduction) return false;
    // プライベートイベントは共有不可
    if (event.visibility == 'プライベート') return false;
    // 中止されたイベントも共有不可
    if (event.status == GameEventStatus.cancelled) return false;
    // 下書きは共有不可
    if (event.status == GameEventStatus.draft) return false;
    return true;
  }

  /// イベントを共有する
  /// [sharePositionOrigin] はiPadでシェアシートの表示位置を指定するために必要
  static Future<void> shareEvent(GameEvent event, {Rect? sharePositionOrigin}) async {
    if (!canShareEvent(event)) {
      if (kDebugMode) {
        print('EventShareService: Cannot share this event (visibility: ${event.visibility}, status: ${event.status})');
      }
      return;
    }

    try {
      final shareText = _buildShareText(event);
      await Share.share(
        shareText,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (kDebugMode) {
        print('EventShareService: Share error - $e');
      }
      rethrow;
    }
  }

  /// 共有用テキストを生成
  static String _buildShareText(GameEvent event) {
    final buffer = StringBuffer();

    // イベント名
    buffer.writeln('【${event.name}】');
    buffer.writeln();

    // 開催日時
    final dateFormat = _getDateFormat();
    buffer.writeln('📅 開催: ${dateFormat.format(event.startDate)}〜');

    // ゲーム情報（存在する場合）
    if (event.gameName != null && event.gameName!.isNotEmpty) {
      buffer.writeln('🎮 ゲーム: ${event.gameName}');
    }

    // 参加者情報
    buffer.writeln('👥 参加者: ${event.participantCount}/${event.maxParticipants}人');

    // 賞品情報（存在する場合）
    if (event.prizeContent != null && event.prizeContent!.isNotEmpty) {
      buffer.writeln('🏆 賞品あり');
    }
    buffer.writeln();

    // 説明文（最大100文字）
    if (event.description.isNotEmpty) {
      final description = event.description.length > 100
          ? '${event.description.substring(0, 100)}...'
          : event.description;
      buffer.writeln(description);
      buffer.writeln();
    }

    // イベント詳細URL
    final eventUrl = DeepLinkService.generateEventShareUrl(event.id);
    buffer.writeln('▼ 詳細はこちら');
    buffer.writeln(eventUrl);
    buffer.writeln();

    // ハッシュタグ
    final hashtags = <String>['Go.', 'ゲームイベント'];

    // ゲーム名をハッシュタグに追加
    if (event.gameName != null && event.gameName!.isNotEmpty) {
      final gameTag = _sanitizeHashtag(event.gameName!);
      if (gameTag.isNotEmpty) {
        hashtags.add(gameTag);
      }
    }

    // イベントタグをハッシュタグに追加
    for (final tag in event.eventTags) {
      final sanitizedTag = _sanitizeHashtag(tag);
      if (sanitizedTag.isNotEmpty && !hashtags.contains(sanitizedTag)) {
        hashtags.add(sanitizedTag);
      }
    }

    buffer.write(hashtags.map((tag) => '#$tag').join(' '));

    return buffer.toString();
  }

  /// 日付フォーマッターを取得
  static DateFormat _getDateFormat() {
    try {
      return DateFormat('yyyy/MM/dd HH:mm', 'ja_JP');
    } catch (e) {
      // フォールバック: デフォルトロケール使用
      return DateFormat('yyyy/MM/dd HH:mm');
    }
  }

  /// ハッシュタグ用に文字列をサニタイズ
  /// スペースや特殊文字を除去し、ハッシュタグとして使用可能な形式に変換
  static String _sanitizeHashtag(String text) {
    // スペース、ハッシュ記号、その他SNSで問題となる文字を除去
    return text
        .replaceAll(RegExp(r'[\s#@\n\r\t]'), '')
        .replaceAll(RegExp(r'[　]'), ''); // 全角スペースも除去
  }
}
