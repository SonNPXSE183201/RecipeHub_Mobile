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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: NomadKit.sand,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(Icons.coffee_rounded, color: Colors.white, size: iconSize),
      ),
    );
  }
}
