import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/event_model.dart';
import '../../l10n/app_localizations.dart';

class PastEventsSelectionDialog extends StatefulWidget {
  final List<Event> pastEvents;
  final String title;
  final String emptyMessage;

  const PastEventsSelectionDialog({
    super.key,
    required this.pastEvents,
    required this.title,
    required this.emptyMessage,
  });

  static Future<Event?> show(
    BuildContext context, {
    required List<Event> pastEvents,
    String? title,
    String? emptyMessage,
  }) async {
    final l10n = L10n.of(context);
    return await showDialog<Event?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PastEventsSelectionDialog(
        pastEvents: pastEvents,
        title: title ?? l10n.selectFromPastEvents,
        emptyMessage: emptyMessage ?? l10n.noCopyableEventsMessage,
      ),
    );
  }

  @override
  State<PastEventsSelectionDialog> createState() =>
      _PastEventsSelectionDialogState();
}

class _PastEventsSelectionDialogState extends State<PastEventsSelectionDialog> {
  String _searchQuery = '';
  List<Event> _filteredEvents = [];

  @override
  void initState() {
    super.initState();
    _filteredEvents = widget.pastEvents;
  }

  void _filterEvents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEvents = widget.pastEvents;
      } else {
        _filteredEvents = widget.pastEvents
            .where(
              (event) =>
                  event.name.toLowerCase().contains(query.toLowerCase()) ||
                  (event.gameName?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Dialog(
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeXL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textLight),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // 検索バー
            TextField(
              onChanged: _filterEvents,
              decoration: InputDecoration(
                hintText: l10n.searchEventsPlaceholder,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // イベント一覧
            Expanded(
              child: _filteredEvents.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        return _buildEventItem(context, _filteredEvents[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = L10n.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: AppDimensions.iconXXL,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            _searchQuery.isNotEmpty ? l10n.noSearchResults : widget.emptyMessage,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.tryDifferentKeyword,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, Event event) {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Material(
        color: AppColors.backgroundTransparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pop(event),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: AppDimensions.cardElevation / 2,
                  offset: const Offset(0, AppDimensions.shadowOffsetY / 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // イベント画像
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(color: AppColors.border),
                    image: event.imageUrl != null && event.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(event.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: event.imageUrl == null || event.imageUrl!.isEmpty
                      ? const Icon(
                          Icons.image_not_supported,
                          color: AppColors.textLight,
                          size: AppDimensions.iconM,
                        )
                      : null,
                ),
                const SizedBox(width: AppDimensions.spacingL),

                // イベント情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.gameName != null &&
                          event.gameName!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          event.gameName!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: AppDimensions.iconS,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppDimensions.spacingXS),
                          Expanded(
                            child: Text(
                              _formatDate(context, event.eventDate),
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Icon(
                            Icons.group,
                            size: AppDimensions.iconS,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppDimensions.spacingXS),
                          Flexible(
                            child: Text(
                              l10n.participantCountFormat(event.participantIds.length, event.maxParticipants),
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 選択アイコン
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
  }
}
