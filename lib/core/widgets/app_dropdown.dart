import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/nomad_kit.dart';

/// Controlled NomadKit selector. The popup uses the field's exact width and
/// only the available space below it, including when the keyboard is visible.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Chọn mục',
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;

  Future<void> _open(BuildContext context) async {
    final field = context.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final origin = field.localToGlobal(Offset.zero, ancestor: overlay);
    final top = origin.dy + field.size.height;
    final media = MediaQuery.of(context);
    final height = math.min(
      320.0,
      math.max(
        0.0,
        overlay.size.height -
            top -
            media.viewInsets.bottom -
            media.padding.bottom,
      ),
    );
    if (height == 0) return;
    final result = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, _) => Stack(
        children: [
          Positioned(
            left: origin.dx,
            top: top,
            width: field.size.width,
            child: Material(
              key: const ValueKey('app_dropdown_menu'),
              color: NomadKit.surface,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: NomadKit.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: [
                      for (final item in items)
                        InkWell(
                          onTap: item.enabled
                              ? () => Navigator.pop(context, item.value)
                              : null,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: DefaultTextStyle(
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: NomadKit.ink,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                child: item.child,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (context.mounted && result != null) onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => item.value == value).firstOrNull;
    final enabled = onChanged != null && items.isNotEmpty;
    return Material(
      color: NomadKit.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: NomadKit.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? () => _open(context) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: DefaultTextStyle(
                    style: const TextStyle(fontSize: 15, color: NomadKit.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: selected?.child ?? Text(hint),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more_rounded, color: NomadKit.sandDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
