import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final String fallbackText;

  const AppLogo({super.key, this.size = 28, this.fallbackText = 'DocIn'});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/DocIn.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Text(fallbackText, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
