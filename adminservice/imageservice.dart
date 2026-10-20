// utils/image_utils.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker_platform_interface/src/types/image_source.dart';

class PlatformFileData {
  final String? path;
  final String? name;
  final Uint8List? bytes;
  final int? size;
  final String? extension;

  PlatformFileData({
    this.path,
    this.name,
    this.bytes,
    this.size,
    this.extension,
  });

  bool get isWeb => bytes != null;
  bool get isMobile => path != null;
}

class ImageUtils {
  static Future<PlatformFileData?> pickImage(ImageSource gallery) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // IMPORTANT for web
    );

    if (result == null) return null;

    final file = result.files.first;

    return PlatformFileData(
      path: file.path,
      name: file.name,
      bytes: file.bytes,
      size: file.size,
      extension: file.extension,
    );
  }

  static Uint8List? imageToBytes(dynamic image) {
    if (image is PlatformFileData) {
      return image.bytes;
    } else if (image is File) {
      return image.readAsBytesSync();
    }
    return null;
  }

  static String? getImageName(dynamic image) {
    if (image is PlatformFileData) {
      return image.name;
    } else if (image is File) {
      return image.path.split('/').last;
    }
    return null;
  }
}
