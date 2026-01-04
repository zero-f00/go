import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart' show L10n;
import '../../data/models/notification_model.dart';

/// 通知メッセージのローカライズヘルパー
class NotificationLocalizationHelper {
  /// ローカライズされた通知タイトルを取得
  static String getLocalizedTitle(BuildContext context, NotificationData notification) {
    final l10n = L10n.of(context);
    final data = notification.data ?? {};

    switch (notification.type) {
      case NotificationType.eventApproved:
        return l10n.notificationEventApprovedTitle;

      case NotificationType.eventRejected:
        return l10n.notificationEventRejectedTitle;

      case NotificationType.eventApplication:
        return l10n.notificationEventApplicationTitle;

      case NotificationType.violationReported:
        // 運営者向けか違反者向けかを判断
        final isAnonymous = data['isAnonymous'] as bool? ?? true;
        if (isAnonymous) {
          return l10n.notificationViolationReportedToViolatedTitle;
        } else {
          return l10n.notificationViolationReportedToOrganizerTitle;
        }

      case NotificationType.violationProcessed:
        final status = data['status'] as String?;
        if (status == 'dismissed') {
          return l10n.notificationViolationProcessedDismissedTitle;
        }
        return l10n.notificationViolationProcessedResolvedTitle;

      case NotificationType.violationDismissed:
        // 報告者向けか違反者向けかを判断
        if (notification.title.contains('報告した') || notification.title.contains('Your Reported')) {
          return l10n.notificationViolationDismissedToReporterTitle;
        }
        return l10n.notificationViolationDismissedToViolatedTitle;

      case NotificationType.violationDeleted:
        if (notification.title.contains('報告した') || notification.title.contains('Your Reported')) {
          return l10n.notificationViolationDeletedToReporterTitle;
        }
        return l10n.notificationViolationDeletedToViolatedTitle;

      case NotificationType.appealSubmitted:
        return l10n.notificationAppealSubmittedTitle;

      case NotificationType.appealProcessed:
        final appealStatus = data['appealStatus'] as String?;
        if (appealStatus == 'approved') {
          return l10n.notificationAppealApprovedTitle;
        }
        return l10n.notificationAppealRejectedTitle;

      case NotificationType.eventReminder:
        return l10n.notificationEventReminderTitle;

      case NotificationType.eventUpdated:
        final hasCriticalChanges = data['hasCriticalChanges'] as bool? ?? false;
        if (hasCriticalChanges) {
          return l10n.notificationEventUpdateImportantTitle;
        }
        return l10n.notificationEventUpdateTitle;

      case NotificationType.eventDraftReverted:
        return l10n.notificationEventDraftRevertedTitle;

      case NotificationType.eventCancelled:
        return l10n.notificationEventCancellationTitle;

      case NotificationType.eventCancelProcessed:
        return l10n.notificationEventCancellationManagerTitle;

      case NotificationType.follow:
        return l10n.notificationNewFollowerTitle;

      case NotificationType.eventInvite:
        return l10n.notificationEventInviteTitle;

      case NotificationType.eventWaitlist:
        // タイトルで登録完了かどうか判断
        if (notification.title.contains('登録完了') || notification.title.contains('Registration')) {
          return l10n.notificationEventWaitlistRegisteredTitle;
        }
        return l10n.notificationEventWaitlistTitle;

      case NotificationType.eventFull:
        return l10n.notificationEventFullTitle;

      case NotificationType.eventCapacityWarning:
        // タイトルで空き枠発生か定員間近かを判断
        if (notification.title.contains('空き枠') || notification.title.contains('Vacancy')) {
          return l10n.notificationEventCapacityVacancyTitle;
        }
        return l10n.notificationEventCapacityWarningTitle;

      case NotificationType.participantCancelled:
        return l10n.notificationParticipantCancelledTitle;

      case NotificationType.matchReport:
        return l10n.notificationMatchReportTitle;

      case NotificationType.matchReportResponse:
        return l10n.notificationMatchReportResponseTitle;

      // その他のタイプはデフォルトのタイトルを使用
      default:
        return notification.title;
    }
  }

  /// ローカライズされた通知メッセージを取得
  static String getLocalizedMessage(BuildContext context, NotificationData notification) {
    final l10n = L10n.of(context);
    final data = notification.data ?? {};

    switch (notification.type) {
      case NotificationType.eventApproved:
        final eventName = data['eventName'] as String? ?? '';
        final adminMessage = data['adminMessage'] as String?;
        if (adminMessage != null && adminMessage.isNotEmpty) {
          return l10n.notificationEventApprovedWithAdminMessage(eventName, adminMessage);
        }
        return l10n.notificationEventApprovedMessage(eventName);

      case NotificationType.eventRejected:
        final eventName = data['eventName'] as String? ?? '';
        final adminMessage = data['adminMessage'] as String?;
        if (adminMessage != null && adminMessage.isNotEmpty) {
          return l10n.notificationEventRejectedWithAdminMessage(eventName, adminMessage);
        }
        return l10n.notificationEventRejectedMessage(eventName);

      case NotificationType.eventApplication:
        final eventTitle = data['eventTitle'] as String? ?? '';
        final applicantUsername = data['applicantUsername'] as String? ?? '';
        return l10n.notificationEventApplicationMessage(applicantUsername, eventTitle);

      case NotificationType.violationReported:
        final eventName = data['eventName'] as String? ?? '';
        final isAnonymous = data['isAnonymous'] as bool? ?? true;
        if (isAnonymous) {
          return l10n.notificationViolationReportedToViolatedMessage(eventName);
        }
        return l10n.notificationViolationReportedToOrganizerMessage(eventName);

      case NotificationType.violationProcessed:
        final eventName = data['eventName'] as String? ?? '';
        final status = data['status'] as String?;
        final penalty = data['penalty'] as String?;
        if (status == 'dismissed') {
          return l10n.notificationViolationProcessedDismissedMessage(eventName);
        }
        if (penalty != null && penalty.isNotEmpty) {
          return l10n.notificationViolationProcessedResolvedWithPenalty(eventName, penalty);
        }
        return l10n.notificationViolationProcessedResolvedMessage(eventName);

      case NotificationType.violationDismissed:
        final eventName = data['eventName'] as String? ?? '';
        final reason = data['reason'] as String?;
        // 報告者向けか違反者向けか運営者向けかを判断
        if (notification.title.contains('報告した') || notification.title.contains('Your Reported')) {
          return l10n.notificationViolationDismissedToReporterMessage(eventName);
        }
        if (data['dismissedByUserId'] != null && notification.fromUserId != null) {
          // 運営者向け
          if (reason != null && reason.isNotEmpty) {
            return l10n.notificationViolationDismissedToOrganizerWithReason(eventName, reason);
          }
          return l10n.notificationViolationDismissedToOrganizerMessage(eventName);
        }
        // 違反者向け
        if (reason != null && reason.isNotEmpty) {
          return l10n.notificationViolationDismissedToViolatedWithReason(eventName, reason);
        }
        return l10n.notificationViolationDismissedToViolatedMessage(eventName);

      case NotificationType.violationDeleted:
        final eventName = data['eventName'] as String? ?? '';
        final reason = data['reason'] as String?;
        if (notification.title.contains('報告した') || notification.title.contains('Your Reported')) {
          return l10n.notificationViolationDeletedToReporterMessage(eventName);
        }
        if (data['deletedByUserId'] != null && notification.fromUserId != null) {
          // 運営者向け
          if (reason != null && reason.isNotEmpty) {
            return l10n.notificationViolationDeletedToOrganizerWithReason(eventName, reason);
          }
          return l10n.notificationViolationDeletedToOrganizerMessage(eventName);
        }
        // 違反者向け
        if (reason != null && reason.isNotEmpty) {
          return l10n.notificationViolationDeletedToViolatedWithReason(eventName, reason);
        }
        return l10n.notificationViolationDeletedToViolatedMessage(eventName);

      case NotificationType.appealSubmitted:
        final eventName = data['eventName'] as String? ?? '';
        return l10n.notificationAppealSubmittedMessage(eventName);

      case NotificationType.appealProcessed:
        final eventName = data['eventName'] as String? ?? '';
        final appealStatus = data['appealStatus'] as String?;
        final appealResponse = data['appealResponse'] as String?;
        String baseMessage;
        if (appealStatus == 'approved') {
          baseMessage = l10n.notificationAppealApprovedMessage(eventName);
        } else {
          baseMessage = l10n.notificationAppealRejectedMessage(eventName);
        }
        if (appealResponse != null && appealResponse.isNotEmpty) {
          baseMessage += l10n.notificationAppealWithResponseSuffix(appealResponse);
        }
        return baseMessage;

      case NotificationType.eventReminder:
        final eventName = data['eventName'] as String? ?? '';
        final hoursUntilEvent = data['hoursUntilEvent'] as int?;
        final timeText = hoursUntilEvent != null
            ? l10n.notificationEventReminderTimeHours(hoursUntilEvent)
            : l10n.notificationEventReminderTimeSoon;
        return l10n.notificationEventReminderMessage(eventName, timeText);

      case NotificationType.eventUpdated:
        final eventName = data['eventName'] as String? ?? '';
        final updatedByUserName = data['updatedByUserName'] as String? ?? '';
        // 変更サマリーをローカライズ
        final localizedChangesSummary = _generateLocalizedChangesSummary(l10n, data);
        return l10n.notificationEventUpdateMessage(eventName, updatedByUserName, localizedChangesSummary);

      case NotificationType.eventDraftReverted:
        final eventName = data['eventName'] as String? ?? '';
        return l10n.notificationEventDraftRevertedMessage(eventName);

      case NotificationType.eventCancelled:
        final eventName = data['eventName'] as String? ?? '';
        final reason = data['reason'] as String? ?? '';
        final isApproved = data['isApproved'] as bool? ?? false;
        if (isApproved) {
          return l10n.notificationEventCancellationApprovedMessage(eventName, reason);
        }
        return l10n.notificationEventCancellationPendingMessage(eventName, reason);

      case NotificationType.eventCancelProcessed:
        final eventName = data['eventName'] as String? ?? '';
        final reason = data['reason'] as String? ?? '';
        final participantCount = data['participantCount'] as int? ?? 0;
        final pendingCount = data['pendingCount'] as int? ?? 0;
        return l10n.notificationEventCancellationManagerMessage(
          eventName, participantCount, pendingCount, reason);

      case NotificationType.follow:
        final fromUserName = data['fromUserName'] as String? ?? '';
        return l10n.notificationNewFollowerMessage(fromUserName);

      case NotificationType.eventInvite:
        final createdByName = data['createdByName'] as String? ?? '';
        final eventName = data['eventName'] as String? ?? '';
        return l10n.notificationEventInviteMessage(createdByName, eventName);

      case NotificationType.eventWaitlist:
        final eventName = data['eventName'] as String? ?? '';
        final waitlistPosition = data['waitlistPosition'] as int? ?? 1;
        // タイトルで登録完了かどうか判断
        if (notification.title.contains('登録完了') || notification.title.contains('Registration')) {
          return l10n.notificationEventWaitlistRegisteredMessage(eventName, waitlistPosition);
        }
        return l10n.notificationEventWaitlistMessage(eventName, waitlistPosition);

      case NotificationType.eventFull:
        final eventName = data['eventName'] as String? ?? '';
        return l10n.notificationEventFullMessage(eventName);

      case NotificationType.eventCapacityWarning:
        final eventName = data['eventName'] as String? ?? '';
        // 空き枠発生かどうかを判断
        if (notification.title.contains('空き枠') || notification.title.contains('Vacancy')) {
          final waitlistCount = data['waitlistCount'] as int? ?? 0;
          return l10n.notificationEventCapacityVacancyMessage(eventName, waitlistCount);
        }
        final percentage = data['percentage'] as int? ?? 0;
        final currentCount = data['currentCount'] as int? ?? 0;
        final maxParticipants = data['maxParticipants'] as int? ?? 0;
        return l10n.notificationEventCapacityWarningMessage(eventName, percentage, currentCount, maxParticipants);

      case NotificationType.participantCancelled:
        final eventName = data['eventName'] as String? ?? '';
        final userName = data['userName'] as String? ?? '';
        final cancellationReason = data['cancellationReason'] as String? ?? '';
        return l10n.notificationParticipantCancelledMessage(eventName, userName, cancellationReason);

      case NotificationType.matchReport:
        return l10n.notificationMatchReportMessage;

      case NotificationType.matchReportResponse:
        return l10n.notificationMatchReportResponseMessage;

      // その他のタイプはデフォルトのメッセージを使用
      default:
        return notification.message;
    }
  }

  /// ローカライズされたカテゴリ表示名を取得
  static String getLocalizedCategoryDisplayName(BuildContext context, NotificationData notification) {
    final l10n = L10n.of(context);

    switch (notification.type) {
      // ignore: deprecated_member_use_from_same_package
      case NotificationType.friendRequest:
      // ignore: deprecated_member_use_from_same_package
      case NotificationType.friendAccepted:
      // ignore: deprecated_member_use_from_same_package
      case NotificationType.friendRejected:
      case NotificationType.follow:
        return l10n.notificationCategoryFollow;
      case NotificationType.eventInvite:
      case NotificationType.eventReminder:
      case NotificationType.eventApproved:
      case NotificationType.eventRejected:
      case NotificationType.eventApplication:
      case NotificationType.eventUpdated:
      case NotificationType.eventDraftReverted:
      case NotificationType.eventCancelled:
      case NotificationType.eventCancelProcessed:
      case NotificationType.eventFull:
      case NotificationType.eventCapacityWarning:
      case NotificationType.eventWaitlist:
      case NotificationType.participantCancelled:
        return l10n.notificationCategoryEvent;
      case NotificationType.violationReported:
      case NotificationType.violationProcessed:
      case NotificationType.violationDismissed:
      case NotificationType.violationDeleted:
      case NotificationType.appealSubmitted:
      case NotificationType.appealProcessed:
        return l10n.notificationCategoryViolation;
      case NotificationType.matchReport:
      case NotificationType.matchReportResponse:
        return l10n.notificationCategoryMatch;
      case NotificationType.system:
        return l10n.notificationCategorySystem;
    }
  }

  /// イベント更新のローカライズされた変更サマリーを生成
  static String _generateLocalizedChangesSummary(L10n l10n, Map<String, dynamic> data) {
    final criticalCount = data['criticalChangeCount'] as int? ?? 0;
    final moderateCount = data['moderateChangeCount'] as int? ?? 0;
    final minorCount = data['minorChangeCount'] as int? ?? 0;
    final hasCriticalChanges = data['hasCriticalChanges'] as bool? ?? false;
    final hasModerateChanges = data['hasModerateChanges'] as bool? ?? false;
    final hasMinorChanges = data['hasMinorChanges'] as bool? ?? false;

    // 新しいデータ形式の場合はローカライズされたサマリーを生成
    if (criticalCount > 0 || moderateCount > 0 || minorCount > 0) {
      final summaryParts = <String>[];

      if (hasCriticalChanges && criticalCount > 0) {
        summaryParts.add(l10n.eventChangeSummaryCritical(criticalCount));
      }

      if (hasModerateChanges && moderateCount > 0) {
        summaryParts.add(l10n.eventChangeSummaryModerate(moderateCount));
      }

      if (hasMinorChanges && minorCount > 0) {
        summaryParts.add(l10n.eventChangeSummaryMinor(minorCount));
      }

      if (summaryParts.isEmpty) {
        return l10n.eventChangeSummaryNoChanges;
      }

      return summaryParts.join(', ');
    }

    // 古いデータ形式の場合はそのままchangesSummaryを使用（後方互換性）
    final changesSummary = data['changesSummary'] as String? ?? '';
    if (changesSummary.isNotEmpty) {
      return changesSummary;
    }

    return l10n.eventChangeSummaryNoChanges;
  }
}
