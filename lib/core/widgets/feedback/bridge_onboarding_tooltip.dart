import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';

/// Which edge of the tooltip body the arrow notch sits on, and therefore
/// which direction it points.
///
/// * [bottomCenter] — arrow at the bottom of the body, pointing **down**.
///   Used when the tooltip body floats *above* its target.
/// * [topCenter] — arrow at the top of the body, pointing **up**.
///   Used when the tooltip body floats *below* its target.
/// * [leftCenter] — arrow on the left edge, pointing **left**.
/// * [rightCenter] — arrow on the right edge, pointing **right**.
enum TooltipArrowAlignment { topCenter, bottomCenter, leftCenter, rightCenter }

/// Onboarding tooltip overlay pointing at a target (e.g. the 수정하기 pill
/// on the time-confirm screen, or the first-launch hints on child-home).
///
/// Figma source: `docs/figma-specs/10-time-confirm.md` (state 3 — filled + tip,
/// node `662-11249`).
///
/// Visual:
///   * Rounded dark card (bg [AppColors.gray600] = `#5F6165`,
///     radius [AppTokens.dialogRadius] = 12), padded 16 / 12, soft drop shadow.
///   * Optional bold [title] (white, Caption/Bold) at the top.
///   * Required [bullets] — each rendered as `•` + Text.rich on a single row,
///     with inline `underline` emphasis supported via [TextSpan] children.
///   * Optional top-right close (X) icon when [onDismiss] is provided.
///   * Triangular notch (~10×6) painted on the edge designated by
///     [arrowAlignment] in the same dark color as the body so it visually
///     merges with the card.
///
/// Positioning is the caller's responsibility — wrap in a [Stack]/[Positioned]
/// or [OverlayEntry] to anchor against the target widget. The default
/// [arrowAlignment] is [TooltipArrowAlignment.topCenter] (body floats *below*
/// the target, arrow points *up*) which matches the Figma 시간설정 tooltip.
class BridgeOnboardingTooltip extends StatelessWidget {
  const BridgeOnboardingTooltip({
    super.key,
    this.title,
    required this.bullets,
    this.arrowAlignment = TooltipArrowAlignment.topCenter,
    this.maxWidth = 280,
    this.onDismiss,
  });

  /// Optional bold title rendered above the bullets (Caption/Bold, white).
  /// When null, no title slot is rendered.
  final String? title;

  /// Bulleted content — each entry becomes a single `•` + Text.rich row.
  /// Use inline [TextSpan]s with `decoration: TextDecoration.underline` to
  /// emphasize phrases (e.g. `주 1회`, `시간 설정 탭` per spec).
  final List<TextSpan> bullets;

  /// Which edge the arrow notch sits on. Defaults to
  /// [TooltipArrowAlignment.topCenter] (body below target, arrow points up).
  final TooltipArrowAlignment arrowAlignment;

  /// Maximum width for the tooltip body. Defaults to 280.
  final double maxWidth;

  /// Optional dismiss handler. When non-null, renders a top-right close (X)
  /// icon inside the card.
  final VoidCallback? onDismiss;

  static const double _arrowLength = 10; // base width along the body edge
  static const double _arrowDepth = 6; // how far it protrudes from the body

  // Dark surface per Figma audit phase 5 (`#5F6165` = AppColors.gray600).
  // Title renders in white; bullet body in gray100 (`#F5F7FA`).
  static const Color _surface = AppColors.gray600;
  static const Color _titleColor = Colors.white;
  static const Color _bulletColor = AppColors.gray100;

  // Lighter shadow than the prior white-card variant so the drop still reads
  // softly against light backgrounds without darkening the already-dark card.
  static const BoxShadow _shadow = BoxShadow(
    color: Color(0x0F000000), // black @ ~6%
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  bool get _isVertical =>
      arrowAlignment == TooltipArrowAlignment.topCenter ||
      arrowAlignment == TooltipArrowAlignment.bottomCenter;

  @override
  Widget build(BuildContext context) {
    final Widget body = _buildBody();
    final Widget arrow = _buildArrow();

    final List<Widget> stack = switch (arrowAlignment) {
      TooltipArrowAlignment.topCenter => <Widget>[arrow, body],
      TooltipArrowAlignment.bottomCenter => <Widget>[body, arrow],
      TooltipArrowAlignment.leftCenter => <Widget>[arrow, body],
      TooltipArrowAlignment.rightCenter => <Widget>[body, arrow],
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: _semanticsLabel(),
      child: _isVertical
          ? Column(mainAxisSize: MainAxisSize.min, children: stack)
          : Row(mainAxisSize: MainAxisSize.min, children: stack),
    );
  }

  String _semanticsLabel() {
    final StringBuffer buffer = StringBuffer();
    if (title != null) {
      buffer.write(title);
    }
    for (final TextSpan span in bullets) {
      if (buffer.isNotEmpty) buffer.write('. ');
      buffer.write(span.toPlainText());
    }
    return buffer.toString();
  }

  Widget _buildBody() {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(AppTokens.dialogRadius),
          boxShadow: const <BoxShadow>[_shadow],
        ),
        child: Stack(
          children: <Widget>[
            Padding(
              // Reserve space on the right for the close icon when present so
              // long titles don't run under it.
              padding: EdgeInsets.only(right: onDismiss != null ? 20 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null) ...<Widget>[
                    Text(
                      title!,
                      style: AppTypography.captionBold.copyWith(
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: AppTokens.smallGap),
                  ],
                  for (int i = 0; i < bullets.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: 6),
                    _Bullet(span: bullets[i], color: _bulletColor),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              Positioned(
                top: -4,
                right: -4,
                child: _CloseButton(onTap: onDismiss!, color: _titleColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrow() {
    final Size size = _isVertical
        ? const Size(_arrowLength, _arrowDepth)
        : const Size(_arrowDepth, _arrowLength);
    return CustomPaint(
      size: size,
      painter: _ArrowPainter(alignment: arrowAlignment, color: _surface),
    );
  }
}

/// Single bullet row: `•` glyph + Text.rich content. The glyph and the text
/// share the same [color] and the same Caption/Regular baseline so they align
/// visually across multiple bullets.
class _Bullet extends StatelessWidget {
  const _Bullet({required this.span, required this.color});

  final TextSpan span;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTypography.captionRegular.copyWith(color: color);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('•', style: base),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(TextSpan(style: base, children: <InlineSpan>[span])),
        ),
      ],
    );
  }
}

/// Top-right close (X) affordance rendered when [BridgeOnboardingTooltip.onDismiss]
/// is provided. 24×24 hit target meets WCAG 2.1 SC 2.5.5 (Target Size, AAA).
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap, required this.color});

  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '닫기',
      child: InkResponse(
        onTap: onTap,
        radius: 16,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(Icons.close, size: 14, color: color),
        ),
      ),
    );
  }
}

/// Paints the triangular notch on the side designated by [alignment].
///
/// The triangle is solid-filled with [color] so it visually merges with the
/// tooltip body. No stroke / no shadow on the arrow itself — the body
/// shadow handles the drop.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.alignment, required this.color});

  final TooltipArrowAlignment alignment;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path path = Path();
    switch (alignment) {
      case TooltipArrowAlignment.topCenter:
        // Arrow protrudes upward from the body's top edge.
        path
          ..moveTo(0, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width / 2, 0)
          ..close();
        break;
      case TooltipArrowAlignment.bottomCenter:
        // Arrow protrudes downward from the body's bottom edge.
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close();
        break;
      case TooltipArrowAlignment.leftCenter:
        // Arrow protrudes leftward from the body's left edge.
        path
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
        break;
      case TooltipArrowAlignment.rightCenter:
        // Arrow protrudes rightward from the body's right edge.
        path
          ..moveTo(0, 0)
          ..lineTo(0, size.height)
          ..lineTo(size.width, size.height / 2)
          ..close();
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.alignment != alignment || oldDelegate.color != color;
  }
}
