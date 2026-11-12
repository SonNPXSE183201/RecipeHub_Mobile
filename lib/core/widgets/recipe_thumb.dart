import 'package:flutter/material.dart';

import '../theme/nomad_kit.dart';
import 'redesign_widgets.dart';

/// Ảnh đại diện món: ưu tiên ảnh trên Firebase Storage (`imageUrl`), sau đó ảnh
/// bundle trong app (`assetPath`), cuối cùng là biểu tượng thương hiệu.
class RecipeThumb extends StatelessWidget {
  const RecipeThumb({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width = 72,
    this.height = 82,
  });

  final String? imageUrl;
  final String? assetPath;
  final double width;
  final double height;

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: NomadKit.sandLight,
    alignment: Alignment.center,
    child: const RhSvgIcon('assets/redesign/brand_coffee.svg', size: 28),
  );

  Widget _asset() => assetPath == null
      ? _placeholder()
      : Image.asset(assetPath!, width: width, height: height, fit: BoxFit.cover);

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: url.isEmpty
          ? _asset()
          : Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              cacheWidth: (width * 3).round(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _placeholder(),
              errorBuilder: (context, error, stack) => _asset(),
            ),
    );
  }
}
