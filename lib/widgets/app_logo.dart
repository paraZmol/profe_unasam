import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final String fallbackText;

  const AppLogo({super.key, this.size = 28, this.fallbackText = 'DocIn'});

  Future<String?> _findLogoAsset() async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestJson);
    final matches = manifest.keys
        .where((k) => k.startsWith('assets/icons/DoCin.'))
        .toList();
    if (matches.isEmpty) return null;
    matches.sort();
    return matches.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _findLogoAsset(),
      builder: (context, snapshot) {
        final assetPath = snapshot.data;
        if (assetPath == null) {
          return Text(
            fallbackText,
            style: Theme.of(context).textTheme.titleLarge,
          );
        }
        return Image.asset(
          assetPath,
          height: size,
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Text(fallbackText, style: Theme.of(context).textTheme.titleLarge),
        );
      },
    );
  }
}
