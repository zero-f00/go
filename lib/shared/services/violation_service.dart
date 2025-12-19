import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/violation_record_model.dart';
import '../../data/repositories/violation_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'notification_service.dart';
import '../providers/auth_provider.dart';

/// 違反管理サービスのプロバイダー
final violationServiceProvider = Provider<ViolationService>((ref) {
  return ViolationService(
    violationRepository: ref.read(violationRepositoryProvider),
    userRepository: ref.read(userRepositoryProvider),
  );
});

/// 違反管理サービス
class ViolationService {
  final ViolationRepository _violationRepository;
  final UserRepository _userRepository;

  const ViolationService({
    required ViolationRepository violationRepository,
    required UserRepository userRepository,
  }) : _violationRepository = violationRepository,
       _userRepository = userRepository;

  /// 違反を報告する
  Future<String> reportViolation({
    required String eventId,
    required String eventName,
    required String violatedUserId,
    required String reportedByUserId,
    required ViolationType violationType,
    required String description,
    required ViolationSeverity severity,
    String? notes,
  }) async {
    try {
      // 報告者の情報を取得
      final reporter = await _userRepository.getUserById(reportedByUserId);
      if (reporter == null) {
        throw Exception('報告者の情報が見つかりません');
      }

      final now = DateTime.now();

      // 重要度に基づいて異議申立期限を設定
      final appealDeadline = _calculateAppealDeadline(severity, now);

      // 違反記録を作成
      final violation = ViolationRecord(
        eventId: eventId,
        eventName: eventName,
        violatedUserId: violatedUserId,
        reportedByUserId: reportedByUserId,
        reportedByUserName: reporter.username,
        violationType: violationType,
        description: description,
        severity: severity,
        reportedAt: now,
        status: ViolationStatus.pending,
        notes: notes,
        appealDeadline: appealDeadline,
        canProcessWithoutAppeal: false, // 初期状態では異議申立期間を考慮
      );

      final violationId = await _violationRepository.createViolation(violation);

      // 通知を送信
      final notificationService = NotificationService.instance;
      await notificationService.sendViolationReportedNotification(
        violatedUserId: violatedUserId,
        eventId: eventId,
        eventName: eventName,
        violationId: violationId,
        reportedByUserId: reportedByUserId,
        violationType: violationType.name,
        severity: severity.name,
      );

      return violationId;
    } catch (e) {
      throw Exception('違反報告に失敗しました: $e');
    }
  }

  /// 違反記録を編集する
  Future<void> editViolation({
    required String violationId,
    ViolationType? violationType,
    String? description,
    ViolationSeverity? severity,
    String? notes,
  }) async {
    try {
      // 既存の違反記録を取得
      final existingViolation = await _violationRepository.getViolation(violationId);
      if (existingViolation == null) {
        throw Exception('違反記録が見つかりません');
      }

      // 更新された違反記録を作成（指定されたフィールドのみ更新）
      final updatedViolation = existingViolation.copyWith(
        violationType: violationType ?? existingViolation.violationType,
        description: description ?? existingViolation.description,
        severity: severity ?? existingViolation.severity,
        notes: notes ?? existingViolation.notes,
      );

      await _violationRepository.updateViolation(updatedViolation);
    } catch (e) {
      throw Exception('違反記録の編集に失敗しました: $e');
    }
  }

  /// 違反記録を処理する（解決済みにする）
  Future<void> resolveViolation({
    required String violationId,
    required String resolvedByUserId,
    required String penalty,
    String? notes,
  }) async {
    try {
      // 既存の違反記録を取得
      final existingViolation = await _violationRepository.getViolation(violationId);
      if (existingViolation == null) {
        throw Exception('違反記録が見つかりません');
      }

      // 更新された違反記録を作成
      final updatedViolation = existingViolation.copyWith(
        status: ViolationStatus.resolved,
        penalty: penalty,
        notes: notes,
        resolvedAt: DateTime.now(),
        resolvedByUserId: resolvedByUserId,
      );

      await _violationRepository.updateViolation(updatedViolation);
    } catch (e) {
      throw Exception('違反記録の処理に失敗しました: $e');
    }
  }

  /// 違反記録を却下する
  Future<void> dismissViolation({
    required String violationId,
    required String resolvedByUserId,
    String? notes,
  }) async {
    try {
      // 既存の違反記録を取得
      final existingViolation = await _violationRepository.getViolation(violationId);
      if (existingViolation == null) {
        throw Exception('違反記録が見つかりません');
      }

      // 更新された違反記録を作成
      final updatedViolation = existingViolation.copyWith(
        status: ViolationStatus.dismissed,
        notes: notes,
        resolvedAt: DateTime.now(),
        resolvedByUserId: resolvedByUserId,
      );

      await _violationRepository.updateViolation(updatedViolation);
    } catch (e) {
      throw Exception('違反記録の却下に失敗しました: $e');
    }
  }

  /// 違反記録を調査中にする
  Future<void> markUnderReview({
    required String violationId,
    required String reviewerUserId,
    String? notes,
  }) async {
    try {
      // 既存の違反記録を取得
      final existingViolation = await _violationRepository.getViolation(violationId);
      if (existingViolation == null) {
        throw Exception('違反記録が見つかりません');
      }

      // 更新された違反記録を作成
      final updatedViolation = existingViolation.copyWith(
        status: ViolationStatus.underReview,
        notes: notes,
      );

      await _violationRepository.updateViolation(updatedViolation);
    } catch (e) {
      throw Exception('違反記録のステータス更新に失敗しました: $e');
    }
  }

  /// イベントの違反記録一覧を取得
  Future<List<ViolationRecord>> getEventViolations(String eventId) async {
    try {
      return await _violationRepository.getViolationsByEvent(eventId);
    } catch (e) {
      throw Exception('イベント違反記録の取得に失敗しました: $e');
    }
  }

  /// 特定ユーザーの違反履歴を取得（運営者向け）
  /// 運営者が参加者の過去の違反歴を確認する際に使用
  Future<List<ViolationRecord>> getUserViolationHistory({
    required String userId,
    required String reporterId,
  }) async {
    try {
      return await _violationRepository.getUserViolationHistory(userId, reporterId);
    } catch (e) {
      throw Exception('ユーザー違反履歴の取得に失敗しました: $e');
    }
  }

  /// 未処理の違反記録を取得
  Future<List<ViolationRecord>> getPendingViolations(String eventId) async {
    try {
      return await _violationRepository.getPendingViolations(eventId);
    } catch (e) {
      throw Exception('未処理違反記録の取得に失敗しました: $e');
    }
  }

  /// 違反記録の統計を取得
  Future<ViolationStatistics> getViolationStatistics(String eventId) async {
    try {
      return await _violationRepository.getViolationStatistics(eventId);
    } catch (e) {
      throw Exception('違反記録統計の取得に失敗しました: $e');
    }
  }

  /// 警告履歴を取得（軽微〜中程度の違反記録）
  Future<List<ViolationRecord>> getWarningHistory(String eventId) async {
    try {
      final allViolations = await _violationRepository.getViolationsByEvent(eventId);
      return allViolations.where((violation) =>
          violation.severity == ViolationSeverity.minor ||
          violation.severity == ViolationSeverity.moderate).toList();
    } catch (e) {
      throw Exception('警告履歴の取得に失敗しました: $e');
    }
  }

  /// 違反記録の検索
  Future<List<ViolationRecord>> searchViolations({
    String? eventId,
    String? violatedUserId,
    ViolationType? violationType,
    ViolationSeverity? severity,
    ViolationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      return await _violationRepository.searchViolations(
        eventId: eventId,
        violatedUserId: violatedUserId,
        violationType: violationType,
        severity: severity,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('違反記録の検索に失敗しました: $e');
    }
  }

  /// 違反記録のリアルタイム監視
  Stream<List<ViolationRecord>> watchEventViolations(String eventId) {
    try {
      return _violationRepository.watchViolationsByEvent(eventId);
    } catch (e) {
      throw Exception('違反記録の監視に失敗しました: $e');
    }
  }

  /// ユーザーの違反リスクレベルを計算
  Future<ViolationRiskLevel> calculateUserRiskLevel({
    required String userId,
    required String reporterId,
  }) async {
    try {
      final violationHistory = await getUserViolationHistory(
        userId: userId,
        reporterId: reporterId,
      );

      if (violationHistory.isEmpty) {
        return ViolationRiskLevel.low;
      }

      // 重要度別にポイントを計算
      int riskPoints = 0;
      for (final violation in violationHistory) {
        if (violation.status == ViolationStatus.resolved) {
          riskPoints += violation.severity.penaltyLevel;
        }
      }

      // 最近の違反を重く評価
      final recentViolations = violationHistory.where((violation) =>
        DateTime.now().difference(violation.reportedAt).inDays <= 30
      ).length;

      riskPoints += recentViolations * 2;

      // リスクレベルを判定
      if (riskPoints >= 8) {
        return ViolationRiskLevel.high;
      } else if (riskPoints >= 4) {
        return ViolationRiskLevel.medium;
      } else if (riskPoints >= 1) {
        return ViolationRiskLevel.low;
      } else {
        return ViolationRiskLevel.none;
      }
    } catch (e) {
      throw Exception('違反リスクレベルの計算に失敗しました: $e');
    }
  }

  /// 違反記録を削除（管理者のみ）
  Future<void> deleteViolation(String violationId) async {
    try {
      await _violationRepository.deleteViolation(violationId);
    } catch (e) {
      throw Exception('違反記録の削除に失敗しました: $e');
    }
  }

  /// 違反記録を復旧する（未処理状態に戻す）
  Future<void> revertViolation({
    required String violationId,
    String? notes,
  }) async {
    try {
      // 既存の違反記録を取得
      final existingViolation = await _violationRepository.getViolation(violationId);
      if (existingViolation == null) {
        throw Exception('違反記録が見つかりません');
      }

      // 既に未処理状態の場合はエラー
      if (existingViolation.status == ViolationStatus.pending) {
        throw Exception('この違反記録は既に未処理状態です');
      }

      // 更新された違反記録を作成（未処理状態に戻す）
      final updatedViolation = existingViolation.copyWith(
        status: ViolationStatus.pending,
        penalty: null, // ペナルティをクリア
        resolvedAt: null, // 解決日時をクリア
        resolvedByUserId: null, // 解決者をクリア
        notes: notes ?? existingViolation.notes, // 新しいメモがあれば更新
      );

      await _violationRepository.updateViolation(updatedViolation);
    } catch (e) {
      throw Exception('違反記録の復旧に失敗しました: $e');
    }
  }

  /// 一括処理：複数の違反記録を一度に処理
  Future<void> batchResolveViolations({
    required List<String> violationIds,
    required String resolvedByUserId,
    required String penalty,
    String? notes,
  }) async {
    try {
      final updates = {
        'status': ViolationStatus.resolved.name,
        'penalty': penalty,
        'notes': notes,
        'resolvedAt': DateTime.now(),
        'resolvedByUserId': resolvedByUserId,
      };

      await _violationRepository.batchUpdateViolations(violationIds, updates);
    } catch (e) {
      throw Exception('違反記録の一括処理に失敗しました: $e');
    }
  }

  /// 運営者が管理する全ての違反記録を取得
  Future<List<ViolationRecord>> getOrganizerViolations(String organizerId) async {
    try {
      return await _violationRepository.getViolationsForOrganizer(organizerId);
    } catch (e) {
      throw Exception('運営者違反記録の取得に失敗しました: $e');
    }
  }

  /// テスト用の違反記録を作成（開発時のみ使用）
  Future<void> createTestViolations({
    required String eventId,
    required String eventName,
    required String reporterId,
    int count = 3,
  }) async {
    try {
      // テストデータ作成開始

      final testViolations = [
        ViolationRecord(
          eventId: eventId,
          eventName: eventName,
          violatedUserId: 'test_user_1',
          reportedByUserId: reporterId,
          reportedByUserName: 'テスト運営者',
          violationType: ViolationType.abusiveLanguage,
          description: 'テストイベント中に不適切な発言を行った',
          severity: ViolationSeverity.moderate,
          reportedAt: DateTime.now().subtract(const Duration(days: 1)),
          status: ViolationStatus.pending,
        ),
        ViolationRecord(
          eventId: eventId,
          eventName: eventName,
          violatedUserId: 'test_user_2',
          reportedByUserId: reporterId,
          reportedByUserName: 'テスト運営者',
          violationType: ViolationType.noShow,
          description: 'イベント参加申請後の無断欠席',
          severity: ViolationSeverity.minor,
          reportedAt: DateTime.now().subtract(const Duration(days: 2)),
          status: ViolationStatus.resolved,
          penalty: '警告',
          resolvedAt: DateTime.now().subtract(const Duration(hours: 12)),
          resolvedByUserId: reporterId,
        ),
        ViolationRecord(
          eventId: eventId,
          eventName: eventName,
          violatedUserId: 'test_user_3',
          reportedByUserId: reporterId,
          reportedByUserName: 'テスト運営者',
          violationType: ViolationType.harassment,
          description: '他の参加者に対する嫌がらせ行為',
          severity: ViolationSeverity.severe,
          reportedAt: DateTime.now().subtract(const Duration(days: 3)),
          status: ViolationStatus.underReview,
        ),
      ];

      for (int i = 0; i < count && i < testViolations.length; i++) {
        await _violationRepository.createViolation(testViolations[i]);
        // テストデータ作成完了
      }

      // 全テストデータ作成完了
    } catch (e) {
      throw Exception('テストデータの作成に失敗しました: $e');
    }
  }

  /// Firestoreコレクションの存在確認（デバッグ用）
  Future<bool> checkCollectionExists() async {
    try {
      final testQuery = await _violationRepository.collection.limit(1).get();
      // コレクション確認完了
      return true;
    } catch (e) {
      // コレクション確認エラー
      return false;
    }
  }

  /// 違反記録を取得
  Future<ViolationRecord?> getViolation(String violationId) async {
    try {
      return await _violationRepository.getViolation(violationId);
    } catch (e) {
      // 違反記録取得エラー
      return null;
    }
  }

  /// 異議申立を提出
  Future<void> submitAppeal({
    required String violationId,
    required String appealText,
    required String appellantUserId,
  }) async {
    try {
      // 異議申立提出開始

      await _violationRepository.updateViolationById(
        violationId,
        {
          'appealText': appealText,
          'appealedAt': DateTime.now(),
          'appealStatus': AppealStatus.pending.name,
        },
      );

      // 異議申立提出完了
    } catch (e) {
      // 異議申立提出エラー
      throw Exception('異議申立の提出に失敗しました: $e');
    }
  }

  /// 異議申立を処理
  Future<void> processAppeal({
    required String violationId,
    required AppealStatus appealStatus,
    required String appealResponse,
    required String processorUserId,
  }) async {
    try {
      // 異議申立処理開始

      final updateData = {
        'appealStatus': appealStatus.name,
        'appealResponse': appealResponse,
        'appealResolvedAt': DateTime.now(),
        'appealResolvedByUserId': processorUserId,
      };

      // 異議が承認された場合は、違反記録を取り消し状態にする
      if (appealStatus == AppealStatus.approved) {
        updateData['status'] = ViolationStatus.dismissed.name;
        updateData['notes'] = '異議申立により取り消し';
      }

      await _violationRepository.updateViolationById(violationId, updateData);

      // 異議申立処理完了
    } catch (e) {
      // 異議申立処理エラー
      throw Exception('異議申立の処理に失敗しました: $e');
    }
  }

  /// 異議申立期限を計算（一律24時間）
  DateTime _calculateAppealDeadline(ViolationSeverity severity, DateTime reportedAt) {
    // イベントでの違反行為のため、一律24時間の猶予期間
    return reportedAt.add(const Duration(hours: 24));
  }

  /// 運営者が異議申立期間を待たずに処理可能かどうかを判定
  bool canProcessWithoutAppeal(ViolationRecord violation) {
    if (violation.appealDeadline == null) {
      return true; // 期限が設定されていない場合は処理可能
    }

    final now = DateTime.now();
    final hasActiveAppeal = violation.appealText != null &&
                          violation.appealStatus != null &&
                          violation.appealStatus!.requiresAction;

    // 異議申立が提出されている場合は、異議申立処理が必要
    if (hasActiveAppeal) {
      return false;
    }

    // 異議申立期限が過ぎている場合は処理可能
    return now.isAfter(violation.appealDeadline!);
  }

  /// 残り異議申立期間を取得（時間）
  int? getRemainingAppealHours(ViolationRecord violation) {
    if (violation.appealDeadline == null) {
      return null;
    }

    final now = DateTime.now();
    final difference = violation.appealDeadline!.difference(now);

    if (difference.isNegative) {
      return 0; // 期限切れ
    }

    return difference.inHours + 1; // 1時間未満も1時間として扱う
  }

  /// 違反記録の猶予期間情報を更新
  Future<void> updateAppealGracePeriod({
    required String violationId,
    DateTime? newAppealDeadline,
    bool? canProcess,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (newAppealDeadline != null) {
        updateData['appealDeadline'] = newAppealDeadline;
      }

      if (canProcess != null) {
        updateData['canProcessWithoutAppeal'] = canProcess;
      }

      await _violationRepository.updateViolationById(violationId, updateData);
    } catch (e) {
      throw Exception('猶予期間情報の更新に失敗しました: $e');
    }
  }
}

/// 違反リスクレベル
enum ViolationRiskLevel {
  none('リスクなし', 'これまでに違反記録はありません'),
  low('低リスク', '軽微な違反が1〜2件あります'),
  medium('中リスク', '中程度以上の違反があるか、複数の違反があります'),
  high('高リスク', '重大な違反があるか、多数の違反履歴があります');

  const ViolationRiskLevel(this.displayName, this.description);

  final String displayName;
  final String description;

  /// リスクレベルに対応する色を取得
  // TODO: AppColorsをインポートして適切な色を返す
  String get colorCode {
    switch (this) {
      case ViolationRiskLevel.none:
        return '#4CAF50'; // 緑
      case ViolationRiskLevel.low:
        return '#8BC34A'; // 薄緑
      case ViolationRiskLevel.medium:
        return '#FF9800'; // オレンジ
      case ViolationRiskLevel.high:
        return '#F44336'; // 赤
    }
  }
}