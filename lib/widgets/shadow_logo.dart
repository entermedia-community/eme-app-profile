import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// The EME logo with its drop shadow (`assets/icon/logo_shadow.svg`).
///
/// flutter_svg ignores SVG filters, so the shadow is drawn here from a
/// blurred, darkened copy. Shadow offset and blur scale with [width].
class ShadowLogo extends StatelessWidget {
  const ShadowLogo({super.key, required this.width});

  static const _asset = 'assets/icon/logo_light.svg';

  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [SvgPicture.asset(_asset, width: width)]);
  }
}
