import 'dart:typed_data';

/// 웹 다운로드(파일 저장) - 비웹 플랫폼용 스텁
///
/// 웹이 아닌 플랫폼에서는 false를 반환합니다.
bool downloadBytes(Uint8List bytes, {required String fileName, String mimeType = 'application/octet-stream'}) {
  return false;
}

