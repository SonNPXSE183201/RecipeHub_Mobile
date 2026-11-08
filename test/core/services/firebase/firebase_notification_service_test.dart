import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/firebase/firebase_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppNotification _notification(int index) => AppNotification(
  id: 'notification-$index',
  title: 'Thông báo $index',
  body: '',
  receivedAt: DateTime(2026).add(Duration(minutes: index)),
  origin: NotificationOrigin.background,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final pendingCount in [0, 99, 100, 105]) {
    test(
      'Giữ tối đa 100 thông báo mới nhất khi có $pendingCount mục chờ',
      () async {
        final otherUserPending = [jsonEncode(_notification(-1).toJson())];
        SharedPreferences.setMockInitialValues({
          'rh_notification_pending_bg_v1_a': [
            for (var i = 0; i < pendingCount; i++)
              jsonEncode(_notification(i).toJson()),
          ],
          'rh_notification_pending_bg_v1_b': otherUserPending,
        });
        final prefs = await SharedPreferences.getInstance();

        // Nhận liên tiếp nhiều thông báo trước khi lịch sử được tải.
        for (var i = pendingCount; i < pendingCount + 3; i++) {
          await FirebaseNotificationService.saveScopedPending(
            prefs,
            'a',
            _notification(i),
          );
          expect(
            prefs.getStringList('rh_notification_pending_bg_v1_a')!.length,
            lessThanOrEqualTo(100),
          );
        }

        final total = pendingCount + 3;
        final retained = total > 100 ? 100 : total;
        final expectedIds = [
          for (var i = total - retained; i < total; i++) 'notification-$i',
        ];
        final pending = prefs.getStringList('rh_notification_pending_bg_v1_a')!;
        expect(
          pending.map(
            (item) => (jsonDecode(item) as Map<String, dynamic>)['id'],
          ),
          expectedIds,
        );
        expect(
          prefs.getStringList('rh_notification_pending_bg_v1_b'),
          otherUserPending,
        );

        final history = await FirebaseNotificationService.loadScopedHistory(
          prefs,
          'a',
        );
        expect(history.map((item) => item.id), expectedIds.reversed.toList());
        expect(prefs.containsKey('rh_notification_pending_bg_v1_a'), isFalse);
      },
    );
  }
}
