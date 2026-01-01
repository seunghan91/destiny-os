# Pretendard 폰트 다운로드 가이드

Destiny.OS는 Pretendard 폰트를 사용합니다.

## 📥 다운로드 방법

### Option 1: GitHub Release (권장)
1. [Pretendard GitHub](https://github.com/orioncactus/pretendard) 방문
2. Releases 페이지에서 최신 버전 다운로드 (v1.3.9 이상)
3. `Pretendard-1.3.x.zip` 파일 다운로드
4. 압축 해제 후 `public/static` 폴더에서 TTF 파일 찾기

### Option 2: Direct Download
- [SourceForge Mirror](https://sourceforge.net/projects/pretendard.mirror/)에서 직접 다운로드

## 📁 필요한 파일 (9개 웨이트)

이 폴더(`assets/fonts/`)에 다음 TTF 파일들을 복사하세요:

```
assets/fonts/
├── Pretendard-Thin.ttf          (100)
├── Pretendard-ExtraLight.ttf    (200)
├── Pretendard-Light.ttf         (300)
├── Pretendard-Regular.ttf       (400) ← 기본
├── Pretendard-Medium.ttf        (500)
├── Pretendard-SemiBold.ttf      (600)
├── Pretendard-Bold.ttf          (700)
├── Pretendard-ExtraBold.ttf     (800)
└── Pretendard-Black.ttf         (900)
```

## ⚙️ 설치 후 작업

1. 모든 TTF 파일을 `assets/fonts/` 폴더에 복사
2. 터미널에서 실행:
   ```bash
   flutter pub get
   ```
3. 앱 완전 재시작 (Hot Reload/Restart가 아닌 완전 종료 후 재실행)

## 📄 라이선스

Pretendard는 **SIL Open Font License 1.1**로 배포됩니다.
- ✅ 상업적 사용 가능
- ✅ 수정 가능
- ✅ 재배포 가능

## 🔗 참고 링크

- [공식 GitHub](https://github.com/orioncactus/pretendard)
- [폰트 소개 페이지](https://cactus.tistory.com/306)
- [라이선스 전문](https://github.com/orioncactus/pretendard/blob/main/LICENSE)
