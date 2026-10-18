import 'package:flutter/material.dart';
import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/recipe_hub_logo.dart';

class LoadingTransitionPage extends StatefulWidget {
  const LoadingTransitionPage({super.key, required this.message, this.onComplete});
  final String message;
  final VoidCallback? onComplete;

  @override
  State<LoadingTransitionPage> createState() => _LoadingTransitionPageState();
}

class _LoadingTransitionPageState extends State<LoadingTransitionPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    if (widget.onComplete != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) widget.onComplete!();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: NomadKit.canvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: NomadKit.sandLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: NomadKit.sand.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Center(
                    child: RecipeHubLogo(size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    minHeight: 4,
                    color: NomadKit.sand,
                    backgroundColor: NomadKit.border,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: NomadKit.ink,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hệ thống đang đồng bộ cơ sở dữ liệu SOP...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: NomadKit.secondary,
                ),
              ),
            ],
          ),
        ),
      );
}
