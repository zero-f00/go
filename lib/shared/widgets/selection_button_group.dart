import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// 選択ボタングループウィジェット
/// 単一選択用のボタングループを表示
class SelectionButtonGroup<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T? selectedOption;
  final Function(T) onSelectionChanged;
  final String Function(T) optionBuilder;
  final String Function(T)? tooltipBuilder;
  final bool isRequired;

  const SelectionButtonGroup({
    super.key,
    required this.label,
    required this.options,
    this.selectedOption,
    required this.onSelectionChanged,
    required this.optionBuilder,
    this.tooltipBuilder,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label + (isRequired ? ' *' : ''),
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            return GestureDetector(
              onTap: () => onSelectionChanged(option),
              child: Tooltip(
                message: tooltipBuilder?.call(option) ?? '',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                    vertical: AppDimensions.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    optionBuilder(option),
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? AppColors.textWhite : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}