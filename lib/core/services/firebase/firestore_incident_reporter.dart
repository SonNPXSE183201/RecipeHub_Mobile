import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/incident_report.dart';
import '../device/device_info_reader.dart';
import '../interfaces/i_incident_reporter.dart';

const String _kStashKey = 'rh_incident_stash_v1';
const String _kReportedKey = 'rh_incident_crash_reported_v1';

/// Ghi sự cố vào Firestore `incidents/{id}`. Web Admin nghe collection này real-time.
class FirestoreIncidentReporter implements IIncidentReporter {
  FirestoreIncidentReporter({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  String? _uid;
  String? _email;
  bool? _pendingFlush;

  @override
  void setUser({String? uid, String? email}) {
    _uid = uid;
    _email = email;
    final crashed = _pendingFlush;
    if (uid != null && crashed != null) {
      _pendingFlush = null;
      unawaited(flushPending(crashedLastRun: crashed));
    }
  }

  @override
  void scheduleFlush({required bool crashedLastRun}) {
    _pendingFlush = crashedLastRun;
    if (_uid != null) setUser(uid: _uid, email: _email);
  }

  @override
  Future<bool> report(IncidentReport r) => _write(r, uid: _uid, email: _email);

  /// Ghi với người dùng truyền vào (không đổi state dùng chung khi gửi bù).
  Future<bool> _write(IncidentReport r, {required String? uid, required String? email}) async {
    try {
      final d = await DeviceInfoReader.read();
      await _db.collection('incidents').doc(r.id).set({
        'uid': uid,
        'email': uid == null ? null : email,
        'kind': r.kindCode,
        'source': r.sourceCode,
        'errorType': r.errorType,
        'message': r.message,
        'stackTop': r.stackTop,
        'screen': r.screen,
        'appVersion': d.appVersion,
        'buildNumber': d.buildNumber,
        'deviceModel': d.model,
        'osVersion': d.osVersion,
        'occurredAt': Timestamp.fromDate(r.occurredAt ?? DateTime.now()),
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'open',
      }).timeout(const Duration(seconds: 8));
      return true;
    } on FirebaseException catch (e) {
      // Document đã tồn tại (bản trước đã tới server) → rules chặn ghi đè: coi như đã gửi.
      if (e.code == 'permission-denied') {
        debugPrint('[Incident] ${r.id} bị từ chối (đã có hoặc không hợp lệ) – bỏ qua');
        return true;
      }
      debugPrint('[Incident] report failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('[Incident] report failed: $e');
      return false;
    }
  }

  @override
  Future<void> stashForNextLaunch(IncidentReport r) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kStashKey) ?? <String>[];
      list.add(jsonEncode({...r.toJson(), 'uid': _uid, 'email': _email}));
      await prefs.setStringList(_kStashKey, list.length > 20 ? list.sublist(list.length - 20) : list);
    } catch (_) {
      // Đang crash: không làm gì thêm được.
    }
  }

  @override
  Future<void> removeStashed(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kStashKey) ?? const <String>[];
      final kept = list.where((raw) {
        try {
          return (jsonDecode(raw) as Map<String, dynamic>)['id'] != id;
        } catch (_) {
          return false;
        }
      }).toList();
      await prefs.setStringList(_kStashKey, kept);
    } catch (_) {}
  }

  @override
  Future<void> markCrashAlreadyReported() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReportedKey, true);
  }

  @override
  Future<int> flushPending({required bool crashedLastRun}) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyReported = prefs.getBool(_kReportedKey) ?? false;
    await prefs.remove(_kReportedKey);
    final stashed = prefs.getStringList(_kStashKey) ?? const <String>[];
    final currentUid = _uid;
    final currentEmail = _email;
    var sent = 0;
    final remaining = <String>[];
    for (final raw in stashed) {
      Map<String, dynamic> j;
      try {
        j = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        continue; // bản ghi hỏng
      }
      // Rules chỉ cho ghi uid của chính mình: khác người đang đăng nhập → gửi ẩn danh.
      final sameUser = j['uid'] != null && j['uid'] == currentUid;
      final ok = await _write(
        IncidentReport.fromJson(j),
        uid: sameUser ? currentUid : null,
        email: sameUser ? currentEmail : null,
      );
      if (ok) {
        sent++;
      } else {
        remaining.add(raw);
      }
    }
    await prefs.setStringList(_kStashKey, remaining);
    if (crashedLastRun && stashed.isEmpty && !alreadyReported) {
      final ok = await _write(
        IncidentReport(
          kind: IncidentKind.fatal,
          source: IncidentSource.previousCrash,
          errorType: 'NativeCrash',
          message: 'Ứng dụng bị crash ở lần chạy trước (Crashlytics: didCrashOnPreviousExecution).',
          occurredAt: DateTime.now(),
        ),
        uid: currentUid,
        email: currentEmail,
      );
      if (ok) sent++;
    }
    return sent;
  }
}
