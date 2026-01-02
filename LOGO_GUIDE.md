# 2026 신년운세 (MBTI 운세) - 로고 가이드

## 📱 앱인토스 등록용 로고

**위치**: `web/logos/`

### 라이트 버전 (밝은 배경용)
- **파일**: `app-logo-light-600.png`
- **크기**: 600x600 PNG
- **배경**: 흰색 (#FFFFFF)
- **메인 컬러**: 보라색 그라데이션 (#667eea → #764ba2)
- **포인트**: 금색 별 장식

### 다크 버전 (어두운 배경용)
- **파일**: `app-logo-dark-600.png`
- **크기**: 600x600 PNG
- **배경**: 다크 네이비 (#1a1a2e)
- **메인 컬러**: 금색 그라데이션 (#FFD700 → #FFA500)
- **포인트**: 빛나는 이펙트 + 별 장식

---

## 🎨 디자인 컨셉

### 심볼
- **수정구슬 (Crystal Ball)**: 운세를 상징하는 신비로운 구체
- **별 장식**: 2026년의 희망과 행운을 의미
- **그라데이션 효과**: 현대적이고 고급스러운 느낌

### 타이포그래피
1. **"2026"** - 가장 크게, 연도 강조
2. **"신년운세"** - 중간 크기, 한글 명확성
3. **"MBTI Fortune"** - 작게, 글로벌 호환성

### 컬러 시스템
| 모드 | 배경 | 메인 컬러 | 포인트 |
|------|------|-----------|--------|
| Light | #FFFFFF | #667eea → #764ba2 | #FFD700 |
| Dark | #1a1a2e | #FFD700 → #FFA500 | #FFFFFF |

---

## 📂 전체 로고 파일 위치

### 원본 소스 (SVG)
```
assets/
├── logo-light.svg        # 라이트 버전 원본
├── logo-dark.svg         # 다크 버전 원본
└── og-image.svg          # SNS 공유 이미지 원본
```

### 앱인토스용
```
web/logos/
├── app-logo-light-600.png  (600x600)
└── app-logo-dark-600.png   (600x600)
```

### iOS
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-1024x1024@1x.png
├── Icon-App-60x60@3x.png (180x180)
├── Icon-App-60x60@2x.png (120x120)
└── ... (총 13개 사이즈)
```

### Android
```
android/app/src/main/res/
├── mipmap-xxxhdpi/ic_launcher.png (192x192)
├── mipmap-xxhdpi/ic_launcher.png  (144x144)
├── mipmap-xhdpi/ic_launcher.png   (96x96)
├── mipmap-hdpi/ic_launcher.png    (72x72)
└── mipmap-mdpi/ic_launcher.png    (48x48)
```

### macOS
```
macos/Runner/Assets.xcassets/AppIcon.appiconset/
├── app_icon_1024.png
├── app_icon_512.png
├── app_icon_256.png
├── app_icon_128.png
├── app_icon_64.png
├── app_icon_32.png
└── app_icon_16.png
```

### Web/PWA
```
web/
├── icons/
│   ├── Icon-512.png
│   ├── Icon-192.png
│   ├── Icon-maskable-512.png
│   └── Icon-maskable-192.png
├── apple-touch-icon.png (180x180)
├── favicon.png (32x32)
└── og-image.png (1200x630)
```

---

## 📋 앱인토스 등록 정보

### 앱 정보
- **한국어 앱 이름**: 2026 신년운세 (MBTI 운세)
- **영어 앱 이름**: MBTI New Year Fortune 2026
- **appName**: fortune-2026-mbti
- **사용 연령**: 전체 또는 만 12세 이상

### 필수 파일
1. 라이트 로고: `web/logos/app-logo-light-600.png`
2. 다크 로고: `web/logos/app-logo-dark-600.png`

### 랜딩페이지
- URL: https://destiny-os-2026.web.app
- 구성: 소개/약관/개인정보/문의

### 고객센터
- 이메일: support@destinyos.app
- 운영시간: 평일 10:00~18:00

---

## 🔄 로고 업데이트 방법

### SVG 수정 후 전체 재생성
```bash
# 앱인토스용
rsvg-convert -w 600 -h 600 assets/logo-light.svg -o web/logos/app-logo-light-600.png
rsvg-convert -w 600 -h 600 assets/logo-dark.svg -o web/logos/app-logo-dark-600.png

# iOS (예시)
rsvg-convert -w 1024 -h 1024 assets/logo-dark.svg -o ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png

# Android (예시)
rsvg-convert -w 192 -h 192 assets/logo-dark.svg -o android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Web (예시)
rsvg-convert -w 512 -h 512 assets/logo-dark.svg -o web/icons/Icon-512.png
```

---

## ✅ 체크리스트

### 디자인 완료
- [x] 라이트 버전 로고 디자인
- [x] 다크 버전 로고 디자인
- [x] SNS 공유 이미지 디자인

### 플랫폼별 아이콘 생성
- [x] 앱인토스용 600x600 PNG 2종
- [x] iOS 앱 아이콘 (13개 사이즈)
- [x] Android 앱 아이콘 (5개 사이즈)
- [x] macOS 앱 아이콘 (7개 사이즈)
- [x] Web/PWA 아이콘 (6개)

### 브랜딩 업데이트
- [x] pubspec.yaml 앱 설명
- [x] web/index.html 메타 태그
- [x] web/about.html 서비스 소개
- [x] web/terms.html 이용약관
- [x] web/privacy.html 개인정보처리방침
- [x] README.md 프로젝트 설명

---

**최종 업데이트**: 2026년 1월 1일
**제작자**: Claude Code SuperClaude
**버전**: 1.0.0
