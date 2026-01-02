#!/bin/bash

# ============================================================================
# Flutter Web 최적화 빌드 스크립트
# ============================================================================
# 목표:
# - 번들 크기: 4.1MB → 1.2MB (71% 감소)
# - FCP: 1.69s → 0.9s (47% 개선)
# ============================================================================

set -e  # 에러 발생 시 중단

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Flutter Web 최적화 빌드 시작"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ============================================================================
# Step 1: 이전 빌드 정리
# ============================================================================
echo ""
echo "📦 Step 1: 이전 빌드 정리..."
rm -rf build/web
flutter clean

# ============================================================================
# Step 2: 최적화 빌드 실행
# ============================================================================
echo ""
echo "🔨 Step 2: 최적화 빌드 실행..."
echo ""

flutter build web \
  --release \
  --tree-shake-icons \
  --pwa-strategy offline-first \
  --source-maps \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/ \
  -O4

echo ""
echo "✅ 빌드 완료!"

# ============================================================================
# Step 3: NOTICES 파일 제거 (프로덕션 불필요)
# ============================================================================
echo ""
echo "🗑️  Step 3: NOTICES 파일 제거..."
if [ -f "build/web/assets/NOTICES" ]; then
  NOTICES_SIZE=$(du -h build/web/assets/NOTICES | cut -f1)
  echo "   NOTICES 크기: $NOTICES_SIZE"
  rm build/web/assets/NOTICES
  echo "   ✅ NOTICES 파일 삭제 완료"
else
  echo "   ℹ️  NOTICES 파일 없음"
fi

# ============================================================================
# Step 4: 번들 크기 분석
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step 4: 번들 크기 분석"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 전체 빌드 크기
TOTAL_SIZE=$(du -sh build/web | cut -f1)
echo ""
echo "📦 전체 빌드 크기: $TOTAL_SIZE"

# main.dart.js 크기
if [ -f "build/web/main.dart.js" ]; then
  MAIN_JS_SIZE=$(du -h build/web/main.dart.js | cut -f1)
  echo "📄 main.dart.js: $MAIN_JS_SIZE"
fi

# Deferred 번들 크기 (있는 경우)
echo ""
echo "📦 Deferred 번들:"
find build/web -name "main.dart.js_*.part.js" -type f -exec du -h {} \; | head -10

# CanvasKit 크기
echo ""
echo "🎨 CanvasKit:"
if [ -f "build/web/canvaskit/canvaskit.wasm" ]; then
  CANVASKIT_SIZE=$(du -h build/web/canvaskit/canvaskit.wasm | cut -f1)
  echo "   canvaskit.wasm: $CANVASKIT_SIZE"
fi

# 가장 큰 파일 Top 10
echo ""
echo "📊 가장 큰 파일 Top 10:"
find build/web -type f -size +100k -exec du -h {} \; | sort -rh | head -10

# ============================================================================
# Step 5: 압축 효과 시뮬레이션
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗜️  Step 5: Gzip 압축 효과 시뮬레이션"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v gzip &> /dev/null; then
  if [ -f "build/web/main.dart.js" ]; then
    # 원본 크기
    ORIGINAL_SIZE=$(stat -f%z build/web/main.dart.js 2>/dev/null || stat -c%s build/web/main.dart.js)

    # Gzip 압축 테스트
    gzip -c build/web/main.dart.js > /tmp/main.dart.js.gz
    GZIPPED_SIZE=$(stat -f%z /tmp/main.dart.js.gz 2>/dev/null || stat -c%s /tmp/main.dart.js.gz)

    # 압축률 계산
    REDUCTION=$(echo "scale=1; (1 - $GZIPPED_SIZE / $ORIGINAL_SIZE) * 100" | bc)

    echo ""
    echo "   원본: $(numfmt --to=iec-i --suffix=B $ORIGINAL_SIZE)"
    echo "   Gzip: $(numfmt --to=iec-i --suffix=B $GZIPPED_SIZE)"
    echo "   압축률: ${REDUCTION}%"

    rm /tmp/main.dart.js.gz
  fi
else
  echo "   ⚠️  gzip 명령어 없음 - 압축 시뮬레이션 스킵"
fi

# ============================================================================
# Step 6: 빌드 성공 요약
# ============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 빌드 성공!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📂 빌드 경로: build/web"
echo ""
echo "다음 단계:"
echo "  1. 로컬 테스트: cd build/web && python3 -m http.server 8000"
echo "  2. Lighthouse 측정: lighthouse http://localhost:8000"
echo "  3. Firebase 배포: firebase deploy"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
