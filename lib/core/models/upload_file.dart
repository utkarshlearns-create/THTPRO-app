import 'dart:typed_data';

/// A file the user picked, carried as bytes rather than a path.
///
/// A path is not portable. On web an `XFile` from the image picker has a blob
/// URL for a path and no filesystem behind it, so `MultipartFile.fromFile`
/// throws — KYC submission failed outright in the browser while working fine on
/// a device. Reading the bytes up front makes one code path serve both.
class UploadFile {
  const UploadFile({required this.bytes, required this.filename});

  final Uint8List bytes;

  /// Sent to the server as the upload's filename. The backend keys the stored
  /// document off the form field, not this, but the extension is what tells it
  /// the content type.
  final String filename;

  int get sizeBytes => bytes.length;
}
