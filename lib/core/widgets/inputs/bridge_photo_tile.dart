import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// A filled photo tile used in the mission perform photo grid
/// (`426-19035` / `426-18995` / `426-18974` per `docs/figma-specs/11-mission.md` §5).
///
/// Renders a 157 × 156 rounded-corner image preview of a file at [path]
/// with a circular black-overlay × button at the top-right that triggers
/// [onDelete]. Falls back to a gray placeholder with `broken_image` if the
/// underlying file cannot be decoded (e.g. the user deleted it externally
/// or the path is stale).
///
/// Pairs with [BridgeAddPhotoTile] in the grid layout — that one shows
/// the dashed "추가 업로드" affordance for capturing another photo.
class BridgePhotoTile extends StatelessWidget {
  const BridgePhotoTile({
    super.key,
    required this.path,
    required this.onDelete,
  });

  /// Absolute path to the captured image file (from `image_picker`).
  final String path;

  /// Invoked when the user taps the top-right × close glyph.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 157,
            height: 156,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 157,
              height: 156,
              color: AppColors.gray200,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.gray400,
                size: 32,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A dashed-border "add more" tile used in the mission perform photo grid
/// when `photos.length < 4`. Mirrors the small variant of `BridgeCameraCTA`
/// described in `docs/figma-specs/11-mission.md` §5.
///
/// Visual: 157 × 156, radius 8, [AppColors.gray100] background, dashed 2 px
/// [AppColors.gray400] border, with a centered column of camera icon +
/// label (defaults to "추가 업로드"). Tapping anywhere on the tile fires
/// [onTap], which should launch the camera (NOT the gallery — see the
/// critical annotation in spec §3).
class BridgeAddPhotoTile extends StatelessWidget {
  const BridgeAddPhotoTile({
    super.key,
    required this.onTap,
    this.label = '추가 업로드',
  });

  /// Invoked when the user taps the tile. Callers should open the camera.
  final VoidCallback onTap;

  /// Label rendered under the camera icon. Defaults to `'추가 업로드'`.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DottedBorder(
          color: AppColors.gray400,
          strokeWidth: 2,
          dashPattern: const [6, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          child: Container(
            width: 157,
            height: 156,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 28,
                    color: AppColors.gray700,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
