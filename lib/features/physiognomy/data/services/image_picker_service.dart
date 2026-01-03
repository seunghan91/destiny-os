import 'dart:typed_data';

import 'image_picker_stub.dart'
    if (dart.library.html) 'image_picker_web.dart'
    as picker;

/// 플랫폼별 이미지 선택 서비스
class ImagePickerService {
  /// 웹에서 이미지 파일 선택
  static Future<Uint8List?> pickImage() async {
    return picker.pickImageFromWeb();
  }
}
