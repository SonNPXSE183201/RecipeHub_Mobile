import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../device/device_info_reader.dart';
import '../interfaces/i_device_registry.dart';

/// `users/{uid}/devices/{sha256(token)[0..32]}` – id ngắn, ổn định cho mỗi token.
class FirestoreDeviceRegistry implements IDeviceRegistry {
  FirestoreDeviceRegistry({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static String deviceIdOf(String token) => sha256.convert(utf8.encode(token)).toString().substring(0, 32);

  @override
  Future<void> register(String uid, String token) async {
    final d = await DeviceInfoReader.read();
    final ref = _db.doc('users/$uid/devices/${deviceIdOf(token)}');
    await ref.set({
      'token': token,
      'platform': d.platform,
      'model': d.model,
      'osVersion': d.osVersion,
      'appVersion': '${d.appVersion}+${d.buildNumber}',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unregister(String uid, String token) => _db.doc('users/$uid/devices/${deviceIdOf(token)}').delete();
}
