import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// The EME logo with its drop shadow (`assets/icon/logo_shadow.svg`).
///
/// flutter_svg ignores SVG filters, so the shadow is drawn here from a
/// blurred, darkened copy. Shadow offset and blur scale with [width].
class ShadowLogo extends StatelessWidget {
  const ShadowLogo({super.key, required this.width});

  static const _asset = 'assets/icon/logo_shadow.svg';

  final double width;

  @override
  Widget build(BuildContext context) {
    final blur = width / 120;
    return Stack(
      children: [
        Transform.translate(
          offset: Offset(width / 120, width / 80),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: SvgPicture.asset(
              _asset,
              width: width,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        SvgPicture.asset(_asset, width: width),
      ],
    );
  }
}
