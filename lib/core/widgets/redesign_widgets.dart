import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/nomad_kit.dart';

String rhInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'RH';
  if (parts.length == 1) {
    final end = parts.first.length >= 2 ? 2 : 1;
    return parts.first.substring(0, end).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class RhSvgIcon extends StatelessWidget {
  const RhSvgIcon(this.asset, {super.key, this.size = 20, this.color});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset,
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

class RhAvatar extends StatelessWidget {
  const RhAvatar({super.key, required this.initials, this.size = 36});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: NomadKit.sandLight,
      shape: BoxShape.circle,
    ),
    child: Text(
      initials,
      style: NomadKit.caption.copyWith(
        fontWeight: FontWeight.w500,
        color: NomadKit.sandDark,
      ),
    ),
  );
}

class RhPageHeader extends StatelessWidget {
  const RhPageHeader({
    super.key,
    required this.title,
    this.initials,
    this.trailing,
  });

  final String title;
  final String? initials;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: Text(title, style: NomadKit.title)),
          ...switch ((trailing, initials)) {
            (final Widget child, _) => [child],
            (null, final String value) => [RhAvatar(initials: value)],
            _ => const <Widget>[],
          },
        ],
      ),
    ),
  );
}

class RhBrandHeader extends StatelessWidget {
  const RhBrandHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const RhSvgIcon('assets/redesign/brand_coffee.svg', size: 25),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Recipe'),
                  TextSpan(
                    text: 'Hub',
                    style: NomadKit.title.copyWith(color: NomadKit.sandDark),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NomadKit.title,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    ),
  );
}

class RhSectionHeading extends StatelessWidget {
  const RhSectionHeading({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 4),
    child: Row(
      children: [
        Expanded(child: Text(title, style: NomadKit.section)),
        if (trailing != null)
          Text(
            trailing!,
            style: NomadKit.label.copyWith(color: NomadKit.secondary),
          ),
      ],
    ),
  );
}

class RhPrimaryButton extends StatelessWidget {
  const RhPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: NomadKit.sandDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: NomadKit.border,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (icon != null) Icon(icon, size: 20),
        ],
      ),
    ),
  );
}

class RhChevron extends StatelessWidget {
  const RhChevron({super.key, this.color = NomadKit.secondary});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      RhSvgIcon('assets/redesign/chevron_right.svg', size: 18, color: color);
}

class RhFlowScaffold extends StatelessWidget {
  const RhFlowScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomAction,
    this.trailing,
  });

  final String title;
  final Widget body;
  final Widget? bottomAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: NomadKit.canvas,
    appBar: AppBar(
      toolbarHeight: 64,
      backgroundColor: NomadKit.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 58,
      leading: IconButton(
        tooltip: 'Quay lại',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
      ),
      titleSpacing: 0,
      title: Text(
        title,
        style: NomadKit.label.copyWith(color: NomadKit.secondary),
      ),
      actions: [
        ?trailing,
        if (trailing == null)
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: SizedBox(
                width: 5,
                height: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: NomadKit.sandDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
      shape: const Border(bottom: BorderSide(color: NomadKit.border)),
    ),
    body: SafeArea(top: false, child: body),
    bottomNavigationBar: bottomAction == null
        ? null
        : SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: const BoxDecoration(
                color: NomadKit.surface,
                border: Border(top: BorderSide(color: NomadKit.border)),
              ),
              child: bottomAction,
            ),
          ),
  );
}

class RhNotice extends StatelessWidget {
  const RhNotice({super.key, required this.message, this.title, this.icon});

  final String message;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: const BoxDecoration(
      color: NomadKit.sandLight,
      border: Border(left: BorderSide(color: NomadKit.sandDark, width: 3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon ?? Icons.error_outline_rounded,
          size: 17,
          color: NomadKit.sandDark,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(title!, style: NomadKit.label),
                const SizedBox(height: 2),
              ],
              Text(
                message,
                style: NomadKit.label.copyWith(fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
