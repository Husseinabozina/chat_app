import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_preferences.dart';

final class SecurePreferencesStore implements PreferencesStore {
  const SecurePreferencesStore(this.storage);
  final FlutterSecureStorage storage;
  static const key = 'mingle.device_preferences.v1';
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String value) => storage.write(key: key, value: value);
}
