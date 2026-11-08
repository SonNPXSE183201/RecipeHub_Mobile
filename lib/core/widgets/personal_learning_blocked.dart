import 'package:flutter/material.dart';

import '../theme/nomad_kit.dart';

/// Chặn route học/tự luyện cá nhân với Admin: quay về Trang chủ + SnackBar giải thích.
/// Điều kiện vai trò nằm ở `AuthViewModel.hasPersonalLearning`, widget này chỉ phản hồi UI.
class PersonalLearningBlocked extends StatefulWidget {
  const PersonalLearningBlocked({super.key});

  @override
  State<PersonalLearningBlocked> createState() => _PersonalLearningBlockedState();
}

class _PersonalLearningBlockedState extends State<PersonalLearningBlocked> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Tài khoản Admin không có mục học và tự luyện cá nhân.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(backgroundColor: NomadKit.canvas);
}
