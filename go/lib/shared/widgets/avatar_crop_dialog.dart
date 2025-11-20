import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// アバター画像を丸形に加工するダイアログ
class AvatarCropDialog extends StatefulWidget {
  final File imageFile;

  const AvatarCropDialog({
    super.key,
    required this.imageFile,
  });

  /// 画像を選択・撮影してクロップする
  static Future<File?> cropImage(BuildContext context, File imageFile) {
    return showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AvatarCropDialog(imageFile: imageFile),
    );
  }

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  File? _croppedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cropImage();
  }

  Future<void> _cropImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'プロフィール画像を調整',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.textOnPrimary,
            backgroundColor: AppColors.backgroundDark,
            activeControlsWidgetColor: AppColors.accent,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            statusBarColor: AppColors.primary,
            cropFrameColor: AppColors.accent,
            cropGridColor: AppColors.accent.withValues(alpha: 0.5),
            cropFrameStrokeWidth: 2,
            cropGridStrokeWidth: 1,
            showCropGrid: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'プロフィール画像を調整',
            doneButtonTitle: '完了',
            cancelButtonTitle: 'キャンセル',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
            rotateClockwiseButtonHidden: false,
            hidesNavigationBar: true,
            rectX: 0,
            rectY: 0,
            rectWidth: 300,
            rectHeight: 300,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _croppedFile = File(croppedFile.path);
          _isLoading = false;
        });
      } else {
        // キャンセルされた場合
        if (mounted) {
          Navigator.of(context).pop(null);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('画像の加工に失敗しました: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(null);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        backgroundColor: AppColors.backgroundLight,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              const Text(
                '画像を読み込んでいます...',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_croppedFile == null) {
      return const SizedBox();
    }

    return Dialog(
      backgroundColor: AppColors.backgroundLight,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            const Text(
              'プロフィール画像の確認',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // 加工後画像プレビュー
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: AppDimensions.cardElevation,
                    offset: const Offset(0, AppDimensions.shadowOffsetY),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.file(
                  _croppedFile!,
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            const Text(
              'この画像をプロフィール画像として使用しますか？',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // ボタン
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingM,
                      ),
                      backgroundColor: AppColors.backgroundLight,
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_croppedFile),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spacingM,
                      ),
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '使用する',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}