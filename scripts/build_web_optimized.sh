#!/bin/bash
# ============================================================================
# 웹 빌드 최적화 스크립트
# - HTML 렌더러 사용 (CanvasKit 제거로 ~2MB 감소)
# - 최대 최적화 레벨 적용
# ============================================================================

set -e

echo "🚀 웹 빌드 최적화 시작..."
echo ""

# 프로젝트 루트로 이동
cd "$(dirname "$0")/.."

# 이전 빌드 정리
echo "🧹 이전 빌드 정리..."
flutter clean
rm -rf build/web

# 의존성 설치
echo "📦 의존성 설치..."
flutter pub get

# 최적화된 웹 빌드
echo ""
echo "🔨 최적화된 웹 빌드 중..."
echo "   - 렌더러: HTML (CanvasKit 제거)"
echo "   - 최적화 레벨: O4"
echo "   - 트리 셰이킹: 활성화"
echo ""

flutter build web \
  --release \
  --web-renderer html \
  --dart2js-optimization O4 \
  --no-source-maps

# 빌드 결과 확인
echo ""
echo "📊 빌드 결과:"
du -sh build/web
echo ""
echo "주요 파일 크기:"
ls -lh build/web/main.dart.js 2>/dev/null || echo "  main.dart.js: 분할됨"
ls -lh build/web/main.dart.js_*.part.js 2>/dev/null | head -5

# gzip 압축 크기 확인 (실제 전송 크기)
echo ""
echo "📦 gzip 압축 후 예상 크기:"
if [ -f build/web/main.dart.js ]; then
  GZIP_SIZE=$(gzip -c build/web/main.dart.js | wc -c | awk '{printf "%.1f", $1/1024/1024}')
  echo "  main.dart.js (gzip): ${GZIP_SIZE}MB"
fi

echo ""
echo "✅ 빌드 완료!"
echo ""
echo "다음 명령어로 배포하세요:"
echo "  firebase deploy --only hosting"
