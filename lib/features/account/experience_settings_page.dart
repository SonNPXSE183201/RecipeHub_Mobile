import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/nomad_kit.dart';
import '../../core/widgets/redesign_widgets.dart';

class ExperienceSettingsPage extends StatefulWidget {
  const ExperienceSettingsPage({super.key});

  @override
  State<ExperienceSettingsPage> createState() => _ExperienceSettingsPageState();
}

class _ExperienceSettingsPageState extends State<ExperienceSettingsPage> {
  bool _largeText = false;
  bool _reduceMotion = false;
  bool _highContrast = false;

  @override
  Widget build(BuildContext context) => RhFlowScaffold(
    title: 'Cài đặt trải nghiệm',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Text('Khả năng tiếp cận', style: NomadKit.title.copyWith(fontSize: 26)),
        const SizedBox(height: 8),
        const Text(
          'Điều chỉnh cách nội dung hiển thị và chuyển động trong ứng dụng.',
          style: NomadKit.body,
        ),
        const SizedBox(height: 24),
        _SettingSwitch(
          icon: Icons.text_fields_rounded,
          title: 'Chữ dễ đọc hơn',
          subtitle: 'Tăng độ nổi bật cho nội dung chính',
          value: _largeText,
          onChanged: (value) => setState(() => _largeText = value),
        ),
        _SettingSwitch(
          icon: Icons.motion_photos_off_outlined,
          title: 'Giảm chuyển động',
          subtitle: 'Giảm hiệu ứng lật trang và chuyển cảnh',
          value: _reduceMotion,
          onChanged: (value) => setState(() => _reduceMotion = value),
        ),
        _SettingSwitch(
          icon: Icons.contrast_rounded,
          title: 'Tương phản cao',
          subtitle: 'Làm rõ đường viền và trạng thái thao tác',
          value: _highContrast,
          onChanged: (value) => setState(() => _highContrast = value),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 26),
          Text('Công cụ kiểm thử', style: NomadKit.section),
          const SizedBox(height: 8),
          const RhNotice(
            icon: Icons.science_outlined,
            title: 'Chỉ có trong bản debug',
            message: 'Mô phỏng mạng không xuất hiện trong bản release và không ảnh hưởng dữ liệu thật.',
          ),
        ],
      ],
    ),
  );
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: NomadKit.lineSoft)),
    ),
    child: SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: NomadKit.sandDark),
      title: Text(
        title,
        style: NomadKit.label.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: NomadKit.caption),
      value: value,
      onChanged: onChanged,
    ),
  );
}
