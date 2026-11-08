import 'package:flutter/material.dart';
import '../theme/nomad_kit.dart';

class RecipeHubLogo extends StatelessWidget {
  const RecipeHubLogo({
    super.key,
    this.size = 36,
    this.iconSize = 20,
    this.radius = 12,
  });

  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/app_logo_hero_2k.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (ctx, err, stack) => Icon(
        Icons.coffee_rounded,
        color: NomadKit.sand,
        size: iconSize,
      ),
    );
  }
}
