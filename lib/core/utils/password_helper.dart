import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PasswordHelper {
  const PasswordHelper._();

  static final Random _random = Random.secure();

  static String generateSalt([int length = 16]) {
    final values = List<int>.generate(length, (_) => _random.nextInt(256));
    return values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  // The app stores a salted SHA-256 hash so the raw password never touches SQLite.
  static String hashPassword({required String password, required String salt}) {
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }
}
