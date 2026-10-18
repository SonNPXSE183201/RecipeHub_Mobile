import 'package:flutter/material.dart';
import '../theme/nomad_kit.dart';
import 'recipe_hub_logo.dart';

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.showBack = true,
    this.showLogo = false,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final bool showBack;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NomadKit.canvas,
      appBar: AppBar(
        backgroundColor: NomadKit.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: NomadKit.ink),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: Row(
          children: [
            if (showLogo) ...[
              const RecipeHubLogo(size: 28, iconSize: 16, radius: 8),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: NomadKit.ink,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: action != null ? [action!] : null,
      ),
      body: SafeArea(child: child),
    );
  }
}
