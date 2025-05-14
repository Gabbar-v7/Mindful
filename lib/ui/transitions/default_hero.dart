/*
 *
 *  * Copyright (c) 2024 Mindful (https://github.com/akaMrNagar/Mindful)
 *  * Author : Pawan Nagar (https://github.com/akaMrNagar)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'dart:ui';

import 'package:flutter/material.dart';

class DefaultHero extends StatelessWidget {
  const DefaultHero({
    super.key,
    required this.tag,
    required this.child,
  });

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      createRectTween: (begin, end) => _DefaultRectTween(begin, end),
      tag: tag,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: child,
      ),
    );
  }
}

class _DefaultRectTween extends RectTween {
  _DefaultRectTween(
    Rect? begin,
    Rect? end,
  ) : super(begin: begin, end: end);

  @override
  Rect lerp(double t) {
    final elasticCurveValue = Curves.easeOutBack.transform(t);
    return Rect.fromLTRB(
      lerpDouble(begin?.left, end?.left, elasticCurveValue) ?? 0,
      lerpDouble(begin?.top, end?.top, elasticCurveValue) ?? 0,
      lerpDouble(begin?.right, end?.right, elasticCurveValue) ?? 0,
      lerpDouble(begin?.bottom, end?.bottom, elasticCurveValue) ?? 0,
    );
  }
}
