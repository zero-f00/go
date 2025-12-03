import '../../data/models/event_model.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../constants/event_management_types.dart';
import '../../data/repositories/shared_game_repository.dart';
import '../services/game_service.dart';

/// Event モデルを GameEvent モデルに変換するユーティリティクラス
class EventConverter {
  EventConverter._();

  /// Event を GameEvent に変換
  static Future<GameEvent> eventToGameEvent(Event event) async {

    try {
      // ゲームアイコンURLを取得
      String? gameIconUrl;
      String? gameName = event.gameName; // イベントに保存されているゲーム名も使用

      if (event.gameId != null) {
        try {
          final sharedGameRepository = SharedGameRepository();
          final sharedGame = await sharedGameRepository.findExistingGame(event.gameId!);
          if (sharedGame != null) {
            gameIconUrl = sharedGame.game.iconUrl;
            gameName = sharedGame.game.name; // shared_gamesから最新の名前を取得
          } else {
            // フォールバック: iTunes APIから直接取得を試みる
            if (gameName != null && gameName.isNotEmpty) {
              try {
                final gameService = GameService.instance;
                final games = await gameService.searchGames(gameName);
                if (games.isNotEmpty) {
                  final game = games.first;
                  gameIconUrl = game.iconUrl;
                  // shared_gamesコレクションに保存
                  await gameService.getOrCacheGame(game);
                }
              } catch (itunesError) {
                // iTunes API エラーは無視して続行
              }
            }
          }
        } catch (e) {
          // shared_games取得エラーは無視して続行
        }
      }

      final gameEvent = GameEvent(
      id: event.id ?? '',
      name: event.name,
      subtitle: event.subtitle,
      description: event.description,
      type: _mapEventToGameEventType(event),
      status: _mapEventToGameEventStatus(event),
      startDate: event.eventDate,
      endDate: event.registrationDeadline ?? event.eventDate.add(const Duration(days: 1)),
      participantCount: event.participantIds.length,
      maxParticipants: event.maxParticipants,
      completionRate: _calculateCompletionRate(event),
      isPremium: false, // EventモデルにはPremium情報がないため false
      hasFee: event.hasParticipationFee,
      rewards: _parseRewards(event),
      gameId: event.gameId,
      gameName: gameName ?? event.gameName, // shared_gamesまたはiTunesから取得した名前を優先
      gameIconUrl: gameIconUrl,
      imageUrl: event.imageUrl,
      rules: event.rules,
      registrationDeadline: event.registrationDeadline,
      prizeContent: event.prizeContent,
      contactInfo: event.contactInfo,
      policy: event.policy,
      additionalInfo: event.additionalInfo,
      streamingUrls: event.streamingUrls,
      minAge: null, // EventモデルにはminAge情報がない
      feeAmount: _parseFeeAmount(event.participationFeeText),
      feeText: event.participationFeeText, // 参加費テキストをそのまま保持
      feeSupplement: event.participationFeeSupplement, // 参加費補足情報を追加
      platforms: event.platforms,
      approvalMethod: 'automatic', // デフォルト値
      visibility: _mapEventVisibilityToString(event.visibility),
      language: event.language,
      hasAgeRestriction: false, // EventモデルにはAge制限情報がない
      hasStreaming: event.hasStreaming,
      eventTags: event.eventTags,
      sponsors: event.sponsorIds, // スポンサーIDをそのまま設定
      managers: _buildManagersList(event), // 作成者とmanagerIdsを統合したリスト
      blockedUsers: event.blockedUserIds, // NGユーザーIDを設定
      createdBy: event.createdBy, // 作成者情報を追加
      cancellationReason: event.cancellationReason, // 中止理由を追加
      cancelledAt: event.cancelledAt, // 中止日時を追加
    );

      return gameEvent;
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  /// EventをGameEventTypeにマッピング
  static GameEventType _mapEventToGameEventType(Event event) {
    // イベントタグを基にタイプを決定
    if (event.eventTags.contains('daily') || event.eventTags.contains('デイリー')) {
      return GameEventType.daily;
    }
    if (event.eventTags.contains('weekly') || event.eventTags.contains('ウィークリー')) {
      return GameEventType.weekly;
    }
    if (event.eventTags.contains('seasonal') || event.eventTags.contains('シーズナル')) {
      return GameEventType.seasonal;
    }
    // デフォルトはspecial
    return GameEventType.special;
  }

  /// EventStatusをGameEventStatusにマッピング
  static GameEventStatus _mapEventToGameEventStatus(Event event) {
    final now = DateTime.now();

    switch (event.status) {
      case EventStatus.draft:
        return GameEventStatus.upcoming;
      case EventStatus.scheduled:
        // 予約公開の場合、公開日時前なら upcoming
        if (event.scheduledPublishAt != null && now.isBefore(event.scheduledPublishAt!)) {
          return GameEventStatus.upcoming;
        }
        // 公開日時を過ぎていれば通常の published と同じ処理
        if (now.isBefore(event.eventDate)) {
          return GameEventStatus.upcoming;
        } else if (event.registrationDeadline != null && now.isAfter(event.registrationDeadline!)) {
          return GameEventStatus.expired;
        } else {
          return GameEventStatus.active;
        }
      case EventStatus.published:
        if (now.isBefore(event.eventDate)) {
          return GameEventStatus.upcoming;
        } else if (event.registrationDeadline != null && now.isAfter(event.registrationDeadline!)) {
          return GameEventStatus.expired;
        } else {
          return GameEventStatus.active;
        }
      case EventStatus.completed:
        return GameEventStatus.completed;
      case EventStatus.cancelled:
        return GameEventStatus.cancelled;
    }
  }

  /// 完了率を計算
  static double _calculateCompletionRate(Event event) {
    if (event.maxParticipants <= 0) return 0.0;
    return event.participantIds.length / event.maxParticipants;
  }

  /// 参加費金額を解析
  static double? _parseFeeAmount(String? feeText) {
    if (feeText == null || feeText.isEmpty) return null;

    // 数字のパターンをマッチング（円、yen、¥などの通貨記号も対応）
    final regex = RegExp(r'(\d+(?:,\d{3})*(?:\.\d+)?)');
    final match = regex.firstMatch(feeText.replaceAll(',', ''));

    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }

    return null;
  }

  /// 報酬情報を解析
  static Map<String, double> _parseRewards(Event event) {
    if (!event.hasPrize) {
      return {};
    }

    // 簡単な報酬解析（prizeContentから情報を抽出）
    final rewards = <String, double>{};
    final content = event.prizeContent?.toLowerCase() ?? '';

    if (content.contains('コイン') || content.contains('coin')) {
      rewards['coin'] = 100.0; // デフォルト値
    }
    if (content.contains('ジェム') || content.contains('gem')) {
      rewards['gem'] = 10.0; // デフォルト値
    }
    if (content.contains('経験値') || content.contains('exp')) {
      rewards['exp'] = 500.0; // デフォルト値
    }

    // prizeContentに具体的な内容がある場合は解析、なければ一般的な賞品として登録
    if (rewards.isEmpty) {
      if (content.isNotEmpty && (content.contains('賞品') || content.contains('商品') || content.contains('景品') || content.contains('prize'))) {
        rewards['prize'] = 1.0; // 存在フラグとして使用
      } else {
        // prizeContentが空またはキーワードがない場合でも、hasPrizeがtrueなら一般賞品として扱う
        rewards['prize'] = 1.0;
      }
    }

    return rewards;
  }

  /// EventVisibilityを文字列にマッピング（日本語表記）
  static String _mapEventVisibilityToString(EventVisibility visibility) {
    switch (visibility) {
      case EventVisibility.public:
        return 'パブリック';
      case EventVisibility.private:
        return 'プライベート';
      case EventVisibility.inviteOnly:
        return '招待制';
    }
  }

  /// 作成者と管理者を統合したマネージャーリストを構築
  static List<String> _buildManagersList(Event event) {
    final managers = <String>[];

    // イベント作成者を最初に追加
    if (event.createdBy.isNotEmpty) {
      managers.add(event.createdBy);
    }

    // 管理者IDを追加（重複を避ける）
    for (final managerId in event.managerIds) {
      if (!managers.contains(managerId)) {
        managers.add(managerId);
      }
    }


    return managers;
  }

  /// Event リストを GameEvent リストに変換
  static Future<List<GameEvent>> eventsToGameEvents(List<Event> events) async {
    final gameEvents = <GameEvent>[];
    for (final event in events) {
      final gameEvent = await eventToGameEvent(event);
      gameEvents.add(gameEvent);
    }
    return gameEvents;
  }

  /// イベントをタイプ別にフィルタリング
  static Future<List<GameEvent>> filterEventsByManagementType(
    List<Event> events,
    String currentUserId,
    EventManagementType managementType,
  ) async {
    List<Event> filteredEvents;

    switch (managementType) {
      case EventManagementType.createdEvents:
        // 作成したイベント
        filteredEvents = events.where((event) => event.createdBy == currentUserId).toList();
        break;
      case EventManagementType.collaborativeEvents:
        // 共同編集者のイベント
        filteredEvents = events.where((event) =>
          event.managerIds.contains(currentUserId) && event.createdBy != currentUserId
        ).toList();
        break;
      case EventManagementType.draftEvents:
        // 下書きイベント
        filteredEvents = events.where((event) =>
          event.status == EventStatus.draft &&
          (event.createdBy == currentUserId || event.managerIds.contains(currentUserId))
        ).toList();
        break;
      case EventManagementType.pastEvents:
        // 過去のイベント
        final now = DateTime.now();
        filteredEvents = events.where((event) =>
          (event.createdBy == currentUserId || event.managerIds.contains(currentUserId)) &&
          (event.status == EventStatus.completed ||
           (event.registrationDeadline != null && now.isAfter(event.registrationDeadline!)))
        ).toList();
        break;
    }

    return await eventsToGameEvents(filteredEvents);
  }

  /// GameEvent を Event に変換（参加申し込み用）
  static Future<Event> gameEventToEvent(GameEvent gameEvent) async {
    return Event(
      id: gameEvent.id,
      name: gameEvent.name,
      subtitle: gameEvent.subtitle,
      description: gameEvent.description,
      rules: gameEvent.rules ?? '',
      imageUrl: gameEvent.imageUrl,
      gameId: gameEvent.gameId,
      gameName: gameEvent.gameName,
      platforms: gameEvent.platforms ?? [],
      eventDate: gameEvent.startDate,
      registrationDeadline: gameEvent.registrationDeadline ?? gameEvent.startDate,
      maxParticipants: gameEvent.maxParticipants,
      additionalInfo: gameEvent.additionalInfo,
      hasParticipationFee: gameEvent.hasFee,
      participationFeeText: gameEvent.feeText ?? gameEvent.feeAmount?.toString(),
      participationFeeSupplement: gameEvent.feeSupplement,
      hasPrize: gameEvent.rewards.isNotEmpty,
      prizeContent: gameEvent.prizeContent,
      sponsorIds: gameEvent.sponsors ?? [],
      managerIds: gameEvent.managers ?? [],
      blockedUserIds: const [],
      visibility: _mapStringToEventVisibility(gameEvent.visibility ?? 'パブリック'),
      eventTags: gameEvent.eventTags ?? [],
      language: gameEvent.language ?? '日本語',
      contactInfo: gameEvent.contactInfo,
      hasStreaming: gameEvent.hasStreaming ?? false,
      streamingUrls: gameEvent.streamingUrls,
      policy: gameEvent.policy,
      createdBy: gameEvent.createdBy ?? '',
      createdAt: DateTime.now(), // 仮の値
      updatedAt: DateTime.now(), // 仮の値
      participantIds: const [],
      status: _mapGameEventStatusToEventStatus(gameEvent.status),
      eventPassword: null, // GameEventモデルにはパスワードフィールドがない
      scheduledPublishAt: null,
      cancellationReason: gameEvent.cancellationReason, // 中止理由を追加
      cancelledAt: gameEvent.cancelledAt, // 中止日時を追加
    );
  }

  /// GameEventStatus を EventStatus にマッピング
  static EventStatus _mapGameEventStatusToEventStatus(GameEventStatus status) {
    switch (status) {
      case GameEventStatus.upcoming:
        return EventStatus.published;
      case GameEventStatus.active:
        return EventStatus.published;
      case GameEventStatus.completed:
        return EventStatus.completed;
      case GameEventStatus.expired:
        return EventStatus.cancelled;
      case GameEventStatus.cancelled:
        return EventStatus.cancelled;
    }
  }

  /// 文字列をEventVisibilityにマッピング
  static EventVisibility _mapStringToEventVisibility(String visibility) {
    switch (visibility) {
      case 'プライベート':
        return EventVisibility.private;
      case '招待制':
        return EventVisibility.inviteOnly;
      default:
        return EventVisibility.public;
    }
  }
}

