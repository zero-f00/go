import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// 配信URL入力ウィジェット
/// 複数の配信URLを追加・削除できる
class StreamingUrlInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final List<String> initialUrls;
  final int maxUrls;
  final Function(List<String>)? onChanged;
  final String? Function(List<String>)? validator;
  final bool isEnabled;

  const StreamingUrlInputField({
    super.key,
    this.label,
    this.hint,
    this.initialUrls = const [],
    this.maxUrls = 5,
    this.onChanged,
    this.validator,
    this.isEnabled = true,
  });

  @override
  State<StreamingUrlInputField> createState() => _StreamingUrlInputFieldState();
}

class _StreamingUrlInputFieldState extends State<StreamingUrlInputField> {
  late List<String> _urls;
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _urls = List.from(widget.initialUrls);
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// URLの追加
  void _addUrl(String url) {
    final trimmedUrl = url.trim();

    if (trimmedUrl.isEmpty) return;

    // 重複チェック
    if (_urls.contains(trimmedUrl)) {
      setState(() {
        _errorText = 'このURLは既に追加されています';
      });
      return;
    }

    // 最大数チェック
    if (_urls.length >= widget.maxUrls) {
      setState(() {
        _errorText = '最大${widget.maxUrls}個まで配信URLを追加できます';
      });
      return;
    }

    // URL形式チェック
    if (!_isValidUrl(trimmedUrl)) {
      setState(() {
        _errorText = '有効なURLを入力してください (https://... または http://...)';
      });
      return;
    }

    setState(() {
      _urls.add(trimmedUrl);
      _controller.clear();
      _errorText = null;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(_urls);
    }
  }

  /// URLの削除
  void _removeUrl(int index) {
    setState(() {
      _urls.removeAt(index);
      _errorText = null;
    });

    if (widget.onChanged != null) {
      widget.onChanged!(_urls);
    }
  }

  /// URLの有効性チェック
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// エンターキー押下時の処理
  void _onSubmitted(String value) {
    _addUrl(value);
  }

  /// バリデーション実行
  String? _runValidation() {
    if (widget.validator != null) {
      return widget.validator!(_urls);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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

        // URL追加フィールド
        TextFormField(
          controller: _controller,
          enabled: widget.isEnabled && _urls.length < widget.maxUrls,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: widget.hint ?? 'https://... と入力してEnterで追加',
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: AppDimensions.fontSizeM,
            ),
            suffixIcon: IconButton(
              onPressed: widget.isEnabled && _controller.text.isNotEmpty
                  ? () => _addUrl(_controller.text)
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
              right: 48,
              top: AppDimensions.spacingM,
              bottom: AppDimensions.spacingM,
            ),
          ),
          onFieldSubmitted: widget.isEnabled ? _onSubmitted : null,
          onChanged: (value) {
            if (_errorText != null) {
              setState(() {
                _errorText = null;
              });
            }
          },
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

        // URL数の表示
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          '${_urls.length}/${widget.maxUrls}個の配信URL',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: AppDimensions.fontSizeS,
          ),
        ),

        // 既存URL一覧
        if (_urls.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingM),
          Column(
            children: _urls.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;

              return _UrlCard(
                url: url,
                onDeleted: widget.isEnabled ? () => _removeUrl(index) : null,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

/// URL表示カードウィジェット
class _UrlCard extends StatelessWidget {
  final String url;
  final VoidCallback? onDeleted;

  const _UrlCard({
    required this.url,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        child: Row(
          children: [
            // URLアイコン
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXS),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: const Icon(
                Icons.link,
                size: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),

            // URL文字列
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    url,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _extractDomain(url),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppDimensions.fontSizeS,
                    ),
                  ),
                ],
              ),
            ),

            // 削除ボタン
            if (onDeleted != null)
              IconButton(
                onPressed: onDeleted,
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                tooltip: 'URLを削除',
              ),
          ],
        ),
      ),
    );
  }

  /// URLからドメイン名を抽出
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return 'Invalid URL';
    }
  }
}