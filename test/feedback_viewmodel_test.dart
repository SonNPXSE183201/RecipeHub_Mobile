import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipehub_mobile/core/models/app_models.dart';
import 'package:recipehub_mobile/core/services/interfaces/i_feedback_repository.dart';
import 'package:recipehub_mobile/core/services/mock/mock_crash_reporter.dart';
import 'package:recipehub_mobile/core/services/mock/mock_feedback_repository.dart';
import 'package:recipehub_mobile/core/viewmodels/feedback_viewmodel.dart';

NewFeedback _fb(String uid, {String? img}) => NewFeedback(
  ownerUid: uid,
  ownerName: 'Barista $uid',
  ownerRole: 'Barista',
  storeBranch: 'Landmark 81',
  type: FeedbackType.issue,
  content: 'Kem bị chìm',
  targetCode: 'CF-MUOI',
  targetName: 'Cà Phê Muối',
  version: 'v1',
  stepNote: 'Bước 4',
  attachmentUrl: img,
  attachmentPath: img == null ? null : 'feedback/$uid/a.jpg',
);

Future<void> _pump() => Future<void>.delayed(Duration.zero);

class _FailingRepo extends MockFeedbackRepository {
  @override
  Stream<List<FeedbackItemModel>> watchMine(String uid) => Stream.error(
    const FeedbackFailure(
      'Mất kết nối. Kiểm tra mạng rồi thử lại.',
      code: 'unavailable',
    ),
  );
}

void main() {
  group('FeedbackListViewModel', () {
    test(
      'Barista chỉ thấy phản hồi của mình; Admin thấy tất cả, real-time',
      () async {
        final repo = MockFeedbackRepository();
        await repo.create(_fb('a'));
        await repo.create(_fb('b', img: 'https://img/b.jpg'));

        final viewer = FeedbackListViewModel(
          repo: repo,
          crash: MockCrashReporter(),
        )..bind(uid: 'a', isAdmin: false);
        final admin = FeedbackListViewModel(
          repo: repo,
          crash: MockCrashReporter(),
        )..bind(uid: 'x', isAdmin: true);
        await _pump();
        expect(viewer.visible.map((f) => f.ownerUid), ['a']);
        expect(admin.visible.length, 2);
        expect(admin.visible.first.hasAttachment, isTrue);

        // Phản hồi mới xuất hiện ngay ở Admin, không cần tải lại.
        await repo.create(_fb('c'));
        await _pump();
        expect(admin.visible.length, 3);
        expect(viewer.visible.length, 1);
      },
    );

    test('lọc theo trạng thái và đếm', () async {
      final repo = MockFeedbackRepository();
      final id = await repo.create(_fb('a'));
      await repo.create(_fb('a'));
      await repo.setStatus(id, FeedbackStatus.resolved);
      final vm = FeedbackListViewModel(repo: repo, crash: MockCrashReporter())
        ..bind(uid: 'a', isAdmin: false);
      await _pump();
      expect(vm.countFor(FeedbackFilter.open), 1);
      expect(vm.countFor(FeedbackFilter.resolved), 1);
      vm.setFilter(FeedbackFilter.resolved);
      expect(vm.visible.single.status, FeedbackStatus.resolved);
    });

    test(
      'lỗi stream → state Error có thông điệp tiếng Việt, retry đăng ký lại',
      () async {
        final vm = FeedbackListViewModel(
          repo: _FailingRepo(),
          crash: MockCrashReporter(),
        )..bind(uid: 'a', isAdmin: false);
        await _pump();
        expect(vm.state, isA<FeedbackListError>());
        expect(
          (vm.state as FeedbackListError).message,
          contains('Mất kết nối'),
        );
        vm.retry();
        expect(vm.state, isA<FeedbackListLoading>());
      },
    );
  });

  group('FeedbackDetailViewModel', () {
    test('Admin trả lời kèm đổi trạng thái; Barista thấy ngay', () async {
      final repo = MockFeedbackRepository();
      final id = await repo.create(_fb('a', img: 'https://img/a.jpg'));
      final admin = FeedbackDetailViewModel(
        repo: repo,
        crash: MockCrashReporter(),
        feedbackId: id,
        myUid: 'adm',
        myName: 'Quản lý',
        isAdmin: true,
      );
      final barista = FeedbackDetailViewModel(
        repo: repo,
        crash: MockCrashReporter(),
        feedbackId: id,
        myUid: 'a',
        myName: 'Barista a',
        isAdmin: false,
      );
      await _pump();
      expect(barista.item!.attachmentUrl, 'https://img/a.jpg');

      expect(
        await admin.sendReply(
          '  Thả đá trước khi rót kem  ',
          newStatus: FeedbackStatus.resolved,
        ),
        isTrue,
      );
      await _pump();
      expect(barista.replies.single.message, 'Thả đá trước khi rót kem');
      expect(barista.replies.single.isAdmin, isTrue);
      expect(barista.item!.status, FeedbackStatus.resolved);
    });

    test(
      'Barista không đổi được trạng thái; nội dung rỗng không gửi',
      () async {
        final repo = MockFeedbackRepository();
        final id = await repo.create(_fb('a'));
        final vm = FeedbackDetailViewModel(
          repo: repo,
          crash: MockCrashReporter(),
          feedbackId: id,
          myUid: 'a',
          myName: 'A',
          isAdmin: false,
        );
        await _pump();
        expect(await vm.changeStatus(FeedbackStatus.closed), isFalse);
        expect(await vm.sendReply('   '), isFalse);
        expect(vm.item!.status, FeedbackStatus.newFeedback);
      },
    );

    test('id không tồn tại → notFound', () async {
      final vm = FeedbackDetailViewModel(
        repo: MockFeedbackRepository(),
        crash: MockCrashReporter(),
        feedbackId: 'x',
        myUid: 'a',
        myName: 'A',
        isAdmin: false,
      );
      await _pump();
      expect(vm.notFound, isTrue);
    });
  });
}
