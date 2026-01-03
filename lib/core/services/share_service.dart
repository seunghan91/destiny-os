import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/web_download_stub.dart'
    if (dart.library.html) '../utils/web_download_web.dart'
    as web_download;

/// 공유 서비스
///
/// RepaintBoundary를 사용하여 위젯을 이미지로 캡처하고
/// SNS 플랫폼에 최적화된 형태로 공유하는 기능 제공
class ShareService {
  /// 위젯을 이미지로 캡처하고 공유
  ///
  /// [key]: RepaintBoundary의 GlobalKey
  /// [fileName]: 저장할 파일명 (확장자 제외)
  /// [shareText]: 공유 시 함께 전송할 텍스트
  static Future<void> captureAndShare({
    required GlobalKey key,
    required String fileName,
    String? shareText,
  }) async {
    try {
      // 1. RenderRepaintBoundary 가져오기
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('위젯을 찾을 수 없습니다. RepaintBoundary가 빌드되었는지 확인하세요.');
      }

      // 2. 위젯을 이미지로 변환 (고해상도: pixelRatio 3.0)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('이미지 변환에 실패했습니다.');
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        web_download.downloadBytes(
          pngBytes,
          fileName: '$fileName.png',
          mimeType: 'image/png',
        );
        if (shareText != null && shareText.trim().isNotEmpty) {
          try {
            await Share.share(shareText, subject: '운명의 OS 2026 - 궁합 분석');
          } catch (_) {}
        }
        return;
      }

      // 4. 공유
      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: '$fileName.png',
      );
      await Share.shareXFiles(
        [xFile],
        text: shareText,
        subject: '운명의 OS 2026 - 궁합 분석',
      );
    } catch (e) {
      throw Exception('공유 중 오류가 발생했습니다: $e');
    }
  }

  /// 위젯 캡처 결과를 "파일 경로"로 돌려주는 API는 웹에서 동작이 일관되지 않아 비권장입니다.
  /// 필요 시 `shareBytes` 또는 `captureAndShare`를 사용하세요.
  static Future<String> captureToFile({
    required GlobalKey key,
    required String fileName,
  }) async {
    throw UnsupportedError(
      'captureToFile는 더 이상 지원하지 않습니다. shareBytes/captureAndShare를 사용하세요.',
    );
  }

  /// 바이트 데이터를 공유
  ///
  /// [bytes]: 이미지 바이트 데이터
  /// [fileName]: 파일명 (확장자 포함)
  /// [shareText]: 공유 시 함께 전송할 텍스트
  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    String? shareText,
  }) async {
    try {
      if (kIsWeb) {
        web_download.downloadBytes(
          bytes,
          fileName: fileName,
          mimeType: 'image/png',
        );
        if (shareText != null && shareText.trim().isNotEmpty) {
          try {
            await Share.share(shareText, subject: '운명의 OS 2026');
          } catch (_) {}
        }
        return;
      }

      final xFile = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: fileName,
      );
      await Share.shareXFiles([xFile], text: shareText, subject: '운명의 OS 2026');
    } catch (e) {
      throw Exception('공유 중 오류가 발생했습니다: $e');
    }
  }

  /// 텍스트만 공유
  ///
  /// [text]: 공유할 텍스트
  /// [subject]: 공유 제목 (이메일 등에서 사용)
  static Future<void> shareText({required String text, String? subject}) async {
    try {
      await Share.share(text, subject: subject ?? '운명의 OS 2026');
    } catch (e) {
      throw Exception('공유 중 오류가 발생했습니다: $e');
    }
  }

  /// 공유 텍스트 생성 (궁합 분석용)
  ///
  /// [partnerName]: 상대방 이름
  /// [overallScore]: 총점
  static String generateCompatibilityShareText({
    required String partnerName,
    required int overallScore,
  }) {
    final emoji = overallScore >= 80
        ? '💕'
        : overallScore >= 60
        ? '✨'
        : overallScore >= 40
        ? '💪'
        : '🤔';

    return '''$emoji 나와 ${partnerName.isNotEmpty ? '${partnerName}님' : '그 사람'}의 궁합은 ${overallScore}점!

운명의 OS 2026에서 더 자세한 분석을 확인해보세요 👉 https://destiny-os-2026.web.app''';
  }
}
