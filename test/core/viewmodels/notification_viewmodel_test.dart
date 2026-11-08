import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/session_models.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_notification_service.dart';
import 'package:recipehub_mobile/core/viewmodels/notification_viewmodel.dart';

class _DelayedPermissionService extends MockNotificationService {
  final reads = <Completer<NotificationPermission>>[];

  @override
  Future<NotificationPermission> getPermissionStatus() {
    final read = Completer<NotificationPermission>();
    reads.add(read);
    return read.future;
  }
}

Future<void> _flushEvents() => Future<void>.delayed(Duration.zero);

void main() {
  late _DelayedPermissionService service;
  late MockCrashReporter crash;
  late NotificationViewModel vm;

  setUp(() {
    service = _DelayedPermissionService();
    crash = MockCrashReporter();
    vm = NotificationViewModel(service: service, crash: crash);
  });

  tearDown(() => vm.dispose());

  Future<void> start() =>
      vm.start(roleCode: 'viewer', storeCode: 'Q1', uid: 'user');

  test('Không hiện primer khi FCM mở app trước khi đọc xong quyền', () async {
    final observedPrimer = <bool>[];
    vm.addListener(() => observedPrimer.add(vm.shouldShowPermissionPrimer));
    final starting = start();
    await _flushEvents();

    expect(vm.isStarted, isTrue);
    expect(vm.shouldShowPermissionPrimer, isFalse);
    service.simulateOpened(
      AppNotification(
        id: 'cold-start',
        title: 'Công thức mới',
        body: '',
        receivedAt: DateTime(2026),
        origin: NotificationOrigin.background,
      ),
    );
    await _flushEvents();

    expect(vm.items.single.id, 'cold-start');
    expect(observedPrimer, isNotEmpty);
    expect(observedPrimer, everyElement(isFalse));
    service.reads.single.complete(NotificationPermission.granted);
    await starting;
    expect(vm.shouldShowPermissionPrimer, isFalse);
  });

  for (final permission in NotificationPermission.values) {
    test('Primer sau khi đọc quyền $permission', () async {
      final starting = start();
      await _flushEvents();
      service.reads.single.complete(permission);
      await starting;

      expect(vm.permission, permission);
      expect(
        vm.shouldShowPermissionPrimer,
        permission == NotificationPermission.notDetermined,
      );
      vm.dismissPermissionPrimer();
      expect(vm.shouldShowPermissionPrimer, isFalse);
    });
  }

  test('Không hiện primer nếu đọc quyền thất bại', () async {
    final starting = start();
    await _flushEvents();
    service.reads.single.completeError(StateError('Không đọc được quyền'));
    await starting;

    expect(crash.recordedErrors, hasLength(1));
    expect(vm.shouldShowPermissionPrimer, isFalse);
  });

  test('Phiên mới phải đọc lại quyền, bỏ kết quả của phiên cũ', () async {
    final oldStart = start();
    await _flushEvents();
    await vm.reset();
    final newStart = start();
    await _flushEvents();
    expect(vm.shouldShowPermissionPrimer, isFalse);

    service.reads.last.complete(NotificationPermission.granted);
    await newStart;
    service.reads.first.complete(NotificationPermission.notDetermined);
    await oldStart;

    expect(vm.permission, NotificationPermission.granted);
    expect(vm.shouldShowPermissionPrimer, isFalse);
  });

  test('Không dùng quyền notDetermined của lần đăng nhập trước', () async {
    final firstStart = start();
    await _flushEvents();
    service.reads.single.complete(NotificationPermission.notDetermined);
    await firstStart;
    expect(vm.shouldShowPermissionPrimer, isTrue);

    await vm.reset();
    final nextStart = start();
    await _flushEvents();
    expect(vm.shouldShowPermissionPrimer, isFalse);
    service.reads.last.complete(NotificationPermission.denied);
    await nextStart;
    expect(vm.shouldShowPermissionPrimer, isFalse);
  });
}
