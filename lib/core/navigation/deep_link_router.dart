import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/feedback/my_feedback_list_page.dart';
import '../viewmodels/auth_viewmodel.dart';

import '../../features/learning/learning_task_detail_page.dart';
import '../../features/learning/notifications_page.dart';
import '../../features/lookup/recipe_detail_size_page.dart';
import '../../features/sop/sop_detail_page.dart';
import '../models/session_models.dart';
import '../services/mock_data_service.dart';
import '../viewmodels/recipe_viewmodel.dart';

/// Ánh xạ DeepLink (payload FCM) → màn hình đích. Không tìm thấy → trung tâm thông báo.
class DeepLinkRouter {
  DeepLinkRouter._();

  static Widget resolve(BuildContext context, DeepLink link) {
    final data = MockDataService.instance;
    switch (link.target) {
      case DeepLinkTarget.recipe:
        final matches = context.read<RecipeViewModel>().items.where((r) => r.id == link.id || r.code == link.id);
        if (matches.isNotEmpty) return RecipeDetailSizePage(recipe: matches.first, source: 'notification');
      case DeepLinkTarget.sop:
        final s = data.sops.where((x) => x.id == link.id || x.code == link.id);
        if (s.isNotEmpty) return SopDetailPage(sop: s.first);
      case DeepLinkTarget.task:
        final t = data.tasks.where((x) => x.id == link.id);
        if (t.isNotEmpty) return LearningTaskDetailPage(task: t.first);
      case DeepLinkTarget.feedback:
        return const MyFeedbackListPage();
      case DeepLinkTarget.notifications:
        break;
    }
    return const NotificationsPage();
  }

  static Future<void> open(BuildContext context, DeepLink link) async {
    final navigator = Navigator.of(context);
    Widget page = resolve(context, link);
    if (link.target == DeepLinkTarget.recipe && page is NotificationsPage) {
      // Món không nằm trong danh sách đã tải (bị giới hạn bởi max_lookup_results) → hỏi Gateway.
      final auth = context.read<AuthViewModel>();
      final recipe = await context.read<RecipeViewModel>().findForDeepLink(link.id);
      // Đăng xuất trong lúc chờ mạng → không đẩy trang công thức lên màn đăng nhập.
      if (auth.status != AuthStatus.authenticated) return;
      if (recipe != null) page = RecipeDetailSizePage(recipe: recipe, source: 'notification');
    }
    await navigator.push(MaterialPageRoute<void>(builder: (_) => page));
  }
}
