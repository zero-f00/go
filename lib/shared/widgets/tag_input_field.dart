import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// タグ入力ウィジェット
/// ユーザが自由にタグを追加・削除できる
class TagInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<String> initialTags;
  final int maxTags;
  final int maxTagLength;
  final Function(List<String>)? onChanged;
  final String? Function(List<String>)? validator;
  final bool isEnabled;

  const TagInputField({
    super.key,
    this.label,
    this.hint,
    this.initialTags = const [],
    this.maxTags = 10,
    this.maxTagLength = 20,
    this.onChanged,
    this.validator,
    this.isEnabled = true,
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  late List<String> _tags;
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// タグの追加
  void _addTag(String tag) {
    final trimmedTag = tag.trim();

    if (trimmedTag.isEmpty) return;

    // 重複チェック
    if (_tags.contains(trimmedTag)) {
      setState(() {
        _errorText = 'このタグは既に追加されています';
      });
      return;
    }

    // 最大数チェック
    if (_tags.length >= widget.maxTags) {
      setState(() {
        _errorText = '最大${widget.maxTags}個までタグを追加できます';
      });
      return;
    }

    // 文字数チェック
    if (trimmedTag.length > widget.maxTagLength) {
      setState(() {
        _errorText = 'タグは${widget.maxTagLength}文字以内で入力してください';
      });
      return;
    }

    // 禁止文字チェック
    if (!_isValidTag(trimmedTag)) {
      setState(() {
        _errorText = 'タグに使用できない文字が含まれています';
      });
      return;
    }

    setState(() {
      _tags.add(trimmedTag);
      _controller.clear();
      _errorText = null;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(_tags);
    }
  }

  /// タグの削除
  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
      _errorText = null;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(_tags);
    }
  }

  /// タグの有効性チェック
  bool _isValidTag(String tag) {
    // 英数字、ひらがな、カタカナ、漢字、一部の記号のみ許可
    final validPattern = RegExp(r'^[a-zA-Z0-9\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAFー・＃＆＠＋－]*$');
    return validPattern.hasMatch(tag);
  }

  /// エンターキー押下時の処理
  void _onSubmitted(String value) {
    _addTag(value);
  }

  /// バリデーション実行
  String? _runValidation() {
    if (widget.validator != null) {
      return widget.validator!(_tags);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // 外部バリデーションチェック
    final externalError = _runValidation();
    final displayError = _errorText ?? externalError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],

        // タグ追加フィールド
        TextFormField(
          controller: _controller,
          enabled: widget.isEnabled && _tags.length < widget.maxTags,
          decoration: InputDecoration(
            hintText: widget.hint ?? 'タグを入力してEnterで追加',
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: AppDimensions.fontSizeM,
            ),
            suffixIcon: IconButton(
              onPressed: widget.isEnabled && _controller.text.isNotEmpty
                  ? () => _addTag(_controller.text)
                  : null,
              icon: const Icon(Icons.add),
            ),
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.only(
              left: AppDimensions.spacingL,
              right: 48, // suffixIconの分のスペースを確保
              top: AppDimensions.spacingM,
              bottom: AppDimensions.spacingM,
            ),
          ),
          onFieldSubmitted: widget.isEnabled ? _onSubmitted : null,
          onChanged: (value) {
            // エラーをクリア
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
          inputFormatters: [
            LengthLimitingTextInputFormatter(widget.maxTagLength),
          ],
        ),

        // エラーメッセージ
        if (displayError != null) ...[
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            displayError,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: AppDimensions.fontSizeS,
            ),
          ),
        ],

        // タグ数の表示
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          '${_tags.length}/${widget.maxTags}個のタグ',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: AppDimensions.fontSizeS,
          ),
        ),

        // 既存タグ一覧
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingS,
            children: _tags.asMap().entries.map((entry) {
              final index = entry.key;
              final tag = entry.value;

              return _TagChip(
                tag: tag,
                onDeleted: widget.isEnabled ? () => _removeTag(index) : null,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// タグチップウィジェット
class _TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onDeleted;

  const _TagChip({
    required this.tag,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppDimensions.spacingS,
              top: AppDimensions.spacingXS,
              bottom: AppDimensions.spacingXS,
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDeleted != null)
            GestureDetector(
              onTap: onDeleted,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppDimensions.spacingXS,
                  right: AppDimensions.spacingS,
                  top: AppDimensions.spacingXS,
                  bottom: AppDimensions.spacingXS,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 既定タグ表示ウィジェット（表示専用）
class TagDisplayWidget extends StatelessWidget {
  final List<String> tags;
  final int? maxDisplay;
  final TextStyle? tagStyle;

  const TagDisplayWidget({
    super.key,
    required this.tags,
    this.maxDisplay,
    this.tagStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTags = maxDisplay != null && tags.length > maxDisplay!
        ? tags.take(maxDisplay!).toList()
        : tags;

    final hasMore = maxDisplay != null && tags.length > maxDisplay!;

    return Wrap(
      spacing: AppDimensions.spacingXS,
      runSpacing: AppDimensions.spacingXS,
      children: [
        ...displayTags.map((tag) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            tag,
            style: tagStyle ?? const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeXS,
            ),
          ),
        )),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: AppDimensions.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              '+${tags.length - maxDisplay!}',
              style: tagStyle ?? const TextStyle(
                color: AppColors.textMuted,
                fontSize: AppDimensions.fontSizeXS,
              ),
            ),
          ),
      ],
    );
  }
}