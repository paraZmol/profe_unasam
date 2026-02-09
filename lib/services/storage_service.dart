import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadProfesorSuggestionImage({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'suggestions/profesores/$userId/${timestamp}_$sanitizedName';
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: _guessContentType(fileName),
      cacheControl: 'public,max-age=31536000',
    );

    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  Future<String> uploadYapeQrImage({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'app_settings/yape_qr/$userId/${timestamp}_$sanitizedName';
    final ref = _storage.ref().child(path);

    final metadata = SettableMetadata(
      contentType: _guessContentType(fileName),
      cacheControl: 'public,max-age=31536000',
    );

    final task = await ref.putData(bytes, metadata);
    return task.ref.getDownloadURL();
  }

  String _guessContentType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.bmp')) return 'image/bmp';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
