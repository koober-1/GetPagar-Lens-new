import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class AppSizing {
  static double _w(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Keeps content readable on tablets/large screens.
  static double maxContentWidth(BuildContext context) {
    final w = _w(context);
    if (w >= 900) return 520;
    if (w >= 600) return 480;
    return w;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final w = _w(context);
    final horizontal = w >= 600 ? 24.0 : 18.0;
    return EdgeInsets.fromLTRB(horizontal, 26, horizontal, 24);
  }

  /// Dialog card width close to the screenshot (not full screen).
  static double dialogMaxWidth(BuildContext context) {
    final w = _w(context);
    return math.min(360, w - 36); // keep side margins visible
  }

  static double dialogHorizontalInset(BuildContext context) {
    final w = _w(context);
    return w >= 600 ? 40 : 24;
  }

  /// OTP box sizing will be derived from available width (LayoutBuilder),
  /// but we still keep min/max so it looks good on all screens.
  static double clampOtpBoxWidth(double value) => value.clamp(40.0, 52.0);
  static double clampOtpBoxHeight(double value) => value.clamp(52.0, 60.0);
}

