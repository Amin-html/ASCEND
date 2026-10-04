import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart'
    show AesGcm, Hmac, Pbkdf2, SecretBox, SecretKey;

import 'package:ascend/features/backup/domain/backup_exceptions.dart';
import 'package:ascend/features/backup/domain/backup_format.dart';
import 'package:ascend/features/backup/domain/backup_models.dart';

const int _nonceLength = 12;
const int _macLength = 16;
const int _minIterations = 1;
const int _maxIterations = 2000000;

Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
    ) {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );
  return pbkdf2.deriveKeyFromPassword(password: password, nonce: salt);
}

Future<Uint8List> _encryptBytes(
    Uint8List data,
    String password,
    Uint8List salt,
    int iterations,
    ) async {
  final key = await _deriveKey(password, salt, iterations);
  final box = await AesGcm.with256bits().encrypt(data, secretKey: key);
  return Uint8List.fromList(box.concatenation());
}

Future<Uint8List> _decryptBytes(
    Uint8List data,
    String password,
    Uint8List salt,
    int iterations,
    ) async {
  final key = await _deriveKey(password, salt, iterations);
  final box = SecretBox.fromConcatenation(
    data,
    nonceLength: _nonceLength,
    macLength: _macLength,
  );
  final clear = await AesGcm.with256bits().decrypt(box, secretKey: key);
  return Uint8List.fromList(clear);
}

Uint8List _randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256)),
  );
}

/// Контейнер `.plannerbackup`: JSON-заголовок + payload (base64).
///
/// payload = gzip(JSON), а при пароле AES-256-GCM поверх gzip
/// (nonce + шифртекст + тег). Ключ: PBKDF2-HMAC-SHA256 с солью из заголовка.
/// checksum = SHA-256 от payload в том виде, как он лежит в файле.
class BackupCodec {
  const BackupCodec();

  Future<Uint8List> encode({
    required Map<String, Object?> payload,
    required int schemaVersion,
    required DateTime createdAt,
    required BackupSummary summary,
    String? password,
    int iterations = BackupFormat.pbkdf2Iterations,
  }) async {
    final plain = utf8.encode(jsonEncode(payload));
    final compressed = Uint8List.fromList(gzip.encode(plain));

    final encrypted = password != null && password.isNotEmpty;
    Uint8List stored = compressed;
    Map<String, Object?>? kdf;

    if (encrypted) {
      final salt = _randomBytes(BackupFormat.saltLength);
      stored = await Isolate.run(
            () => _encryptBytes(compressed, password, salt, iterations),
      );
      kdf = {
        'name': 'pbkdf2-hmac-sha256',
        'iterations': iterations,
        'salt': base64Encode(salt),
      };
    }

    final envelope = <String, Object?>{
      'magic': BackupFormat.magic,
      'backupVersion': BackupFormat.backupVersion,
      'schemaVersion': schemaVersion,
      'appVersion': BackupFormat.appVersion,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'encrypted': encrypted,
      'summary': summary.toJson(),
      'kdf': ?kdf,
      'checksum': sha256.convert(stored).toString(),
      'payload': base64Encode(stored),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  /// Проверяет структуру и контрольную сумму. Пароль не нужен.
  ParsedBackup parse(Uint8List bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupInvalidFileException();
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['magic'] != BackupFormat.magic) {
      throw const BackupInvalidFileException();
    }

    final version = decoded['backupVersion'];
    if (version is! int || version < 1) {
      throw const BackupInvalidFileException();
    }
    if (version > BackupFormat.backupVersion) {
      throw const BackupNewerVersionException();
    }

    final schema = decoded['schemaVersion'];
    final createdRaw = decoded['createdAt'];
    final payloadRaw = decoded['payload'];
    final checksum = decoded['checksum'];
    if (schema is! int ||
        schema < 1 ||
        createdRaw is! String ||
        payloadRaw is! String ||
        checksum is! String) {
      throw const BackupInvalidFileException();
    }

    final createdAt = DateTime.tryParse(createdRaw);
    if (createdAt == null) throw const BackupInvalidFileException();

    final Uint8List stored;
    try {
      stored = base64Decode(payloadRaw);
    } on FormatException {
      throw const BackupCorruptedException();
    }
    if (sha256.convert(stored).toString() != checksum) {
      throw const BackupCorruptedException();
    }

    final encrypted = decoded['encrypted'] == true;
    int? iterations;
    Uint8List? salt;
    if (encrypted) {
      final kdf = decoded['kdf'];
      if (kdf is! Map<String, dynamic>) {
        throw const BackupInvalidFileException();
      }
      final rawIterations = kdf['iterations'];
      final rawSalt = kdf['salt'];
      if (rawIterations is! int ||
          rawIterations < _minIterations ||
          rawIterations > _maxIterations ||
          rawSalt is! String) {
        throw const BackupInvalidFileException();
      }
      try {
        salt = base64Decode(rawSalt);
      } on FormatException {
        throw const BackupInvalidFileException();
      }
      iterations = rawIterations;
    }

    final summaryRaw = decoded['summary'];
    final appVersion = decoded['appVersion'];

    return ParsedBackup(
      header: BackupHeader(
        backupVersion: version,
        schemaVersion: schema,
        appVersion: appVersion is String ? appVersion : 'unknown',
        createdAt: createdAt,
        encrypted: encrypted,
        summary: summaryRaw is Map<String, dynamic>
            ? BackupSummary.fromJson(summaryRaw)
            : const BackupSummary(),
        kdfIterations: iterations,
        kdfSalt: salt,
      ),
      payloadBytes: stored,
    );
  }

  /// Расшифровывает и распаковывает содержимое.
  Future<Map<String, Object?>> readPayload(
      ParsedBackup parsed, {
        String? password,
      }) async {
    final header = parsed.header;
    var data = parsed.payloadBytes;

    if (header.encrypted) {
      if (password == null || password.isEmpty) {
        throw const BackupPasswordRequiredException();
      }
      final salt = header.kdfSalt;
      final iterations = header.kdfIterations;
      if (salt == null || iterations == null) {
        throw const BackupInvalidFileException();
      }
      final encryptedData = data;
      try {
        data = await Isolate.run(
              () => _decryptBytes(encryptedData, password, salt, iterations),
        );
      } on Object {
        throw const BackupWrongPasswordException();
      }
    }

    try {
      final json = jsonDecode(utf8.decode(gzip.decode(data)));
      if (json is! Map<String, dynamic>) {
        throw const BackupCorruptedException();
      }
      return json;
    } on Object {
      throw const BackupCorruptedException();
    }
  }
}