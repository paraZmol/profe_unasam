import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoadingDots extends StatefulWidget {
  final Color? color;
  final double size;
  final double spacing;

  const LoadingDots({super.key, this.color, this.size = 8, this.spacing = 6});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotScale(double t, int index) {
    final phase = (t + index * 0.2) % 1.0;
    return 0.6 + 0.4 * math.sin(phase * 2 * math.pi).abs();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.onPrimary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final scale = _dotScale(t, index);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: color.withOpacity(scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
